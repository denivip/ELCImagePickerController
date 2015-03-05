//
//  AssetTablePicker.h
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ELCAsset.h"
#import "ELCAssetSelectionDelegate.h"
#import "DVTableViewController.h"

@interface ELCAssetTablePicker : DVTableViewController <ELCAssetDelegate>

@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, weak) id <ELCAssetSelectionDelegate> delegate;
@property (nonatomic, strong) ALAssetsGroup *assetGroup;
@property (nonatomic, strong) NSMutableArray *elcAssetsBySection;
@property (nonatomic, strong) IBOutlet UILabel *selectedAssetsLabel;
@property (nonatomic) BOOL singleSelection;
@property (nonatomic) BOOL immediateReturn;
@property (nonatomic) BOOL groupByDate;

- (int)totalSelectedAssets;
- (void)preparePhotos;
- (void)doneAction:(id)sender;
- (void)assetSelected:(ELCAsset *)asset;

@end