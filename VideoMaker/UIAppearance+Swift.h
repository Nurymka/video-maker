//
//  UIAppearance+Swift.h
//  VideoMaker
//
//  Created by Tom on 10/20/15.
//  Copyright © 2015 Tom. All rights reserved.
//

#import <UIKit/UIKit.h>
// from http://stackoverflow.com/questions/24136874/appearancewhencontainedin-in-swift
@interface UIView (UIViewAppearance_Swift)

// appearanceWhenContainedIn: is not available in Swift. This fixes that.
+ (instancetype)my_appearanceWhenContainedIn:(Class<UIAppearanceContainer>)containerClass;

@end
