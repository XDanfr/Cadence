import AppKit
import Foundation

// Transparent 1024px foregrounds, with the same placement as the legacy icon.
// Icon Composer supplies the background, masking and Liquid Glass itself.
let folder = URL(fileURLWithPath: "dist/IconComposer")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
for (name, color) in [
    ("cadence-timer-purple", NSColor(red: 0.345, green: 0.337, blue: 0.839, alpha: 1)),
    ("cadence-timer-white", NSColor.white)
] {
    let pixels = 1024
    let p = CGFloat(pixels)
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: pixels * 4, bitsPerPixel: 32)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: p, height: p).fill()
    let configuration = NSImage.SymbolConfiguration(pointSize: p * 0.56, weight: .medium)
        .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
    guard let timer = NSImage(systemSymbolName: "timer", accessibilityDescription: "Cadence timer")?.withSymbolConfiguration(configuration) else {
        fatalError("The timer SF Symbol is unavailable")
    }
    let available = NSRect(x: p * 0.2, y: p * 0.19, width: p * 0.6, height: p * 0.62)
    let fit = min(available.width / timer.size.width, available.height / timer.size.height)
    let width = timer.size.width * fit
    let height = timer.size.height * fit
    timer.draw(in: NSRect(x: available.midX - width / 2, y: available.midY - height / 2, width: width, height: height))
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent("\(name).png"))
}
try Data(contentsOf: URL(fileURLWithPath: "docs/IconComposer-notes.md")).write(to: folder.appendingPathComponent("IconComposer-notes.md"))
