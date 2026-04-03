#!/usr/bin/env swift

import Cocoa

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()

// Background: blue-indigo gradient rounded rect
let bgRect = NSRect(x: 0, y: 0, width: size, height: size)
let cornerRadius: CGFloat = size * 0.22
let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)

// Space Black MacBook tone
let gradient = NSGradient(colors: [
    NSColor(red: 0.14, green: 0.14, blue: 0.15, alpha: 1.0),
    NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0),
])!
gradient.draw(in: bgPath, angle: -90)

// Lock icon — white tinted
if let lockSymbol = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil) {
    let config = NSImage.SymbolConfiguration(pointSize: size * 0.45, weight: .light)
    let configured = lockSymbol.withSymbolConfiguration(config)!

    let symbolSize = configured.size
    let x = (size - symbolSize.width) / 2
    let y = (size - symbolSize.height) / 2
    let drawRect = NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height)

    // Draw symbol then composite white over it
    let tinted = NSImage(size: NSSize(width: symbolSize.width, height: symbolSize.height))
    tinted.lockFocus()
    configured.draw(in: NSRect(origin: .zero, size: symbolSize))
    NSColor.white.set()
    NSRect(origin: .zero, size: symbolSize).fill(using: .sourceAtop)
    tinted.unlockFocus()

    tinted.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 0.95)
}

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:])
else {
    print("Error: Failed to generate PNG")
    exit(1)
}

let outputPath = "AppIcon.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("Generated: \(outputPath) (\(Int(size))x\(Int(size)))")
