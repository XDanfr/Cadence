import SwiftUI
import CadenceCore

struct OnboardingView: View {
    @EnvironmentObject private var model: Model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var draft: Preferences
    private let titles = ["Welcome to Cadence", "Find your pace", "Make it yours", "A gentle reminder"]
    init(preferences: Preferences) { _draft = State(initialValue: preferences) }
    var body: some View {
        VStack(spacing: 22) {
            HStack {
                Label("Cadence", systemImage: "timer").font(.headline)
                Spacer()
                Text("\(step + 1) of \(titles.count)").font(.caption).foregroundStyle(.secondary)
            }
            ProgressView(value: Double(step + 1), total: Double(titles.count)).accessibilityLabel("Setup progress")
            VStack(spacing: 10) {
                Image(systemName: ["timer", "dial.low", "paintpalette", "bell"][step])
                    .font(.system(size: 36, weight: .light)).foregroundStyle(model.accentColor)
                Text(titles[step]).font(.system(size: 28, weight: .semibold, design: .rounded))
            }.padding(.top, 4)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch step {
                    case 0:
                        Text("A little structure. A lot of breathing room.").font(.title3).frame(maxWidth: .infinity)
                        feature("One thing at a time", detail: "Set an intention, focus for a while, then make room for a break.", icon: "leaf")
                        feature("Always close by", detail: "Close the window and keep the countdown in your menu bar.", icon: "menubar.rectangle")
                        feature("Your time stays yours", detail: "Your settings and focus history stay on this Mac. No account needed.", icon: "lock")
                    case 1:
                        HStack {
                            pace("Classic", focus: 25, short: 5, long: 15)
                            pace("Deep work", focus: 50, short: 10, long: 20)
                            pace("Gentle start", focus: 15, short: 3, long: 10)
                        }
                        Stepper("Focus: \(draft.focusMinutes) minutes", value: $draft.focusMinutes, in: 1...180)
                        Stepper("Short break: \(draft.shortMinutes) minutes", value: $draft.shortMinutes, in: 1...60)
                        Stepper("Long break: \(draft.longMinutes) minutes", value: $draft.longMinutes, in: 1...120)
                        Stepper("Long break every \(draft.rounds) focus intervals", value: $draft.rounds, in: 2...12)
                        Toggle("Start breaks automatically", isOn: $draft.autoBreak)
                        Text("Focus intervals wait for you by default. You can change every interval and flow setting later.").font(.caption).foregroundStyle(.secondary)
                    case 2:
                        Picker("Accent colour", selection: Binding(get: { AccentTheme(rawValue: draft.accentTheme ?? "system") ?? .system }, set: { draft.accentTheme = $0.rawValue })) {
                            ForEach(AccentTheme.allCases) { theme in
                                Label { Text(theme.title) } icon: { Image(nsImage: theme.swatchImage).renderingMode(.original) }.tag(theme)
                            }
                        }
                        Picker("Appearance", selection: $draft.appearance) {
                            ForEach(["System", "Light", "Dark"], id: \.self) { Text($0).tag($0) }
                        }
                        Stepper("Daily goal: \(draft.dailyGoal) intervals", value: $draft.dailyGoal, in: 1...20)
                        Picker("Alarm sound", selection: $draft.sound) {
                            ForEach(model.sounds, id: \.self) { Text($0).tag($0) }
                        }
                        Text("The Mac accent follows your system colour, with purple for Multicolour. All settings can be changed later.").font(.caption).foregroundStyle(.secondary)
                    default:
                        Text("Get a quiet nudge when an interval ends. Notification access is optional; the timer and Apple alarm sounds work without it.")
                        Toggle("Show interval notifications", isOn: $draft.notifications)
                        NotificationSettingsView(showToggle: false)
                        Text("Apple Music asks for Automation permission only when you use its controls. Launch at login is available in Settings.").font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
            }
            HStack {
                Button(model.hasCompletedOnboarding ? "Cancel" : "Skip setup") { model.completeOnboarding() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                if step > 0 { Button("Back") { step -= 1 } }
                Button(step == titles.count - 1 ? "Let's begin" : "Continue") {
                    if step == titles.count - 1 { model.completeOnboarding(draft) } else { step += 1 }
                }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
            }
        }
        .padding(28).frame(width: 600, height: 600)
        .tint(model.accentColor)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: step)
        .interactiveDismissDisabled()
    }
    private func feature(_ title: String, detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.title2).foregroundStyle(model.accentColor).frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 6)
    }
    private func pace(_ name: String, focus: Int, short: Int, long: Int) -> some View {
        let selected = draft.focusMinutes == focus && draft.shortMinutes == short && draft.longMinutes == long
        return Button {
            draft.focusMinutes = focus; draft.shortMinutes = short; draft.longMinutes = long
        } label: {
            VStack(spacing: 5) {
                Text(name).font(.callout.weight(.semibold))
                Text("\(focus) / \(short) / \(long)").font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity).padding(12)
                .background(model.accentColor.opacity(selected ? 0.18 : 0.05), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? model.accentColor : .clear))
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
}
