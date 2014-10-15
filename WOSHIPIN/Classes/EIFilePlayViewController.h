//
//  EIFilePlayViewController.h
//  Eeye
//
//  Created by Li Xinghua on 10-8-31.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "pe_ctrl.h"

@class VideoView;

@interface EIFilePlayViewController : UIViewController {
	IBOutlet VideoView *videoView;
	IBOutlet UILabel *playtimeLabel;
	IBOutlet UISlider *progressSlider;
	IBOutlet UINavigationBar* _navBar;
	PF_HANDLE pf_handle;
	NSString *file_path;
	NSTimer *atimer;
	int totallen;
	int curpos;//current position
	bool messageViewsShown;
	bool playOrpause;
	bool cancelViewhide;
	bool tapMode; // distinguish one tap or double-tap
	NSDate* touchBeginDate;
	NSTimer* OnetapTimer;
	NSTimer* UserSeekTimer;
	int userseekflag;

}


@property (nonatomic, readonly)VideoView *videoView;


- (IBAction)OnOpenFile:(id)sender;
- (IBAction)OnPlayFile:(id)sender;
- (IBAction)OnPauseFile:(id)sender;
- (IBAction)OnCloseFile:(id)sender;
- (IBAction)OnUserSeekProgress:(id)sender;
- (IBAction)OnPlayPauseFile:(id)sender;

- (void)_onpresentOrHideMessageViewsAnimated:(NSTimer*)timer;

- (id)initWithFilePath:(NSString *)path;
- (void)_presentOrHideMessageViewsAnimated:(BOOL)animated;

@end
