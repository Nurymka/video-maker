//
//  UIElementsContainer.swift
//  VideoMaker
//
//  Created by Tom on 10/22/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit

class UIElementsContainer: UIView {
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let hitTestView = super.hitTest(point, withEvent: event)
        if hitTestView == self {
            return nil
        }
        return hitTestView
    }
}
