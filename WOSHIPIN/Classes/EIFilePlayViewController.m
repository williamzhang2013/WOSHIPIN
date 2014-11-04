//
//  EIFilePlayViewController.m
//  Eeye
//
//  Created by Li Xinghua on 10-8-31.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EIFilePlayViewController.h"
#import "FileAttribute.h"
#import "VideoView.h"
#import "Common.h"

@implementation EIFilePlayViewController
@synthesize videoView;


#pragma mark priviate methods

-(void)onEndoffile:(id)arg
{
	[self OnCloseFile: nil];
}

#pragma mark -
#pragma mark c callback methods
static void pf_event_handler(void *caller, int evt,int param1)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	EIFilePlayViewController *controller = (EIFilePlayViewController *)caller;
	
	if (evt == PE_EVENT_VIDEOYUVOUT)
	{
		VIDEOYUV_T *yuv = (VIDEOYUV_T*)param1;

		
		[[controller videoView] SetVideoData:yuv->data Stride:yuv->linesize Width:yuv->width Height:yuv->height];
		
	}
	else if (evt == PE_EVENT_PLAYFILE)
	{
		if (param1 == PF_ENDOFFILE )
		{
			/*IMPORTANT NOTE: caller must call PF_Close() to do cleanup in case end-of-file*/
			printf("--end_of_file--\n");

			[(NSObject*)caller performSelectorOnMainThread:@selector(onEndoffile:) withObject:nil waitUntilDone:NO];

		}

	}
	
	
	[pool release];
}	


#pragma mark Initialize

- (id)initWithFilePath:(NSString *)path
{
	if (self = [super initWithNibName:@"EIFilePlayViewController" bundle:nil]) {
		self.wantsFullScreenLayout = YES;
		file_path = [path copy];
	}
	return self;	
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/
-(void) _onUpdatePlaytimeMethod:(NSTimer*)timer
{
	
	if (userseekflag==0 && pf_handle && totallen > 0)
	{
		curpos = PF_GetPosition(pf_handle);
		[progressSlider setValue: (curpos*50/totallen) animated:YES];
		playtimeLabel.text = [NSString stringWithFormat:@"%02d:%02d/%02d:%02d", curpos/60, curpos % 60,totallen/60,totallen%60 ];
	}
	
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	messageViewsShown = true;
	playOrpause = true;
	cancelViewhide = false;
	tapMode = true;
	userseekflag = 0;

	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	[UIApplication sharedApplication].idleTimerDisabled = YES;//xinghua 20101026

	
	UINavigationItem *navItem = _navBar.topItem;
	FileAttribute *fa = [[FileAttribute alloc] initWithFullFilePath:file_path];
	
	navItem.title = fa.cameraName;//[file_path lastPathComponent];
	[fa release];
	
	//[UIApplication sharedApplication].statusBarHidden = YES;
	//auto play the file
	pf_handle = PF_Open([file_path UTF8String],pf_event_handler,(void*)self);
	PF_Play(pf_handle);
		
	curpos = 0;
	totallen = PF_GetDuration(pf_handle);
	[progressSlider setMaximumValue:50]; ///////
	[progressSlider setMinimumValue:0];
	
	playtimeLabel.text = [NSString stringWithFormat:@"00:00/%02d:%02d", totallen/60,totallen%60 ];

	[self adjustLayout:self.interfaceOrientation];
	atimer = [NSTimer scheduledTimerWithTimeInterval:1. target:self selector:@selector(_onUpdatePlaytimeMethod:) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:animated];
	
	[UIApplication sharedApplication].idleTimerDisabled = NO;//xinghua 20101026

	//Restore status bar status //xinghua 20101020
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
	[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
	[[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];
}


- (void)_onpresentOrHideMessageViewsAnimated:(NSTimer*)timer{
	//cancelViewhide = false;
	[self _presentOrHideMessageViewsAnimated:YES];
	tapMode = true;
}



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	//[self _presentOrHideMessageViewsAnimated:YES];
	if (tapMode) {
		touchBeginDate = [NSDate date];
		OnetapTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 
													   target:self 
													 selector:@selector(_onpresentOrHideMessageViewsAnimated:) 
													 userInfo:nil repeats:NO];
		//cancelViewhide = true;
	}
	else {
		[OnetapTimer invalidate];
		if (((UIView *)videoView).contentMode == UIViewContentModeScaleAspectFit) {
			((UIView *)videoView).contentMode = UIViewContentModeScaleAspectFill;
		} else {
			((UIView *)videoView).contentMode = UIViewContentModeScaleAspectFit;
		}
	}
	tapMode = !tapMode;
}



- (void)_presentOrHideMessageViewsAnimated:(BOOL)animated{
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:.4];
		[UIView setAnimationDelay:.05];
	}
	
	//If message views are shown, fade them out
	if (messageViewsShown) {
		[[UIApplication sharedApplication] setStatusBarHidden:YES animated:animated];
		_navBar.alpha = 0;
		
		progressSlider.alpha = 0;
		playtimeLabel.alpha = 0;
	}
	//if not, show them in
	else {
		[[UIApplication sharedApplication] setStatusBarHidden:NO animated:animated];
		_navBar.alpha = 1;
		
		progressSlider.alpha = 1;
		playtimeLabel.alpha = 1;
	}
	
	messageViewsShown = !messageViewsShown;
	
	if (animated) {
		[UIView commitAnimations];
	}
}

