import SwiftUI
import AppKit
import UserNotifications
import CadenceCore

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) { UNUserNotificationCenter.current().delegate = self }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) { completionHandler([.banner]) }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
@main struct CadenceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = Model()
    var body: some Scene {
        WindowGroup("Cadence", id: "main") {
            Dashboard().environmentObject(model).tint(model.accentColor)
                .preferredColorScheme(model.preferences.appearance == "Dark" ? .dark : model.preferences.appearance == "Light" ? .light : nil)
                .frame(minWidth: 820, minHeight: 620)
        }
        .defaultSize(width: 940, height: 700)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button(model.running ? "Pause timer" : "Start timer") { model.toggle() }.keyboardShortcut(.return, modifiers: .command)
                Button("Reset interval") { model.reset() }.keyboardShortcut("r", modifiers: .command)
                Button("Skip interval") { model.skip() }.keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
        MenuBarExtra {
            MenuPanel().environmentObject(model).tint(model.accentColor)
        } label: { Label(model.running ? model.clock : "Cadence", systemImage: "timer") }
        .menuBarExtraStyle(.window)
        Settings { SettingsView().environmentObject(model).tint(model.accentColor).frame(width: 540, height: 540) }
    }
}

struct GlassCard: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 28))
        } else if #available(macOS 26, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28))
        } else {
            content.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
                .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(.white.opacity(0.2)))
                .shadow(color: .black.opacity(0.06), radius: 20, y: 8)
        }
    }
}
extension View { func glassCard() -> some View { modifier(GlassCard()) } }

