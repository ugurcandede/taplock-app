#!/usr/bin/env swift

import Cocoa

// Generate a clean lock icon for TapLock app
// Rounded rect background with SF Symbol lock

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()

// Background: dark rounded rect
let bgRect = NSRect(x: 0, y: 0, width: size, height: size)
let cornerRadius: CGFloat = size * 0.22
let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)

// Gradient background
let gradient = NSGradient(
    starting: NSColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1.0),
    ending: NSColor(red: 0.06, green: 0.06, blue: 0.10, alpha: 1.0)
)!
gradient.draw(in: bgPath, angle: -90)

// Lock icon using SF Symbol
if let lockSymbol = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil) {
    let config = NSImage.SymbolConfiguration(pointSize: size * 0.45, weight: .light)
    let configured = lockSymbol.withSymbolConfiguration(config)!

    let symbolSize = configured.size
    let x = (size - symbolSize.width) / 2
    let y = (size - symbolSize.height) / 2

    NSColor.white.setFill()
    configured.draw(
        in: NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height),
        from: .zero,
        operation: .sourceOver,
        fraction: 0.9
    )
}

image.unlockFocus()

// Save as PNG
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
