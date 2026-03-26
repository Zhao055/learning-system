import Foundation
import Network
import Combine

/// Monitors network connectivity using NWPathMonitor.
/// Used to auto-switch between Synapse (server) and Direct (MiniMax) modes.
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true
    @Published private(set) var isExpensive: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.zhiya.networkmonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    /// Check if Synapse server is reachable (network available + server responds)
    func isSynapseReachable() async -> Bool {
        guard isConnected else { return false }
        return await SynapseAPI.shared.testConnection()
    }
}
