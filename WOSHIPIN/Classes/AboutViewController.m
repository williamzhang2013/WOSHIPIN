//
//  AboutViewController.m
//  Eeye
//
//  Created by Li Xinghua on 10-9-13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AboutViewController.h"
#import "SyscfgViewController.h"
//#import "Cfg2ViewController.h"

/*		=====revision history =========
 
 v0.3
	20100914
    - support recorded file playback, seek,pause
	20100916
    - code fix in EIPlayViewController.m (IBOutlet instance release in dealloc)
 v0.4
	20101020
    - support iOS 4 , iTunes file sharing
    - save recording files into Document folder
	- save as .MP4 file
 
 v0.5 
    20101026
    - bug fix for multiple touch (PTZ control) , (EIPlayViewController.m)
    - recorded file rename 
 
 v0.6 
	20101102
	- change recorded MP4 file setting
    - bug fix to support 3G (QVGA)
	- bug fix for PTZ control
 v0.7
    20101124
    - Redefine/implement class Camera
    - bug fix for PTZ control (UDP port)
    20101125
    - keep showing last webpage after live monitoring
    - double tap to toggle display mode in Live PlayingView
 v0.8
	20101203
    - update UI icons and text display
	20101206
    - add sound and picture hint when PTZ control
	- add " quick user guide "
	- add observer UIApplicationWillTerminateNotification
	20101210
	- update icons
    - adjust gaps between control panel icons
 
 v1.0
    20101213 first product release
    - adjust layout of control panel
 
 v1.1
	20101227
	- use own file playback UI instead MPMoviePlayer
	- bug fix for Chinese camera name
 
 -----------Tailored for Guangxi-------------
    20110503
 v0.5 
 
 
 v0.6 20110512
	- change appicon and splash picture
    - remove help button in aboutviewcontroller
	- pe_ctrl.cpp  , change VIDEO_BUFFEROVER_NB 
 
  ---------- 沃看交通 AppStore update submission
 
 v2.0
    - to upgrade from existing v1.1
 
 v2.1
    - remove extra data in setup_codec , to avoid masaic at beginning
    
 xinghua 20110613
    update AppIcons, About Splash, Bundle Display Name (沃视频)
 
 xinghua 20110618
    modify Splash again required by customer
 
 v2.2
	- to support upto 4-layer tree navigation
 
 
 
 v3.0
     -------沃视频
	- 广西联通全新要求 ，多个入口，分账户登录
 
	xinghua 20110914
	- update icons, and entry definitions 
	xinghua 20110915
	- add  hyperlink for 沃看直播 沃看影视
	xinghua 20111011
	- change 
		CMS：121.31.255.6
		VAU:  121.31.255.9
 
	- add CfgViewController
 
	xinghua 20111018
	-Cfg2ViewController
 
 v3.1
	xinghua 20111020 for appstore submission
 
 v3.2
	xinghua 20111105
	- remove default psw for "沃联通 沃交通"
    － bug fix in case of no rootid found
	xinghua 20111222
	- 登录  button
 v3.3
    
 */


#define MAIN_VER	3
#define MINOR_VER	3

const NSString *cuVersion = @"V3.3";

const char *all_month_abbr[12]= {
	"Jan",
	"Feb",
	"Mar",
	"Apr",
	"May",
	"Jun",
	"Jul",
	"Aug",
	"Sep",
	"Oct",
	"Nov",
	"Dec"
};

static int parseDATE(char*date_str, int *year, int *month, int *day)
{
	int i;
	for (i = 0; i<12; i++)
	{
		if (memcmp(date_str,all_month_abbr[i],3) == 0)
		{
			*month = i+1;
			break;
		}
	}
	
	sscanf(&date_str[4],"%d %d", day, year );
	
	return 0;
	
}

@implementation AboutViewController

@synthesize verLabel;
@synthesize buildLabel;
@synthesize contentLabel;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/
/*
-(void)showUserGuide
{
	UICameraWebViewController *helpController = [[UICameraWebViewController alloc] initWithNibName:@"UICameraWebViewController" bundle:nil];
	UINavigationController *navigationCtrl = [[UINavigationController alloc] initWithRootViewController:helpController];
	[helpController release];  
	
	helpController.modalTransitionStyle =  UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:navigationCtrl animated:YES];
	[navigationCtrl release];
	
}
*/


-(void)showCfgView
{
#if 1    
	SyscfgViewController *vc = [[SyscfgViewController alloc] initWithNibName:@"SyscfgViewController" bundle:nil];
	//Cfg2ViewController *vc = [[Cfg2ViewController alloc] initWithStyle:UITableViewStyleGrouped];
	
	/*UINavigationController *navigationCtrl = [[UINavigationController alloc] initWithRootViewController:vc];
	[vc release];
	
	navigationCtrl.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:navigationCtrl animated:YES];
	[navigationCtrl release];*/
	[self.navigationController pushViewController:vc animated:YES];
	[vc release];
#endif
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"关于";
	
	/*
	UIBarButtonItem * helpItem = [[UIBarButtonItem alloc]
								  initWithTitle:@"用户指南" style:UIBarButtonItemStyleBordered target:self action:@selector(showUserGuide)];
	self.navigationItem.rightBarButtonItem = helpItem;
	[helpItem release];
	*/
#if 1
	UIBarButtonItem * cfgItem = [[UIBarButtonItem alloc]
								  initWithTitle:@"配置" style:UIBarButtonItemStyleBordered target:self action:@selector(showCfgView)];
	self.navigationItem.rightBarButtonItem = cfgItem;
	[cfgItem release];
#endif
	
	
	//self.verLabel.text = [NSString stringWithFormat:@"版本: %d.%d ", MAIN_VER, MINOR_VER];
    NSDictionary *infoDict =[[NSBundle mainBundle] infoDictionary];
    NSString     *versionNum =[infoDict objectForKey:@"CFBundleShortVersionString"];
    //NSString     *build = [infoDict objectForKey:@"CFBundleVersion"];
    self.verLabel.text = [NSString stringWithFormat:@"版本: %@", versionNum];
	

	int y,m, d;
	parseDATE(__DATE__, &y, &m, &d);
	self.buildLabel.text = [NSString stringWithFormat:@"发布: %d-%02d-%02d %s", y,m,d, __TIME__];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

//- (void)viewDidUnload {
//    [self setContentLabel:nil];
//    [super viewDidUnload];
//    // Release any retained subviews of the main view.
//    // e.g. self.myOutlet = nil;
//	self.verLabel = nil;
//	self.buildLabel = nil;
//}


- (void)dealloc {
    [super dealloc];
    
    [contentLabel release];	
	[verLabel release];
	[buildLabel release];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}
#endif
- (BOOL)shouldAutorotate
{
    return YES;
}

@end
