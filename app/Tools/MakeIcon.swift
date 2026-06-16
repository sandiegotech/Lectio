// Generates the Lectio app icon (1024×1024 PNG) — a fine-binding mark in "The Margin"
// palette: a serif "L" in cream on oxblood cloth, a gilt double-rule frame, a gilt
// diamond. Run:  swift app/Tools/MakeIcon.swift <output.png>
import AppKit

let out = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "icon-1024.png"

let size: CGFloat = 1024

func color(_ hex: UInt) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

// No alpha — app icons must be fully opaque.
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                          bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false,
                          colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Cloth background — oxblood, darker toward the bottom for depth.
NSGradient(colors: [color(0x7C3328), color(0x431D16)])!
    .draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: -90)

// Gilt double-rule frame.
let gilt = color(0xC6A867)
gilt.setStroke()
func frame(inset: CGFloat, radius: CGFloat, line: CGFloat) {
    let r = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let p = NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius)
    p.lineWidth = line
    p.stroke()
}
frame(inset: 92, radius: 64, line: 9)
frame(inset: 128, radius: 46, line: 3)

// The serif "L".
let para = NSMutableParagraphStyle()
para.alignment = .center
let serif = NSFont(name: "Hoefler Text", size: 660)
    ?? NSFont(name: "Georgia-Bold", size: 620)
    ?? NSFont.systemFont(ofSize: 620, weight: .semibold)
let letter = NSAttributedString(string: "L", attributes: [
    .font: serif, .foregroundColor: color(0xEFE6D2), .paragraphStyle: para,
])
let ls = letter.size()
letter.draw(at: NSPoint(x: (size - ls.width) / 2, y: (size - ls.height) / 2 + 52))

// Gilt diamond ornament, centred low.
let cx = size / 2, cy: CGFloat = 250, d: CGFloat = 26
let dia = NSBezierPath()
dia.move(to: NSPoint(x: cx, y: cy + d))
dia.line(to: NSPoint(x: cx + d, y: cy))
dia.line(to: NSPoint(x: cx, y: cy - d))
dia.line(to: NSPoint(x: cx - d, y: cy))
dia.close()
gilt.setFill()
dia.fill()

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
