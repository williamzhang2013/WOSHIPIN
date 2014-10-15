//
//  SetVsAlarmViewController.m
//  VISS_GX
//
//  Created by Li Xinghua on 12-11-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SetVsAlarmViewController.h"
#import "AlarmTimeCfgViewController.h"
#import "AlarmXXXViewController.h"

extern BOOL doVsAlarmRrefresh;

static unsigned char fromStr2Int(const char * s)
{
    return (s[0]-'0')*10 + (s[1]-'0'); 
}

static void fromInt2Str(unsigned char i,  char *s)
{
    s[0] = i/10 + '0';
    s[1] = (i%10) + '0';
}


@implementation SetVsAlarmViewController


- (id)initWithCamera:(NSDictionary*)dict
{
    if(self = [super initWithStyle:UITableViewStyleGrouped])
    {
        curCamDict = dict;
    }
    return self;
}


-(void)_onApplyButton:(id)sender
{
    //validate start_time end_time 
    if (alarmtime_i[0] * 60 + alarmtime_i[1] > alarmtime_i[2] * 60 + alarmtime_i[3])
    {
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"错误", @"") 
                                                             message:NSLocalizedString(@"布防设置起始时间不能大于结束时间!", @"")
                                                            delegate:nil 
                                                   cancelButtonTitle:NSLocalizedString(@"OK" , @"")
                                                   otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        return;
    }
    
    
    NSString * videoId = [curCamDict valueForKey:@"videoId"];
    NSString *setVScmds = [NSString stringWithFormat:@"motionDetectionAlarmEnabled=%@,%@&motionDetectionAlarmTime=%@,%02d%02d-%02d%02d", videoId , switchCtl.on?@"true":@"false",videoId,  alarmtime_i[0],alarmtime_i[1],alarmtime_i[2],alarmtime_i[3]];
    
    
    
    for (NSDictionary *dict in mdAlarmOutputCfg)
    {
        if ([dict valueForKey:@"AlarmOutput"])
        {
            NSString * channelNumber = [dict valueForKey:@"channelNumber"];
            NSString * normalState = [dict valueForKey:@"normalState"];
            int alarmState = 1- normalState.intValue;
            
            setVScmds = [setVScmds stringByAppendingFormat:@"&motionDetectionAlarmOutput=%@,%@,%d",videoId, channelNumber, alarmState];
        }
    }
    
    for (NSDictionary *dict in mdAlarmRecordShootCfg)
    {
        if ([dict valueForKey:@"AlarmRecord"])
        {
            NSString * channelNumber = [dict valueForKey:@"channelNumber"];
            setVScmds = [setVScmds stringByAppendingFormat:@"&motionDetectionAlarmRecord=%@,%@",videoId, channelNumber];
        }
    }
    
    for (NSDictionary *dict in mdAlarmRecordShootCfg)
    {
        if ([dict valueForKey:@"AlarmShoot"])
        {
            NSString * channelNumber = [dict valueForKey:@"channelNumber"];
            setVScmds = [setVScmds stringByAppendingFormat:@"&motionDetectionAlarmShoot=%@,%@",videoId, channelNumber];
        }
    }
    [[MCUEngine sharedObj] setVsAlarmConfiguration:curCamDict config:setVScmds];
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.prompt = @"正在改变移动侦测配置...";
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
    self.tableView.userInteractionEnabled = NO;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"修改配置";
	[MCUEngine sharedObj].delegate = self;	
    
    applyBtn = [[UIBarButtonItem alloc] initWithTitle:@"应用" style:UIBarButtonItemStyleBordered target:self action:@selector(_onApplyButton:)];

	switchCtl = [[UISwitch alloc] initWithFrame:CGRectMake(198.0, 8.0, 94.0, 28.0)];
    //vsalarm_config_copy = [[MCUEngine sharedObj].camera_alarm_configuration copy];

    self.navigationItem.rightBarButtonItem = applyBtn;
    
    NSString *enabled =  [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionAlarmEnabled"];
    if ([enabled isEqualToString:@"false"])
        switchCtl.on = NO; 
    else
        switchCtl.on = YES;    
    
    
    NSString * alarmTime = [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionAlarmTime"];
    
    const char *alarmtime_cstr = [alarmTime UTF8String];
    alarmtime_i[0] = fromStr2Int(&alarmtime_cstr[0]);
    alarmtime_i[1] = fromStr2Int(&alarmtime_cstr[2]);
    alarmtime_i[2] = fromStr2Int(&alarmtime_cstr[5]);
    alarmtime_i[3] = fromStr2Int(&alarmtime_cstr[7]);

    //find out all available items for AlarmOutput
    NSDictionary *vsDict = [[MCUEngine sharedObj] queryVSObj:[curCamDict valueForKey:@"vsId"]];
    mdAlarmOutputCfg = [vsDict valueForKey:@"gpio_out_array"];
    NSArray * cur_alarmoutput = [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionAlarmOutput"];
    
    for (NSMutableDictionary *dict in mdAlarmOutputCfg)
    {
        for (NSDictionary *dict2 in cur_alarmoutput)
        {
            if ([[dict valueForKey:@"channelNumber"] isEqualToString:[dict2 valueForKey:@"outputChannelNumber"]])
            {
                [dict setValue:@"1" forKey:@"AlarmOutput"];
                break;
            }
        }
    }
    [mdAlarmOutputCfg retain];
    ///////then for AlarmRecord/Shoot ////////////////////
    NSArray * cur_alarmrecord = [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionAlarmRecord"];
    NSArray * cur_alarmshoot = [[MCUEngine sharedObj].camera_alarm_configuration valueForKey:@"motionDetectionAlarmShoot"];
    
    NSNumber *portal_entry = [curCamDict valueForKey:@"portal_entry"];
    NSArray *allCams = [[MCUEngine sharedObj] filterCameras:[portal_entry intValue] byVsId:[curCamDict valueForKey:@"vsId"]];

    mdAlarmRecordShootCfg = [NSMutableArray arrayWithCapacity:[allCams count]];
    
    for (NSDictionary *dict in allCams)
    {
        NSMutableDictionary *dd = [NSMutableDictionary dictionaryWithCapacity:3];
        [dd setValue:[dict valueForKey:@"name"] forKey:@"name"];
        [dd setValue:[dict valueForKey:@"videoId"] forKey:@"channelNumber"];
        
        for (NSDictionary *dict2 in cur_alarmrecord)
        {
            if ([[dict valueForKey:@"videoId"] isEqualToString:[dict2 valueForKey:@"channelNumber"]])
            {
                [dd setValue:@"1" forKey:@"AlarmRecord"];
                break;
            }
        }
        for (NSDictionary *dict2 in cur_alarmshoot)
        {
            if ([[dict valueForKey:@"videoId"] isEqualToString:[dict2 valueForKey:@"channelNumber"]])
            {
                [dd setValue:@"1" forKey:@"AlarmShoot"];
                break;
            }
        }
        
        [mdAlarmRecordShootCfg addObject:dd];
    }
    [mdAlarmRecordShootCfg retain];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)dealloc {
    [applyBtn release];
    [switchCtl release];
    
    [mdAlarmOutputCfg release];
    [mdAlarmRecordShootCfg release];
    [super dealloc];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [curCamDict valueForKey:@"name"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ACellIdentifier = @"ACell";
    static NSString *BCellIdentifier = @"BCell";
    UITableViewCell *cell ;
    
    if (indexPath.row == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:ACellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ACellIdentifier] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
        cell.textLabel.text = @"启动移动侦测告警";
        [cell.contentView addSubview:switchCtl];
            
    }
    else 
    {
        cell = [tableView dequeueReusableCellWithIdentifier:BCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:BCellIdentifier] autorelease];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
        
        if (indexPath.row == 1)
        {
            cell.textLabel.text = @"告警时间";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%02d:%02d-%02d:%02d", alarmtime_i[0],alarmtime_i[1],alarmtime_i[2],alarmtime_i[3]];
        }
        else if (indexPath.row == 2)
        {
            cell.textLabel.text = @"告警输出号";
            //cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [mdAlarmOutput count]];
        }
        else if (indexPath.row == 3)
        {
            cell.textLabel.text = @"录像通道输出号";
            //cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [mdAlarmRecord count]];
        }
        else //if (indexPath.row == 4)
        {
            cell.textLabel.text = @"告警抓拍通道号";
            //cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [mdAlarmShoot count]];
        }
    }
         
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1)
    {
        AlarmTimeCfgViewController *vc = [[AlarmTimeCfgViewController alloc] initWithAlarmTime:alarmtime_i];        
        vc.title = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    }
    else if (indexPath.row == 2)
    {
        AlarmXXXViewController *vc = [[AlarmXXXViewController alloc] initForAlarmOutput:mdAlarmOutputCfg ];
        vc.title = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    }
    else if (indexPath.row == 3)
    {
        AlarmXXXViewController *vc = [[AlarmXXXViewController alloc] initForAlarmRecord:mdAlarmRecordShootCfg ];
        vc.title = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    }
    else if (indexPath.row == 4)
    {
        AlarmXXXViewController *vc = [[AlarmXXXViewController alloc] initForAlarmShoot:mdAlarmRecordShootCfg ];
        vc.title = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];	
}


#pragma mark -
#pragma mark MCUEngine delegate
-(void)onLoggingProgressReport: (int) state param:(int) para
{
    if (state == LOG_SETVSALARMCONFIGURATION)
    {
        //setVSIng = NO;
		self.navigationItem.prompt = nil;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        self.navigationItem.hidesBackButton = NO;
        self.tableView.userInteractionEnabled = YES;
        self.navigationItem.rightBarButtonItem = applyBtn;        
        
        doVsAlarmRrefresh = YES;
        [self.navigationController popViewControllerAnimated:YES];
    }
	else if (state == LOG_NETWORK_FAIL)
	{
        //setVSIng = NO;
		self.navigationItem.prompt = [NSString stringWithFormat:@"网络连接错误(%d)", para];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        self.navigationItem.hidesBackButton = NO;
        self.navigationItem.rightBarButtonItem = applyBtn;
        self.tableView.userInteractionEnabled = YES;
	}
	else if (state == LOG_RESULTCODE_ERROR)
	{ 
        //setVSIng = NO;
        self.navigationItem.prompt = [NSString stringWithFormat:@"服务器返回错误(%d)",  para];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        self.navigationItem.hidesBackButton = NO;
        self.navigationItem.rightBarButtonItem = applyBtn;
        self.tableView.userInteractionEnabled = YES;
	}
}


@end
