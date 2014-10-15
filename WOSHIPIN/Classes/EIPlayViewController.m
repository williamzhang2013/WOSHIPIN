//
//  EIPlayViewController.m
//  Eeye
//
//  Created by Near on 10-4-20.
//  Copyright 2010 Exmart. All rights reserved.
//

//Mon Aug 16 23:06:43 unknown com.apple.mediaserverd[21] <Notice>: vxdDec - Frame# 1, DecodeFrame failed with error: 6 

#import "EIPlayViewController.h"
#import "Camera.h"
#import "VideoView.h"
#import "Utilities.h"
#import "RecordingCenter.h"
#import "AsyncUdpSocket.h"
#import "MBProgressHUD.h"
#import "Common.h"

#pragma mark -

//#define ValidateOrientation(orientation)\
//((orientation) == UIInterfaceOrientationLandscapeLeft || \
//(orientation) == UIInterfaceOrientationLandscapeRight) \

static void rtsppe_event_handler(void *caller, int evt,int param1);

#pragma mark -
@interface EIPlayViewController(PrivateMethods)
@property (nonatomic, retain)NSDate *touchBeginDate;
@property (nonatomic, readonly)BOOL messageViewsShown;
@property (nonatomic, retain)NSTimer *fadeMessageViewsOutTimer;
@property (nonatomic, retain)NSTimer *updatePlayingTimeTimer;

- (void)_setupHeaderNacBar;
//- (void)_setOrientation:(UIInterfaceOrientation)orientation;
//Hide or show message views
- (void)_presentOrHideMessageViewsAnimated:(BOOL)animated;

//Timers
- (void)_fadeMessageViewsOutTimerMethod:(NSTimer *)timer;
- (void)_startFadeMessageViewsOutTimer;
- (void)_updatePlayingTimeTimerMethod:(NSTimer *)timer;

- (void)_doneBarButtonAction:(id)sender;

//RTSP event handle
- (void)_handle_rtsppe_event:(NSValue *)noti_arg;

//Start or stop video from camera via rtsp
- (void)_startPlayingVideoFromCamera;
- (void)_stopPlayingVideo;

//xinghua show/hide detailed controls
- (void)_hideDetailedControls:(BOOL) bhidden;

@end
@implementation EIPlayViewController(PrivateMethods)
@dynamic touchBeginDate;

- (NSDate *)touchBeginDate{
  return _touchBeginDate;
}
- (void)setTouchBeginDate:(NSDate *)newDate{
  [_touchBeginDate release];
  _touchBeginDate = [newDate retain];
}
@dynamic messageViewsShown;
- (BOOL)messageViewsShown{
  return _controlPanel.alpha != 0;
}
@dynamic fadeMessageViewsOutTimer;
- (NSTimer *)fadeMessageViewsOutTimer{
  return _fadeMessageViewsOutTimer;
}
- (void)setFadeMessageViewsOutTimer:(NSTimer *)newTimer{
  [_fadeMessageViewsOutTimer invalidate];
  [_fadeMessageViewsOutTimer release];
  
  _fadeMessageViewsOutTimer = [newTimer retain];
}
@dynamic updatePlayingTimeTimer;
- (NSTimer *)updatePlayingTimeTimer{
  return _updatePlayingTimeTimer;
}
- (void)setUpdatePlayingTimeTimer:(NSTimer *)newTimer{
  [_updatePlayingTimeTimer invalidate];
  [_updatePlayingTimeTimer release];
  
  _updatePlayingTimeTimer = [newTimer retain];
}

- (void)_setupHeaderNacBar{  
  _navBar.barStyle = UIBarStyleBlack;
  _navBar.translucent = YES;
  
  UINavigationItem *navItem = _navBar.topItem;
  
  //Left bar button item
  {
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] 
                                          //initWithBarButtonSystemItem:UIBarButtonSystemItemDone
										  initWithTitle:@"返回" style:UIBarButtonItemStyleDone
                                          target:self
                                          action:@selector(_doneBarButtonAction:)];
    navItem.leftBarButtonItem = leftBarButtonItem;
    [leftBarButtonItem release];
  }
  
  [self.view addSubview:recordingMark_];
	[self.view bringSubviewToFront:recordingMark_];
  recordingMark_.center = CGPointMake(460, 40);
#if 0
  //Title view
  {
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 44)];
    titleView.backgroundColor = [UIColor clearColor];
    
    _timeLabel = [[[UILabel alloc] init] autorelease];
    _timeLabel.textAlignment = UITextAlignmentCenter;
    _timeLabel.adjustsFontSizeToFitWidth = YES;
    _timeLabel.minimumFontSize = 8;
    _timeLabel.font = [UIFont systemFontOfSize:14];
    _timeLabel.text = @"00:00";
    _timeLabel.backgroundColor = [UIColor clearColor];
    _timeLabel.textColor = [UIColor whiteColor];
    _timeLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    _timeLabel.frame = CGRectMake(titleView.bounds.size.width - 80, 0, 80, 44);
    
    [titleView addSubview:_timeLabel];
    
    statusLabel = [[[UILabel alloc] init] autorelease];
    statusLabel.textAlignment = UITextAlignmentRight;
    statusLabel.adjustsFontSizeToFitWidth = YES;
    statusLabel.minimumFontSize = 8;
    statusLabel.font = [UIFont boldSystemFontOfSize:17];
    statusLabel.text = @"正在连接";
    statusLabel.backgroundColor = [UIColor clearColor];
    statusLabel.textColor = [UIColor whiteColor];
    statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    statusLabel.frame = CGRectMake(titleView.bounds.size.width - 140, 0, 80, 44);
    [titleView addSubview:statusLabel];
    
    _titleLabel = [[[UILabel alloc] init] autorelease];
    _titleLabel.textAlignment = UITextAlignmentCenter;
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.minimumFontSize = 8;
    _titleLabel.font = [UIFont boldSystemFontOfSize:17];
    _titleLabel.text = _currentCamera.puName;
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _titleLabel.frame = CGRectMake(0, 0, titleView.frame.size.width - _timeLabel.frame.size.width, 44);
    _titleLabel.center = CGPointMake(titleView.bounds.size.width/2 - 30, titleView.bounds.size.height/2);
    
    [titleView addSubview:_titleLabel];
    
    navItem.titleView = titleView;
    [titleView release];
  }
