//
//  FontKit.swift
//  VideoMaker
//
//  Created by Tom on 10/18/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit

class FontKit {
    static var regularWeightFontName = UIFont.systemFontOfSize(10).fontName
    static var mediumWeightFontName = UIFont.boldSystemFontOfSize(10).fontName
    static var boldWeightFontName = UIFont.boldSystemFontOfSize(10).fontName
    
    static let segmentedControlLabel = UIFont(name: regularWeightFontName, size: 16.0)!
    static let artistAndTrackNameLabel = UIFont(name: regularWeightFontName, size: 16.0)!
    static let captionFont = UIFont(name: mediumWeightFontName, size: 27.0)!
    static let navBarTitle = UIFont(name: regularWeightFontName, size: 20.0)!
    static let searchBarText = UIFont(name: regularWeightFontName, size: 14.0)!
    
    // UIAlertController Fonts
    static let alertControllerTitle = UIFont(name: regularWeightFontName, size: 14.0)!
    static let alertControllerMessage = UIFont(name: regularWeightFontName, size: 15.0)!
    static let alertControllerDefault = UIFont(name: regularWeightFontName, size: 18.0)!
    static let alertControllerDestructive = UIFont(name: regularWeightFontName, size: 18.0)!
    static let alertControllerCancel = UIFont(name: boldWeightFontName, size: 18.0)!
}
