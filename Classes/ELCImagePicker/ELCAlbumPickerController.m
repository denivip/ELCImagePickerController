//
//  AlbumPickerController.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAlbumPickerController.h"
#import "ELCAssetTablePicker.h"
#import "DVGTogetherAppearance.h"
#import "DVGTableViewCell.h"
#import "DVIntroductionInfoViewController.h"

@interface ELCAlbumPickerController ()
<UIAlertViewDelegate,
DVIntroductionInfoViewControllerDelegate>

@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, readonly, strong) ALAssetsFilter *assetsFilter;
@property (nonatomic, weak) UIAlertView *alertView;

@end

@implementation ELCAlbumPickerController

#pragma mark -
#pragma mark View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.titleScreen = @"Import from Album";
        self.assetsType = ELCAlbumPickerAssetsTypeVideo;
    }
    return self;
}

- (void)dealloc
{
    _alertView.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundColor = [UIColor togetherBackgroundColor];
    self.tableView.separatorColor = [UIColor togetherCellSeparatorColor];
	
	[self.navigationItem setTitle:NSLocalizedString(@"Loading...", @"[Title bar title]")];

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@checkselector0(self, cancelButton)];
	[self.navigationItem setRightBarButtonItem:cancelButton];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	self.assetGroups = tempArray;
    
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    self.library = assetLibrary;

    // Load Albums into assetGroups
    dispatch_async(dispatch_get_main_queue(), ^
    {
        @autoreleasepool {
            // Group enumerator Block
            void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
            {
                if (group == nil) {
                    return;
                }
                [group setAssetsFilter:self.assetsFilter];
                if ([group numberOfAssets] == 0) {
                    return;
                }
                // added fix for camera albums order
                ALAssetsGroupType nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
                if (nType == ALAssetsGroupSavedPhotos) {
                    [self.assetGroups insertObject:group atIndex:0];
                }
                else {
                    [self.assetGroups addObject:group];
                }

                // Reload albums
                [self performSelectorOnMainThread:@checkselector0(self, reloadTableView) withObject:nil waitUntilDone:YES];
            };

            // Group Enumerator Failure Block
            void (^assetGroupEnumeratorFailure)(NSError *) = ^(NSError *error) {
                if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized) {
                    DVIntroductionInfoViewController *infoController = [[DVIntroductionInfoViewController alloc] init];
                    infoController.type = DVIntroductionInfoTypePhoto;
                    infoController.delegate = self;
                    [self.navigationController pushViewController:infoController animated:YES];
                } else {
                    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"[Alert title]") message:[NSString stringWithFormat:NSLocalizedString(@"Album Error: %@ - %@", @"[Alert error message]: {localized description} - {localized recovery suggestion}"), [error localizedDescription], [error localizedRecoverySuggestion]] delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
                    [alert show];
                    self.alertView = alert;
                }

                NSLog(@"A problem occured %@", [error description]);
            };

            // Enumerate Albums
            [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                                        usingBlock:assetGroupEnumerator 
                                      failureBlock:assetGroupEnumeratorFailure];
        }
    });
}

- (void)reloadTableView
{
	[self.tableView reloadData];
    if (self.assetsType == ELCAlbumPickerAssetsTypePhoto) {
        [self.navigationItem setTitle:NSLocalizedString(@"IMPORT_LIBRARY_PHOTOS", @"[Title bar title]")];
    } else {
        [self.navigationItem setTitle:NSLocalizedString(@"IMPORT_LIBRARY_VIDEOS", @"[Title bar title]")];
    }
}

- (void)cancelButton
{
    [self.delegate elc_assetSelectionDidCancel:self];
}

- (NSString *)groupName:(ALAssetsGroup *)g
{
    NSString *sGroupPropertyName = [g valueForProperty:ALAssetsGroupPropertyName];
    if ([[sGroupPropertyName lowercaseString] isEqualToString:@"photos"] &&
        self.assetsType == ELCAlbumPickerAssetsTypeVideo) {
        // On iOS 8 change Photos to Videos.
        sGroupPropertyName = NSLocalizedString(@"VIDEOS_GROUP_TITLE", nil);
    }

    return sGroupPropertyName;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.assetGroups count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[DVGTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Get count
    ALAssetsGroup *g = (ALAssetsGroup*)[self.assetGroups objectAtIndex:indexPath.row];
    NSInteger gCount = [g numberOfAssets];
    NSString *sGroupPropertyName = [self groupName:g];

    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%ld)", sGroupPropertyName, (long)gCount];
    [cell.imageView setImage:[UIImage imageWithCGImage:[(ALAssetsGroup*)[self.assetGroups objectAtIndex:indexPath.row] posterImage]]];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	ELCAssetTablePicker *picker = [[ELCAssetTablePicker alloc] initWithNibName: nil bundle: nil];
    picker.library = self.library;
	picker.delegate = self.delegate;
    picker.assetGroup = [self.assetGroups objectAtIndex:indexPath.row];
    [picker.assetGroup setAssetsFilter:self.assetsFilter];
	[self.navigationController pushViewController:picker animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return 57;
}

#pragma mark - Alert view delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        [self.delegate elc_assetSelectionDidCancel:self];
    }
}

- (ALAssetsFilter *)assetsFilter {
    if (self.assetsType == ELCAlbumPickerAssetsTypePhoto) {
        return [ALAssetsFilter allPhotos];
    } else {
        return [ALAssetsFilter allVideos];
    }
}

#pragma mark - DVIntroductionViewControllerDelegate

- (void)infoControllerDidDisappear:(DVIntroductionInfoViewController *)controller withType:(DVIntroductionInfoType)type {
    [self.navigationController popViewControllerAnimated:NO];
    [self.delegate elc_assetSelectionDidCancel:self];
}

@end

