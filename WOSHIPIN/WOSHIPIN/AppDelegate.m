//
//  AppDelegate.m
//  WOSHIPIN
//
//  Created by Li Xinghua on 12-11-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "EIPlayViewController.h"
#import "EILocalFileListViewController.h"
#import "RecordingCenter.h"


#import "AboutViewController.h"
#import "DeviceListController.h"
#import "SearchCamViewController.h"
#import "EntryListViewController.h"


@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
	[[MCUEngine sharedObj] load];
    
    
	NSMutableArray *tabBarViewControllers = [NSMutableArray array];
    
	{
		EntryListViewController * entryListVC = [[EntryListViewController alloc] initWithStyle:UITableViewStyleGrouped];
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:entryListVC];
		UIImage *areaImage = [UIImage imageNamed:@"tab_surveill_pressed.png"];
		UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:areaImage tag:0];
		
		navController.tabBarItem = tabBarItem;
		[tabBarItem release];
		
		navController.title = @"沃·视频";
		[tabBarViewControllers addObject:navController];  
		[entryListVC release];
		[navController release];
		
	}
    
	/*{
     AreaListController * areaListVC = [[AreaListController alloc] initWithStyle:UITableViewStylePlain];
     UINavigationController *areaNavController = [[UINavigationController alloc] initWithRootViewController:areaListVC];
     UIImage *areaImage = [UIImage imageNamed:@"tab_surveill_pressed.png"];
     UITabBarItem *areaNavTabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:areaImage tag:0];
     
     areaNavController.tabBarItem = areaNavTabBarItem;
     [areaNavTabBarItem release];
     
     areaNavController.title = @"沃·视频";
     [tabBarViewControllers addObject:areaNavController];  
     [areaListVC release];
     [areaNavController release];
     
     }*/
	
	{//camera device search
		
		SearchCamViewController *searchCamVC = [[SearchCamViewController alloc] initWithNibName:@"SearchCamViewController" bundle:nil];		
		
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:searchCamVC];
		
		UIImage * searchImage = [UIImage imageNamed:@"tab_searchcam.png"];//TODO
		
		UITabBarItem * searchNavTabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:searchImage tag:0];
		
		navigationController.tabBarItem = searchNavTabBarItem;
		navigationController.title = @"搜索";
		[searchImage release];
		[searchNavTabBarItem release];
		
		
		[searchCamVC release];
		[tabBarViewControllers addObject:navigationController];
		[navigationController release];
	}
	
	
    //Local recording file list view controller
	{
		EILocalFileListViewController *localFileListViewController = [[EILocalFileListViewController alloc] initWithNibName:@"EILocalFileListViewController" bundle:nil];
		[localFileListViewController setArrayToDisplay:[RecordingCenter recordingFiles]];
        
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:localFileListViewController];
        
		UIImage * settingImage = [[UIImage alloc] initWithContentsOfFile:
                                  [[NSBundle mainBundle] pathForResource:@"tab_record_pressed" ofType:@"png"]];
        
		UITabBarItem * settingNavTabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:settingImage tag:0];
        
		//navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bk.png"]];
		navigationController.tabBarItem = settingNavTabBarItem;
		navigationController.title = @"录像";
		[settingImage release];
		[settingNavTabBarItem release];
        
        
		[localFileListViewController release];
		[tabBarViewControllers addObject:navigationController];
		[navigationController release];
	}
    
    
	
    {
        UIViewController * aboutVC;
		aboutVC = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
		UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:aboutVC];
		
        
        UIImage * settingImage = [[UIImage alloc] initWithContentsOfFile:
                                  [[NSBundle mainBundle] pathForResource:@"tab_about_pressed" ofType:@"png"]];
        
        UITabBarItem * aboutTabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:settingImage tag:0];
        
        //aboutVC.tabBarItem = aboutTabBarItem;
        //aboutVC.title = @"关于";
		navController.tabBarItem = aboutTabBarItem;
		navController.title = @"关于";
		
        [settingImage release];
        [aboutTabBarItem release];
        
        
        [tabBarViewControllers addObject:/*aboutVC*/navController];
        [aboutVC release];
		[navController release];
        
    }
    
	_tabBarController = [[UITabBarController alloc] init];
	_tabBarController.viewControllers = tabBarViewControllers;
    
    if ([UIWindow instancesRespondToSelector:@selector(rootViewController)])
        _window.rootViewController = _tabBarController;   
    
	[_window addSubview:_tabBarController.view];
	[_window makeKeyAndVisible];
    return YES;
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    [[MCUEngine sharedObj] unload];
	[[MCUEngine sharedObj] release];

}

@end
