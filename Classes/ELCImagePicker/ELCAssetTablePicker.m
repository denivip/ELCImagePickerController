//
//  AssetTablePicker.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "DVTogetherAppearance.h"
#import "DVTogetherAppearance.h"

static float kELCSectionTitleHeight = 20.0f;
static float kELCSectionTitleTopSpace = 22.0f;

@interface ELCAssetTablePicker ()
@property (nonatomic) NSInteger columns;
@property (nonatomic, copy) NSSet *disabledURLs;
@end

@implementation ELCAssetTablePicker

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.titleScreen = @"Import Videos";
    }
    return self;
}

- (void)viewDidLoad
{
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	[self.tableView setAllowsSelection:NO];
    self.tableView.backgroundColor = [UIColor togetherBackgroundColor];

    self.elcAssetsBySection = @[].mutableCopy;
	
    if (self.immediateReturn) {
        
    } else {
        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@checkselector(self, doneAction:)];
        [self.navigationItem setRightBarButtonItem:doneButtonItem];
        [self.navigationItem setTitle:NSLocalizedString(@"Loading...", @"[Title bar title]")];
    }

    NSArray *disabledURLArray = [self.delegate elc_assetSelectionAssetURLsToDisableSelection:self];
    self.disabledURLs = [NSSet setWithArray:disabledURLArray];

	[self performSelectorInBackground:@checkselector0(self, preparePhotos) withObject:nil];

    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSUInteger width = CGRectGetWidth(self.view.bounds)/4;
    self.columns = self.view.bounds.size.width / width;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    NSUInteger width = CGRectGetWidth(self.view.bounds)/4;
    self.columns = self.view.bounds.size.width / width;
    [self.tableView reloadData];
}

- (void)preparePhotos
{
    @autoreleasepool {
        self.elcAssetsBySection = @[].mutableCopy;
        __block NSMutableArray* elcAssets = @[].mutableCopy;
        [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if(result == nil) {
                return;
            }
            ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
            [elcAsset setParent:self];
            NSString *url = [[result valueForProperty:ALAssetPropertyAssetURL] absoluteString];
            elcAsset.enabled = ![self.disabledURLs containsObject:url];
            [elcAssets addObject:elcAsset];
        }];
        
        if(self.groupByDate){
            // Grouping assets by date
            [elcAssets sortUsingComparator:^NSComparisonResult(ELCAsset *obj1, ELCAsset *obj2) {
                NSDate *date1 = [obj1.asset valueForProperty:ALAssetPropertyDate];
                if (! date1 ||
                    [date1 compare:[NSDate distantPast]] == NSOrderedAscending ||
                    [date1 compare:[NSDate distantFuture]] == NSOrderedDescending) {
                    // Если даты нет или она некорректная, то задаем текущую.
                    date1 = [NSDate date];
                }
                NSDate *date2 = [obj2.asset valueForProperty:ALAssetPropertyDate];
                if (! date2 ||
                    [date2 compare:[NSDate distantPast]] == NSOrderedAscending ||
                    [date2 compare:[NSDate distantFuture]] == NSOrderedDescending) {
                    // Если даты нет или она некорректная, то задаем текущую.
                    date2 = [NSDate date];
                }
                return -1*[date1 compare:date2];
            }];
            static NSDateFormatter *dateFormatter = nil;
            if (dateFormatter == nil) {
                dateFormatter = [[NSDateFormatter alloc] init];
                //[dateFormatter setLocale:[NSLocale applicationCurrentLocale]];
                [dateFormatter setMonthSymbols:dateFormatter.standaloneMonthSymbols];
                [dateFormatter setDateFormat:@"d,MMMM,yyyy"];
            }
            NSString* sectionKey = @"";
            for(ELCAsset* elcAsset in elcAssets){
                NSDate *assetDate = [elcAsset.asset valueForProperty:ALAssetPropertyDate];
                if (! assetDate ||
                    [assetDate compare:[NSDate distantPast]] == NSOrderedAscending ||
                    [assetDate compare:[NSDate distantFuture]] == NSOrderedDescending) {
                    // Если даты нет или она некорректная, то задаем текущую.
                    assetDate = [NSDate date];
                }
                NSString* assetKey = [dateFormatter stringFromDate:assetDate];
                if([assetKey compare:sectionKey] != NSOrderedSame){
                    NSMutableArray* section = @[].mutableCopy;
                    [self.elcAssetsBySection addObject:section];
                    sectionKey = assetKey;
                }
                [[self.elcAssetsBySection lastObject] addObject:elcAsset];
            }
        }else{
            [self.elcAssetsBySection addObject:elcAssets];
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            if (self.elcAssetsBySection.count && [[self.elcAssetsBySection objectAtIndex:0] count]
                && [((ELCAsset *)[[self.elcAssetsBySection objectAtIndex:0] objectAtIndex:0]).asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto) {
                [self.navigationItem setTitle:self.singleSelection ? NSLocalizedString(@"IMPORT_LIBRARY_PHOTO_SINGLE", @"[Title bar title] single selection") : NSLocalizedString(@"IMPORT_LIBRARY_PHOTO_MANY", @"[Title bar title] multiple selection")];
            } else {
                [self.navigationItem setTitle:self.singleSelection ? NSLocalizedString(@"IMPORT_LIBRARY_VIDEO_SINGLE", @"[Title bar title] single selection") : NSLocalizedString(@"IMPORT_LIBRARY_VIDEO_MANY", @"[Title bar title] multiple selection")];
            }
            
            if(!self.groupByDate){
                // scroll to bottom
                NSInteger section = [self numberOfSectionsInTableView:self.tableView] - 1;
                NSInteger row = [self tableView:self.tableView numberOfRowsInSection:section] - 1;
                if (section >= 0 && row >= 0) {
                    NSIndexPath *ip = [NSIndexPath indexPathForRow:row
                                                         inSection:section];
                    [self.tableView scrollToRowAtIndexPath:ip
                                          atScrollPosition:UITableViewScrollPositionBottom
                                                  animated:NO];
                }
            }
        });
    }
}

