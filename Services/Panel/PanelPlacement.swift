import AppKit

enum PanelPlacement {
    struct Result {
        let frame: NSRect
        let side: ResolvedSide
    }

    static func compute(
        calendarFrame: NSRect,
        preference: PanelSide,
        panelWidth: CGFloat,
        gap: CGFloat,
        screens: [NSScreen]
    ) -> Result {
        let screen = screens.first(where: { $0.frame.intersects(calendarFrame) }) ?? screens.first
        guard let screen else {
            return Result(frame: .zero, side: .noRoom)
        }

        let visible = screen.visibleFrame
        let needed = panelWidth + gap

        let fitsRight = (visible.maxX - calendarFrame.maxX) >= needed
        let fitsLeft  = (calendarFrame.minX - visible.minX) >= needed

        let resolvedSide: ResolvedSide
        switch preference {
        case .left:
            if fitsLeft        { resolvedSide = .left }
            else if fitsRight  { resolvedSide = .right }
            else               { resolvedSide = .noRoom }
        case .right, .auto:
            if fitsRight       { resolvedSide = .right }
            else if fitsLeft   { resolvedSide = .left }
            else               { resolvedSide = .noRoom }
        }

        guard resolvedSide != .noRoom else {
            return Result(frame: .zero, side: .noRoom)
        }

        let x: CGFloat
        switch resolvedSide {
        case .right:  x = calendarFrame.maxX + gap
        case .left:   x = calendarFrame.minX - gap - panelWidth
        case .noRoom: x = 0
        }

        let bottom = max(calendarFrame.minY, visible.minY)
        let top    = min(calendarFrame.maxY, visible.maxY)
        let height = max(0, top - bottom)

        let frame = NSRect(x: x, y: bottom, width: panelWidth, height: height)
        return Result(frame: frame, side: resolvedSide)
    }
}
