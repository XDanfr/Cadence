import AppKit
import Foundation
let folder = URL(fileURLWithPath: "dist/AppIcon.iconset")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let image = NSImage(size: NSSize(width: pixels, height: pixels))
        image.lockFocus()
        let p = CGFloat(pixels)
        let rect = NSRect(x: p * 0.05, y: p * 0.05, width: p * 0.9, height: p * 0.9)
        let shape = NSBezierPath(roundedRect: rect, xRadius: p * 0.22, yRadius: p * 0.22)
        NSGradient(starting: NSColor(red: 0.32, green: 0.28, blue: 0.85, alpha: 1), ending: NSColor(red: 0.08, green: 0.65, blue: 0.7, alpha: 1))!.draw(in: shape, angle: -45)
        let ring = NSBezierPath(ovalIn: NSRect(x: p * 0.24, y: p * 0.24, width: p * 0.52, height: p * 0.52))
        NSColor.white.withAlphaComponent(0.9).setStroke(); ring.lineWidth = p * 0.045; ring.stroke()
        let hand = NSBezierPath(); hand.move(to: NSPoint(x: p * 0.5, y: p * 0.69)); hand.line(to: NSPoint(x: p * 0.5, y: p * 0.5)); hand.line(to: NSPoint(x: p * 0.64, y: p * 0.43)); hand.lineWidth = p * 0.045; hand.lineCapStyle = .round; hand.lineJoinStyle = .round; hand.stroke()
        image.unlockFocus()
        let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
        let suffix = scale == 2 ? "@2x" : ""
        try bitmap.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
    }
}
