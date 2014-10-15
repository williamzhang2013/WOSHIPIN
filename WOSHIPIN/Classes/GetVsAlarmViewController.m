//
//  GetVsAlarmViewController.m
//  VISS_GX
//
//  Created by Li Xinghua on 12-11-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GetVsAlarmViewController.h"
#import "SetVsAlarmViewController.h"

BOOL doVsAlarmRrefresh= NO;



@implementation GetVsAlarmViewController


- (id)initWithCamera:(NSDictionary*)dict
{
    if(self = [super initWithStyle:UITableViewStyleGrouped])
    {
        curCamDict = dict;
        
    }
    return self;
}

-(void)_onSetVsButton:(id)sender
{
    SetVsAlarmViewController *vc = [[SetVsAlarmViewController alloc] initWithCamera:curCamDict];    
    [self.navigationController pushViewController:vc animated:YES];    
    [vc release];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"移动侦测配置";
    doVsAlarmRrefresh = YES;
    
    if ([curCamDict valueForKey:@"SetVsAlarmConfiguration"] || [curCamDict valueForKey:@"hasAllPrivilege"])
    {
        setvsBtn = [[UIBarButtonItem alloc] initWithTitle:@"修改配置" style:UIBarButtonItemStyleBordered target:self action:@selector(_onSetVsButton:)];
        
    }
    else {
        setvsBtn = nil;
    }

}


