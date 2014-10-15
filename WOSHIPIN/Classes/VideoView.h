//
//  VideoView.h
//  iCidanaPlayer
//
//  Created by 戚丹青 on 09-11-9.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoView : UIView {
	CALayer *screenLayer;
	int bInitVideo;
	unsigned char * rgb;
	int video_width;
	int video_height;
	CGDataProviderRef rawImageProvider;
}

- (void)SetVideoData:(unsigned char *[])data Stride:(int [])stride Width:(int)width Height:(int)height;
//- (void)SetVideoData2:(unsigned char *)rgbdata Width:(int)width Height:(int)height;
@end
