import Foundation
import Speech
import AVFoundation
import UIKit

@MainActor
final class SpeechService: ObservableObject {
    @Published var transcription = ""
    @Published var isRecording = false
    @Published var audioLevel: Float = 0
    @Published var permissionDenied = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?

    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            permissionDenied = true
            return false
        }

        let audioGranted: Bool
        if #available(iOS 17.0, *) {
            audioGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            audioGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        guard audioGranted else {
            permissionDenied = true
            return false
        }

        permissionDenied = false
        return true
    }

    func startRecording() throws {
        // Reset state
        task?.cancel()
        task = nil
        transcription = ""
        audioLevel = 0

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }

        request.shouldReportPartialResults = true
        if #available(iOS 17, *) {
            request.requiresOnDeviceRecognition = recognizer?.supportsOnDeviceRecognition ?? false
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            request.append(buffer)
            // Extract RMS for audio level
            let channelData = buffer.floatChannelData?[0]
            let frames = Int(buffer.frameLength)
            if let data = channelData, frames > 0 {
                var sum: Float = 0
                for i in 0..<frames {
                    sum += data[i] * data[i]
                }
                let rms = sqrtf(sum / Float(frames))
                let level = min(max(rms * 8, 0), 1) // Normalize to 0-1
                Task { @MainActor [weak self] in
                    self?.audioLevel = level
                }
            }
        }

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let result = result {
                    self.transcription = result.bestTranscription.formattedString
                    self.resetSilenceTimer()
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stopRecordingInternal()
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        resetSilenceTimer()

        // Listen for app background
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.stopRecordingInternal()
            }
        }
    }

    func stopRecording() -> String {
        let finalText = transcription
        stopRecordingInternal()
        return finalText
    }

    private func stopRecordingInternal() {
        silenceTimer?.invalidate()
        silenceTimer = nil

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        isRecording = false
        audioLevel = 0

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.stopRecordingInternal()
            }
        }
    }
}
