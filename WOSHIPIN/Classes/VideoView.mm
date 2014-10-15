//
//  VideoView.m
//  iCidanaPlayer
//
//  Created by ??∏π??on 09-11-9.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VideoView.h"
//#include "CI_SDK_Playback.h"
#import <QuartzCore/QuartzCore.h>

@implementation VideoView
/*
- (id)initWithFrameFormat:(CGRect)rect
{
	if (self = [super initWithFrame:rect]) {
		screenLayer = [CALayer layer];	
		[screenLayer setOpaque:YES];	
		[screenLayer setFrame:self.bounds];
		[self.layer addSublayer:screenLayer];
		yuv2rgb_c_init(1,32,0,0,1<<16,1<<16);
		bInitVideo = 0;
		video_width = video_height = 0;
		rgb = NULL;
	}
	return self;	
}
*/
 
- (id)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		//screenLayer = [CALayer layer];	
		//[screenLayer setOpaque:YES];	
		//[screenLayer setFrame:self.bounds];
		//[self.layer addSublayer:screenLayer];
		//[self.layer insertSublayer:screenLayer atIndex:0];
		screenLayer = self.layer;
		screenLayer.contentsGravity = kCAGravityResizeAspect;

		
		//yuv2rgb_c_init(1,32,0,0,1<<16,1<<16);
		bInitVideo = 0;
		video_width = video_height = 0;
		rgb = NULL;
	}
	
	return self;
}
extern int ff_yuv2rgb32(const uint8_t* const srcSlice[], const int srcStride[], uint8_t* rgb, int w, int h);
- (void)SetVideoData:(unsigned char *[])data Stride:(int [])stride Width:(int)width Height:(int)height
{

	if(video_width != width || video_height != height)
	{
		if (bInitVideo)
		{
			CGDataProviderRelease(rawImageProvider);
			if (rgb) {
				free(rgb);
				rgb = NULL;
			}
			bInitVideo = 0;
		}
	}
	if (!bInitVideo)
	{
		rgb = (unsigned char *)malloc(width * height * 4);
		rawImageProvider = CGDataProviderCreateWithData(NULL,rgb,width * height * 4,NULL);
		video_width = width;
		video_height = height;
		bInitVideo = 1;
	}
	if (rgb)
	{

		ff_yuv2rgb32(data,stride,rgb,width,height);
        
		[self drawRect:CGRectMake(0.0, 0.0, 480.0, 320.0)];
	}		
}

- (void)drawRect:(CGRect)rect {
	if (bInitVideo && rgb)
	{
		CGImageRef image = CGImageCreate(video_width, video_height, 8, 32, video_width*4, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst, rawImageProvider, NULL, NO, kCGRenderingIntentDefault);
		if (image != NULL) {
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
			[screenLayer setContents:(id)image];		
			[CATransaction commit];	
			CGImageRelease(image);
		} 
	}
}

- (void)dealloc {
	//yuv2rgb_c_uninit();
	if (rgb)
	{
		CGDataProviderRelease(rawImageProvider);
		free(rgb);
		rgb = NULL;
		bInitVideo = 0;
	}
	[super dealloc];
}
@end