#else
    _timeLabel = [[[UILabel alloc] init] autorelease];
    _timeLabel.textAlignment = UITextAlignmentCenter;
    _timeLabel.adjustsFontSizeToFitWidth = YES;
    _timeLabel.minimumFontSize = 8;
    _timeLabel.font = [UIFont systemFontOfSize:14];
    _timeLabel.text = @"00:00";
    _timeLabel.backgroundColor = [UIColor clearColor];
    _timeLabel.textColor = [UIColor whiteColor];
    _timeLabel.bounds = CGRectMake(0, 0, 80, 44);
    _timeLabel.shadowColor = [UIColor grayColor];
    _timeLabel.shadowOffset = CGSizeMake(0, -1);
    [self.view addSubview:_timeLabel];
    
    statusLabel = [[[UILabel alloc] init] autorelease];
    statusLabel.textAlignment = UITextAlignmentCenter;
    //statusLabel.adjustsFontSizeToFitWidth = YES;
    statusLabel.minimumFontSize = 8;
    statusLabel.font = [UIFont systemFontOfSize:14];
    statusLabel.text = @"正在连接";
    statusLabel.backgroundColor = [UIColor clearColor];
    statusLabel.textColor = [UIColor whiteColor];
    statusLabel.bounds = CGRectMake(0, 0, 100, 44);
    statusLabel.shadowColor = [UIColor grayColor];
    statusLabel.shadowOffset = CGSizeMake(0, -1);    
    [self.view addSubview:statusLabel];
    
    navItem.title = _currentCamera.puName;
#endif
}

- (void)_hideDetailedControls:(BOOL) bhidden
{
	arrowupButton_.hidden =  bhidden;
	arrowdownButton_.hidden =  bhidden;
	arrowleftButton_.hidden =  bhidden;
	arrowrightButton_.hidden =  bhidden;
	
	zoominButton_.hidden = bhidden;
	zoomoutButton_.hidden = bhidden;
	irisopenButton_.hidden = bhidden;
	iriscloseButton_.hidden = bhidden;
}

/*
 - (void)_setOrientation:(UIInterfaceOrientation)orientation{
 //Filter illegal orientations
 if (!ValidateOrientation(orientation)) 
 return;
 
 CGRect fullScreenRect = [[UIScreen mainScreen] bounds];
 self.view.center = CGPointMake(fullScreenRect.size.width/2, fullScreenRect.size.height/2);
 
 CGAffineTransform transform = CGAffineTransformIdentity;
 if (orientation == UIInterfaceOrientationLandscapeLeft) {
 transform  = CGAffineTransformRotate(transform, -M_PI_2);
 }
 else if (orientation == UIInterfaceOrientationLandscapeRight){
 transform = CGAffineTransformRotate(transform, M_PI_2);
 } else if (orientation == UIInterfaceOrientationPortrait) {
 ;
 } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
 transform = CGAffineTransformRotate(transform, M_PI_2 * 2);
 }
 self.view.transform = transform;
 }
 */

- (void)_presentOrHideMessageViewsAnimated:(BOOL)animated{

	/*
   if (self.interfaceOrientation == UIInterfaceOrientationPortrait ||
   self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
   [[UIApplication sharedApplication] setStatusBarHidden:NO animated:animated];
   _navBar.alpha = 1;
   _controlPanel.alpha = 1;
   return;
   }
	 */
  
  if (animated) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:.4];
    [UIView setAnimationDelay:.05];
  }
  
  //If message views are shown, fade them out
  if (self.messageViewsShown) {
    [[UIApplication sharedApplication] setStatusBarHidden:YES animated:animated];
    _navBar.alpha = 0;
    _controlPanel.alpha = 0;
		
		[self _hideDetailedControls:YES];
  }
  //if not, show them in
  else {
    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:animated];
    _navBar.alpha = 1;
    _controlPanel.alpha = 1;
		
		[self _hideDetailedControls:!toggleControlButton_.selected];
  }
  
  if (animated) {
    [UIView commitAnimations];
  }
  
  if (self.messageViewsShown) {
    //[self _startFadeMessageViewsOutTimer];
  }
}