struct Dashboard: View {
    @EnvironmentObject private var model: Model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tab = 0
    @State private var showReset = false
    private var accent: Color { model.accentColor }
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            GeometryReader { proxy in
                Circle().fill(accent.opacity(0.25)).frame(width: 550).blur(radius: 100).offset(x: -170, y: -230)
                Circle().fill(accent.opacity(0.14)).frame(width: 440).blur(radius: 90).offset(x: proxy.size.width - 280, y: 230)
            }.allowsHitTesting(false)
            VStack(spacing: 22) {
                HStack {
                    Image(systemName: "timer").font(.title2).foregroundStyle(accent)
                    Text("Cadence").font(.title2.weight(.semibold))
                    Spacer()
                    Picker("Page", selection: $tab) { Text("Timer").tag(0); Text("Insights").tag(1) }.pickerStyle(.segmented).labelsHidden().frame(width: 190)
                    SettingsLink { Image(systemName: "slider.horizontal.3").font(.title3) }.buttonStyle(.plain).help("Settings · ⌘,")
                }.padding(.top, 18)
                if tab == 0 { ScrollView { timerPage.padding(.bottom, 4) }.scrollIndicators(.hidden) } else { InsightsView() }
                HStack {
                    Label("Find your rhythm. Keep your space.", systemImage: "sparkle").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("⌘R reset · ⇧⌘N skip").font(.caption).foregroundStyle(.tertiary)
                }
            }.padding(30)
        }
        .tint(accent)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: model.state.phase)
        .alert("Cadence", isPresented: Binding(get: { model.message != nil }, set: { if !$0 { model.message = nil } })) { Button("OK") { model.message = nil } } message: { Text(model.message ?? "") }
        .confirmationDialog("Reset this interval?", isPresented: $showReset) { Button("Reset interval", role: .destructive) { model.reset() } }
    }
    private var timerPage: some View {
        HStack(alignment: .top, spacing: 22) {
            VStack(spacing: 24) {
                HStack(spacing: 8) {
                    ForEach(Phase.allCases, id: \.self) { phase in
                        Button { model.select(phase) } label: {
                            Text(phase.title).font(.callout.weight(.medium)).padding(.horizontal, 15).padding(.vertical, 10)
                                .background(model.state.phase == phase ? accent.opacity(0.2) : .clear, in: Capsule())
                        }.buttonStyle(.plain)
                    }
                }
                ZStack {
                    Circle().stroke(accent.opacity(0.1), lineWidth: 13)
                    Circle().trim(from: 0, to: model.progress).stroke(accent.gradient, style: StrokeStyle(lineWidth: 13, lineCap: .round)).rotationEffect(.degrees(-90))
                    VStack(spacing: 10) {
                        Text(model.state.phase == .focus ? "MAKE ROOM FOR FOCUS" : "TAKE A LITTLE BREATHER").font(.system(size: 10, weight: .semibold, design: .rounded)).tracking(2).foregroundStyle(.secondary)
                        Text(model.clock).font(.system(size: 64, weight: .light, design: .rounded)).monospacedDigit().contentTransition(.numericText()).accessibilityLabel("\(model.clock) remaining")
                        Label(model.running ? "In your rhythm" : "Whenever you're ready", systemImage: model.running ? "waveform" : "moon").font(.caption).foregroundStyle(.secondary)
                    }
                }.frame(width: 260, height: 260).padding(8)
                HStack(spacing: 16) {
                    Button { if model.running || model.progress > 0 { showReset = true } else { model.reset() } } label: { Image(systemName: "arrow.counterclockwise") }.buttonStyle(.bordered).controlSize(.large).help("Reset interval")
                    Button { model.toggle() } label: { Label(model.running ? "Pause" : "Start", systemImage: model.running ? "pause.fill" : "play.fill").frame(width: 110) }.buttonStyle(.borderedProminent).controlSize(.large)
                    Button { model.skip() } label: { Image(systemName: "forward.end.fill") }.buttonStyle(.bordered).controlSize(.large).help("Skip without recording a session")
                }
                if model.alarmRinging { Button("Dismiss alarm", systemImage: "bell.slash") { model.stopAlarm() }.buttonStyle(.borderedProminent) }
                HStack(spacing: 7) {
                    ForEach(0..<max(1, model.preferences.rounds), id: \.self) { index in
                        Circle().fill(index < model.state.completedRounds % max(1, model.preferences.rounds) ? accent : accent.opacity(0.16)).frame(width: 8, height: 8)
                    }
                    Text("Round \(model.state.completedRounds % max(1, model.preferences.rounds) + 1) of \(model.preferences.rounds)").font(.caption).foregroundStyle(.secondary).padding(.leading, 5)
                }
            }.padding(25).frame(maxWidth: .infinity).glassCard()
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Your intention", systemImage: "pencil.line").font(.headline)
                    TextField("What are you working on?", text: $model.state.task, axis: .vertical).textFieldStyle(.plain).lineLimit(2...3)
                        .onChange(of: model.state.task) { _, _ in model.save() }
                    Divider()
                    Text("One thing at a time is enough.").font(.caption).foregroundStyle(.secondary)
                }.padding(22).glassCard()
                VStack(alignment: .leading, spacing: 14) {
                    HStack { Label("Today", systemImage: "sun.max").font(.headline); Spacer(); Text("\(model.today.count)/\(model.preferences.dailyGoal)").monospacedDigit().foregroundStyle(.secondary) }
                    ProgressView(value: Double(model.today.count), total: Double(max(model.preferences.dailyGoal, model.today.count)))
                    Text("\(Int(model.today.reduce(0) { $0 + $1.seconds }) / 60) minutes of focus").font(.caption).foregroundStyle(.secondary)
                }.padding(22).glassCard()
                VStack(alignment: .leading, spacing: 14) {
                    Label("Set the pace", systemImage: "dial.low").font(.headline)
                    preset("Classic", subtitle: "25 / 5 / 15", focus: 25, short: 5, long: 15)
                    preset("Deep work", subtitle: "50 / 10 / 20", focus: 50, short: 10, long: 20)
                    preset("Gentle start", subtitle: "15 / 3 / 10", focus: 15, short: 3, long: 10)
                    Button("Add 5 minutes", systemImage: "plus.circle") { model.extend() }.buttonStyle(.plain).font(.callout).padding(.top, 2)
                }.padding(22).glassCard()
                Button { model.musicToggle() } label: {
                    HStack { Image(systemName: "music.note").font(.title2); VStack(alignment: .leading) { Text("Music").font(.headline); Text("Play / pause Apple Music").font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "playpause.fill") }.padding(18)
                }.buttonStyle(.plain).glassCard().help("Control Music; opens it if it isn't running")
            }.frame(width: 270)
        }
    }
    private func preset(_ name: String, subtitle: String, focus: Int, short: Int, long: Int) -> some View {
        Button { model.preset(focus, short, long) } label: { HStack { Text(name); Spacer(); Text(subtitle).font(.caption).foregroundStyle(.secondary) } }.buttonStyle(.plain).disabled(model.running).help("Apply when the timer is paused")
    }
}

struct MenuPanel: View {
    @EnvironmentObject private var model: Model
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        VStack(spacing: 16) {
            HStack { Text("Cadence").font(.headline); Spacer(); Text(model.state.phase.title).foregroundStyle(.secondary) }
            Text(model.clock).font(.system(size: 46, weight: .light, design: .rounded)).monospacedDigit()
            if !model.state.task.isEmpty { Text(model.state.task).font(.caption).lineLimit(2) }
            ProgressView(value: model.progress)
            HStack { Button(model.running ? "Pause" : "Start") { model.toggle() }.buttonStyle(.borderedProminent); Button("Skip") { model.skip() }; Button("+5 min") { model.extend() } }
            if model.alarmRinging { Button("Dismiss alarm") { model.stopAlarm() } }
            Divider()
            HStack { Button("Open Cadence") { openWindow(id: "main"); NSApp.activate(ignoringOtherApps: true) }; Spacer(); SettingsLink { Image(systemName: "gearshape") } }
            Button("Quit Cadence") { model.save(); NSApp.terminate(nil) }.font(.caption).foregroundStyle(.secondary)
        }.padding(22).frame(width: 300)
    }
}
