//
//  ProgressSliderCell.swift
//  Pocket Casts
//
//  Created by Stuart Moore on 10/4/17.
//  Copyright © 2017 Morten Just Petersen. All rights reserved.
//

import Foundation

class ProgressSliderCell: NSSliderCell {

    let barRadius: CGFloat = 1.5

    override func drawKnob(_ knobRect: NSRect) {
        //
    }

    override func drawBar(inside rect: NSRect, flipped: Bool) {
        guard let controlWidth = controlView?.frame.width else {
            return super.drawBar(inside: rect, flipped: flipped)
        }

        var newRect = rect
        newRect.size.height = 3

        let value = CGFloat((doubleValue - minValue) / (maxValue - minValue))
        let finalWidth = CGFloat(value * (controlWidth - 2))

        var leftRect = newRect
        leftRect.size.width = finalWidth

        let backgroundPath = NSBezierPath(roundedRect: newRect, xRadius: barRadius, yRadius: barRadius)
        NSColor.scrollBarColor.setFill()
        backgroundPath.fill()

        let activePath = NSBezierPath(roundedRect: leftRect, xRadius: barRadius, yRadius: barRadius)
        NSColor.progressBlue.setFill()
        activePath.fill()
    }

}
