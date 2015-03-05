//
//  AssetTablePicker.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "DVGTogetherAppearance.h"

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

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
	
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

        [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {

            if(result == nil) {
                return;
            }

            ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
            [elcAsset setParent:self];
            NSString *url = [[result valueForProperty:ALAssetPropertyAssetURL] absoluteString];
            elcAsset.enabled = ![self.disabledURLs containsObject:url];
            [self.elcAssets addObject:elcAsset];
        }];

        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
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
            
            if (self.elcAssets.count && [((ELCAsset *)[self.elcAssets objectAtIndex:0]).asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto) {
                [self.navigationItem setTitle:self.singleSelection ? NSLocalizedString(@"IMPORT_LIBRARY_PHOTO_SINGLE", @"[Title bar title] single selection") : NSLocalizedString(@"IMPORT_LIBRARY_PHOTO_MANY", @"[Title bar title] multiple selection")];
            } else {
                [self.navigationItem setTitle:self.singleSelection ? NSLocalizedString(@"IMPORT_LIBRARY_VIDEO_SINGLE", @"[Title bar title] single selection") : NSLocalizedString(@"IMPORT_LIBRARY_VIDEO_MANY", @"[Title bar title] multiple selection")];
            }
        });
    }
}

- (void)doneAction:(id)sender
{	
	NSMutableArray *selectedAssetsImages = [[NSMutableArray alloc] init];
	    
	for(ELCAsset *elcAsset in self.elcAssets) {

		if([elcAsset selected]) {
			
			[selectedAssetsImages addObject:[elcAsset asset]];
		}
	}

    [self.delegate elc_assetSelection:self didSelectAssets:selectedAssetsImages library:self.library];
}

- (void)assetSelected:(ELCAsset*)asset
{
    if (self.singleSelection) {

        for(ELCAsset *elcAsset in self.elcAssets) {
            if(asset != elcAsset) {
                elcAsset.selected = NO;
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
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ceil([self.elcAssets count] / (float)self.columns);
}

- (NSArray *)assetsForIndexPath:(NSIndexPath *)path
{
    NSInteger index = path.row * self.columns;
    NSInteger length = MIN(self.columns, [self.elcAssets count] - index);
    return [self.elcAssets subarrayWithRange:NSMakeRange(index, length)];
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
    
    for(ELCAsset *asset in self.elcAssets) {
		if([asset selected]) {   
            count++;	
		}
	}
    
    return count;
}

@end
