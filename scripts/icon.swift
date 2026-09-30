import AppKit
import Foundation
let folder = URL(fileURLWithPath: "dist/AppIcon.iconset")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: pixels * 4, bitsPerPixel: 32)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let p = CGFloat(pixels)
        let rect = NSRect(x: p * 0.05, y: p * 0.05, width: p * 0.9, height: p * 0.9)
        let shape = NSBezierPath(roundedRect: rect, xRadius: p * 0.22, yRadius: p * 0.22)
        // A bright lavender/cyan glass tile keeps the purple timer vivid.
        let purple = NSColor(red: 0.345, green: 0.337, blue: 0.839, alpha: 1)
        NSGradient(colors: [
            NSColor(red: 0.84, green: 0.79, blue: 1.0, alpha: 1),
            NSColor(red: 0.96, green: 0.94, blue: 1.0, alpha: 1),
            NSColor(red: 0.64, green: 0.91, blue: 1.0, alpha: 1)
        ])!.draw(in: shape, angle: -45)
        NSGraphicsContext.saveGraphicsState()
        shape.addClip()
        let glow = NSBezierPath(ovalIn: NSRect(x: p * 0.12, y: p * 0.52, width: p * 0.8, height: p * 0.55))
        NSGradient(starting: .white.withAlphaComponent(0.65), ending: .white.withAlphaComponent(0))!.draw(in: glow, angle: -90)
        NSGraphicsContext.restoreGraphicsState()
        NSColor.white.withAlphaComponent(0.7).setStroke()
        shape.lineWidth = p * 0.012
        shape.stroke()
        // Use the same SF Symbol as the header and menu bar, rather than a
        // separate hand-drawn clock. Palette rendering bakes in Cadence purple.
        let configuration = NSImage.SymbolConfiguration(pointSize: p * 0.56, weight: .medium)
            .applying(NSImage.SymbolConfiguration(paletteColors: [purple]))
        guard let timer = NSImage(systemSymbolName: "timer", accessibilityDescription: "Cadence timer")?.withSymbolConfiguration(configuration) else {
            fatalError("The timer SF Symbol is unavailable")
        }
        let available = NSRect(x: p * 0.2, y: p * 0.19, width: p * 0.6, height: p * 0.62)
        let fit = min(available.width / timer.size.width, available.height / timer.size.height)
        let width = timer.size.width * fit
        let height = timer.size.height * fit
        timer.draw(in: NSRect(x: available.midX - width / 2, y: available.midY - height / 2, width: width, height: height))
        NSGraphicsContext.restoreGraphicsState()
        let suffix = scale == 2 ? "@2x" : ""
        try bitmap.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
    }
}