- (void)_fadeMessageViewsOutTimerMethod:(NSTimer *)timer{
  [self _presentOrHideMessageViewsAnimated:YES];
}
- (void)_startFadeMessageViewsOutTimer{
  self.fadeMessageViewsOutTimer = [NSTimer scheduledTimerWithTimeInterval:3. 
                                                                   target:self 
                                                                 selector:@selector(_fadeMessageViewsOutTimerMethod:)
                                                                 userInfo:nil
                                                                  repeats:NO];
}
- (void)_updatePlayingTimeTimerMethod:(NSTimer *)timer{
  _timeLabel.text = [Utilities convertSecondesToTimeString:fabs([_recordStartDate timeIntervalSinceNow])];
  /*
   if(recording) {
   //recordingMark_.highlighted = !recordingMark_.highlighted;
   recordingMark_.hidden = !recordingMark_.hidden;
   } else {
   //recordingMark_.highlighted = NO;
   recordingMark_.hidden = YES;
   }
   */
}

- (void)_doneBarButtonAction:(id)sender{
  MBProgressHUD * hud = [[MBProgressHUD alloc] initWithWindow:self.view.window];
  hud.labelText = @"请稍候";
  hud.delegate = self;
  [self.view.window addSubview:hud];
  [hud showWhileExecuting:@selector(_stopPlayingVideo) onTarget:self withObject:nil animated:YES];
  
  //[self _stopPlayingVideo];
}



- (void)_handle_rtsppe_event:(NSValue *)noti_arg
{
  int *arg = (int *)[noti_arg pointerValue];
  int evt = arg[0];
  
  NSLog(@"event::::%d",evt);
  
  switch(evt)
  {
    case PE_EVENT_BUFFERING:
      statusLabel.text = @"正在载入";
      break;
    case PE_EVENT_PLAYING:
      statusLabel.text = @"";//@"正在测试";      
      break;
    case PE_EVENT_RTSPCONN_LOST:
      statusLabel.text = @"连接断开";      
      break;
    case PE_EVENT_RTSPOPEN_COMPLETE:
      if (arg[1] == -1)
      {
        statusLabel.text = @"连接失败";
        //RTSP connection open fail
      }
      else {
        statusLabel.text = @"连接成功";
      }
      
      break;
      
  }
  
  free(arg);
  //TODO
}

- (void)_startPlayingVideoFromCamera{
  _playStartDate = [[NSDate date] retain];
  self.updatePlayingTimeTimer = [NSTimer scheduledTimerWithTimeInterval:1. 
                                                                 target:self
                                                               selector:@selector(_updatePlayingTimeTimerMethod:)
                                                               userInfo:nil
                                                                repeats:YES];
  PE_Start(rtsp_pe, (char *)[_currentCamera.rtspURL cStringUsingEncoding:NSUTF8StringEncoding]);
  statusLabel.text = @"正在连接";
}

- (void)_stopPlayingVideo{
  [_playStartDate release];
  _playStartDate = nil;
  self.updatePlayingTimeTimer = nil;

	PE_Stop(rtsp_pe);//will stop record if it is active
	PE_Destroy(rtsp_pe);
	rtsp_pe = NULL;
	recording = NO;
}


//xinghua 20101126

-(void)_touchHintHideTimerMethod:(NSTimer *)timer
{
#if 0
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:.6];
    [UIView setAnimationDelay:.05];
	
	touchHintLabel.alpha = 0.0;
	
	[UIView commitAnimations];
#else
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:.7];
    [UIView setAnimationDelay:.05];
	
	if (ptzCtrlHintImage.alpha == 1.0)
		ptzCtrlHintImage.alpha = 0.0;
	else
		ptzCtrlHintImage.alpha = 1.0;
	
	[UIView commitAnimations];
	
	ptzCtrlHintStep --;
	if (ptzCtrlHintStep > 0)
		[NSTimer scheduledTimerWithTimeInterval:0.7 
									 target:self 
								   selector:@selector(_touchHintHideTimerMethod:)
								   userInfo:nil
									repeats:NO];
#endif
}
//xinghua 20101126
-(void)showPTZControlHint:(NSInteger)hint
{
	switch(hint)
	{
		case 0:
			touchHintLabel.text = @"云台向上转命令";
			ptzCtrlHintImage.image = [UIImage imageNamed:@"h_up_normal.png"];
			break;
		case 1:
			touchHintLabel.text = @"云台向下转命令";
			ptzCtrlHintImage.image = [UIImage imageNamed:@"h_down_normal.png"];
			break;
		case 2:
			touchHintLabel.text = @"云台向左转命令";
			ptzCtrlHintImage.image = [UIImage imageNamed:@"h_left_normal.png"];
			break;
		case 3:
			touchHintLabel.text = @"云台向右转命令";
			ptzCtrlHintImage.image = [UIImage imageNamed:@"h_right_normal.png"];
			break;
		case 4:
			touchHintLabel.text = @"镜头拉近命令";
			ptzCtrlHintImage.image = [UIImage imageNamed:@"i_zoomin_normal.png"];
			break;
		case 5:
			touchHintLabel.text = @"镜头拉远命令";
			ptzCtrlHintImage.image = [UIImage imageNamed:@"i_zoomout_normal.png"];
			break;
		case 6:
			break;
			
	}
	
#if 0 //xinghua 20101206, dont use label hint
	if (touchHintLabel.alpha == 1.0)
		[touchHintTimer invalidate];
	else
		touchHintLabel.alpha = 1.0;//show it
	
	
	touchHintTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 
													  target:self 
													selector:@selector(_touchHintHideTimerMethod:)
													userInfo:nil
													 repeats:NO];