- (void)dealloc {
    [setvsBtn release];
    
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (doVsAlarmRrefresh == NO)
    {
        return;
    }

    doVsAlarmRrefresh = NO;
	[MCUEngine sharedObj].delegate = self;	
    
    NSLog(@"MCUEngine delegate set to GetVsAlarmViewController");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.prompt = @"正在获取移动侦测配置...";
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = nil;
    
    getVSIng = YES;
    NSDictionary * curVsDict = [[MCUEngine sharedObj] queryVSObj:[curCamDict valueForKey:@"vsId"]];
    
    //first check VS Dictionary
    if ([curVsDict valueForKey:@"getvs"])
    {
        [[MCUEngine sharedObj] getVsAlarmConfiguration:curCamDict];
    }
    else {
        [[MCUEngine sharedObj] entryQueryVSProcess: (NSMutableDictionary *)curCamDict];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (getVSIng)
        return 0;
    else
        return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) 
        return [curCamDict valueForKey:@"name"];
    else if (section == 1)
        return @"告警输出号";
    else if (section == 2)
        return @"录像通道输出号";
    else //if (section == 3)
        return @"告警抓拍通道号";
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
       return 2;
    else if (section == 1) 
    {
        //AlarmOutput
        NSArray * motionDetectionAlarmOutput =  [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionAlarmOutput"];
        int c = [motionDetectionAlarmOutput count];
        return  c== 0 ? 1: c;
    }
    else if (section == 2) 
    {
        //AlarmRecord
        NSArray * motionDetectionAlarmRecord =  [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionAlarmRecord"];
        int c = [motionDetectionAlarmRecord count] ;
        return  c== 0 ? 1: c;
    }
    else //if (section == 3) 
    {
        //AlarmShoot
        NSArray * motionDetectionAlarmShoot =  [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionAlarmShoot"];
        int c= [motionDetectionAlarmShoot count];
        return  c== 0 ? 1: c;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier0 = @"Cell0";
    static NSString *CellIdentifier1 = @"Cell1";
    UITableViewCell *cell;

    if (indexPath.section == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier0];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier0] autorelease];
        }
        if (indexPath.row == 0)
        {
            cell.textLabel.text = @"移动侦测告警";
            
            NSString *enabled =  [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionAlarmEnabled"];
            if ([enabled isEqualToString:@"false"])
                cell.detailTextLabel.text = @"未启用";
            else
                cell.detailTextLabel.text = @"已启用";
        }
        /*else if (indexPath.row == 1)
        {
            cell.textLabel.text = @"频率";
            NSString *freq =  [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionFrequency"];
            cell.detailTextLabel.text = freq;
        }
        else if (indexPath.row == 2)
        {
            cell.textLabel.text = @"敏感度";
            NSString *sensitivity =  [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionSensitivity"];
            cell.detailTextLabel.text = sensitivity;
        }*/
        else if (indexPath.row == 1)
        {
            cell.textLabel.text = @"布防时间";
            NSString *alarmTime =  [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionAlarmTime"];
            cell.detailTextLabel.text = alarmTime;
        }
    }
    else if (indexPath.section == 1)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1] autorelease];
        }

        NSArray * motionDetectionAlarmOutput =  [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionAlarmOutput"];
        if ([motionDetectionAlarmOutput count] == 0)
        {
            cell.textLabel.text = @"未设置";
        }
        else {
            //
            NSDictionary *alarm_dict = [motionDetectionAlarmOutput objectAtIndex:indexPath.row];
            NSString *outputChannelNumber = [alarm_dict valueForKey:@"outputChannelNumber"];
            
            NSNumber * entry_idx = [curCamDict valueForKey:@"portal_entry"];
            NSString *camNam = 
            [[MCUEngine sharedObj] queryCameraName: [entry_idx intValue] withVsId:[curCamDict valueForKey:@"vsId"] withVideoId:outputChannelNumber];
            
            if (camNam)
                cell.textLabel.text = camNam;
            else {
                cell.textLabel.text = outputChannelNumber;
            }
        }

    }
    else if (indexPath.section == 2)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1] autorelease];
        }
        
        NSArray * motionDetectionAlarmRecord =  [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionAlarmRecord"];
        if ([motionDetectionAlarmRecord count] == 0)
        {
            cell.textLabel.text = @"未设置";
        }
        else {
            NSDictionary *alarm_dict = [motionDetectionAlarmRecord objectAtIndex:indexPath.row];
            NSString *channelNumber = [alarm_dict valueForKey:@"channelNumber"];
            
            NSNumber * entry_idx = [curCamDict valueForKey:@"portal_entry"];
            NSString *camNam = 
            [[MCUEngine sharedObj] queryCameraName: [entry_idx intValue] withVsId:[curCamDict valueForKey:@"vsId"] withVideoId:channelNumber];
            
            if (camNam)
                cell.textLabel.text = camNam;
            else {
                cell.textLabel.text = channelNumber;
            }
        }

    }
    else //if (indexPath.section == 3)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1] autorelease];
        }
        
        NSArray * motionDetectionAlarmShoot =  [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionAlarmShoot"];
        if ([motionDetectionAlarmShoot count] == 0)
        {
            cell.textLabel.text = @"未设置";
        }
        else {
            NSDictionary *alarm_dict = [motionDetectionAlarmShoot objectAtIndex:indexPath.row];
            NSString *channelNumber = [alarm_dict valueForKey:@"channelNumber"];
            
            NSNumber * entry_idx = [curCamDict valueForKey:@"portal_entry"];
            NSString *camNam = 
            [[MCUEngine sharedObj] queryCameraName: [entry_idx intValue] withVsId:[curCamDict valueForKey:@"vsId"] withVideoId:channelNumber];
            
            if (camNam)
                cell.textLabel.text = camNam;
            else {
                cell.textLabel.text = channelNumber;
            }
        }
        
    }
        
    cell.userInteractionEnabled = NO;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //do nothing
}

#pragma mark -
#pragma mark MCUEngine delegate
-(void)onLoggingProgressReport: (int) state param:(int) para
{
    if (state == LOG_LOGOUT)
    {
        [[MCUEngine sharedObj] getVsAlarmConfiguration:curCamDict];
    }
    else if (state == LOG_GETVSALARMCONFIGURATION)
    {
        getVSIng = NO;
        self.navigationItem.hidesBackButton = NO;        
        self.navigationItem.prompt = nil;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self.tableView reloadData];
        self.navigationItem.rightBarButtonItem = setvsBtn;
    }
	else if (state == LOG_NETWORK_FAIL)
	{
        getVSIng = NO;
        self.navigationItem.hidesBackButton = NO;        
		self.navigationItem.prompt = [NSString stringWithFormat:@"网络连接错误(%d)", para];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	else if (state == LOG_RESULTCODE_ERROR)
	{ 
        getVSIng = NO;
        self.navigationItem.hidesBackButton = NO;        
        self.navigationItem.prompt = [NSString stringWithFormat:@"服务器返回错误(%d)",  para];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
    
}

@end
