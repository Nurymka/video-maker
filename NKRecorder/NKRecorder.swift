//
//  File.swift
//  VideoMaker
//
//  Created by Tom on 10/24/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit

public struct NKRecorder {
    static let currentBundle = NSBundle(identifier: "me.tom.NKRecorder")!
    
    public static func rootNavController() -> UINavigationController {
        loadCustomFonts()
        let main = UIStoryboard(name: "Main", bundle: currentBundle)
        return main.instantiateViewControllerWithIdentifier("NKRecorderRootNavController") as! UINavigationController
    }
    
    private static func loadCustomFonts() {
        func iterateEnum<T: Hashable>(_: T.Type) -> AnyGenerator<T> {
            var i = 0
            return anyGenerator {
                let next = withUnsafePointer(&i) { UnsafePointer<T>($0).memory }
                return next.hashValue == i++ ? next : nil
            }
        }
        
        for font in iterateEnum(R.Fonts.self) {
            let fontURL = currentBundle.URLForResource(font.rawValue, withExtension: ".ttf")
            
            if let fontData = NSData(contentsOfURL: fontURL!) {
                let provider = CGDataProviderCreateWithCFData(fontData as CFDataRef)
                let font = CGFontCreateWithDataProvider(provider)
                var error: Unmanaged<CFError>?
                if (!CTFontManagerRegisterGraphicsFont(font!, &error)) {
                    print("Failed to register font: \(error)")
                }
            }
        }
    }
}