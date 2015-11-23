//
//  ResourceExtensions.swift
//  VideoMaker
//
//  Created by Tom on 10/18/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit

// xcres

//extension UIFont {
//    convenience init!(fontName: R.Fonts, size: CGFloat) {
//        self.init(name: fontName.rawValue, size: size)
//    }
//}

extension UIImage {
    convenience init?(key: R.ImagesAssets) {
        self.init(named: key.rawValue, inBundle: VideoMakerViewController.currentBundle, compatibleWithTraitCollection: nil)
    }
}
