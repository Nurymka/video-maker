//
//  RecordButtonTouchGestureRecognizer.swift
//  VideoMaker
//
//  Created by Tom on 9/7/15.
//  Copyright (c) 2015 Tom. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

public class RecordButtonTouchGestureRecognizer: UIGestureRecognizer {
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if enabled {
            state = .Began
        }
    }
    
    override public func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if enabled {
            state = .Ended
        }
    }
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if enabled {
            state = .Ended
        }
    }
}