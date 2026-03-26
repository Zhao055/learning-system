import SwiftUI

struct WelcomeSetupView: View {
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @StateObject private var vm = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZhiyaMascotView(emotion: .happy, size: 80)

                    Text("你好，我是知芽")
                        .font(ZhiyaTheme.heading(24))
                        .foregroundColor(ZhiyaTheme.darkBrown)

                    Text("配置 AI 后，知芽可以用更自然的方式和你对话")
                        .font(ZhiyaTheme.body(14))
                        .foregroundColor(ZhiyaTheme.lightBrown)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)

                // Server URL
                VStack(alignment: .leading, spacing: 8) {
                    Text("服务器地址")
                        .font(ZhiyaTheme.label())
                        .foregroundColor(ZhiyaTheme.darkBrown)

                    TextField("http://192.168.x.x:3000", text: $vm.serverURL)
                        .font(ZhiyaTheme.body(14))
                        .textFieldStyle(.roundedBorder)
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

                        connectionStatusIcon(vm.serverConnectionStatus)
                    }
                }
                .padding(.horizontal, 24)

                // API Key
                VStack(alignment: .leading, spacing: 8) {
                    Text("MiniMax API Key")
                        .font(ZhiyaTheme.label())
                        .foregroundColor(ZhiyaTheme.darkBrown)

                    SecureField("sk-...", text: $vm.apiKey)
                        .font(ZhiyaTheme.body(14))
                        .textFieldStyle(.roundedBorder)
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

                        connectionStatusIcon(vm.connectionStatus)
                    }
                }
                .padding(.horizontal, 24)

                // AI Mode
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI 模式")
                        .font(ZhiyaTheme.label())
                        .foregroundColor(ZhiyaTheme.darkBrown)

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
                .padding(.horizontal, 24)

                Spacer(minLength: 32)

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        vm.saveServerURL()
                        vm.saveApiKey()
                        hasCompletedSetup = true
                    } label: {
                        Text("下一步")
                            .font(ZhiyaTheme.label())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(ZhiyaTheme.goldenAmber)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        hasCompletedSetup = true
                    } label: {
                        Text("跳过，稍后设置")
                            .font(ZhiyaTheme.caption())
                            .foregroundColor(ZhiyaTheme.lightBrown)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(ZhiyaTheme.cream.ignoresSafeArea())
        .onAppear { vm.load() }
    }

    @ViewBuilder
    private func connectionStatusIcon(_ status: SettingsViewModel.ConnectionStatus) -> some View {
        switch status {
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
