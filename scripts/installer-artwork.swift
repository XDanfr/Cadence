import AppKit

// Finder coordinates use a top-left origin. Background and icon placement share this canvas.
let width = 800.0, height = 500.0
let output = CommandLine.arguments.dropFirst().first ?? "dist/installer"
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
let purple = NSColor(srgbRed: 0.34510, green: 0.33725, blue: 0.83922, alpha: 1)
let ink = NSColor(srgbRed: 0.16, green: 0.14, blue: 0.30, alpha: 1)
let iconURL = URL(fileURLWithPath: "Resources/Cadence.icon/icon.json")
let document = try JSONSerialization.jsonObject(with: Data(contentsOf: iconURL)) as! [String: Any]
let stops = (document["fill"] as! [String: Any])["linear-gradient"] as! [String]
func colour(_ value: String) -> NSColor {
    let parts = value.split(separator: ":", maxSplits: 1)
    let components = parts[1].split(separator: ",").map { CGFloat(Double($0)!) }
    return NSColor(colorSpace: parts[0] == "display-p3" ? .displayP3 : .sRGB, components: components, count: 4)
}
let gradient = NSGradient(colors: stops.map(colour))!
func text(_ value: String, top: Double, size: Double, weight: NSFont.Weight, colour: NSColor) {
    let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
    (value as NSString).draw(in: NSRect(x: 40, y: top, width: width - 80, height: 50), withAttributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: colour, .paragraphStyle: paragraph
    ])
}
func render(scale: Int, preview: Bool) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(width) * scale, pixelsHigh: Int(height) * scale,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .sRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    context.cgContext.translateBy(x: 0, y: height)
    context.cgContext.scaleBy(x: 1, y: -1)
    // AppKit text/image drawing also needs to know this context is flipped.
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context.cgContext, flipped: true)
    gradient.draw(from: NSPoint(x: 0, y: 0), to: NSPoint(x: width, y: height), options: [.drawsBeforeStartingLocation, .drawsAfterEndingLocation])
    purple.withAlphaComponent(0.85).setStroke()
    let border = NSBezierPath(roundedRect: NSRect(x: 16, y: 16, width: width - 32, height: height - 32), xRadius: 24, yRadius: 24)
    border.lineWidth = 3; border.stroke()
    text("Cadence", top: 52, size: 38, weight: .semibold, colour: ink)
    text("Drag Cadence to Applications", top: 106, size: 17, weight: .regular, colour: ink.withAlphaComponent(0.72))
    // Clean, rounded arrow between the two real Finder icons.
    let arrow = NSBezierPath(); arrow.lineWidth = 5; arrow.lineCapStyle = .round; arrow.lineJoinStyle = .round
    arrow.move(to: NSPoint(x: 346, y: 244)); arrow.line(to: NSPoint(x: 454, y: 244))
    arrow.move(to: NSPoint(x: 435, y: 225)); arrow.line(to: NSPoint(x: 454, y: 244)); arrow.line(to: NSPoint(x: 435, y: 263))
    purple.setStroke(); arrow.stroke()
    text("A little structure. A lot of breathing room.", top: 405, size: 14, weight: .regular, colour: ink.withAlphaComponent(0.58))
    if preview {
        let app = NSImage(contentsOfFile: "dist/Cadence.app/Contents/Resources/Cadence.icns")!
        let folder = NSWorkspace.shared.icon(forFile: "/Applications")
        app.draw(in: NSRect(x: 156, y: 180, width: 128, height: 128), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        folder.draw(in: NSRect(x: 516, y: 180, width: 128, height: 128), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        // Icon labels below are placed separately so their centres match the actual Finder layout.
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
        for (label, x) in [("Cadence", 140.0), ("Applications", 500.0)] {
            (label as NSString).draw(in: NSRect(x: x, y: 320, width: 160, height: 25), withAttributes: [
                .font: NSFont.systemFont(ofSize: 14), .foregroundColor: ink, .paragraphStyle: paragraph
            ])
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep
}
let background = NSImage(size: NSSize(width: width, height: height))
background.addRepresentation(render(scale: 1, preview: false))
background.addRepresentation(render(scale: 2, preview: false))
try background.tiffRepresentation!.write(to: URL(fileURLWithPath: "\(output)/background.tiff"))
try render(scale: 2, preview: true).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(output)/design-preview.png"))
