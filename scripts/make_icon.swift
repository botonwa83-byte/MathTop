import AppKit
let S: CGFloat = 1024
let image = NSImage(size: NSSize(width: S, height: S)); image.lockFocus()
NSGradient(starting: NSColor(red: 0.96, green: 0.39, blue: 0.25, alpha: 1), ending: NSColor(red: 0.98, green: 0.68, blue: 0.25, alpha: 1))!.draw(in: NSRect(x: 0, y: 0, width: S, height: S), angle: 45)
if let base = NSImage(systemSymbolName: "function", accessibilityDescription: nil), let sym = base.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 560, weight: .bold)) {
 let tinted = NSImage(size: sym.size); tinted.lockFocus(); sym.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1); NSColor.white.set(); NSRect(origin: .zero, size: sym.size).fill(using: .sourceAtop); tinted.unlockFocus(); let scale = 560 / max(sym.size.width, sym.size.height); tinted.draw(in: NSRect(x: (S-sym.size.width*scale)/2, y: (S-sym.size.height*scale)/2, width: sym.size.width*scale, height: sym.size.height*scale))
}
image.unlockFocus(); let png = NSBitmapImageRep(data: image.tiffRepresentation!)!.representation(using: .png, properties: [:])!; try! png.write(to: URL(fileURLWithPath: "MathTop/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"))
