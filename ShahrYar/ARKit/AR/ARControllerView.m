//
//  ARControllerView.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/28.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "ARControllerView.h"

@implementation ARControllerView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *subview in self.subviews) {
        if ([subview pointInside: [subview convertPoint:point fromView:self] withEvent:event]) {
            return subview;
        }
    }
    return [super hitTest:point withEvent:event];
}

@end
