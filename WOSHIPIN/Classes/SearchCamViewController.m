//
//  SearchCamViewController.m
//  VISS
//
//  Created by Li Xinghua on 11-5-4.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SearchCamViewController.h"
#import "AppDelegate.h"
#import "EIPlayViewController.h"
#import "Camera.h"
#import "Common.h"


@implementation SearchCamViewController

@synthesize filteredListContent,allCameraList;

- (NSMutableArray *)filteredListContent
{
	if (filteredListContent == nil)
	{
		filteredListContent = [[NSMutableArray alloc] init];
	}
	return filteredListContent;
}
/*
-(NSArray *)getCamList
{
	EeyeAppDelegate *dg = [[UIApplication sharedApplication] delegate];
	return dg.cameraList;
	return nil;
}*/

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"搜索监控设备";
	self.navigationController.title = @"搜索";
	
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	self.allCameraList = [NSMutableArray array];
	
	for (int i=0; i< PORTAL_ENTRY_NUM; i++)
	{
		if (g_wxx_loginDone[i] == NO)
			continue;
	
		[self.allCameraList addObjectsFromArray:[[MCUEngine sharedObj] getCameraList:i]];
	}
	
	[self.tableView reloadData];
}

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

	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		return [self.filteredListContent count];
	}
	else
	{
		return [self.allCameraList count];
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	NSDictionary *dict ;
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		dict = [self.filteredListContent objectAtIndex:indexPath.row];
	}
	else
	{
		dict = [self.allCameraList objectAtIndex:indexPath.row];
	}

	cell.textLabel.text = [dict valueForKey:@"name"];
	
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	NSDictionary *dict = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		dict = [self.filteredListContent objectAtIndex:indexPath.row];
	}
	else
	{
		dict = [self.allCameraList objectAtIndex:indexPath.row];
	}

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
	camera.rtspPort = /*g_rtspPort*/ [MCUEngine sharedObj].RtspPort;
	camera.rtspIP = /*(NSString*)kIPAddress_VAU*/[[MCUEngine sharedObj] getVAUIPAddr];
	[camera generateRTSPURL];
	
	//	NSLog(@"rtspURL %@",camera.rtspURL);
#else
    Camera *camera = [[Camera alloc] initWithCAMDict:dict];        

#endif
	EIPlayViewController *playViewController = [[EIPlayViewController alloc] initControllerWithCamera:camera];
	playViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentModalViewController:playViewController animated:YES];
	[playViewController release];
	
	[camera release];
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
    [super dealloc];
	[filteredListContent release];
	self.allCameraList = nil;
}


#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	[self.filteredListContent removeAllObjects]; // First clear the filtered array.
	

		for (NSDictionary *object in self.allCameraList)
		{
			NSString *name = [object valueForKey:@"name"];
			NSRange r = [name rangeOfString: searchString options:NSCaseInsensitiveSearch];
			
			if (r.location != NSNotFound)
			//if (!NSEqualRanges( NSMakeRange(NSNotFound, 0) , r))
				[self.filteredListContent addObject:object];
		}
	
	// Return YES to cause the search result table view to be reloaded.
	return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
	// Return YES to cause the search result table view to be reloaded.
	return NO;
}



@end

