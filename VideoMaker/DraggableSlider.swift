//
//  DraggableSlider.swift
//  VideoMaker
//
//  Created by Tom on 9/30/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit
import QuartzCore

class DraggableSlider: UIControl {
    var minimumValue = 0.0 {
        didSet {
            updateLayerFrames()
        }
    }
    var maximumValue = 1.0 {
        didSet {
            updateLayerFrames()
        }
    }
    var lowerValue = 0.3 {
        didSet {
            updateLayerFrames()
        }
    }
    var upperValue = 0.8 {
        didSet {
            updateLayerFrames()
        }
    }
    var range = 0.0
    var previousLocation = CGPoint()
    
    let trackLayer = DraggableSliderTrackLayer()
    
    var trackTintColor = UIColor(white: 0.9, alpha: 1.0) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    var trackHighlightTintColor = UIColor(red: 0.0, green: 0.45, blue: 0.94, alpha: 1.0) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    var curvaceousness: CGFloat = 1.0 {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    override var frame: CGRect {
        didSet {
            updateLayerFrames()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        range = upperValue - lowerValue
        trackLayer.draggableSlider = self
        trackLayer.contentsScale = UIScreen.mainScreen().scale
        layer.addSublayer(trackLayer)
        updateLayerFrames()
    }
    
    func updateLayerFrames() {
        trackLayer.frame = bounds
        trackLayer.setNeedsDisplay()
    }
    
    func positionForValue(value: Double) -> Double {
        return Double(bounds.width) * (value - minimumValue) / (maximumValue - minimumValue)
    }
    
    func updateRange() {
        range = upperValue - lowerValue
    }
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        previousLocation = touch.locationInView(self)
        trackLayer.isHighlighted = trackLayer.isPositionHighlighted(previousLocation)
        if trackLayer.isHighlighted {
            sendActionsForControlEvents(.TouchDragEnter)
        }
        return trackLayer.isHighlighted
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let location = touch.locationInView(self)
        
        let deltaLocation = Double(location.x - previousLocation.x)
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width)
        
        previousLocation = location
        
        if !(deltaValue > 0 && upperValue == maximumValue) && !(deltaValue < 0 && lowerValue == minimumValue) {
            if lowerValue + deltaValue < minimumValue {
                lowerValue = minimumValue
                upperValue = minimumValue + range
            } else if upperValue + deltaValue > maximumValue {
                upperValue = maximumValue
                lowerValue = maximumValue - range
            } else {
                lowerValue += deltaValue
                upperValue += deltaValue
            }
        }
        sendActionsForControlEvents(.ValueChanged)
        return true
    }
    
    override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        if trackLayer.isHighlighted {
            sendActionsForControlEvents(.TouchDragExit)
        }
        trackLayer.isHighlighted = false
    }
}

class DraggableSliderTrackLayer: CALayer {
    weak var draggableSlider: DraggableSlider?
    
    var highlightedPortion: UIBezierPath?
    var isHighlighted = false
    
    override func drawInContext(ctx: CGContext) {
        if let slider = draggableSlider {
            let cornerRadius = bounds.height * slider.curvaceousness / 2.0
            let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
            CGContextAddPath(ctx, path.CGPath)
            
            CGContextSetFillColorWithColor(ctx, slider.trackTintColor.CGColor)
            CGContextAddPath(ctx, path.CGPath)
            CGContextFillPath(ctx)
            
            CGContextSetFillColorWithColor(ctx, slider.trackHighlightTintColor.CGColor)
            let lowerValuePosition = CGFloat(slider.positionForValue(slider.lowerValue))
            let upperValuePosition = CGFloat(slider.positionForValue(slider.upperValue))
            let highlightedRect = CGRect(x: lowerValuePosition, y: 0.0, width: upperValuePosition - lowerValuePosition, height: bounds.height)
            highlightedPortion = UIBezierPath(roundedRect: highlightedRect, cornerRadius: cornerRadius)
            CGContextAddPath(ctx, highlightedPortion!.CGPath)
            CGContextFillPath(ctx)
        }
    }
    
    func isPositionHighlighted(point: CGPoint) -> Bool {
        if let path = highlightedPortion {
            if path.containsPoint(point) {
                return true
            }
        }
        return false
    }
}
