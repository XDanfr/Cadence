import SwiftUI
import AppKit

enum AccentTheme: String, CaseIterable, Identifiable {
    case system, purple, blue, teal, green, yellow, orange, red, pink, graphite
    var id: String { rawValue }
    var title: String { self == .system ? "Mac accent colour" : rawValue.capitalized }
    // Native menu pickers tint symbol images with the current accent. Draw an
    // original, non-template swatch so each item retains its own colour.
    var swatchImage: NSImage {
        let fillColor = NSColor(color)
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { _ in
            fillColor.setFill()
            NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 12, height: 12)).fill()
            return true
        }
        image.isTemplate = false
        return image
    }
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
