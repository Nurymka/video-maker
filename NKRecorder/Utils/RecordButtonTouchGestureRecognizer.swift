//
//  RecordButtonTouchGestureRecognizer.swift
//  VideoMaker
//
//  Created by Tom on 9/7/15.
//  Copyright (c) 2015 Tom. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass

class RecordButtonTouchGestureRecognizer: UIGestureRecognizer {
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if enabled {
            state = .Began
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if enabled {
            state = .Ended
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if enabled {
            state = .Ended
        }
    }
}