- (void)adjustLayout:(UIInterfaceOrientation)interfaceOrientation
{
	switch (interfaceOrientation) {
		case UIInterfaceOrientationPortrait:
        {
            //[progressSlider setFrame:CGRectMake(10, 400, 300, 22)];
            progressSlider.frame = CGRectMake(10, 400, SCREEN_WIDTH-20, 22);
            [playtimeLabel setFrame:CGRectMake(20, 430, 121, 21)];
            //[videoView setFrame:CGRectMake(0, 120, 320, 240)];
            videoView.bounds = CGRectMake(0, 120, SCREEN_WIDTH, SCREEN_HEIGHT/2);
            videoView.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2);
        }
			break;
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight:
        {
            //[progressSlider setFrame:CGRectMake(10, 295, 460, 22)];
            progressSlider.frame = CGRectMake(10, 295, SCREEN_HEIGHT-20, 22);
            [playtimeLabel setFrame:CGRectMake(20, 270, 121, 21)];
            //[videoView setCenter:CGPointMake(240, 160)];
            //[videoView setBounds:CGRectMake(0, 0, 480, 320)];
            videoView.center = CGPointMake(SCREEN_HEIGHT/2, SCREEN_WIDTH/2);
            videoView.bounds = CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
        }
			break;
		default:
			break;
	}
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait ||
			interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
			interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
                                         duration:(NSTimeInterval)duration {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	//[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:duration];
	[[UIApplication sharedApplication] setStatusBarOrientation:interfaceOrientation];
	
    [self adjustLayout:interfaceOrientation];

	[UIView commitAnimations];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	[atimer invalidate];
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];

}


- (void)dealloc {
    [super dealloc];	
	[videoView release];
	[playtimeLabel release];
	[progressSlider release];
	[_navBar release];
	
	[file_path release];

}

#pragma mark Actions

- (IBAction)OnOpenFile:(id)sender
{
	if (pf_handle == NULL)
	pf_handle = PF_Open([file_path UTF8String],pf_event_handler,(void*)self);
}
- (IBAction)OnPlayFile:(id)sender
{
	if (pf_handle)
	PF_Play(pf_handle);
}

- (IBAction)OnPauseFile:(id)sender
{
	if (pf_handle)
	PF_Pause(pf_handle);
}

// Add Func
- (IBAction)OnPlayPauseFile:(id)sender
{
	playOrpause = !playOrpause;
	UINavigationItem *navItem = _navBar.topItem;
	if (playOrpause) {
		// Switch from Pause to Play
		//navItem.title = @"Playing...";
		UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] 
											  //initWithBarButtonSystemItem:UIBarButtonSystemItemPause
											   initWithTitle:@"返回" style:UIBarButtonItemStyleDone
											  target:self
											  action:@selector(OnPlayPauseFile:)];
		navItem.rightBarButtonItem = rightBarButtonItem;
		[self OnPlayFile:sender];
	}
	else {
		//navItem.title = @"Pause";
		//navItem.rightBarButtonItem.style = UIBarButtonSystemItemPause;
		UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] 
											   initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
											   target:self
											   action:@selector(OnPlayPauseFile:)];
		navItem.rightBarButtonItem = rightBarButtonItem;
		// Switch from Play to Pause
		[self OnPauseFile:sender];
	}
}


- (IBAction)OnCloseFile:(id)sender
{
	
	if (pf_handle)
	{
	PF_Close(pf_handle);
	pf_handle = NULL;
	}
	 [self dismissModalViewControllerAnimated:YES];
}

- (void)_checkSeekTimerMethod:(NSTimer*)timer{

	if (pf_handle == NULL)
		return;
	
	if(PF_GetSeekStatus(pf_handle) == 0)
	{
		int play_pos = PF_GetPosition(pf_handle);
		int slider_pos = progressSlider.value *totallen/ 50;
		if (abs(play_pos - slider_pos) < 5 || userseekflag == 0)
		{
			userseekflag = 0;
			[timer invalidate];
			[atimer fire];
		}
		else
			userseekflag -- ;
	}
}
- (void)_onUserSeekTimerMethod:(NSTimer*)timer{
	
	if (pf_handle == NULL)
		return;
	
	NSLog(@"seek progress");
	int target_pos = progressSlider.value *totallen/ 50;
	int cur_pos = PF_GetPosition(pf_handle);
	if (abs(target_pos - cur_pos) > 5)
	{
		PF_Seek2(pf_handle, target_pos);
	}

	//delay some time to check Seek Result
	userseekflag = 8;
	[NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(_checkSeekTimerMethod:) userInfo:nil repeats:YES];

}


//In Response to Value change of Sliderbar. We need to distinguish "User Move" and "Timer update" 
- (IBAction)OnUserSeekProgress:(id)sender
{
	
	//NSLog(@"seek progress");
	int slider_pos = progressSlider.value *totallen/ 50;
	if (abs(slider_pos - curpos) < 5)
	{
		return;
	}
	 
	
	if (userseekflag == 1)//userSeek Timer is still active
	{
		[UserSeekTimer invalidate];
		UserSeekTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_onUserSeekTimerMethod:) userInfo:nil repeats:NO];
	}
	else if (userseekflag == 0)
	{
		userseekflag = 1;
		UserSeekTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_onUserSeekTimerMethod:) userInfo:nil repeats:NO];
	}
}



@end