- (void)doneAction:(id)sender
{
	NSMutableArray *selectedAssetsImages = [[NSMutableArray alloc] init];
    for(NSArray *assets in self.elcAssetsBySection) {
        for(ELCAsset *elcAsset in assets) {
            if([elcAsset selected]) {
                [selectedAssetsImages addObject:[elcAsset asset]];
            }
        }
	}

    [self.delegate elc_assetSelection:self didSelectAssets:selectedAssetsImages library:self.library];
}

- (void)assetSelected:(ELCAsset*)asset
{
    if (self.singleSelection) {
        for(NSArray *assets in self.elcAssetsBySection) {
            for(ELCAsset *elcAsset in assets) {
                if(asset != elcAsset) {
                    elcAsset.selected = NO;
                }
            }
        }
    }
    if (self.immediateReturn) {
        NSArray *singleAssetArray = [NSArray arrayWithObject:[asset asset]];
        [self.delegate elc_assetSelection:self didSelectAssets:singleAssetArray library:self.library];
    }
}

- (void)assetDeselected:(ELCAsset*)asset
{
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.elcAssetsBySection count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(!self.groupByDate){
        return 0;
    }
    if(section < 0 || section >= [self.elcAssetsBySection count]){
        return 0;
    }
    NSArray* sectionAssets = [self.elcAssetsBySection objectAtIndex:section];
    if([sectionAssets count] == 0){
        return 0;
    }
    return kELCSectionTitleHeight+kELCSectionTitleTopSpace;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if(!self.groupByDate){
        return nil;
    }
    if(section < 0 || section >= [self.elcAssetsBySection count]){
        return nil;
    }
    NSArray* sectionAssets = [self.elcAssetsBySection objectAtIndex:section];
    if([sectionAssets count] == 0){
        return nil;
    }
    ELCAsset* firstAsset = [sectionAssets objectAtIndex:0];
    NSDate *assetDate = [firstAsset.asset valueForProperty:ALAssetPropertyDate];
    if (! assetDate ||
        [assetDate compare:[NSDate distantPast]] == NSOrderedAscending ||
        [assetDate compare:[NSDate distantFuture]] == NSOrderedDescending) {
        // Если даты нет или она некорректная, то задаем текущую.
        assetDate = [NSDate date];
    }

    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        //[dateFormatter setLocale:[NSLocale applicationCurrentLocale]];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        [dateFormatter setMonthSymbols:dateFormatter.standaloneMonthSymbols];
    }
    UIView* titleWrapper = [[UIView alloc] initWithFrame:CGRectMake(0.0f,0.0f,self.view.frame.size.width,kELCSectionTitleHeight+kELCSectionTitleTopSpace)];
    UILabel* title = [[UILabel alloc] initWithFrame:CGRectMake(10.0f,kELCSectionTitleTopSpace,self.view.frame.size.width,kELCSectionTitleHeight)];
    [title applyTogetherAppearance];
    title.text = [dateFormatter stringFromDate:assetDate];
    [titleWrapper addSubview:title];
    return titleWrapper;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section < 0 || section >= [self.elcAssetsBySection  count]){
        return 0;
    }
    NSArray* sectionAssets = [self.elcAssetsBySection objectAtIndex:section];
    
    if (self.columns > 0)
        return ceil([sectionAssets count] / (float)self.columns);
    else
        return ceil([sectionAssets count] / 4.f);
}

- (NSArray *)assetsForIndexPath:(NSIndexPath *)path
{
    NSArray* sectionAssets = [self.elcAssetsBySection objectAtIndex:path.section];
    NSInteger index = path.row * self.columns;
    NSInteger length = MIN(self.columns, [sectionAssets count] - index);
    return [sectionAssets subarrayWithRange:NSMakeRange(index, length)];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {		        
        cell = [[ELCAssetCell alloc] initWithAssets:[self assetsForIndexPath:indexPath] reuseIdentifier:CellIdentifier];

    } else {		
		[cell setAssets:[self assetsForIndexPath:indexPath]];
	}
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger width = CGRectGetWidth(self.view.bounds)/4;
    return width - 1;
}

- (int)totalSelectedAssets {
    
    int count = 0;

    for(NSArray *assets in self.elcAssetsBySection) {
        for(ELCAsset *asset in assets) {
            if([asset selected]) {
                count++;
            }
        }
    }
    
    return count;
}

@end
