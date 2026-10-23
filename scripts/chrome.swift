// Renders the Simulator's own device chrome as a bezel PNG with a transparent screen,
// from the artwork Xcode ships. Needs Xcode on this Mac.
//
// Usage: swift chrome.swift "<device type name>" <out.png> [--scale 3]
//
// The device type name is as in `xcrun simctl list devicetypes`, for example
// "iPhone 17 Pro". The screen's size comes from the device's framebuffer mask, which
// also shapes the hole, so the recording's corners hide under the bezel.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let arguments = CommandLine.arguments
guard arguments.count >= 3 else {
    print("Usage: swift chrome.swift \"<device type name>\" <out.png> [--scale 3]")
    exit(1)
}
let deviceName = arguments[1]
let output = URL(fileURLWithPath: arguments[2])
let scale: CGFloat = arguments.count >= 5 && arguments[3] == "--scale" ? CGFloat(Double(arguments[4]) ?? 3) : 3

let profileDirectory = "/Library/Developer/CoreSimulator/Profiles/DeviceTypes/\(deviceName).simdevicetype/Contents/Resources/"
guard let profile = NSDictionary(contentsOfFile: profileDirectory + "profile.plist"),
      let chromeIdentifier = profile["chromeIdentifier"] as? String,
      let maskName = profile["framebufferMask"] as? String
else {
    print("No simulator profile for \(deviceName)")
    exit(1)
}
let chromeName = chromeIdentifier.components(separatedBy: ".").last ?? ""
let chromeDirectory = "/Library/Developer/DeviceKit/Chrome/\(chromeName).devicechrome/Contents/Resources/"

func page(_ path: String) -> CGPDFPage {
    guard let document = CGPDFDocument(URL(fileURLWithPath: path) as CFURL), let page = document.page(at: 1) else {
        print("Missing \(path)")
        exit(1)
    }
    return page
}

let mask = page(profileDirectory + maskName + ".pdf")
let pixels = mask.getBoxRect(.mediaBox).size
let screen = CGSize(width: pixels.width / scale, height: pixels.height / scale)
let border: CGFloat = 18
let margin: CGFloat = 20
let body = CGRect(x: margin, y: margin, width: screen.width + border * 2, height: screen.height + border * 2)
let canvas = CGSize(width: body.width + margin * 2, height: body.height + margin * 2)

let context = CGContext(data: nil, width: Int(canvas.width * scale), height: Int(canvas.height * scale), bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
// Top-left origin in points.
context.translateBy(x: 0, y: canvas.height * scale)
context.scaleBy(x: scale, y: -scale)
context.interpolationQuality = .high

/// Draws a chrome PDF stretched into `rect`, clipped to it: the strips draw past their
/// one-point boxes.
func draw(_ name: String, in rect: CGRect) {
    let piece = page(chromeDirectory + name + ".pdf")
    let box = piece.getBoxRect(.mediaBox)
    context.saveGState()
    context.clip(to: rect)
    context.translateBy(x: rect.minX, y: rect.maxY)
    context.scaleBy(x: rect.width / box.width, y: -rect.height / box.height)
    context.drawPDFPage(piece)
    context.restoreGState()
}

// Buttons first: they sit under the body.
let buttons: [(String, Bool, CGFloat, CGSize)] = [
    ("Mute BTN", true, 160, CGSize(width: 16, height: 34)),
    ("Vol BTN", true, 221, CGSize(width: 16, height: 64)),
    ("Vol BTN", true, 300, CGSize(width: 16, height: 64)),
    ("X_Power BTN", false, 262, CGSize(width: 16, height: 101)),
]
for (name, isLeft, y, size) in buttons {
    let x = isLeft ? body.minX - size.width + 8 : body.maxX - 8
    draw(name, in: CGRect(x: x, y: body.minY + y, width: size.width, height: size.height))
}
let corner: CGFloat = 110
let inner = body.insetBy(dx: corner, dy: corner)
draw("Phone TL", in: CGRect(x: body.minX, y: body.minY, width: corner, height: corner))
draw("Phone TR", in: CGRect(x: body.maxX - corner, y: body.minY, width: corner, height: corner))
draw("Phone BL", in: CGRect(x: body.minX, y: body.maxY - corner, width: corner, height: corner))
draw("Phone BR", in: CGRect(x: body.maxX - corner, y: body.maxY - corner, width: corner, height: corner))
draw("Phone Top", in: CGRect(x: inner.minX, y: body.minY, width: inner.width, height: corner))
draw("Phone Base", in: CGRect(x: inner.minX, y: body.maxY - corner, width: inner.width, height: corner))
draw("Phone Left", in: CGRect(x: body.minX, y: inner.minY, width: corner, height: inner.height))
draw("Phone Right", in: CGRect(x: body.maxX - corner, y: inner.minY, width: corner, height: inner.height))
context.setFillColor(CGColor(gray: 0, alpha: 1))
context.fill(inner)

// Cut the screen out in the display's own shape.
context.saveGState()
context.setBlendMode(.destinationOut)
context.translateBy(x: body.minX + border, y: body.minY + border + screen.height)
context.scaleBy(x: 1 / scale, y: -1 / scale)
context.drawPDFPage(mask)
context.restoreGState()

guard let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)
else { exit(1) }
CGImageDestinationAddImage(destination, image, nil)
CGImageDestinationFinalize(destination)
print("\(output.path): screen \(Int(screen.width))x\(Int(screen.height)) points at \(Int(scale))x")
