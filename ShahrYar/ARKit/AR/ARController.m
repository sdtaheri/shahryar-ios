//
//  ARController.m
//  PrometAR
//
// Created by Geoffroy Lesage on 4/24/13.
// Copyright (c) 2013 Promet Solutions Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "ARController.h"

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransform3D.h>

#import "LocationMath.h"
#import "ARSettings.h"

#import "AROverlayView.h"

@interface ARController ()

@end

@implementation ARController

// -- Shape warper -- //
#define CATransform3DPerspective(t, x, y) (CATransform3DConcat(t, CATransform3DMake(1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1)))
#define CATransform3DMakePerspective(x, y) (CATransform3DPerspective(CATransform3DIdentity, x, y))

//CG_INLINE CATransform3D
//CATransform3DMake(CGFloat m11, CGFloat m12, CGFloat m13, CGFloat m14,
//				  CGFloat m21, CGFloat m22, CGFloat m23, CGFloat m24,
//				  CGFloat m31, CGFloat m32, CGFloat m33, CGFloat m34,
//				  CGFloat m41, CGFloat m42, CGFloat m43, CGFloat m44)
//{
//	CATransform3D t;
//	t.m11 = m11; t.m12 = m12; t.m13 = m13; t.m14 = m14;
//	t.m21 = m21; t.m22 = m22; t.m23 = m23; t.m24 = m24;
//	t.m31 = m31; t.m32 = m32; t.m33 = m33; t.m34 = m34;
//	t.m41 = m41; t.m42 = m42; t.m43 = m43; t.m44 = m44;
//	return t;
//}

#pragma mark - AR builders

- (NSArray*)radarSpots {
    NSMutableArray *spots = [NSMutableArray arrayWithCapacity:self.overlayViews.count];
    
    for (AROverlayView *overlayView in self.overlayViews) {
        NSDictionary *spot = @{@"angle": @([self.locationMath getARObjectXPosition:overlayView]/HORIZ_SENS),
                               @"distance": @([overlayView distanceFromLocation:self.userCoordinate])};
        [spots addObject:spot];
    }
    return [spots copy];
}

- (void)reloadData
{
    [self setVerticalPosWithDistance];
    [self checkForVerticalPosClashes];
    [self checkAllVerticalPos];
    
    [self setFramesForOverlays];
}

// Warps the view into a parrallelogram shape in order to give it a 3D perspective
-(void)warpView:(AROverlayView*)arView
{
//    arView.layer.sublayerTransform = CATransform3DMakePerspective(0, arView.vertice*-0.0003);
//    
//    float shrinkLevel = powf(0.95, arView.vertice-1);
//    arView.transform = CGAffineTransformMakeScale(shrinkLevel, shrinkLevel);
    
}
-(int)setYPosForView:(AROverlayView*)arView
{
    int pos = Y_CENTER-(int)(arView.frame.size.height*arView.vertice);
    pos -= (powf(arView.vertice, 2)*1);
    
    return pos-(arView.frame.size.height/2);
}

-(void)setVerticalPosWithDistance {
    for (AROverlayView *overlayView in self.overlayViews) {
        
        double distance = [overlayView distanceFromLocation:self.userCoordinate];
        
        if (distance < 20) {
            overlayView.vertice = 0;
        } else if (distance < 50) {
            overlayView.vertice = 1;
        } else if (distance < 100) {
            overlayView.vertice = 2;
        } else if (distance < 200) {
            overlayView.vertice = 3;
        } else if (distance < 300) {
            overlayView.vertice = 4;
        } else {
            overlayView.vertice = 5;
        }
    }
}

-(void)checkForVerticalPosClashes {
    BOOL gotConflict = YES;
    
    while (gotConflict) {
        gotConflict = NO;
        
        for (AROverlayView *overlayView in self.overlayViews) {
            for (AROverlayView *anotherOverlayView in self.overlayViews) {
                
                if (overlayView == anotherOverlayView) continue;
                
                if (overlayView.vertice != anotherOverlayView.vertice) continue;
                
                int diff = abs([self.locationMath getARObjectXPosition:overlayView] - [self.locationMath getARObjectXPosition:anotherOverlayView]);
                
                if (diff > overlayView.bounds.size.width) continue;
                
                gotConflict = YES;
                
                if (diff < overlayView.bounds.size.width &&
                    [anotherOverlayView distanceFromLocation:self.userCoordinate] < [overlayView distanceFromLocation:self.userCoordinate]) {
                    overlayView.vertice++;
                } else if (diff < overlayView.bounds.size.width) {
                    anotherOverlayView.vertice++;
                }
            }
        }
    }
}

-(void)checkAllVerticalPos {
    for (AROverlayView *overlayView in self.overlayViews) {
        if (overlayView.vertice == 0) {
            return;
        }
    }
    for (AROverlayView *overlayView in self.overlayViews) {
        overlayView.vertice--;
    }
    [self checkAllVerticalPos];
}

-(void)setFramesForOverlays {
    for (AROverlayView *overlayView in self.overlayViews) {
        
        [overlayView setFrame:CGRectMake([self.locationMath getARObjectXPosition:overlayView],
                                           [self setYPosForView:overlayView],
                                           overlayView.bounds.size.width,
                                           overlayView.bounds.size.height)];
        
        [self warpView:overlayView];
    }
}


#pragma mark - Main Initialization

- (id)init {
    self = [super init];
    if (self) {
        self.locationMath = [[LocationMath alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self.locationMath stopTracking];
}

@end
