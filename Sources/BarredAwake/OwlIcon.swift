import AppKit

/// Draws the menu-bar owl. Eyes are shut when `awake` is false,
/// wide open when `awake` is true. Rendered as a template image so it
/// tints itself to the menu bar (light/dark, active/inactive).
enum OwlIcon {
    static func image(awake: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            draw(in: rect, awake: awake)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func draw(in rect: NSRect, awake: Bool) {
        let s = min(rect.width, rect.height)
        let cx = rect.midX
        // Work in a square inset slightly from the edges.
        let pad = s * 0.06
        let line = max(1.0, s * 0.085)

        NSColor.black.setStroke()
        NSColor.black.setFill()

        // --- Ear tufts -------------------------------------------------
        let tuftW = s * 0.20
        let tuftH = s * 0.22
        let tuftY = rect.maxY - pad - tuftH
        for sign in [-1.0, 1.0] {
            let baseX = cx + sign * s * 0.26
            let tuft = NSBezierPath()
            tuft.move(to: NSPoint(x: baseX - tuftW / 2, y: tuftY))
            tuft.line(to: NSPoint(x: baseX, y: tuftY + tuftH))
            tuft.line(to: NSPoint(x: baseX + tuftW / 2, y: tuftY))
            tuft.close()
            tuft.fill()
        }

        // --- Head ------------------------------------------------------
        let headRect = NSRect(
            x: rect.minX + pad,
            y: rect.minY + pad,
            width: s - pad * 2,
            height: (tuftY + tuftH * 0.35) - (rect.minY + pad)
        )
        let head = NSBezierPath(ovalIn: headRect)
        head.lineWidth = line
        head.stroke()

        // --- Eyes ------------------------------------------------------
        let eyeY = headRect.midY + headRect.height * 0.10
        let eyeDX = headRect.width * 0.21
        let eyeCenters = [NSPoint(x: cx - eyeDX, y: eyeY),
                          NSPoint(x: cx + eyeDX, y: eyeY)]

        if awake {
            // Wide-open eyes: big ring + filled pupil.
            let r = headRect.width * 0.165
            for c in eyeCenters {
                let socket = NSBezierPath(ovalIn: NSRect(x: c.x - r, y: c.y - r,
                                                         width: r * 2, height: r * 2))
                socket.lineWidth = line * 0.9
                socket.stroke()
                let pr = r * 0.45
                NSBezierPath(ovalIn: NSRect(x: c.x - pr, y: c.y - pr,
                                            width: pr * 2, height: pr * 2)).fill()
            }
        } else {
            // Shut eyes: sleepy downward arcs ⌒ with little lashes.
            let w = headRect.width * 0.18
            for c in eyeCenters {
                let lid = NSBezierPath()
                lid.move(to: NSPoint(x: c.x - w, y: c.y))
                lid.curve(to: NSPoint(x: c.x + w, y: c.y),
                          controlPoint1: NSPoint(x: c.x - w * 0.4, y: c.y - w * 0.9),
                          controlPoint2: NSPoint(x: c.x + w * 0.4, y: c.y - w * 0.9))
                lid.lineWidth = line
                lid.lineCapStyle = .round
                lid.stroke()
            }
        }

        // --- Beak ------------------------------------------------------
        let beakH = headRect.height * 0.16
        let beakW = headRect.width * 0.12
        let beakTop = eyeY - headRect.height * 0.14
        let beak = NSBezierPath()
        beak.move(to: NSPoint(x: cx - beakW / 2, y: beakTop))
        beak.line(to: NSPoint(x: cx + beakW / 2, y: beakTop))
        beak.line(to: NSPoint(x: cx, y: beakTop - beakH))
        beak.close()
        beak.fill()
    }
}
