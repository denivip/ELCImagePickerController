//
//  AssetCell.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "DVMessagesManager.h"
#import "DVGTogetherAppearance.h"

static BOOL defaultDimsCellOnSelection = NO;
static NSString* defaultOverlayImageName = @"Overlay";
static NSString* defaultDisabledImageName = @"Overlay-disabled";

@interface ELCAssetCell ()

@property (nonatomic, strong) NSArray *rowAssets;
@property (nonatomic, strong) NSMutableArray *imageViewArray;
@property (nonatomic, strong) NSMutableArray *overlayViewArray;
@property (nonatomic, strong) NSMutableArray *durationViewArray;
@property (nonatomic, strong) NSMutableArray *cameraViewArray;

@end

@implementation ELCAssetCell

@synthesize rowAssets = _rowAssets;
- (id)initWithAssets:(NSArray *)assets reuseIdentifier:(NSString *)identifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
	if(self) {
        self.backgroundColor = [UIColor togetherBackgroundColor];

        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@checkselector(self, cellTapped:)];
        [self addGestureRecognizer:tapRecognizer];
        
        NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.imageViewArray = mutableArray;
        
        NSMutableArray *durationArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.durationViewArray = durationArray;
        
        NSMutableArray *cameraArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.cameraViewArray = cameraArray;
        
        NSMutableArray *overlayArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.overlayViewArray = overlayArray;

        [self setAssets:assets];
	}
	return self;
}

+ (void)setDefaultOverlayImageName:(NSString*)overlayImage shouldDimCell:(BOOL)shouldDim {
    defaultOverlayImageName = overlayImage;
    defaultDimsCellOnSelection = shouldDim;
}

+ (void)setDefaultDisabledImageName:(NSString*)overlayImage {
    defaultDisabledImageName = overlayImage;
}

- (void)setAssets:(NSArray *)assets
{
    self.rowAssets = assets;
	for (UIView *view in [self.contentView subviews]) {
		[view removeFromSuperview];
	}
    //set up a pointer here so we don't keep calling [UIImage imageNamed:] if creating overlays
    UIImage *overlayImage = nil;
    UIImage *overlayImageHighlighted = nil;
    for (int i = 0; i < [_rowAssets count]; ++i) {

        ELCAsset *asset = [_rowAssets objectAtIndex:i];
        if (i < [_imageViewArray count]) {
            UIImageView *imageView = [_imageViewArray objectAtIndex:i];
            imageView.image = [UIImage imageWithCGImage:asset.asset.thumbnail];
            if ([asset.asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
                UILabel *labelView = [_durationViewArray objectAtIndex:i];
                NSUInteger duration = [[asset.asset valueForProperty:ALAssetPropertyDuration] integerValue];
                labelView.text = [NSString stringWithFormat:@"%lu:%02lu", (unsigned long)duration/60, (unsigned long)duration%60];
            }
        } else {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:asset.asset.thumbnail]];
            [_imageViewArray addObject:imageView];
        
            if ([asset.asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
                UILabel *labelView = [[UILabel alloc] init];
                labelView.backgroundColor = [[UIColor togetherHighlightedCellBackgroundColor] colorWithAlphaComponent:0.5f];
                labelView.textAlignment = NSTextAlignmentRight;
                labelView.textColor = [UIColor whiteColor];
                labelView.font = [UIFont systemFontOfSize:14.f];
                NSUInteger duration = [[asset.asset valueForProperty:ALAssetPropertyDuration] integerValue];
                labelView.text = [NSString stringWithFormat:@"%lu:%02lu", (unsigned long)duration/60, (unsigned long)duration%60];
                [_durationViewArray addObject:labelView];
            
                UIImageView *cameraView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_cam"]];
                [_cameraViewArray addObject:cameraView];
            }
        }
        
        if (i < [_overlayViewArray count]) {
            UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
            overlayView.hidden = asset.selected || !asset.enabled ? NO : YES;
            overlayView.highlighted = !asset.enabled;
        } else {
            if (overlayImage == nil) {
                overlayImage = [UIImage imageNamed:defaultOverlayImageName];
                overlayImageHighlighted = [UIImage imageNamed:defaultDisabledImageName];
            }
            UIImageView *overlayView = [[UIImageView alloc] initWithImage:overlayImage highlightedImage:overlayImageHighlighted];
            [_overlayViewArray addObject:overlayView];
            overlayView.hidden = asset.selected || !asset.enabled ? NO : YES;
            overlayView.highlighted = !asset.enabled;
            if(defaultDimsCellOnSelection){
                overlayView.contentMode = UIViewContentModeCenter;
            }
        }
        if (i < [_overlayViewArray count]) {
            UIImageView *imageView = [_imageViewArray objectAtIndex:i];
            if(defaultDimsCellOnSelection && asset.selected){
                imageView.alpha = 0.7;
            }else{
                imageView.alpha = 1.0;
            }
        }
    }
}

- (void)cellTapped:(UITapGestureRecognizer *)tapRecognizer
{
    CGPoint point = [tapRecognizer locationInView:self];
    CGFloat startX = 4;
    
    NSUInteger width = CGRectGetWidth(self.bounds)/4 - 5;
    CGRect frame = CGRectMake(startX, 2, width, width);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
        if (CGRectContainsPoint(frame, point)) {
            ELCAsset *asset = [_rowAssets objectAtIndex:i];
            if (asset.enabled) {
                NSString *type = [asset.asset valueForProperty:ALAssetPropertyType];
                CGFloat duration = [[asset.asset valueForProperty:ALAssetPropertyDuration] floatValue];
                if ([type isEqualToString:ALAssetTypeVideo] && duration < 0.5) {
                    [[DVMessagesManager sharedInstance] showInformation:NSLocalizedString(@"This video is too short", nil)];
                }
                else {
                    asset.selected = !asset.selected;
                    UIImageView *imageView = [_imageViewArray objectAtIndex:i];
                    UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
                    overlayView.hidden = !asset.selected;
                    if(defaultDimsCellOnSelection && asset.selected){
                        imageView.alpha = 0.7;
                    }else{
                        imageView.alpha = 1.0;
                    }
                }
            }
            else{
                [[DVMessagesManager sharedInstance] showInformation:NSLocalizedString(@"This video is already imported", nil)];
            }
            break;
        }
        frame.origin.x = frame.origin.x + frame.size.width + 4;
    }
}

- (void)layoutSubviews
{    
    CGFloat startX = 4;
    
    NSUInteger width = CGRectGetWidth(self.bounds)/4 - 5;
	CGRect frame = CGRectMake(startX, 2, width, width);
	CGRect frameDuration = CGRectMake(0, width - 20, width, 20);
	CGRect frameCamera = CGRectMake(5, 5, 16, 10);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
        ELCAsset *asset = [_rowAssets objectAtIndex:i];
        
		UIImageView *imageView = [_imageViewArray objectAtIndex:i];
		[imageView setFrame:frame];
		[self.contentView addSubview:imageView];
        
        if ([asset.asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
            UILabel *durationView = [_durationViewArray objectAtIndex:i];
            [durationView setFrame:frameDuration];
            [imageView addSubview:durationView];
            
            UIImageView *cameraView = [_cameraViewArray objectAtIndex:i];
            [cameraView setFrame:frameCamera];
            [durationView addSubview:cameraView];
        }
		
        UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
        [overlayView setFrame:frame];
        [self.contentView addSubview:overlayView];
        
		frame.origin.x = frame.origin.x + frame.size.width + 4;
	}
}

@end
