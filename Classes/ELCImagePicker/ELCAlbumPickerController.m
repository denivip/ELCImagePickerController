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

@interface ELCAlbumPickerController () <UIAlertViewDelegate>

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
                NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
                NSUInteger nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];


                if ([[sGroupPropertyName lowercaseString] isEqualToString:@"camera roll"] && nType == ALAssetsGroupSavedPhotos) {
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
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"TITLE_IMPORT_FROM_LIBRARY", @"Import from Library")
                                                                    message:NSLocalizedString(@"SETTINGS_IMPORT_ACCESS_DENIED", @"Message on importing videos when access to library is denied")
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil];
                    [alert show];
                    self.alertView = alert;
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
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%ld)",[g valueForProperty:ALAssetsGroupPropertyName], (long)gCount];
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

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
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

@end

