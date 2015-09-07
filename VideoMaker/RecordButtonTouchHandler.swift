//
//  RecordButtonTouchHandler.swift
//  VideoMaker
//
//  Created by Tom on 9/7/15.
//  Copyright (c) 2015 Tom. All rights reserved.
//

import Foundation

class RecordButtonTouchHandler: UIGestureRecognizer {
    override func touchesBegan(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        if enabled {
            state = .Began
        }
    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        if enabled {
            state = .Ended
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        if enabled {
            state = .Ended
        }
    }
}