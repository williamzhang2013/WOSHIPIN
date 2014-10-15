//
//  AreaListController.m
//  VISS
//
//  Created by Li Xinghua on 11-5-4.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AreaListController.h"
#import "DeviceListController.h"
#import "EeyeAppDelegate.h"

@implementation AreaListController

@synthesize areaList,  subareaList;


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


- (void)viewDidLoad {
    [super viewDidLoad];

	self.title = @"沃·视频";
	self.navigationController.title = @"沃·视频";
 
	self.areaList = [NSArray array];//empty
	self.subareaList = [NSArray array];//empty
	
	
}




#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	return [self.areaList count];
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSDictionary *dict  = [self.areaList objectAtIndex:section];
	NSArray *subarea_array = nil;//[dict valueForKey:@"subarea_array"];
	
	NSNumber* i = [dict valueForKey:@"index_subarray"];
	
	if ([i intValue] >= 0)
	{
		subarea_array = [subareaList objectAtIndex:[i intValue]];
	}
	    
	if (subarea_array == nil)
		return 0;
	else
		return [subarea_array count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSDictionary *dict  = [self.areaList objectAtIndex:section];

	return [dict valueForKey:@"name"];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"AreaCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Configure the cell...
	NSDictionary *dict  = [self.areaList objectAtIndex:indexPath.section];
	NSArray *subarea_array = nil; // [dict valueForKey:@"subarea_array"];

	NSNumber* i = [dict valueForKey:@"index_subarray"];
	
	subarea_array = [self.subareaList objectAtIndex:[i intValue]];
	
	NSDictionary *subarea_itemdict = [subarea_array objectAtIndex:indexPath.row];
	
	cell.textLabel.text = [subarea_itemdict valueForKey:@"name"];
	
    return cell;
}



#pragma mark -
#pragma mark Table view delegate

//xinghua 20110723, filter out camera or subarea
-(NSArray *)_filterSubListByAreaId: (NSString *)areaId
{
	NSMutableArray *camArray = [NSMutableArray array];
	
	EeyeAppDelegate *delegate =  [[UIApplication sharedApplication] delegate];
	
	for (NSDictionary *camDict in delegate.cameraList)
	{
		if ( [areaId isEqualToString:(NSString*)[camDict valueForKey:@"currentAreaId"]] || 
			[areaId isEqualToString:(NSString*)[camDict valueForKey:@"areaId"]] )
		{
			[camArray addObject:camDict];
		}
	}
	
	for (NSDictionary *dict in delegate.allAreaList)
	{
		if ([areaId isEqualToString:(NSString*)[dict valueForKey:@"areaId"]] )
		{
			[camArray addObject:dict];
		}
	}
	
	return camArray;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	

	DeviceListController *devListVC = [[DeviceListController alloc] initWithStyle: UITableViewStyleGrouped];
	
	NSDictionary *dict  = [self.areaList objectAtIndex:indexPath.section];
	NSArray *subarea_array = nil; //[dict valueForKey:@"subarea_array"];
	
	NSNumber* i = [dict valueForKey:@"index_subarray"];
	subarea_array = [subareaList objectAtIndex:[i intValue]];
	
	NSDictionary *subarea_itemdict = [subarea_array objectAtIndex:indexPath.row];
	
	devListVC.camList = [self _filterSubListByAreaId:[subarea_itemdict valueForKey:@"id"]];
	devListVC.title = [subarea_itemdict valueForKey:@"name"];
	
	[self.navigationController pushViewController:devListVC animated:YES];
	[devListVC release];
	
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
	[areaList release];
	[subareaList release];
    [super dealloc];
}

/*
-(void) refreshAreaTreeList
{
	[self.tableView reloadData];//refersh tableview
}*/

@end

