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
#import "ReportVC.h"

@interface AboutTVC ()

@property (nonatomic, strong) NSString *website;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *postalCode;

@end

@implementation AboutTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"بازگشت" style:UIBarButtonItemStyleDone target:nil action:NULL];
    
    self.tableView.contentInset = UIEdgeInsetsMake(16, 0, 0, 0);
    
    self.address = @"تهران، خیابان مفتح جنوبی، نبش خیابان شهید شیرودی، پلاک ۲، سازمان زیباسازی شهر تهران";
    self.website = @"www.zibasazi.ir";
    self.phoneNumber = @"89357000";
    self.postalCode = @"۱۵۸۴۹۱۷۴۱۱";
}

- (IBAction)dismiss:(UIBarButtonItem *)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}
- (IBAction)easterEgg:(UITapGestureRecognizer *)sender {
    
    UITextView *label = [[UITextView alloc] initWithFrame:self.tableView.tableHeaderView.frame];
    label.text = @"Developed By Saeed Taheri\nwww.saeedtaheri.com \nSummer 2015";
    label.textAlignment = NSTextAlignmentCenter;
    label.dataDetectorTypes = UIDataDetectorTypeLink;
    label.editable = NO;
    label.selectable = YES;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.tableView.tableHeaderView = label;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 16;
    } else {
        return 40;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : (section == 1 ? 4 : 1);
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
            
        case 2: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell Normal" forIndexPath:indexPath];
            
            cell.textLabel.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
            return cell;
            break;
        }
            
        default:
            return nil;
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        DDetailCell *detailCell = [tableView cellForRowAtIndexPath:indexPath];
        
        if ([detailCell.label.text isEqualToString:@"شمارهٔ تماس"]) {
            [self callNumber:detailCell.labelButton];
        } else if ([detailCell.label.text isEqualToString:@"وب سایت"]) {
            [self openWebsite:detailCell.labelButton];
        }
    } else if (indexPath.section == 2) {
        [self performSegueWithIdentifier:@"Contact Us" sender:self];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([UIDevice currentDevice].systemVersion.floatValue < 9.0) {
        // Remove seperator inset
        [cell setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 15)];
        
        // Prevent the cell from inheriting the Table View's margin settings
        [cell setPreservesSuperviewLayoutMargins:NO];
        
        // Explictly set your cell's layout margins
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Contact Us"]) {
        ReportVC *rvc = segue.destinationViewController;
        rvc.reportType = @"General";
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

@end