#endif
	//xinghua 20101206 , instead we use animation and sound as hint
	
	if (ptzCtrlHintStep > 0)
	{
		return;
	}
	
	ptzCtrlHintStep = 3;
	AudioServicesPlaySystemSound(tapFileObject);
	/*
	NSString *filepath = [[NSBundle mainBundle] pathForResource:@"ka__" ofType:@"aif"];
	NSError *error;
	AVAudioPlayer *ap = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:filepath] error:&error ];
	if (ap != nil)
	{
		[ap play];
	}
	*/
	ptzCtrlHintImage.alpha = 1.0;

	touchHintTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 
													  target:self 
													selector:@selector(_touchHintHideTimerMethod:)
													userInfo:nil
													 repeats:NO];
	
}

-(void)_onAppTerminate:(NSNotification *)notification 
{
	if (rtsp_pe)
	{
		PE_Destroy(rtsp_pe);
		rtsp_pe = NULL;
	}
}


@end


@implementation EIPlayViewController
@dynamic videoView;

- (VideoView *)videoView{
  //return (VideoView *)self.view;
  return (VideoView *)videoContextView_;
}

#pragma mark -
#pragma mark Initialize

- (id)initControllerWithCamera:(Camera *)camera{
  if (self = [super initWithNibName:@"EIPlayViewController" bundle:nil]) {
    self.wantsFullScreenLayout = YES;
    _currentCamera = [camera retain];
    recording = NO;
	  _touch1_flag = 0; 
	  tapMode = 0;
  }
  return self;
}

#pragma mark MBProgressHUDDelegate 

- (void)hudWasHidden {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark View life cycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  recordingMark_.hidden = YES;  
  [self _setupHeaderNacBar];
  _controlPanel.backgroundColor = [UIColor clearColor];
  videoContextView_.contentMode = UIViewContentModeScaleAspectFit;

	touchHintLabel.alpha = 0.0;//xinghua 20101126
	ptzCtrlHintImage.alpha = 0.0;
	ptzCtrlHintStep = 0;
	snapshotEffectView.alpha = 0.0;

	[self _hideDetailedControls:YES];
  
  
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
	_navBar.barStyle = UIBarStyleBlack;
	_navBar.translucent = YES;
	
	//default
	//videoContextView_.center = CGPointMake(160, 240);
	//videoContextView_.bounds = CGRectMake(0,0,320,240);
  
  [self willAnimateRotationToInterfaceOrientation:self.interfaceOrientation 
                                         duration:0];
	/*
	kacaFileURLRef  =	CFBundleCopyResourceURL (
												 CFBundleGetMainBundle (),
												 CFSTR ("kaca"),
												 CFSTR ("aif"),
												 NULL
												 );

	// Create a system sound object representing the sound file
	AudioServicesCreateSystemSoundID (
									  kacaFileURLRef,
									  &kacaFileObject
									  );
	

	ka__FileURLRef  =	CFBundleCopyResourceURL (
												 CFBundleGetMainBundle (),
												 CFSTR ("ka__"),
												 CFSTR ("aif"),
												 NULL
												 );
	AudioServicesCreateSystemSoundID (
									  ka__FileURLRef,
									  &ka__FileObject
									  );
	*/
	tapFileURLRef  =	CFBundleCopyResourceURL (
												 CFBundleGetMainBundle (),
												 CFSTR ("tap"),
												 CFSTR ("aif"),
												 NULL
												 );
	AudioServicesCreateSystemSoundID (
									  tapFileURLRef,
									  &tapFileObject
									  );
	
	//xinghua 20101206
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(_onAppTerminate:)
												 name:UIApplicationWillTerminateNotification 
											   object:nil];	
	
	
	
  //Create rtsp play engine
  rtsp_pe = PE_Create(rtsppe_event_handler, (void*)self);
}


- (void)viewWillAppear:(BOOL)animated{
	
  [UIApplication sharedApplication].idleTimerDisabled = YES;//xinghua 20101026

	
  self.view.multipleTouchEnabled = YES;
  self.videoView.multipleTouchEnabled = YES;
  [super viewWillAppear:animated];
  
	touchHintLabel.center = CGPointMake(160,240);

  [self _startPlayingVideoFromCamera];
  
  //[self _setOrientation:UIInterfaceOrientationLandscapeLeft];
  //[self _startFadeMessageViewsOutTimer];
  
  //Set up status bar
  //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
  //[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft];
}
- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  _timeLabel.hidden = YES;
  displayModeButton_.hidden = YES;
  displayModeButton_.center = CGPointMake(460, 40);
}

