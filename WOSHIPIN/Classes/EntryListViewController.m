//
//  EntryListViewController.m
//  VISS_gx3
//
//  Created by Li Xinghua on 11-8-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EntryListViewController.h"
#import "common.h"
#import "AreaGroupViewController.h"
#import "UserPswViewController.h"


int g_current_active_entry ;
const NSString *wojiaotong_url = @"http://jt.gx10010.com";
const NSString *wozibo_url = @"http://live.gx10010.com";
const NSString *woyinshi_url = @"http://tv.gx10010.com/demo.jsp";

extern int login_reason;

@implementation EntryListViewController
@synthesize loggingStatus;

-(int)fromCellRow2EntryIndex:(int) row
{
	/*
	int current_entry;
	if (row == 0 || row == 1)
		current_entry = 0;
	else if (row == 2)
		current_entry = 1;
	else if (row == 3)
		current_entry = 2;
	
	return current_entry*/
	
	return row;
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

 
	self.title = @"沃视频";
	self.navigationController.title = @"沃视频";
	
	entryList = [[NSArray alloc] initWithObjects:@"沃看联通", @"沃看企业", @"沃看交通", @"沃看直播", @"沃看影视",nil ];
	filterKeyList = [[NSArray alloc] initWithObjects:@"联通", @"企业", @"交通", @"", @"", nil];//@"营业厅",
	entryImageList = [[NSArray alloc] initWithObjects:@"wo_lt.png", @"wo_qy.png",  @"wo_jt.png", @"wo_zb.png", @"wo_ys.png",nil];
	
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
	[MCUEngine sharedObj].delegate = self;	
    NSLog(@"MCUEngine delegate set to EntryListViewController");
}

- (void)pushNextViewController
{
	AreaGroupViewController * listVC = [[AreaGroupViewController alloc] initWithStyle:UITableViewStyleGrouped];
	listVC.title = [entryList objectAtIndex:selCellRow];
	NSString *rootId = [[MCUEngine sharedObj] findRootIdOfEntry: g_current_active_entry 
													  entry_key:[filterKeyList objectAtIndex:selCellRow ]];
	
	listVC.mainAreaList = [[MCUEngine sharedObj] filterArealistOfEntry:g_current_active_entry
														withAreaId: rootId];
	[self.navigationController pushViewController:listVC animated:YES];
	[listVC release];
	
}

