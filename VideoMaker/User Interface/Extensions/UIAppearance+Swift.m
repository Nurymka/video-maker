//
//  UIAppearance+Swift.m
//  VideoMaker
//
//  Created by Tom on 10/20/15.
//  Copyright © 2015 Tom. All rights reserved.
//

#import "UIAppearance+Swift.h"

@implementation UIView (UIViewAppearance_Swift)
+ (instancetype)my_appearanceWhenContainedIn:(Class<UIAppearanceContainer>)containerClass {
    return [self appearanceWhenContainedIn:containerClass, nil];
}

@end