- (void)viewWillDisappear:(BOOL)animated{
  [super viewWillDisappear:animated];
  
  self.fadeMessageViewsOutTimer = nil;
  
	[UIApplication sharedApplication].idleTimerDisabled = NO;//xinghua 20101026

  //Recover status bar status
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
  [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
  [[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
  
  //NSLog(@"should auto rotate : %d",toInterfaceOrientation);
  if (UIInterfaceOrientationLandscapeLeft == toInterfaceOrientation ||
      UIInterfaceOrientationLandscapeRight == toInterfaceOrientation || 
      UIInterfaceOrientationPortrait == toInterfaceOrientation) 
	{
		
    return YES;
  }
  
  return NO;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
                                         duration:(NSTimeInterval)duration {
  /*
   if (!self.messageViewsShown) {
   [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
   _navBar.alpha = 1;
   _controlPanel.alpha = 1;
   }
	 */
  
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
  //[UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationDuration:duration];
  
  
  
  //NSLog(@"will animate to : %d", interfaceOrientation);
  [[UIApplication sharedApplication] setStatusBarOrientation:interfaceOrientation];
  //  [[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];
  switch (interfaceOrientation) {
	  case UIInterfaceOrientationPortrait:
	  {
		videoContextView_.contentMode = UIViewContentModeScaleAspectFit;
		_navBar.frame = CGRectMake(0, 20, 320, 44);
		recordingMark_.center = CGPointMake(305, 40);
		_navBar.topItem.titleView.frame = CGRectMake(0, 0, 320, 44);
		_timeLabel.center = CGPointMake(280, 42+44);
		statusLabel.center = CGPointMake(50, 42+44);
		//_titleLabel.center = CGPointMake(130, 22);


		zoominButton_.center = CGPointMake(40, 410);
		zoomoutButton_.center = CGPointMake(100, 410);
		irisopenButton_.center = CGPointMake(220, 410);
		iriscloseButton_.center = CGPointMake(280, 410);

		arrowupButton_.center = CGPointMake(160, 80);	
		arrowdownButton_.center = CGPointMake(160, 410);
		arrowleftButton_.center = CGPointMake(22, 240);	
		arrowrightButton_.center = CGPointMake(298, 240);	

		displayModeButton_.hidden = YES;

		videoContextView_.center = CGPointMake(160, 240);
		videoContextView_.bounds = CGRectMake(0,0,320,240);

		touchHintLabel.center = CGPointMake(160,240);
		  ptzCtrlHintImage.center = CGPointMake(160,240);
		  
	  }
      break;
		  
	  case UIInterfaceOrientationLandscapeLeft:
	  case UIInterfaceOrientationLandscapeRight:
	  {
			_navBar.frame = CGRectMake(0, 20, 480, 44);
			recordingMark_.center = CGPointMake(420, 40);
			_navBar.topItem.titleView.frame = CGRectMake(0, 0, 480, 44);
			_timeLabel.center = CGPointMake(440, 44+42);
			statusLabel.center = CGPointMake(50, 44+42);
			//_titleLabel.center = CGPointMake(210, 22);

			zoominButton_.center = CGPointMake(98, 252);
			zoomoutButton_.center = CGPointMake(160, 252);
			irisopenButton_.center = CGPointMake(326, 252);
			iriscloseButton_.center = CGPointMake(393, 252);


			arrowupButton_.center = CGPointMake(240, 80);	
			arrowdownButton_.center = CGPointMake(240, 252);
			arrowleftButton_.center = CGPointMake(22, 160);	
			arrowrightButton_.center = CGPointMake(458, 160);	

			displayModeButton_.hidden = NO;
			videoContextView_.center = CGPointMake(240, 160);
			videoContextView_.bounds = CGRectMake(0, 0, 480, 320);
			touchHintLabel.center = CGPointMake(240,160);
		  ptzCtrlHintImage.center = CGPointMake(240,160);

	  }
      break;

      
    default:
      break;
  }
  
  [UIView commitAnimations];
}



- (void)dealloc {
	
	self.touchBeginDate = nil;
  
	[_navBar release];
	[toggleControlButton_ release];
    [_controlPanel release];
	[recordButton_ release];
	[zoominButton_ release];
	[zoomoutButton_ release];
	[irisopenButton_ release];
	[iriscloseButton_ release];
	[arrowupButton_ release];
	[arrowdownButton_ release];
	[arrowleftButton_ release];
	[arrowrightButton_ release];
	[displayModeButton_ release];
	[recordingMark_ release];
	[videoContextView_ release];
	[touchHintLabel release];
	[ptzCtrlHintImage release];
	[_currentCamera release];
  /*
	AudioServicesDisposeSystemSoundID (kacaFileObject);
	CFRelease (kacaFileURLRef);
	AudioServicesDisposeSystemSoundID (ka__FileObject);
	CFRelease (ka__FileURLRef);
   */
	AudioServicesDisposeSystemSoundID (tapFileObject);
	CFRelease (tapFileURLRef);

	//xinghua 20101206
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];

  [super dealloc];
}

#pragma mark -
#pragma mark Public


CGFloat DistanceBetweenTwoPoints(CGPoint point1,CGPoint point2)
{
  //NSLog(@"%f,%f,%f,%f",point1.x,point1.y,point2.x,point2.y);
  CGFloat dx = point2.x - point1.x;
  CGFloat dy = point2.y - point1.y;
  //NSLog(@"%f,%f,%f",dx,dy,sqrt(dx*dx + dy*dy ));
  return sqrt(dx*dx + dy*dy );
};

- (int)distanceBetweenTouchA:(UITouch *)touchA touchB:(UITouch *)touchB {
  CGPoint pointA = [touchA locationInView:self.view];
  CGPoint pointB = [touchB locationInView:self.view];
  return (int)DistanceBetweenTwoPoints(pointA,pointB);
}






//xinghua 20101026, at least distance 40 to be regarded as up/down/left/right
#define MIN_DISTANCE_MOVE 60 
- (void) controlDirectionWithOriginPoint:(CGPoint)pointA newPoint:(CGPoint)pointB {
	if (pointB.x > pointA.x + MIN_DISTANCE_MOVE) 
	{
		NSLog(@"turn Right");
	[self showPTZControlHint:3];
		[self turnRight:nil];
	}
	if (pointB.x + MIN_DISTANCE_MOVE < pointA.x) {
		NSLog(@"turn Left");
	[self showPTZControlHint:2];
		[self turnLeft:nil];
	}
	if (pointB.y > pointA.y + MIN_DISTANCE_MOVE) {
		NSLog(@"turn Down");
	[self showPTZControlHint:1];
		[self turnDown:nil];
	}
	if (pointB.y + MIN_DISTANCE_MOVE< pointA.y) {
		NSLog(@"turn Up");
	[self showPTZControlHint:0];
		[self turnUp:nil];
	}
}


#pragma mark -
#pragma mark Touch Events
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
  //NSLog(@"touches:%@",touches);
  switch ([touches count]) 
  {
    case 2:
    {
      UITouch * touch1 = [[touches allObjects] objectAtIndex:0];
      UITouch * touch2 = [[touches allObjects] objectAtIndex:1];
      touchPointDistance_ = [self distanceBetweenTouchA:touch1 touchB:touch2];
		NSLog(@"touchBegan 2");
    }
      break;
    case 1:
		  if (_touch1_flag == 0)	//xinghua 20101026
		  {
			self.touchBeginDate = [NSDate date];  
			  firstTouchPoint_ = [[[touches allObjects] objectAtIndex:0] locationInView:self.view];
			  _touch1_flag = 1;
			  NSLog(@"touchBegan 1");
		  }
		  else
			  _touch1_flag = 0;
      break;
  }
  
  
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
  //
  if(zoomed_) return;
  
  if([touches count] == 1) return;
  
	//NSLog(@"moved");
	
  UITouch * touch1 = [[touches allObjects] objectAtIndex:0];
  UITouch * touch2 = [[touches allObjects] objectAtIndex:1];
  int newDistance = [self distanceBetweenTouchA:touch1 touchB:touch2];
  if (touchPointDistance_ == -1) {
    touchPointDistance_ = newDistance; 
    return;
  }
  if (newDistance > touchPointDistance_ + 80) {
	  NSLog(@"zoomIn");
  [self showPTZControlHint:4];

    [self zoomIn:nil];
	  touchPointDistance_ = -1;
	  zoomed_ = YES;
  } else if (newDistance + 80< touchPointDistance_) {
	  NSLog(@"zoomOut");
  [self showPTZControlHint:5];
    [self zoomOut:nil];
	  touchPointDistance_ = -1;
	  zoomed_ = YES;
  }
}

- (void)_onpresentOrHideMessageViewsAnimated:(NSTimer*)timer{
	//cancelViewhide = false;
	[self _presentOrHideMessageViewsAnimated:YES];
	tapMode = 0;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	/*
	if([touches count] ==  1)
	 NSLog(@"touchEnd 1");
	else
	NSLog(@"touchEnd 2");
 */
  if (zoomed_) {
    zoomed_ = NO;
	  touchPointDistance_ = -1;
    return; 
  }
  if([touches count] >=  2) return;
  
	//xinghua 20101026
	if(_touch1_flag == 0) return;
	_touch1_flag = 0;
		
	
  UITouch * touch = [[touches allObjects] objectAtIndex:0];  
  //NSLog(@"%f",DistanceBetweenTwoPoints(firstTouchPoint_, 
  //                                     [touch locationInView:self.view]));

	
  if (DistanceBetweenTwoPoints(firstTouchPoint_, 
                               [touch locationInView:self.view]) < 25) {
    NSTimeInterval timeInterval = [self.touchBeginDate timeIntervalSinceNow];
    self.touchBeginDate = nil;
    
    timeInterval = fabs(timeInterval);
	  
#if 0	  
    if (timeInterval < .5 ) {
      [self _presentOrHideMessageViewsAnimated:YES];
    }
#else
	  if(timeInterval < .3)
	  {
		  if (tapMode == 0)
		  {
			  OnetapTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 
													 target:self 
												   selector:@selector(_onpresentOrHideMessageViewsAnimated:) 
												   userInfo:nil repeats:NO];
		  }
		  else //doube tap to switch display mode in landscape
		  {
			  [OnetapTimer invalidate];
			  if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) )
			  [self switchDisplayMode:nil];
		  }
		  tapMode = 1-tapMode;
	  }
#endif
  } else {
    [self controlDirectionWithOriginPoint:firstTouchPoint_ 
                                 newPoint:[touch locationInView:self.view]];
  }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
  self.touchBeginDate = nil;
  zoomed_ = NO;
	touchPointDistance_ = -1;
}

