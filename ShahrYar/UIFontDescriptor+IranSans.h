//
//  UIFontDescriptor+CustomFont.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/28.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFontDescriptor (IranSans)

+ (UIFontDescriptor *)preferredIranSansFontDescriptorWithTextStyle:(NSString *)style;

+ (UIFontDescriptor *)preferredIranSansBoldFontDescriptorWithTextStyle:(NSString *)style;

@end
