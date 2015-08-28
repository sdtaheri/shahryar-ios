//
//  AboutTVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/23.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "AboutTVC.h"
#import "DDetailCell.h"
#import "UIFontDescriptor+IranSans.h"

@interface AboutTVC () <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSString *website;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *postalCode;

@end

@implementation AboutTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.address = @"تهران، خیابان مفتح جنوبی، نبش خیابان شهید شیرودی، پلاک ۲، سازمان زیباسازی شهر تهران";
    self.email = @"info@zibasazi.ir";
    self.website = @"www.zibasazi.ir";
    self.phoneNumber = @"89357000";
    self.postalCode = @"۱۵۸۴۹۱۷۴۱۱";
}

- (IBAction)dismiss:(UIBarButtonItem *)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 280;
            break;
        default:
            return 44;
            break;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell Text" forIndexPath:indexPath];
            cell.textLabel.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
            return cell;
            break;
        }
            
        case 1: {
            DDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell Detail" forIndexPath:indexPath];
            switch (indexPath.row) {
                case 0: {
                    cell.label.text = @"آدرس";
                    cell.labelDetail.text = self.address;
                    [cell.labelButton setImage:nil forState:UIControlStateNormal];
                    [cell.labelButton removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
                    break;
                }
                case 1: {
                    cell.label.text = @"کدپستی";
                    cell.labelDetail.text = self.postalCode;
                    [cell.labelButton setImage:nil forState:UIControlStateNormal];
                    [cell.labelButton removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
                    break;
                }
                case 2: {
                    cell.label.text = @"شمارهٔ تماس";
                    cell.labelDetail.text = self.phoneNumber;
                    [cell.labelButton setImage:[UIImage imageNamed:@"call"] forState:UIControlStateNormal];
                    [cell.labelButton removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
                    [cell.labelButton addTarget:self action:@selector(callNumber:) forControlEvents:UIControlEventTouchUpInside];

                    break;
                }
                case 3: {
                    cell.label.text = @"ایمیل";
                    cell.labelDetail.text = self.email;
                    [cell.labelButton setImage:[UIImage imageNamed:@"email"] forState:UIControlStateNormal];
                    [cell.labelButton removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
                    [cell.labelButton addTarget:self action:@selector(sendEmail:) forControlEvents:UIControlEventTouchUpInside];
                    break;
                }
                case 4: {
                    cell.label.text = @"وب سایت";
                    cell.labelDetail.text = self.website;
                    [cell.labelButton setImage:[UIImage imageNamed:@"safari"] forState:UIControlStateNormal];
                    [cell.labelButton removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
                    [cell.labelButton addTarget:self action:@selector(openWebsite:) forControlEvents:UIControlEventTouchUpInside];

                    break;
                }
                default:
                    [[cell labelButton] setImage:nil forState:UIControlStateNormal];
                    [[cell labelButton] removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
;
            }
            return cell;
        }
            
        default:
            return nil;
            break;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 15)];
    [cell setPreservesSuperviewLayoutMargins:NO];
    [cell setLayoutMargins:UIEdgeInsetsZero];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    
    UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
    headerView.textLabel.textAlignment = NSTextAlignmentRight;

    headerView.textLabel.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansBoldFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"دربارهٔ ما";
            break;
        case 1:
            return @"تماس با ما";
            break;

        default:
            return nil;
            break;
    }
}


- (void)openWebsite: (UIButton *)sender {
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@",self.website]]];
}

- (void)callNumber: (UIButton *)sender {
    
    NSString *number = self.phoneNumber;
    NSString *correctNumberToCall = [NSString stringWithFormat:@"021 %@",number];
    
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"تماس با:" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [ac addAction:[UIAlertAction actionWithTitle:correctNumberToCall style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *phoneNumber = [@"tel://" stringByAppendingString:[correctNumberToCall stringByReplacingOccurrencesOfString:@" " withString:@""]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"انصراف" style:UIAlertActionStyleCancel handler:NULL]];
    
    [self presentViewController:ac animated:YES completion:NULL];
}

- (void)sendEmail:(UIButton *)sender {
    
    if ([MFMailComposeViewController canSendMail]) {
        
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        [mail setToRecipients:@[self.email]];
        mail.mailComposeDelegate = self;
        
        [self presentViewController:mail animated:YES completion:NULL];
        
    } else {
        NSLog(@"This device cannot send email");
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
