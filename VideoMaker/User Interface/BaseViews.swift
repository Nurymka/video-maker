//
//  BaseViews.swift
//  VideoMaker
//
//  Created by Tom on 10/15/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit

public class BaseView : UIView {
    
    public convenience init() {
        self.init(frame: CGRectZero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public func commonInit() { }
}
