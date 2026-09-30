import SwiftUI
import AppKit

enum AccentTheme: String, CaseIterable, Identifiable {
    case system, purple, blue, teal, green, yellow, orange, red, pink, graphite
    var id: String { rawValue }
    var title: String { self == .system ? "Mac accent colour" : rawValue.capitalized }
    var color: Color {
        switch self {
        case .system: return Color(nsColor: .controlAccentColor)
        case .purple: return .indigo
        case .blue: return .blue
        case .teal: return .teal
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .red: return .red
        case .pink: return .pink
        case .graphite: return .gray
        }
    }
}

extension Model {
    var accentTheme: AccentTheme {
        get { AccentTheme(rawValue: preferences.accentTheme ?? "system") ?? .system }
        set { preferences.accentTheme = newValue.rawValue }
    }
    var accentColor: Color { accentTheme.color }
}
