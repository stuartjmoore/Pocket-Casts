//
//  DockProgressView.swift
//  Pocket Casts
//
//  Created by Moore, Stuart on 12/13/15.
//  Copyright © 2015 Morten Just Petersen. All rights reserved.
//

import Cocoa

class DockProgressView: NSView {

    let thickness: CGFloat = 4

    var percentage: Float = 0 {
        didSet {
            setNeedsDisplayInRect(bounds)
        }
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        let icon = NSWorkspace.sharedWorkspace().iconForFile(NSBundle.mainBundle().bundlePath)
        icon.drawInRect(bounds, fromRect: .zero, operation: .CompositeSourceOver, fraction: 1)

        let rect = bounds.insetBy(dx: thickness + thickness / 2, dy: thickness + thickness / 2)
        let start = NSPoint(x: rect.midX, y: rect.maxY)
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width / 2

        let angle: CGFloat = percentage < 0.25 ? 90 - 360 * CGFloat(percentage) + 360 : 90 - 360 * CGFloat(percentage)

        let arc = NSBezierPath()
        arc.moveToPoint(start)

        arc.appendBezierPathWithArcWithCenter(center,
            radius: radius,
            startAngle: 90,
            endAngle: angle,
            clockwise: true)

        NSColor.whiteColor().set()
        arc.lineWidth = thickness
        arc.stroke()
    }

}
