//
//  EIPlayViewController.h
//  Eeye
//
//  Created by Near on 10-4-20.
//  Copyright 2010 Exmart. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "pe_ctrl.h"
#import "MBProgressHUD.h"
#include <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@class Camera;
@class VideoView;

//EIPlayViewController
//	Play view controller of incoming stream video.
//
@interface EIPlayViewController : UIViewController<MBProgressHUDDelegate> {

	IBOutlet UINavigationBar *_navBar;
  //IBOutlet UIView *cameraControlPanel_;
	IBOutlet UIView *_controlPanel;	//3-button control
	IBOutlet UIButton *toggleControlButton_;
	IBOutlet UIButton *recordButton_;
	
	//detailed controls
	IBOutlet UIButton *zoominButton_;
	IBOutlet UIButton *zoomoutButton_;
	IBOutlet UIButton *irisopenButton_;
	IBOutlet UIButton *iriscloseButton_;
	
	IBOutlet UIButton *arrowupButton_;
	IBOutlet UIButton *arrowdownButton_;
	IBOutlet UIButton *arrowleftButton_;
	IBOutlet UIButton *arrowrightButton_;
  
     IBOutlet UIButton *displayModeButton_;
	
	IBOutlet UIImageView *recordingMark_;
  
	IBOutlet VideoView * videoContextView_;
	
	IBOutlet UILabel *touchHintLabel;

	IBOutlet 	UIView  *snapshotEffectView;

  UILabel *_timeLabel;  
  UILabel *_titleLabel;
  UILabel * statusLabel;
  
  NSDate *_touchBeginDate;
  NSDate *_playStartDate;
  NSDate *_recordStartDate;
  
  NSTimer *_fadeMessageViewsOutTimer;
  NSTimer *_updatePlayingTimeTimer;
  Camera *_currentCamera;
  
  PE_CTRL_T *rtsp_pe;
  
  BOOL recording;
  BOOL capturing;
  
  NSMutableData * mutableData;
  
  // zooming event
  BOOL zoomed_;
  int touchPointDistance_;
  CGPoint firstTouchPoint_;
	int _touch1_flag;	
	int tapMode;
	NSTimer *OnetapTimer;
	NSTimer *touchHintTimer;
	
	CFURLRef		tapFileURLRef;
	SystemSoundID	tapFileObject;
	/*
	CFURLRef		kacaFileURLRef;
	SystemSoundID	kacaFileObject;

	CFURLRef		ka__FileURLRef;
	SystemSoundID	ka__FileObject;
	 */
	
	IBOutlet UIImageView *ptzCtrlHintImage;
	int ptzCtrlHintStep; 
	
}
@property (nonatomic, readonly)VideoView *videoView;

- (id)initControllerWithCamera:(Camera *)camera;

- (void)sendPTZWithOpid:(int)opid para1:(int)para1 para2:(int)para2;
- (IBAction)stopPTZ;

- (IBAction)snapshot:(id)sender;
- (IBAction)record:(id)sender;
- (IBAction)toggleControlPannel:(id)sender;

#pragma mark remote camera control
// direction
- (IBAction)turnLeft:(id)sender;
- (IBAction)turnRight:(id)sender;
- (IBAction)turnUp:(id)sender;
- (IBAction)turnDown:(id)sender;

// light / iris
- (IBAction)openIris:(id)sender;
- (IBAction)closeIris:(id)sender;

// zoom
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;

// focus
- (IBAction)focusNear:(id)sender;
- (IBAction)focusFar:(id)sender;

- (IBAction)switchDisplayMode:(id)sender;

@end
