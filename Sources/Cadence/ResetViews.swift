import SwiftUI
import AppKit
import CadenceCore

struct HistoryResetView: View {
    @EnvironmentObject private var model: Model
    @Environment(\.dismiss) private var dismiss
    @State private var scope: HistoryScope = .today
    @State private var from = Date()
    @State private var through = Date()
    @State private var confirm = false
    // Snapshot IDs when asking for confirmation, so a new completion is never silently deleted.
    @State private var selectedIDs: Set<UUID> = []
    private var range: HistoryRange? { HistoryRange(scope: scope, now: model.now, from: from, through: through) }
    private var matches: [Session] { guard let range else { return [] }; return model.sessions.filter { range.contains($0.date) } }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Reset focus history", systemImage: "arrow.counterclockwise").font(.title2.weight(.semibold))
            Text("Choose the days to clear. Your current timer, round count and settings stay as they are.").foregroundStyle(.secondary)
            Picker("Clear", selection: $scope) { ForEach(HistoryScope.allCases) { Text($0.title).tag($0) } }
            if scope == .custom {
                DatePicker("From", selection: $from, displayedComponents: .date)
                DatePicker("Through", selection: $through, displayedComponents: .date)
                Text("Includes both dates, using your Mac's time zone.").font(.caption).foregroundStyle(.secondary)
            }
            if range == nil { Text("The end date must be on or after the start date.").foregroundStyle(.red) }
            else { Text("\(matches.count) completed focus intervals will be removed.").font(.headline) }
            Text("Export a CSV from Insights first if you want a backup. This cannot be undone.").font(.caption).foregroundStyle(.secondary)
            HStack {
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Clear selected history…", role: .destructive) {
                    selectedIDs = Set(matches.map(\.id)); confirm = true
                }.disabled(range == nil || matches.isEmpty)
            }
        }.padding(28).frame(width: 460)
        .confirmationDialog("Permanently remove \(selectedIDs.count) focus intervals?", isPresented: $confirm, titleVisibility: .visible) {
            Button("Clear history", role: .destructive) {
                model.clearHistory(ids: selectedIDs); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct DataSettingsView: View {
    @EnvironmentObject private var model: Model
    @Environment(\.openWindow) private var openWindow
    @State private var showHistoryReset = false
    @State private var confirmAppReset = false
    var body: some View {
        Form {
            Section("Welcome") {
                Button("Show onboarding again", systemImage: "hand.wave") { openOnboarding() }
                Text("Revisit setup without clearing your history. Changes apply when you finish.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Focus history") {
                Text("\(model.sessions.count) completed focus intervals stored on this Mac.")
                Button("Export CSV…", systemImage: "square.and.arrow.up") { model.exportHistory() }
                Button("Reset history…", role: .destructive) { showHistoryReset = true }.disabled(model.sessions.isEmpty)
                Text("Clear today, the last seven days, a date range or all history.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Start fresh") {
                Button("Reset entire app…", role: .destructive) { confirmAppReset = true }
                Text("Stops the timer and alarm, clears history and intentions, restores default settings, turns off launch at login and brings back onboarding. macOS notification and Automation permissions are managed in System Settings and cannot be reset by Cadence.").font(.caption).foregroundStyle(.secondary)
            }
        }.formStyle(.grouped)
        .sheet(isPresented: $showHistoryReset) { HistoryResetView().environmentObject(model) }
        .confirmationDialog("Reset Cadence and permanently erase all focus history?", isPresented: $confirmAppReset, titleVisibility: .visible) {
            Button("Reset entire app", role: .destructive) {
                if model.resetApp() { openOnboarding() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Cadence", isPresented: Binding(get: { model.message != nil }, set: { if !$0 { model.message = nil } })) {
            Button("OK") { model.message = nil }
        } message: { Text(model.message ?? "") }
    }
    private func openOnboarding() {
        model.showOnboarding = true
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
