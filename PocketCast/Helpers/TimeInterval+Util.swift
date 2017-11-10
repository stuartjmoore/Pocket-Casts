//
//  TimeInterval+Util.swift
//  Pocket Casts
//
//  Created by Stuart Moore on 10/3/17.
//  Copyright © 2017 Morten Just Petersen. All rights reserved.
//

import Foundation

extension TimeInterval {

    var asClock: String {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2

        let hours = Int(self / 3600)
        let minutes = Int((truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(truncatingRemainder(dividingBy: 60))

        let hoursString = formatter.string(from: NSNumber(integerLiteral: hours)) ?? ""
        let minutesString = formatter.string(from: NSNumber(integerLiteral: minutes)) ?? ""
        let secondsString = formatter.string(from: NSNumber(integerLiteral: seconds)) ?? ""

        return "\(hoursString):\(minutesString):\(secondsString)"
    }

}
