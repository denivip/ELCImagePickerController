//
//  AlbumPickerController.h
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ELCAssetSelectionDelegate.h"

typedef NS_ENUM(NSUInteger, ELCAlbumPickerAssetsType) {
    ELCAlbumPickerAssetsTypeVideo,
    ELCAlbumPickerAssetsTypePhoto
};

@interface ELCAlbumPickerController : DVTableViewController

@property (nonatomic, weak) id<ELCAssetSelectionDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *assetGroups;
@property (nonatomic) ELCAlbumPickerAssetsType assetsType;

@end

