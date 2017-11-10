//
//  String+PodcastTrim.swift
//  Pocket Casts
//
//  Created by Stuart Moore on 10/3/17.
//  Copyright © 2017 Morten Just Petersen. All rights reserved.
//

import Foundation

extension String {

    func trimPodcastTitle(forShowTitle showTitle: String) -> String {
        if self.lowercased().hasPrefix(showTitle.lowercased()) {
            let trimmedTitle = String(suffix(count - showTitle.count))

            return trimmedTitle.trimPodcastTitle(forShowTitle: showTitle)
        } else if hasPrefix(" ") || hasSuffix(" ") {
            let trimmedTitle = trimmingCharacters(in: .whitespacesAndNewlines)

            return trimmedTitle.trimPodcastTitle(forShowTitle: showTitle)
        } else if let numberRange = rangeOfCharacter(from: .decimalDigits), numberRange.lowerBound == startIndex {
            let trimmedTitle = String(suffix(from: numberRange.upperBound))

            return trimmedTitle.trimPodcastTitle(forShowTitle: showTitle)
        } else if let punctuationRange = rangeOfCharacter(from: .punctuationCharacters), punctuationRange.lowerBound == startIndex {
            let trimmedTitle = String(suffix(from: punctuationRange.upperBound))

            return trimmedTitle.trimPodcastTitle(forShowTitle: showTitle)
        } else if self.lowercased().hasPrefix("ep.") {
            let trimmedTitle = String(suffix(count - 3))

            return trimmedTitle.trimPodcastTitle(forShowTitle: showTitle)
        } else {
            return self
        }
    }

}
