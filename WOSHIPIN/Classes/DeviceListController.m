//
//  DeviceListController.m
//  VISS
//
//  Created by Li Xinghua on 11-4-26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DeviceListController.h"
#import "Camera.h"
#import "EIPlayViewController.h"
#import "AreaListController.h"
#import "DeviceListController.h"
#import "AppDelegate.h"
#import "Common.h"
#import "GetVsAlarmViewController.h"
extern int g_current_active_entry;

@implementation DeviceListController

@synthesize camList;

#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle

/*
- (void)viewDidLoad {
    [super viewDidLoad];
}*/


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [camList count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"CameraCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	
	NSDictionary *dict = [self.camList objectAtIndex:indexPath.row];
	cell.textLabel.text = [dict valueForKey:@"name"];
	
	NSString *typestr = [dict valueForKey:@"type"];
	if ([typestr isEqualToString:@"AREA"])
	{
		cell.imageView.image = [UIImage imageNamed:@"cell_area.png"];
		cell.detailTextLabel.text = nil;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else {
		cell.imageView.image = [UIImage imageNamed:@"cell_camera.png"];
        
        //xinghua 20121029
        if ([dict valueForKey:@"GetVsAlarmConfiguration"] || [dict valueForKey:@"hasAllPrivilege"])
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
		
		NSString *online = [dict valueForKey:@"online"];
		if (online == nil)
			cell.detailTextLabel.text = nil;
		else if ([online isEqualToString:@"true"])
			cell.detailTextLabel.text = nil;
		else
			cell.detailTextLabel.text = @"离线";//offline
	}
	
    return cell;
}



#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    /* for test only
     static int ccc = 0;
    NSDictionary *camdict = [self.camList objectAtIndex:indexPath.row];
 
    if (ccc == 0)
        [[MCUEngine sharedObj] entryQueryVSProcess:(NSMutableDictionary*)camdict];
    else {
        [[MCUEngine sharedObj] getVsAlarmConfiguration:camdict];
    }
    ccc ++;*/
    NSDictionary *camdict = [self.camList objectAtIndex:indexPath.row];
    GetVsAlarmViewController *vc = [[GetVsAlarmViewController alloc] initWithCamera:camdict];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
	NSDictionary *dict = [self.camList objectAtIndex:indexPath.row];
	
	NSString *typestr = [dict valueForKey:@"type"];
	if ([typestr isEqualToString:@"AREA"])
	{
		DeviceListController *devListVC = [[DeviceListController alloc] initWithStyle: UITableViewStyleGrouped];
		devListVC.camList = [[MCUEngine sharedObj]  filterSublistOfEntry: g_current_active_entry withAreaId:[dict valueForKey:@"id"] ];
		
		devListVC.title = [NSString stringWithFormat:@"%@-%@" ,self.navigationItem.title,  
						   [dict valueForKey:@"name"]];
		
		[self.navigationController pushViewController:devListVC animated:YES];
		[devListVC release];
	}
	else
	{
		NSString *online = [dict valueForKey:@"online"];
		if (online == nil || [online isEqualToString:@"true"])
		{
#if 0
		Camera * camera = [[Camera alloc] init];
		camera.ptzIP = /*(NSString*)kIPAddress_VAU*/ [[MCUEngine sharedObj]getVAUIPAddr];
		camera.puName = [dict valueForKey:@"name"];;
		camera.ptzPort = g_ptzPort;
		camera.puid_ChannelNo = [NSString stringWithFormat:@"%@-%@", [dict valueForKey:@"PuId"],[dict valueForKey:@"videoId"] ];
		camera.streamType = g_streamType;
		camera.rtspPort = /*g_rtspPort*/[MCUEngine sharedObj].RtspPort;
		camera.rtspIP = /*(NSString*)kIPAddress_VAU*/[[MCUEngine sharedObj] getVAUIPAddr];
		[camera generateRTSPURL];
#else
        Camera *camera = [[Camera alloc] initWithCAMDict:dict];        
#endif
		
		NSLog(@"rtspURL %@",camera.rtspURL);
		EIPlayViewController *playViewController = [[EIPlayViewController alloc] initControllerWithCamera:camera];
		playViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		[self presentModalViewController:playViewController animated:YES];
		[playViewController release];
		
		[camera release];
		}
	
	}
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	[camList release];
	
    [super dealloc];
}


@end

