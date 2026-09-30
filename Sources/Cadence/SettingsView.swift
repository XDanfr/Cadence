import SwiftUI
import CadenceCore

struct SettingsView: View {
    @EnvironmentObject private var model: Model
    var body: some View {
        TabView {
            Form {
                Section("Intervals") {
                    Stepper("Focus: \(model.preferences.focusMinutes) minutes", value: $model.preferences.focusMinutes, in: 1...180)
                    Stepper("Short break: \(model.preferences.shortMinutes) minutes", value: $model.preferences.shortMinutes, in: 1...60)
                    Stepper("Long break: \(model.preferences.longMinutes) minutes", value: $model.preferences.longMinutes, in: 1...120)
                    Stepper("Long break every \(model.preferences.rounds) focus intervals", value: $model.preferences.rounds, in: 2...12)
                    Stepper("Daily goal: \(model.preferences.dailyGoal) intervals", value: $model.preferences.dailyGoal, in: 1...20)
                    Text("New durations apply to your next interval. Reset to apply them now.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Flow") {
                    Toggle("Automatically start breaks", isOn: $model.preferences.autoBreak)
                    Toggle("Automatically start focus intervals", isOn: $model.preferences.autoFocus)
                    Toggle("Keep Mac awake during focus", isOn: $model.preferences.preventSleep)
                }
            }.formStyle(.grouped).tabItem { Label("Timer", systemImage: "timer") }
            Form {
                Section("Apple alert sounds") {
                    Picker("Sound", selection: $model.preferences.sound) { ForEach(model.sounds, id: \.self) { Text($0).tag($0) } }
                    Slider(value: $model.preferences.volume, in: 0...1) { Text("Volume") }
                    Button("Preview sound") { model.playSound() }
                    Text("Uses the alert sounds installed with macOS. Alarms repeat until dismissed. Your Mac's output volume and mute setting still apply.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Notifications") {
                    Toggle("Show interval notifications", isOn: $model.preferences.notifications).onChange(of: model.preferences.notifications) { _, enabled in if enabled { model.requestNotifications() } else { model.scheduleNotification() } }
                    Button("Enable notifications…") { model.requestNotifications() }
                    Text("Focus modes can silence notifications. Cadence must be running to play its alarm; scheduled notifications can arrive while it is closed.").font(.caption).foregroundStyle(.secondary)
                }
            }.formStyle(.grouped).tabItem { Label("Alerts", systemImage: "bell") }
            Form {
                Section("Make yourself at home") {
                    Picker("Accent colour", selection: Binding(get: { model.accentTheme }, set: { model.accentTheme = $0 })) {
                        ForEach(AccentTheme.allCases) { theme in
                            Label { Text(theme.title) } icon: { Image(nsImage: theme.swatchImage).renderingMode(.original) }
                                .tag(theme)
                        }
                    }
                    HStack(spacing: 12) {
                        ForEach(AccentTheme.allCases.filter { $0 != .system }) { theme in
                            Button { model.accentTheme = theme } label: {
                                ZStack {
                                    Circle().fill(theme.color).frame(width: 25, height: 25)
                                    if model.accentTheme == theme { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white) }
                                }
                                .padding(3)
                                .overlay(Circle().strokeBorder(model.accentTheme == theme ? theme.color : .clear, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                            .help(theme.title)
                            .accessibilityLabel(theme.title)
                            .accessibilityAddTraits(model.accentTheme == theme ? .isSelected : [])
                        }
                    }
                    Text("Mac accent colour follows System Settings, with Cadence purple for Multicolour. A selected colour applies throughout Cadence, including breaks.").font(.caption).foregroundStyle(.secondary)
                    Picker("Appearance", selection: $model.preferences.appearance) { ForEach(["System", "Light", "Dark"], id: \.self) { Text($0).tag($0) } }
                    Toggle("Launch at login", isOn: $model.preferences.launchAtLogin).onChange(of: model.preferences.launchAtLogin) { _, _ in model.loginChanged() }
                    Text("Cadence keeps working in the menu bar when its window closes.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Cadence 1.0") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Made by XDan").font(.headline)
                        Text("A little structure. A lot of breathing room.").foregroundStyle(.secondary)
                    }
                    Link(destination: URL(string: "https://github.com/XDanfr/Sponsors")!) {
                        Label("Sponsor XDan", systemImage: "heart.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .help("Support XDan on GitHub")
                    Text("Made for macOS Sequoia and later. Native Liquid Glass on Tahoe; translucent materials on Sequoia. History stays on your Mac.").font(.caption).foregroundStyle(.secondary)
                    Link("Source code", destination: URL(string: "https://github.com/XDanfr/Cadence")!)
                }
            }.formStyle(.grouped).tabItem { Label("General", systemImage: "gearshape") }
        }.padding(12)
    }
}

struct InsightsView: View {
    @EnvironmentObject private var model: Model
    @State private var confirmClear = false
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 18) {
                metric("Today", value: "\(model.today.count)", detail: "completed intervals", icon: "checkmark.circle")
                metric("This week", value: "\(Int(model.week.reduce(0) { $0 + $1.seconds }) / 60)", detail: "focused minutes", icon: "chart.bar")
                metric("All time", value: "\(model.sessions.count)", detail: "moments of focus", icon: "sparkles")
            }
            VStack(alignment: .leading, spacing: 16) {
                HStack { Text("Your last seven days").font(.headline); Spacer() }
                HStack(alignment: .bottom, spacing: 20) {
                    ForEach((0..<7).reversed(), id: \.self) { offset in
                        let day = Calendar.current.date(byAdding: .day, value: -offset, to: model.now) ?? model.now
                        let count = model.sessions.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }.count
                        VStack { Text("\(count)").font(.caption).foregroundStyle(.secondary); RoundedRectangle(cornerRadius: 6).fill(model.accentColor.gradient).frame(height: max(5, 85 * min(1, Double(count) / Double(max(1, model.preferences.dailyGoal))))); Text(day, format: .dateTime.weekday(.abbreviated)).font(.caption) }.frame(maxWidth: .infinity).accessibilityElement(children: .combine)
                    }
                }.frame(height: 120)
            }.padding(24).glassCard()
            HStack { Text("Recent focus").font(.headline); Spacer(); Button("Export CSV", systemImage: "square.and.arrow.up") { model.exportHistory() }; Button("Clear history", role: .destructive) { confirmClear = true }.disabled(model.sessions.isEmpty) }
            if model.sessions.isEmpty {
                ContentUnavailableView("Your rhythm starts here", systemImage: "leaf", description: Text("Complete a focus interval to see it here."))
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.sessions.prefix(100)) { session in
                            HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(model.accentColor); VStack(alignment: .leading, spacing: 4) { Text(session.task.isEmpty ? "Focus interval" : session.task).lineLimit(1); Text(session.date, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(.secondary) }; Spacer(); Text("\(Int(session.seconds) / 60) min").monospacedDigit().foregroundStyle(.secondary) }.padding(14)
                            Divider()
                        }
                    }
                }.glassCard()
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .confirmationDialog("Permanently clear your focus history?", isPresented: $confirmClear) { Button("Clear history", role: .destructive) { model.sessions.removeAll(); model.save() } }
    }
    private func metric(_ title: String, value: String, detail: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) { Label(title, systemImage: icon).font(.callout).foregroundStyle(.secondary); Text(value).font(.system(size: 36, weight: .medium, design: .rounded)); Text(detail).font(.caption).foregroundStyle(.secondary) }.padding(24).frame(maxWidth: .infinity, alignment: .leading).glassCard()
    }
}