#pragma mark -
#pragma mark Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 64;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [entryList count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
	
	NSString *imgfilename = [entryImageList objectAtIndex:indexPath.row];
	
	cell.imageView.image = [UIImage imageNamed:imgfilename];
    cell.textLabel.font = [UIFont boldSystemFontOfSize: 24];
    cell.textLabel.text = [entryList objectAtIndex:indexPath.row];
    
    if (indexPath.row == 2) {
        cell.accessoryView = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.detailTextLabel.text = wojiaotong_url;
		return cell;
    }else if (indexPath.row == 3 ) {
		cell.accessoryView = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.detailTextLabel.text = wozibo_url;
		return cell;
	} else if (indexPath.row == 4 ) {
		cell.accessoryView = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.detailTextLabel.text = woyinshi_url;
		return cell;		
	}
    if ([MCUEngine isCurrentSystemOSVersionAbove70]) {
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
	//custom view of "log button"
#if  0

	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	button.frame = CGRectMake(0.0, 0.0, 60, 36);
	[button setTitle:@"登录" forState:UIControlStateNormal];
	button.titleLabel.textColor = [UIColor blueColor];
	button.tag = indexPath.row;
	// set the button's target to this table view controller so we can interpret touch events and map that to a NSIndexSet
	[button addTarget:self action:@selector(checkButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
	button.backgroundColor = [UIColor clearColor];
	cell.accessoryView = button;

#endif
	
	int entry = [self fromCellRow2EntryIndex:indexPath.row];
	if (g_wxx_loginDone[entry])
		cell.detailTextLabel.text = @"已登录";

	else {
		if (selCellRow == indexPath.row && logging)
		{
			cell.detailTextLabel.text = self.loggingStatus;
		}
		else {
			cell.detailTextLabel.text = nil;
		}

	}
    
    return cell;
}



#pragma mark -
#pragma mark Table view delegate

- (void)checkButtonTapped:(id)sender event:(id)event
{
    NSLog(@"Button Tapped");
	if (logging) return;
	
	selCellRow= ((UIButton *)sender).tag;
	g_current_active_entry = [self fromCellRow2EntryIndex:selCellRow];
	
	UserPswViewController *vc = [[UserPswViewController alloc] initWithNibName:@"UserPswLogin" bundle:nil];
	vc.title = [entryList objectAtIndex:selCellRow];
	[self.navigationController pushViewController:vc animated:YES];
	[vc release];
}



- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
	if (logging) return;
	g_current_active_entry = [self fromCellRow2EntryIndex:indexPath.row];
	selCellRow = indexPath.row;
	
	UserPswViewController *vc = [[UserPswViewController alloc] initWithNibName:@"UserPswLogin" bundle:nil];
	vc.title = [entryList objectAtIndex:selCellRow];
	[self.navigationController pushViewController:vc animated:YES];
	[vc release];
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2 )
	{
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:wojiaotong_url]];
		
		return;
	}
	
	if (indexPath.row == 3 )
	{
		[tableView deselectRowAtIndexPath:indexPath animated:YES];	
		
		/*if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:wozibo_url]] == NO)
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
															message:@"无法打开此URL"
														   delegate:self
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			
			[alert show];
			[alert release];
		}
		else*/
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:wozibo_url]];
        //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:wojiaotong_url]];
		
		return;
	}
	if (indexPath.row == 4 )
	{
		[tableView deselectRowAtIndexPath:indexPath animated:YES];	
		/*if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:woyinshi_url]] == NO)
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
															message:@"无法打开此URL"
														   delegate:self
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			
			[alert show];
			[alert release];
		}
		else*/
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:woyinshi_url]];
		
		return;
	}
	
	if (logging) //during logging progress
	{
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		return;
	}

	g_current_active_entry = [self fromCellRow2EntryIndex:indexPath.row];
	selCellRow = indexPath.row;
	
	//if ([[MCUEngine sharedObj] isEntryDataReady:g_current_active_entry] )
	if (g_wxx_loginDone[g_current_active_entry])
	{
		[self pushNextViewController];
	}
	else //log in now
	{
		
		//check user name or password is empty ?
		NSString *user, *password;
		user = [MCUEngine getLoginUserName:g_current_active_entry] ;
		if (user == nil)
			user = @"";
		password = [MCUEngine getLoginPassword:g_current_active_entry];
		if (password == nil)
			password = @"";
		if ( ![MCUEngine getLoginAccountSaved:g_current_active_entry] || 
			[user isEqualToString: @""] || [password isEqualToString: @""])
		{
			//enter user/password view
			
			UserPswViewController *vc = [[UserPswViewController alloc] initWithNibName:@"UserPswLogin" bundle:nil];
			vc.title = [NSString stringWithFormat:@"登录 %@",[entryList objectAtIndex:selCellRow]];
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
		}
		else
			[[MCUEngine sharedObj] entryLogin:g_current_active_entry UserName:user Psw:password];
		
	}
	//[tableView deselectRowAtIndexPath:indexPath animated:YES];
}
#pragma mark -
#pragma mark MCUEngine delegate
-(void)onLoggingProgressReport: (int) state param:(int) para
{
	if (login_reason != 0) return;

	NSString *str = nil;
	
	if (state == LOG_LOGIN)
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		self.navigationItem.prompt = nil;
		
		self.loggingStatus = @"帐户登录...";
		logging = YES;
	}
	else if (state == LOG_REQUESTDATA)
	{
		self.loggingStatus = @"获取监控点数据...";
		logging = YES;
	}
	else if (state == LOG_LOGOUT)
	{
		str = nil;
		logging = NO;
	}
	else if (state == LOG_NETWORK_FAIL)
	{
		self.navigationItem.prompt = [NSString stringWithFormat:@"网络连接错误(%d)", para];
		logging = NO;
	}
	else if (state == LOG_RESULTCODE_ERROR)
	{ 
		if (para == 21)
			self.navigationItem.prompt = [NSString stringWithFormat:@"%@ 用户名或密码错误", [entryList objectAtIndex:selCellRow]];
		else
			self.navigationItem.prompt = [NSString stringWithFormat:@"%@ 服务器返回错误(%d)", [entryList objectAtIndex:selCellRow], para];
		logging = NO;
	}
    else if (state == LOG_GETUSER)
    {
        self.loggingStatus = @"获取用户信息...";
		logging = YES;
    }
    else if (state == LOG_GETROLE)
    {
        self.loggingStatus =  @"获取用户权限";
        logging = YES;
    }
    else if (state == LOG_GETVAU)
    {
        logging = YES;
    }
    else if (state == LOG_GETVS)
    {
        logging = YES;
    }
	
	[self.tableView reloadData];
	
	/*if (logging == NO)
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		if (g_wxx_loginDone[g_current_active_entry])
		{
			[self pushNextViewController];
		}
	}*/
    //xinghua 20121015
    if (state == LOG_LOGOUT)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self pushNextViewController];
    }
	
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
	self.loggingStatus = nil;
	
	[entryList release];
	[filterKeyList release];
	[entryImageList release];
    [super dealloc];
}


@end

