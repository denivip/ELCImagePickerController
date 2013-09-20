//
//  ELCAssetSelectionDelegate.h
//  ELCImagePickerDemo
//
//  Created by JN on 9/6/12.
//  Copyright (c) 2012 ELC Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ELCAssetSelectionDelegate <NSObject>

- (void)elc_assetSelectionDidCancel:(id)assetSelection;

/**
 @param assets NSArray of ALAsset
 */
- (void)elc_assetSelection:(id)assetSelection didSelectAssets:(NSArray *)assets;

/**
 @return NSArray of NSString URLs of ALAssets
 */
- (NSArray *)elc_assetSelectionAssetURLsToDisableSelection:(id)assetSelection;

@end
