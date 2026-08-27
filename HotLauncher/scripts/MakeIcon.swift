import AppKit
import Foundation

guard CommandLine.arguments.count >= 2 else {
    fputs("usage: MakeIcon.swift <AppIcon.icns>\n", stderr)
    exit(1)
}

let dest = URL(fileURLWithPath: CommandLine.arguments[1])
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: size, height: size)
NSColor(calibratedWhite: 0.96, alpha: 1).setFill()
NSBezierPath(roundedRect: rect, xRadius: 220, yRadius: 220).fill()

NSColor.black.setFill()
let inset = rect.insetBy(dx: 180, dy: 180)
if let symbol = NSImage(systemSymbolName: "command.square.fill", accessibilityDescription: nil) {
    let config = NSImage.SymbolConfiguration(pointSize: 560, weight: .medium)
    let configured = symbol.withSymbolConfiguration(config) ?? symbol
    configured.draw(in: inset, from: .zero, operation: .sourceOver, fraction: 1)
}

image.unlockFocus()

let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("HotLauncher.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("failed to rasterize icon\n", stderr)
    exit(1)
}

let master = iconset.appendingPathComponent("icon_1024x1024.png")
try png.write(to: master)

let sizes = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes {
    let out = iconset.appendingPathComponent("icon_\(s)x\(s).png")
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    proc.arguments = ["-z", "\(s)", "\(s)", master.path, "--out", out.path]
    try proc.run()
    proc.waitUntilExit()
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", dest.path]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { exit(1) }