#pragma mark -UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1) {
		if (recording) {
			recordButton_.selected = NO;
			//recordButtonPortail_.selected = NO;
			recordingMark_.hidden = YES; 
			_timeLabel.hidden = YES;
			PE_StopRecord(rtsp_pe);
			recording = NO;
		} else {
			recordButton_.selected = YES;
			//recordButtonPortail_.selected = YES;
			recordingMark_.hidden = NO; 
			_timeLabel.hidden = NO;
			_recordStartDate = [[NSDate date] retain];
			_timeLabel.text = @"00:00";
			NSString * fileName = [RecordingCenter filePathWithCameraName:_currentCamera.puName];
			NSLog(@"start record @ %@",fileName);
			PE_StartRecord(rtsp_pe, (char*)[fileName UTF8String], _currentCamera.streamType);
			recording = YES;
		}
	}
}


#pragma mark IBActions
- (IBAction)snapshot:(id)sender {
//to play a sound, xinghua 20101126
	// Get the URL to the sound file to play
	//AudioServicesPlaySystemSound(kacaFileObject);
	
	NSString *filepath = [[NSBundle mainBundle] pathForResource:@"kaca" ofType:@"aif"];
	NSError *error;
	AVAudioPlayer *ap = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:filepath] error:&error ];
	if (ap != nil)
	{
		[ap play];
	}

	snapshotEffectView.frame = self.videoView.frame;
	//NSLog(@"%d,  %d", snapshotEffectView.frame.size.width, snapshotEffectView.frame.size.height);
	snapshotEffectView.alpha = 1.0;
	
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationBeginsFromCurrentState:NO];
    [UIView setAnimationDuration:.6];
    [UIView setAnimationDelay:.05];
	
	snapshotEffectView.alpha = 0.0;
	
	[UIView commitAnimations];//async
	
    [self performSelectorInBackground:@selector(captureAndSave) withObject:nil];
	
}

