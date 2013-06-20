//
//  ELCImagePickerController.m
//  ELCImagePickerDemo
//
//  Created by ELC on 9/9/10.
//  Copyright 2010 ELC Technologies. All rights reserved.
//

#import "ELCImagePickerController.h"
#import "ELCAsset.h"
#import "ELCAssetCell.h"
#import "ELCAssetTablePicker.h"
#import "ELCAlbumPickerController.h"

@interface ELCImagePickerController ()

@property (nonatomic, retain) NSArray *disabledURLs;

@end

@implementation ELCImagePickerController

@synthesize delegate = _myDelegate;
@synthesize disabledURLs = _disabledURLs;

- (void)cancelImagePicker
{
	if([_myDelegate respondsToSelector:@selector(elcImagePickerControllerDidCancel:)]) {
		[_myDelegate performSelector:@selector(elcImagePickerControllerDidCancel:) withObject:self];
	}
}

- (void)selectedAssets:(NSArray *)assets
{
    if(_myDelegate != nil && [_myDelegate respondsToSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:)]) {
		[_myDelegate performSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:) withObject:self withObject:[NSArray arrayWithArray:assets]];
	} else {
        [self popToRootViewControllerAnimated:NO];
    }
}

- (NSArray *)disabledURLs{
    if (_disabledURLs == nil) {
        NSArray *disabledURLs = nil;
        if ([self.delegate respondsToSelector:@selector(elcImagePickerControllerDisabledURLs:)]) {
            disabledURLs = [[self.delegate elcImagePickerControllerDisabledURLs:self] retain];
        }
        _disabledURLs = disabledURLs;
    }
    return _disabledURLs;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    }
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    NSLog(@"ELC Image Picker received memory warning.");
    
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)dealloc
{
    NSLog(@"deallocing ELCImagePickerController");
    [_disabledURLs release];
    [super dealloc];
}

@end
