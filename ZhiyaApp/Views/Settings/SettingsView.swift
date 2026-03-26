import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var companion: CompanionEngine
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SettingsViewModel()
    @State private var showClearAlert = false

    var body: some View {
        Form {
            // Profile
            Section("个人信息") {
                HStack {
                    ZhiyaMascotView(emotion: .happy, size: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(companion.profile.childName.isEmpty ? "未设置" : companion.profile.childName)
                            .font(ZhiyaTheme.heading(16))
                        Text("第\(companion.profile.daysSinceJoin)天 · \(companion.profile.stage.label)")
                            .font(ZhiyaTheme.caption())
                            .foregroundColor(ZhiyaTheme.lightBrown)
                    }
                }
            }

            // API
            Section("AI 设置") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MiniMax API Key")
                        .font(ZhiyaTheme.caption())
                        .foregroundColor(ZhiyaTheme.lightBrown)
                    SecureField("sk-...", text: $vm.apiKey)
                        .font(ZhiyaTheme.body(14))
                        .onSubmit { vm.saveApiKey() }

                    HStack {
                        Button("保存") { vm.saveApiKey() }
                            .font(ZhiyaTheme.label())
                            .foregroundColor(ZhiyaTheme.goldenAmber)

                        Spacer()

                        Button("测试连接") { vm.testConnection() }
                            .font(ZhiyaTheme.label())
                            .foregroundColor(ZhiyaTheme.softTeal)
                            .disabled(vm.isTesting)

                        switch vm.connectionStatus {
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(ZhiyaTheme.integrity)
                        case .failed:
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ZhiyaTheme.empathy)
                        case .testing:
                            ProgressView()
                        case .unknown:
                            EmptyView()
                        }
                    }
                }
            }

            Section("服务器") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("服务器地址")
                        .font(ZhiyaTheme.caption())
                        .foregroundColor(ZhiyaTheme.lightBrown)
                    TextField("http://192.168.x.x:3000", text: $vm.serverURL)
                        .font(ZhiyaTheme.body(14))
                        .onSubmit { vm.saveServerURL() }

                    HStack {
                        Button("保存") { vm.saveServerURL() }
                            .font(ZhiyaTheme.label())
                            .foregroundColor(ZhiyaTheme.goldenAmber)

                        Spacer()

                        Button("测试连接") { vm.saveServerURL(); vm.testServerConnection() }
                            .font(ZhiyaTheme.label())
                            .foregroundColor(ZhiyaTheme.softTeal)
                            .disabled(vm.isTestingServer)

                        switch vm.serverConnectionStatus {
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(ZhiyaTheme.integrity)
                        case .failed:
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ZhiyaTheme.empathy)
                        case .testing:
                            ProgressView()
                        case .unknown:
                            EmptyView()
                        }
                    }
                }
            }

            Section("AI 模式") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("模式", selection: $vm.aiMode) {
                        ForEach(AIMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(vm.aiMode.description)
                        .font(ZhiyaTheme.caption())
                        .foregroundColor(ZhiyaTheme.lightBrown)
                }
            }

            // Exam date
            Section("考试日期") {
                Toggle("设置考试日期", isOn: $vm.hasExamDate)
                if vm.hasExamDate {
                    DatePicker("考试日期", selection: $vm.examDate, displayedComponents: .date)
                        .onChange(of: vm.examDate) { vm.saveExamDate(companion: companion) }
                }
            }

            // Data
            Section("数据管理") {
                Button("清除所有学习记录") { showClearAlert = true }
                    .foregroundColor(ZhiyaTheme.empathy)
            }
        }
        .scrollContentBackground(.hidden)
        .background(ZhiyaTheme.cream.ignoresSafeArea())
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("完成") { dismiss() }
                    .foregroundColor(ZhiyaTheme.goldenAmber)
            }
        }
        .onAppear { vm.load() }
        .alert("确认清除", isPresented: $showClearAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) { vm.clearProgress() }
        } message: {
            Text("这将清除所有学习记录和错题本数据，无法恢复。")
        }
    }
}
