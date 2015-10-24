//
//  GeometryExtensions.swift
//  VideoMaker
//
//  Created by Tom on 10/15/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit

public let π = CGFloat(M_PI)

extension CGRect {
    public var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    
    public init(center: CGPoint, width: CGFloat, height: CGFloat) {
        let origin = CGPoint(x: center.x - width / 2, y: center.y - height / 2)
        self.init(origin: origin, size: CGSize(width: width, height: height))
    }
    
    public init(center: CGPoint, radius: CGFloat) {
        self.init(center: center, width: radius * 2, height: radius * 2)
    }
}

extension UIBezierPath {
    public convenience init(circleCenter: CGPoint, radius: CGFloat) {
        self.init(ovalInRect: CGRect(center: circleCenter, radius: radius))
    }
}