- (void)captureAndSave {
  if (capturing) {
    return;
  }
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  NSString * fileName = [RecordingCenter filePathForTempPic];
  PE_RequestSnapshot(rtsp_pe, (char*)[fileName UTF8String]);
  int cc = 1000;
  while (PE_CheckSnapshot(rtsp_pe) == 1 && (cc-- > 0)) {
    usleep(500);
  }
  
  if (PE_CheckSnapshot(rtsp_pe) == 0) {
    UIImage * image = [[UIImage alloc] initWithContentsOfFile:fileName];
    UIImageWriteToSavedPhotosAlbum(image, nil, NULL, NULL);
    [image release];
  } else if ( PE_CheckSnapshot(rtsp_pe) == 1){
    PE_UndoSnapshotRequest(rtsp_pe);
  }
  capturing = NO;
  
  [pool release];
}

- (IBAction)record:(id)sender {
  //NSLog(@"record");
	NSString * str ; //xinghua 20101126
	AudioServicesPlaySystemSound(tapFileObject);
	
	if (recording)
		str = @"请确认关闭录像功能";
	else
		str = @"请确认开启录像功能";

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
													message:str
											delegate:self
										  cancelButtonTitle:@"否" 
										  otherButtonTitles:@"是", nil];
	
	[alert show];
	[alert release];
	
#if 0
  if (recording) {
    recordButton_.selected = NO;
    //recordButtonPortail_.selected = NO;
    recordingMark_.hidden = YES; 
    _timeLabel.hidden = YES;
    PE_StopRecord(rtsp_pe);
    recording = NO;
  } else {
    recordButton_.selected = YES;
    //recordButtonPortail_.selected = YES;
    recordingMark_.hidden = NO; 
    _timeLabel.hidden = NO;
    _recordStartDate = [[NSDate date] retain];
    _timeLabel.text = @"00:00";
    NSString * fileName = [RecordingCenter filePathWithCameraName:_currentCamera.puName];
    NSLog(@"start record @ %@",fileName);
    PE_StartRecord(rtsp_pe, [fileName UTF8String], _currentCamera.streamType);
    
    recording = YES;
  }
#endif	
}

- (IBAction)toggleControlPannel:(id)sender {
	
	//TODO
	toggleControlButton_.selected = !toggleControlButton_.selected;
	[self _hideDetailedControls:!toggleControlButton_.selected];
  
	
}

#pragma mark remote camera control
// direction

extern int g_CameraControlLength1;
extern int g_CameraControlLength2;
- (IBAction)turnLeft:(id)sender {
	AudioServicesPlaySystemSound(tapFileObject);

  [self sendPTZWithOpid:3 para1: g_CameraControlLength1 para2:0];
}
- (IBAction)turnRight:(id)sender {
	AudioServicesPlaySystemSound(tapFileObject);
  [self sendPTZWithOpid:4 para1:g_CameraControlLength1 para2:0];
}
- (IBAction)turnUp:(id)sender {
	AudioServicesPlaySystemSound(tapFileObject);
  [self sendPTZWithOpid:1 para1:g_CameraControlLength1 para2:0];
}
- (IBAction)turnDown:(id)sender {
	AudioServicesPlaySystemSound(tapFileObject);
  [self sendPTZWithOpid:2 para1:g_CameraControlLength1 para2:0];
}

// light / iris
- (IBAction)openIris:(id)sender {
	AudioServicesPlaySystemSound(tapFileObject);

  [self sendPTZWithOpid:5 para1:g_CameraControlLength2 para2:0];
}
- (IBAction)closeIris:(id)sender {
	AudioServicesPlaySystemSound(tapFileObject);

  [self sendPTZWithOpid:6 para1:g_CameraControlLength2 para2:0];
}

// zoom
- (IBAction)zoomIn:(id)sender {
	AudioServicesPlaySystemSound(tapFileObject);
  [self sendPTZWithOpid:7 para1:5 para2:0];
}
- (IBAction)zoomOut:(id)sender {
	AudioServicesPlaySystemSound(tapFileObject);
  [self sendPTZWithOpid:8 para1:5 para2:0];
}

