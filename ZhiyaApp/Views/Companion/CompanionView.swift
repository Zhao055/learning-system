import SwiftUI

struct CompanionView: View {
    let companionEngine: CompanionEngine
    @StateObject private var viewModel: CompanionViewModel

    init(companionEngine: CompanionEngine) {
        self.companionEngine = companionEngine
        _viewModel = StateObject(wrappedValue: CompanionViewModel(companionEngine: companionEngine))
    }

    var body: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width

            ZStack {
                VStack(spacing: 0) {
                    // Top bar with settings
                    HStack {
                        Text("知芽")
                            .font(ZhiyaTheme.heading(18))
                            .foregroundColor(ZhiyaTheme.darkBrown)
                        Spacer()
                        Button { viewModel.showSettings = true } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(ZhiyaTheme.lightBrown)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial)

                    // Chat area — tap to dismiss keyboard
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.chatCoordinator.messages) { message in
                                    RichMessageView(
                                        message: message,
                                        availableWidth: availableWidth,
                                        onChallengeAnswer: viewModel.handleChallengeAnswer,
                                        onSuggestionTap: viewModel.handleSuggestionTap,
                                        onSpeak: viewModel.speakMessage,
                                        speakingMessageId: viewModel.ttsService.speakingMessageId
                                    )
                                    .id(message.id)
                                }
                            }
                            .padding(.vertical, 12)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .onChange(of: viewModel.chatCoordinator.messages.count) { _ in
                            if let last = viewModel.chatCoordinator.messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.chatCoordinator.messages.last?.content) { _ in
                            if let last = viewModel.chatCoordinator.messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }

                    // Input bar
                    CompanionInputBar(
                        inputText: $viewModel.inputText,
                        isLoading: viewModel.chatCoordinator.isLoading,
                        isRecording: viewModel.isRecording,
                        onSend: viewModel.sendMessage,
                        onCamera: { viewModel.showCamera = true },
                        onVoice: { viewModel.startVoiceInput() }
                    )
                }
                .background(ZhiyaTheme.cream.ignoresSafeArea())

                // Voice input overlay
                if viewModel.isRecording {
                    VoiceInputView(
                        speechService: viewModel.speechService,
                        onTranscription: { text in
                            viewModel.handleTranscription(text)
                        },
                        onDismiss: {
                            viewModel.stopVoiceInput()
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $viewModel.showSettings) {
            NavigationView {
                SettingsView()
                    .environmentObject(companionEngine)
            }
        }
        .sheet(isPresented: $viewModel.showCamera) {
            CameraInputSheet(isPresented: $viewModel.showCamera) { imageData in
                viewModel.sendImage(imageData)
            }
        }
        .onAppear {
            viewModel.generateProactiveMessages()
        }
    }
}
