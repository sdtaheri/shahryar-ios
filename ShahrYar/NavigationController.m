//
//  NavigationController.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/2.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "NavigationController.h"
#import "AppDelegate.h"

@interface NavigationController ()

@end

@implementation NavigationController

- (void)setShouldHideStatusBar:(BOOL)shouldHideStatusBar {
    _shouldHideStatusBar = shouldHideStatusBar;
    [UIView animateWithDuration:0.2 animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

- (BOOL)prefersStatusBarHidden {
    return self.shouldHideStatusBar;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    UIWindow *window = [(AppDelegate *)[UIApplication sharedApplication].delegate window];
    
    if (window.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        self.shouldHideStatusBar = YES;
    } else {
        self.shouldHideStatusBar = self.navigationBarHidden;
    }
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

@end