// focus
- (IBAction)focusNear:(id)sender {
  
}
- (IBAction)focusFar:(id)sender {
  
}


- (void)sendPTZWithOpid:(int)opid para1:(int)para1 para2:(int)para2 
{
	//send stop first xinghua 20101126
	//[self stopPTZ];
	
  AsyncUdpSocket * updsocket = [[AsyncUdpSocket alloc] initIPv4];
  [updsocket setDelegate:self];
  NSError * error = nil;

	if (_currentCamera.ptzIP == nil) return;

	
  [updsocket connectToHost:_currentCamera.ptzIP onPort:_currentCamera.ptzPort error:&error];
  if(error != nil) NSLog(@"connect error:%@",error);
  
  NSString * string = [[NSString alloc ] initWithFormat:@"INFO sip:gebroadcast@x SIP/2.0\nContent-Type: application/global_eye_v10+xml\nContent Length: 228\nTo: <sip:gebroadcast@x>\nFrom: <sip:test@y>\nCSeq: 1234 INFO\nCall-ID: 01234567890abcdef\nMax-Forwards: 70\nVia: SIP/2.0/UDP 127.0.0.1;branch=z9hG4bK776asdhds\nContact: <sip:test@y>\r\n<!-- PTZ控制 --><?xml version=\"1.0\" encoding=\"UTF-8\"?><Message Verison=\"1.0\"><IE_HEADER MessageType=\"MSG_PTZ_SET_REQ\" UserID=\"%@\" DestID=\"%@\"/> <IE_PTZ OpId=\"%d\" Param1=\"%d\" Param2=\"%d\"/></Message>",
					   [[NSUserDefaults standardUserDefaults] objectForKey:@"rc_user_name_key"] ,_currentCamera.puid_ChannelNo , opid,para1,para2];
	//NSLog(@"%@", string);
  NSData * data = [[string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] retain];
  //NSLog(@"%@",data);
  if ([updsocket sendData:data withTimeout:50 tag:133]){
    NSLog(@"sent");
  }else {
    NSLog(@"error sent");
  }
  
	[string release];
  [self performSelector:@selector(stopPTZ) withObject:nil afterDelay:0.3];
	[self performSelector:@selector(stopPTZ) withObject:nil afterDelay:0.4];//xinghua 20101213
}

- (void)stopPTZ {
  AsyncUdpSocket * updsocket = [[AsyncUdpSocket alloc] initIPv4];
  [updsocket setDelegate:self];
  NSError * error = nil;
	
	if (_currentCamera.ptzIP == nil) return;

	
  [updsocket connectToHost:/*@"220.248.39.11"*/_currentCamera.ptzIP onPort:_currentCamera.ptzPort error:&error];
  if(error != nil) NSLog(@"connect error:%@",error);
  
  NSString * string = [[NSString alloc ]initWithFormat:@"INFO sip:gebroadcast@x SIP/2.0\nContent-Type: application/global_eye_v10+xml\nContent Length: 228\nTo: <sip:gebroadcast@x>\nFrom: <sip:test@y>\nCSeq: 1234 INFO\nCall-ID: 01234567890abcdef\nMax-Forwards: 70\nVia: SIP/2.0/UDP 127.0.0.1;branch=z9hG4bK776asdhds\nContact: <sip:test@y>\r\n<!-- PTZ控制 --><?xml version=\"1.0\" encoding=\"UTF-8\"?><Message Verison=\"1.0\"><IE_HEADER MessageType=\"MSG_PTZ_SET_REQ\" UserID=\"%@\" DestID=\"%@\"/> <IE_PTZ OpId=\"15\" Param1=\"5\" Param2=\"0\"/></Message>",
						[[NSUserDefaults standardUserDefaults] objectForKey:@"rc_user_name_key"] ,_currentCamera.puid_ChannelNo];
  	//NSLog(@"%@", string);

  NSData * data = [[string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] retain];
  //NSLog(@"%@",data);
  if ([updsocket sendData:data withTimeout:50 tag:133]){
    NSLog(@"sent");
  }else {
    NSLog(@"error sent");
  }
  
	[string release];
	
}

- (IBAction)switchDisplayMode:(id)sender {
  if (videoContextView_.contentMode == UIViewContentModeScaleAspectFit) {
    videoContextView_.contentMode = UIViewContentModeScaleAspectFill;
  } else {
    videoContextView_.contentMode = UIViewContentModeScaleAspectFit;
  }
}

@end

#pragma mark -
#pragma mark c callback methods
static void rtsppe_event_handler(void *caller, int evt,int param1)
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  if (evt == PE_EVENT_VIDEOYUVOUT)
  {
    VIDEOYUV_T *yuv = (VIDEOYUV_T*)param1;
    
    EIPlayViewController *controller = (EIPlayViewController *)caller;
    [controller.videoView SetVideoData:yuv->data Stride:yuv->linesize Width:yuv->width Height:yuv->height];
    
  }
  else {
    int *arg = (int*)malloc(2 * sizeof(int));
    NSLog(@"%@", [NSString stringWithFormat:@"rtsppeevt %d", evt]);
    
    arg[0] = evt;
    arg[1] = param1;
    
    [(NSObject*)caller performSelectorOnMainThread:@selector(_handle_rtsppe_event:) withObject:[NSValue valueWithPointer:arg] waitUntilDone:NO];
    
  }
  [pool release];
}


