//
//  AreaGroupViewController.m
//  VISS_gx3
//
//  Created by Li Xinghua on 11-8-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AreaGroupViewController.h"
#import "Common.h"
#import "DeviceListController.h"
#import "Camera.h"
#import "EIPlayViewController.h"
#import "GetVsAlarmViewController.h"

extern int g_current_active_entry;

@implementation AreaGroupViewController
@synthesize mainAreaList;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	
	
	//mainAreaList must be assigned outside by caller
	//create subDevicesList for each main area
	
	subDevicesList = [NSMutableArray array];
	[subDevicesList retain];
	
	for (NSDictionary *areaDict in mainAreaList)
	{
		NSArray *devList = [[MCUEngine sharedObj] filterSublistOfEntry:g_current_active_entry withAreaId:[areaDict valueForKey:@"id"]];
		//NSLog(@"devList %@",devList);
		
		[subDevicesList addObject:devList];
	}
	
	//NSLog(@"subDeviceList %@ ", subDevicesList);
}


#pragma mark -
#pragma mark Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSDictionary *dict = [mainAreaList objectAtIndex:section];
	return [dict valueForKey:@"name"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [mainAreaList count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	NSArray * devList = [subDevicesList objectAtIndex:section];
    return [devList count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
  	NSArray * devList = [subDevicesList objectAtIndex:indexPath.section];
	NSDictionary *dict = [devList objectAtIndex:indexPath.row];

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
        if ([dict valueForKey:@"GetVsAlarmConfiguration"]) {
#ifdef SUPPORT_CAM_DETAIL_INFO
            if ([MCUEngine isCurrentSystemOSVersionAbove70]) {
                cell.accessoryType = UITableViewCellAccessoryDetailButton;
            } else {
                cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            }
#else
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
#endif
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
		
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
  	NSArray * devList = [subDevicesList objectAtIndex:indexPath.section];    
    NSDictionary *camdict = [devList objectAtIndex:indexPath.row];
    GetVsAlarmViewController *vc = [[GetVsAlarmViewController alloc] initWithCamera:camdict];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSArray * devList = [subDevicesList objectAtIndex:indexPath.section];
	NSDictionary *dict = [devList objectAtIndex:indexPath.row];
	
	NSString *typestr = [dict valueForKey:@"type"];
	if ([typestr isEqualToString:@"AREA"])
	{
		DeviceListController * listVC = [[DeviceListController alloc] initWithStyle:UITableViewStyleGrouped];
		listVC.title = [dict valueForKey:@"name"];
		listVC.camList = [[MCUEngine sharedObj] filterSublistOfEntry:g_current_active_entry withAreaId:[dict valueForKey:@"id"]];
		[self.navigationController pushViewController:listVC animated:YES];
		[listVC release];
	}
	else //camera
	{
		NSString *online = [dict valueForKey:@"online"];
		if (online == nil || [online isEqualToString:@"true"])
		{
#if 0
		Camera * camera = [[Camera alloc] init];
		camera.ptzIP = /*(NSString*)kIPAddress_VAU*/[[MCUEngine sharedObj] getVAUIPAddr];
		camera.puName = [dict valueForKey:@"name"];;
		camera.ptzPort = g_ptzPort;
		camera.puid_ChannelNo = [NSString stringWithFormat:@"%@-%@", [dict valueForKey:@"PuId"],[dict valueForKey:@"videoId"] ];
		camera.streamType = g_streamType;
		camera.rtspPort = /*g_rtspPort*/[MCUEngine sharedObj].RtspPort;
		camera.rtspIP = /*(NSString*)kIPAddress_VAU*/[[MCUEngine sharedObj] getVAUIPAddr];
		[camera generateRTSPURL];
#else
        Camera *camera = [[Camera alloc] initWithCAMDict:dict];        

		NSLog(@"rtspURL %@",camera.rtspURL);
#endif	
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
	//[subDevicesList removeAllObjects];
	[subDevicesList release];
	self.mainAreaList = nil;
    [super dealloc];
}


@end

