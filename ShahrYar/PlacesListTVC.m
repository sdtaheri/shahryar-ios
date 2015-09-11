//
//  MorePlacesTVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/19.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "PlacesListTVC.h"
#import "Group.h"
#import "Type.h"
#import "DetailTVC.h"
#import "Mapbox.h"
#import "UIFontDescriptor+IranSans.h"

@interface PlacesListTVC ()

@property (nonatomic, strong) NSArray *places;
@property (nonatomic, strong) NSArray *sortedByDistancePlacesDictionary;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

@property (nonatomic, strong) NSArray *sectionKeys;
@property (nonatomic, strong) NSDictionary *alphabetizedPlaceTitles;

@property (nonatomic, strong) NSArray *sortedCategoryTitles;
@property (nonatomic, strong) NSDictionary *sectionedPlacesInCategories;

@end

@implementation PlacesListTVC

typedef NS_ENUM(NSInteger, SortType) {
    SortTypeAlphabet = 0,
    SortTypeCategories = 1,
    SortTypeDistance = 2
};


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"فهرست";
    
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    self.numberFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"fa_IR"];
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    self.tableView.estimatedRowHeight = 44.f;
    self.navigationController.view.layer.masksToBounds = YES;
    
    [self initializeData];
}

- (void)initializeData {
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:self.annotations.count];
    for (RMAnnotation *annotation in self.annotations) {
        if ([annotation.userInfo isKindOfClass:[Place class]]) {
            [temp addObject: annotation.userInfo];
        } else {
            Group *group = annotation.userInfo;
            for (Place *place in group.places) {
                if (place.category.selected.boolValue) {
                    [temp addObject:place];
                }
            }
        }
    }
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)];
    self.places = [temp sortedArrayUsingDescriptors:@[descriptor]];
    
    if (self.userLocation) {
        temp = [NSMutableArray arrayWithCapacity:self.places.count];
        for (Place *place in self.places) {
            [temp addObject:@{@"Place": place, @"Distance": @([self.userLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:place.latitude.doubleValue longitude:place.longitude.doubleValue]]) }];
        }
        descriptor = [NSSortDescriptor sortDescriptorWithKey:@"Distance" ascending:YES];
        self.sortedByDistancePlacesDictionary = [temp sortedArrayUsingDescriptors:@[descriptor]];
    } else {
        [self.segmentedControl removeSegmentAtIndex:SortTypeDistance animated:YES];
    }
    
    NSMutableArray *letters = [NSMutableArray array];
    NSMutableDictionary *sectionedWords = [NSMutableDictionary dictionary];
    NSArray *strings = [self.places valueForKey:@"title"];
    NSString *currentLetter = nil;
    NSArray *sectionTitles = @[@"الف", @"ب", @"پ", @"ت", @"ث", @"ج", @"چ", @"ح", @"خ", @"د", @"ذ", @"ر", @"ز", @"ژ", @"س", @"ش", @"ص", @"ض", @"ط", @"ظ", @"ع", @"غ", @"ف", @"ق", @"ک", @"گ", @"ل", @"م", @"ن", @"و", @"ه", @"ی"];
    for (NSString *string in strings) {
        if (string.length > 0) {
            NSString *letter = [string substringToIndex:1];
            if ([letter isEqualToString:@"ا"] || [letter isEqualToString:@"آ"] || [letter isEqualToString:@"أ"] || [letter isEqualToString:@"إ"]) {
                letter = @"الف";
            } else if ([letter isEqualToString:@"ک"] || [letter isEqualToString:@"ك"]) {
                letter = @"ک";
            } else if ([letter isEqualToString:@"و"] || [letter isEqualToString:@"ؤ"]) {
                letter = @"و";
            } else if ([sectionTitles containsObject:letter]) {
                letter = letter;
            } else {
                letter = @"#";
            }
            if (![letter isEqualToString:currentLetter]) {
                [letters addObject:letter];
                currentLetter = letter;
            }
            
            if ([sectionedWords objectForKey:letter]) {
                [[sectionedWords objectForKey:letter] addObject:string];
            } else {
                [sectionedWords setObject:[NSMutableArray array] forKey:letter];
                [[sectionedWords objectForKey:letter] addObject:string];
            }
        }
    }
    self.sectionKeys = [NSArray arrayWithArray:letters];
    self.alphabetizedPlaceTitles = sectionedWords;
    
    self.sortedCategoryTitles = [[self.places valueForKeyPath:@"@distinctUnionOfObjects.category.summary"] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    
    NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithCapacity:self.sortedCategoryTitles.count];
    
    for (int i = 0; i < self.sortedCategoryTitles.count; i++) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category.summary = %@", self.sortedCategoryTitles[i]];
        NSArray *results = [self.places filteredArrayUsingPredicate:predicate];
        results = [results valueForKey:@"title"];
        results = [results sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
        
        [tempDic setObject:results forKey:self.sortedCategoryTitles[i]];
    }
    self.sectionedPlacesInCategories = tempDic;
}

