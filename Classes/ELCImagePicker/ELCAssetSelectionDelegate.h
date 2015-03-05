//
//  ELCAssetSelectionDelegate.h
//  ELCImagePickerDemo
//
//  Created by JN on 9/6/12.
//  Copyright (c) 2012 ELC Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@protocol ELCAssetSelectionDelegate <NSObject>

- (void)elc_assetSelectionDidCancel:(id)assetSelection;

/**
 @param assets NSArray of ALAsset
 */
- (void)elc_assetSelection:(id)assetSelection didSelectAssets:(NSArray *)assets library:(ALAssetsLibrary *)library;

/**
 @return NSArray of NSString URLs of ALAssets
 */
- (NSArray *)elc_assetSelectionAssetURLsToDisableSelection:(id)assetSelection;

@optional
- (void)elc_assetToggle:(id)assetSelection didSelectAssets:(NSArray *)assets library:(ALAssetsLibrary *)library;


@end
