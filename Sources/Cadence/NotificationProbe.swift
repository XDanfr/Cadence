import Foundation
import CadenceCore

/// Explicit developer/CI mode. It observes the real permission API; it never grants access.
@MainActor enum NotificationProbe {
    static func startIfRequested() {
        guard let flag = CommandLine.arguments.firstIndex(of: "--notification-probe"),
              CommandLine.arguments.indices.contains(flag + 1) else { return }
        let output = URL(fileURLWithPath: CommandLine.arguments[flag + 1])
        Task {
            let client = SystemNotifications()
            let initial = await client.settings()
            var finished = false
            let header = "Bundle: \(Bundle.main.bundleIdentifier ?? "none")\nInitial permission: \(initial.permission.rawValue)\n"
            func write(_ result: String) {
                try? (header + result + "\n").write(to: output, atomically: true, encoding: .utf8)
            }
            Task {
                do {
                    try await client.requestPermission()
                    let after = await client.settings()
                    finished = true
                    write("Request returned without error. Permission: \(after.permission.rawValue)")
                } catch {
                    finished = true
                    write("REQUEST ERROR: \(error.localizedDescription)")
                }
            }
            Task {
                try? await Task.sleep(for: .seconds(5))
                if !finished { write("Request is awaiting a user decision; CI does not answer the macOS prompt.") }
            }
        }
    }
}