- (IBAction)segmentValueChanged:(UISegmentedControl *)sender {
    [self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case SortTypeAlphabet:
            return self.sectionKeys.count;
            break;
        case SortTypeCategories: {
            return self.sortedCategoryTitles.count;
            break;
        }
        case SortTypeDistance:
            return 1;
            break;
        default:
            return 0;
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case SortTypeAlphabet: {
            NSArray *temp = [self.alphabetizedPlaceTitles objectForKey:self.sectionKeys[section]];
            if (temp) {
                return temp.count;
            } else {
                return 0;
            }
            break;
        }
        case SortTypeCategories: {
            NSArray *temp = [self.sectionedPlacesInCategories objectForKey:self.sortedCategoryTitles[section]];
            if (temp) {
                return temp.count;
            } else {
                return 0;
            }
            break;
        }
        case SortTypeDistance:
            return self.sortedByDistancePlacesDictionary.count;
            break;
        default:
            return 0;
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Place Cell"];
    cell.textLabel.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
    
    switch (self.segmentedControl.selectedSegmentIndex) {
        case SortTypeAlphabet:
            cell.textLabel.text = [self.alphabetizedPlaceTitles objectForKey:self.sectionKeys[indexPath.section]][indexPath.row];
            break;
        case SortTypeCategories: {
            cell.textLabel.text = [self.sectionedPlacesInCategories objectForKey:self.sortedCategoryTitles[indexPath.section]][indexPath.row];
            break;
        }
        case SortTypeDistance: {
            NSString *title = [[self.sortedByDistancePlacesDictionary[indexPath.row] objectForKey:@"Place"] title];
            NSString *subtitle = [self.sortedByDistancePlacesDictionary[indexPath.row] objectForKey:@"Distance"];
            if (subtitle.doubleValue >= 1000) {
                self.numberFormatter.maximumFractionDigits = 1;
                subtitle = [NSString stringWithFormat:@"%@ کیلومتر", [self.numberFormatter stringFromNumber:@([subtitle doubleValue] / 1000.0)]];
            } else {
                self.numberFormatter.maximumFractionDigits = 0;
                subtitle = [NSString stringWithFormat:@"%@ متر", [self.numberFormatter stringFromNumber:@([subtitle doubleValue])]];
            }
            
            NSDictionary *attrs = @{
                                    NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0],
                                    NSForegroundColorAttributeName:[UIColor blackColor]
                                    };
            NSDictionary *subAttrs = @{
                                       NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleCaption1] size: 0],
                                       NSForegroundColorAttributeName:[UIColor lightGrayColor]
                                       };
            
            NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", title, subtitle] attributes:attrs];
            
            NSRange range = NSMakeRange(title.length + 1, subtitle.length);
            [attrStr setAttributes:subAttrs range:range];
            
            cell.textLabel.attributedText = attrStr;
            break;
        }
            
        default:
            cell.textLabel.text = @"Error";
            break;
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textAlignment = NSTextAlignmentRight;
    cell.backgroundView = nil;

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
    headerView.textLabel.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansBoldFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
    headerView.textLabel.textAlignment = NSTextAlignmentRight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case SortTypeAlphabet:
            return self.sectionKeys;
            break;
        default:
            return nil;
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case SortTypeAlphabet:
            return self.sectionKeys[section];
            break;
        case SortTypeCategories: {
            
            return self.sortedCategoryTitles[MIN(section, self.sortedCategoryTitles.count - 1)];
            break;
        }
        case SortTypeDistance:
            return nil;
            break;
        default:
            return nil;
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Show Detail From List"]) {
        DetailTVC *dtvc = segue.destinationViewController;
        dtvc.navigationItem.leftBarButtonItem = nil;
        dtvc.navigationItem.leftItemsSupplementBackButton = YES;
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender];
        switch (self.segmentedControl.selectedSegmentIndex) {
            
            case SortTypeAlphabet: {
                NSInteger rowNumber = 0;
                for (NSInteger i = 0; i < indexPath.section; i++) {
                    rowNumber += [self.tableView numberOfRowsInSection:i];
                }
                rowNumber += indexPath.row;
                dtvc.place = self.places[rowNumber];
                break;
            }
            
            case SortTypeCategories: {
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category.summary = %@", self.sortedCategoryTitles[indexPath.section]];
                NSArray *resultsArray = [self.places filteredArrayUsingPredicate:predicate];
                
                NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)];
                resultsArray = [resultsArray sortedArrayUsingDescriptors:@[descriptor]];
                
                dtvc.place = resultsArray[indexPath.row];

                break;
            }
                
            case SortTypeDistance: {
                dtvc.place = [self.sortedByDistancePlacesDictionary[indexPath.row] objectForKey:@"Place"];
                break;
            }
            default:
                break;
        }
    }
}

- (IBAction)dismissAndFilter:(UIBarButtonItem *)sender {

    __weak MainVC *weakMainVC = self.mainVC;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [weakMainVC performSegueWithIdentifier:@"Filter Segue" sender:nil];
    }];
}

- (IBAction)dismiss:(UIBarButtonItem *)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
