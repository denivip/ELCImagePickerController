//
//  AssetCell.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetCell.h"
#import "ELCAsset.h"

@interface ELCAssetCell ()

@property (nonatomic, retain) NSArray *rowAssets;
@property (nonatomic, retain) NSMutableArray *imageViewArray;
@property (nonatomic, retain) NSMutableArray *overlayViewArray;
@property (nonatomic, retain) NSMutableArray *durationViewArray;
@property (nonatomic, retain) NSMutableArray *cameraViewArray;

@end

@implementation ELCAssetCell

@synthesize rowAssets = _rowAssets;

- (id)initWithAssets:(NSArray *)assets reuseIdentifier:(NSString *)identifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
	if(self) {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
        [self addGestureRecognizer:tapRecognizer];
        [tapRecognizer release];
        
        NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.imageViewArray = mutableArray;
        [mutableArray release];
        
        NSMutableArray *durationArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.durationViewArray = durationArray;
        [durationArray release];
        
        NSMutableArray *cameraArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.cameraViewArray = cameraArray;
        [cameraArray release];
        
        NSMutableArray *overlayArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.overlayViewArray = overlayArray;
        [overlayArray release];

        [self setAssets:assets];
	}
	return self;
}

- (void)setAssets:(NSArray *)assets
{
    self.rowAssets = assets;
	for (UIView *view in [self subviews]) {
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
            UILabel *labelView = [_durationViewArray objectAtIndex:i];
            NSUInteger duration = [[asset.asset valueForProperty:ALAssetPropertyDuration] integerValue];
            labelView.text = [NSString stringWithFormat:@"%d:%02d", duration/60, duration%60];
            
        } else {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:asset.asset.thumbnail]];
            [_imageViewArray addObject:imageView];
            [imageView release];
        
            UILabel *labelView = [[UILabel alloc] init];
            labelView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.7f];
            labelView.textAlignment = NSTextAlignmentRight;
            labelView.textColor = [UIColor whiteColor];
            labelView.font = [UIFont systemFontOfSize:14.f];
            NSUInteger duration = [[asset.asset valueForProperty:ALAssetPropertyDuration] integerValue];
            labelView.text = [NSString stringWithFormat:@"%d:%02d", duration/60, duration%60];
            [_durationViewArray addObject:labelView];
            [labelView release];
        
            UIImageView *cameraView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_cam"]];
            [_cameraViewArray addObject:cameraView];
            [cameraView release];
        }
        
        if (i < [_overlayViewArray count]) {
            UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
            overlayView.hidden = asset.selected || !asset.enabled ? NO : YES;
            overlayView.highlighted = !asset.enabled;
        } else {
            if (overlayImage == nil) {
                overlayImage = [UIImage imageNamed:@"Overlay"];
                overlayImageHighlighted = [UIImage imageNamed:@"Overlay-disabled"];
            }
            UIImageView *overlayView = [[UIImageView alloc] initWithImage:overlayImage highlightedImage:overlayImageHighlighted];
            [_overlayViewArray addObject:overlayView];
            overlayView.hidden = asset.selected || !asset.enabled ? NO : YES;
            overlayView.highlighted = !asset.enabled;
            [overlayView release];
        }
    }
}

- (void)cellTapped:(UITapGestureRecognizer *)tapRecognizer
{
    CGPoint point = [tapRecognizer locationInView:self];
    CGFloat startX = 4;
    
	CGRect frame = CGRectMake(startX, 2, 75, 75);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
        if (CGRectContainsPoint(frame, point)) {
            ELCAsset *asset = [_rowAssets objectAtIndex:i];
            if (asset.enabled) {
                asset.selected = !asset.selected;
                UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
                overlayView.hidden = !asset.selected;
            }
            break;
        }
        frame.origin.x = frame.origin.x + frame.size.width + 4;
    }
}

- (void)layoutSubviews
{    
    CGFloat startX = 4;
    
	CGRect frame = CGRectMake(startX, 2, 75, 75);
	CGRect frameDuration = CGRectMake(0, 55, 75, 20);
	CGRect frameCamera = CGRectMake(5, 5, 16, 10);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
		UIImageView *imageView = [_imageViewArray objectAtIndex:i];
		[imageView setFrame:frame];
		[self addSubview:imageView];
        
        UILabel *durationView = [_durationViewArray objectAtIndex:i];
        [durationView setFrame:frameDuration];
        [imageView addSubview:durationView];
		
        UIImageView *cameraView = [_cameraViewArray objectAtIndex:i];
        [cameraView setFrame:frameCamera];
        [durationView addSubview:cameraView];
		
        UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
        [overlayView setFrame:frame];
        [self addSubview:overlayView];
		
		frame.origin.x = frame.origin.x + frame.size.width + 4;
	}
}

- (void)dealloc
{
	[_rowAssets release];
    [_imageViewArray release];
    [_durationViewArray release];
    [_cameraViewArray release];
    [_overlayViewArray release];
	[super dealloc];
}

@end
