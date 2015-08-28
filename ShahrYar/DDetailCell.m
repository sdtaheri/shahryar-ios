//
//  DDetailCell.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/16.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "DDetailCell.h"
#import "UIFontDescriptor+IranSans.h"

@implementation DDetailCell

- (void)awakeFromNib {

    self.labelDetail.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
    self.label.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
