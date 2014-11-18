//
//  Common.m
//  EyeRecording
//
//  Created by MKevin on 4/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
/*
 20121030
    --don't store "PuId" in camera_dict
    -- keep vsList (of vsDict)
 
 */

#import "Common.h"
#import <CFNetwork/CFNetwork.h>
#import "Md5.h"


NSString * const RCRecordingFileExtension = @"mp4";
int const RCRecordingFileExtensionLength = 3;
NSString * const RCRecordingFileDatePartFormat = @"yyyyMMddHHmmss";
int const RCRecordingFileDatePartFormatLength = 14;

//extern const NSString *cuVersion;

const NSString *kIPAddress_CMS =  @"121.31.255.6"; 
//const NSString *kIPAddress_VAU = @"121.31.255.9";//not used, should be parsed out dynamically

const NSString *kPort_CMS = @"8081";

int g_ptzPort = 5062;
int g_rtspPort = 5546; //not used
int g_streamType = 2;
int g_CameraControlLength1 = 5;
int g_CameraControlLength2 = 5;

BOOL g_wxx_loginDone[PORTAL_ENTRY_NUM];
int login_reason ; // 0: initial login  1: getVS 

static MCUEngine * __gMCUParam = nil;

enum {
	ELEMENT_result = 1,
	ELEMENT_sessionId,
    ELEMENT_domainId,
    
	//RequestDeviceData
	ELEMENT_device,
	ELEMENT_name,
	ELEMENT_type,
	ELEMENT_id,
	ELEMENT_areaId,
	ELEMENT_currentAreaId,
	ELEMENT_vsId,
	ELEMENT_videoId,
	ELEMENT_deviceId,
	ELEMENT_disabled,
	ELEMENT_online,
    
    //GetUser
	ELEMENT_permission,
	ELEMENT_roleId,
    ELEMENT_roleName,
	//areaId
	
	//GetRole
	ELEMENT_command,
    ELEMENT_hasAllPrivilege,
	
	//GetVAU, QueryVsRoute
	ELEMENT_natIp,
	ELEMENT_natPort,
	ELEMENT_natRtspPort,
    
    //GetVS
    ELEMENT_loginUsername,
    ELEMENT_loginPassword,
    ELEMENT_managementPort,
    ELEMENT_gpio,
    ELEMENT_normalState,
    ELEMENT_channelNumber,
    ELEMENT_direction,
    ELEMENT_vendor,
    //Set/Get VsAlaramConfiguration
    ELEMENT_cameraAlarm,
    ELEMENT_cameraNumber,
    ELEMENT_motionDetectionAlarmEnabled,
    ELEMENT_motionDetectionSensitivity,
    ELEMENT_motionDetectionAlarmTime,
    ELEMENT_motionDetectionFrequency,
    ELEMENT_motionDetectionAlarmOutput,
    ELEMENT_motionDetectionAlarmRecord,
    ELEMENT_motionDetectionAlarmShoot,
    
    ELEMENT_outputChannelNumber,
    ELEMENT_alarmState,
};

enum {
	CMDSESSION_USERLOGIN = 1,
	CMDSESSION_REQUESTDEVICEDATA,
	CMDSESSION_KEEPALIVE,
	CMDSESSION_LOGOUT,
    
    CMDSESSION_GETUSER,
	CMDSESSION_GETROLE,
	CMDSESSION_GETVAU,
    CMDSESSION_GETVS,
    CMDSESSION_GETCAMERA,
    CMDSESSION_GETVSALARMCONFIGURATION,
    CMDSESSION_SETVSALARMCONFIGURATION,
    CMDSESSION_QUERYVSROUTE,
};

enum {
    SUBSESSION_GETVS_GPIO = 1,  
    SUBSESSION_GETVSALARM_MITIONDETECTIONALARMOUTPUT,
};



@interface MCUEngine(PrivateMethods)
@property (readwrite, retain) NSMutableArray *wxx_cameraList, *wxx_areaList;

@end

@implementation MCUEngine(PrivateMethods)

@dynamic wxx_cameraList;
-(NSMutableArray*)wxx_cameraList
{
	return _wxx_cameraList[cur_entry];
}
- (void)setWxx_cameraList: (NSMutableArray*)s
{
	[_wxx_cameraList[cur_entry] release];
	_wxx_cameraList[cur_entry] = [s retain];
}

@dynamic wxx_areaList;
-(NSMutableArray*)wxx_areaList
{
	return _wxx_areaList[cur_entry];
}
- (void)setWxx_areaList: (NSMutableArray*)s
{
	[_wxx_areaList[cur_entry] release];
	_wxx_areaList[cur_entry] = [s retain];
}

/*
@dynamic wxx_userPermission;
-(NSMutableArray*)wxx_userPermission
{
	return _wxx_userPermission[cur_entry];
}
- (void)setWxx_userPermission: (NSMutableArray*)s
{
	[_wxx_userPermission[cur_entry] release];
	_wxx_userPermission[cur_entry] = [s retain];
}*/

@end




@implementation MCUEngine

@synthesize VSData, VSFeedConnection, session_id, result_errorStr, devDict, vsList,domain_id,userName_login, RtspPort,VAUPort, delegate = _delegate, userPermissionArray,gpio_out_array,camera_alarm_configuration;

-(id)init
{
	if(self = [super init]){
        
		arrayCMSIP = [NSArray arrayWithObjects: @"121.31.254.136", @"121.31.255.6", nil];
		[arrayCMSIP retain];
		
        //default
        VAUIPAddr = @"121.31.255.9";
        [VAUIPAddr retain];
        RtspPort = 5546;
	}
	return self;
}

+(MCUEngine*)sharedObj
{
	if(nil == __gMCUParam)
	{
		__gMCUParam = [[MCUEngine alloc] init];
	}
	return __gMCUParam;
}

-(void) load;
{
	int i;
	for (i=0;i<PORTAL_ENTRY_NUM;i++)
	{
		g_wxx_loginDone[i] = NO;
	}
	
    self.vsList = [NSMutableArray array];			
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
 
	if([defaults integerForKey:@"version"] != 6)  
	{
        [defaults setInteger:6 forKey:@"version"];

		[defaults setObject:@"wlt" forKey:@"user_0"];
		//[defaults setObject:@"123456" forKey:@"psw_0"];
		
		[defaults setObject:@"wjt" forKey:@"user_1"];
		//[defaults setObject:@"123456" forKey:@"psw_1"];

		[defaults setObject:@"wqy" forKey:@"user_2"];
		//[defaults setObject:@"123456" forKey:@"psw_2"];//xinghua 20111011, don't preset this password for wqy
		
		[defaults setBool:YES forKey:@"saveaccount_0"];
		[defaults setBool:YES forKey:@"saveaccount_1"];
		[defaults setBool:YES forKey:@"saveaccount_2"];

		//[defaults setInteger: 1 forKey:@"IP_INDEX"];//new IP Setting by default
        [defaults setValue:kIPAddress_CMS  forKey:@"CMS_IP"];//default CMS IP
        [defaults setValue:kPort_CMS forKey:@"CMS_Port"];//default CMS Port
		
        [defaults synchronize];
    }
	
}
-(void) unload
{
	
	//TODO
	
}

-(void)dealloc
{
	int i;
	for (i=0;i<PORTAL_ENTRY_NUM;i++)
	{
		//[_wxx_user[i] release];
		//[_wxx_psw[i] release];
		[_wxx_cameraList[i] release];
		[_wxx_areaList[i] release];
	}
	[devDict release];
	[vsList release];

	[session_id release];
    [domain_id release];
    
	[result_errorStr release];
	
	//[arrayVAUIP release];
	[arrayCMSIP release];
    
    [VAUIPAddr release];
	
	[super dealloc];
}

#pragma mark ----------


-(NSString*)getCMSIPAddr
{
#if 0
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	int idx = [defaults integerForKey:@"IP_INDEX"];
	return [arrayCMSIP objectAtIndex:idx];
#else
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

    NSString *cms_ip = [defaults stringForKey:@"CMS_IP"];
    
    return cms_ip;
#endif
}
+(void)setCMSIPAddr:(NSString *)cms_ip
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];        
    [defaults setValue:cms_ip forKey:@"CMS_IP"];
    [defaults synchronize];
}

+(NSString *)getCMSPort
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *cms_port = [defaults stringForKey:@"CMS_Port"];
    
    return cms_port;
}

+(void)setCMSPort:(NSString *)cms_port
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];        
    [defaults setValue:cms_port forKey:@"CMS_Port"];
    [defaults synchronize];
}

-(NSString*)getVAUIPAddr
{
    return VAUIPAddr;//query out by commands
}


/*
+(int)getIPSettingIndex
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	return  [defaults integerForKey:@"IP_INDEX"];
}


+(void)setIPSettingIndex:(int)idx
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:idx forKey:@"IP_INDEX"];
	[defaults synchronize];
}
*/

+(NSString*)getLoginUserName:(int)entry_id
{
	NSString *username = [NSString stringWithFormat:@"user_%d", entry_id];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	return [defaults stringForKey:username]; 
}

+(void)setLoginUserName:(NSString*)s entry:(int)entry_id
{
	NSString *username = [NSString stringWithFormat:@"user_%d", entry_id];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	if (s == nil)
		[defaults removeObjectForKey:username];
	else
		[defaults setObject:s forKey:username];
	
	[defaults synchronize];
}

+(NSString*)getLoginPassword:(int)entry_id
{
	NSString *password = [NSString stringWithFormat:@"psw_%d", entry_id];
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	return [defaults stringForKey:password]; 

}

+(void)setLoginPassword:(NSString*)s entry:(int)entry_id
{
	NSString *password;
	password = [NSString stringWithFormat:@"psw_%d", entry_id];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	if (s == nil)
		[defaults removeObjectForKey:password];
	else
		[defaults setObject:s forKey:password];
	
	[defaults synchronize];
}

+(BOOL)getLoginAccountSaved:(int)entry_id
{
	NSString *key = [NSString stringWithFormat:@"saveaccount_%d", entry_id];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

	return [defaults boolForKey:key];
}

+(void)setLoginAccountSaved:(BOOL)b entry:(int)entry_id
{
	NSString *key = [NSString stringWithFormat:@"saveaccount_%d", entry_id];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:b forKey:key];
	
	[defaults synchronize];
}

+(NSString*)calcMD5:(NSString*)instr
{
	if(instr == nil) return nil;
	
	MD5_CTX ctx;
	MD5Init(&ctx);
	MD5Update(&ctx, (unsigned char*)[instr UTF8String], [instr length]);
	MD5Final(&ctx);
	
	char psw_md5_c[34] = {0};
	for (int i= 0; i< 16;i++)
		sprintf(&psw_md5_c[i*2], "%02x", ctx.digest[i]);
	
	return [NSString stringWithUTF8String:psw_md5_c];
}

/**
 *	@brief	Judge if the OS Version is > 7.0 or not
 *
 *	@return	YES --- 7.0 or above, NO --- under 7.0
 */
+ (BOOL)isCurrentSystemOSVersionAbove70
{
    if (IOS_VERSION >= 7.0) {
        return YES;
    } else {
        return NO;
    }
}

+ (NSString*)getCurrentVersion
{
    NSDictionary *infoDict =[[NSBundle mainBundle] infoDictionary];
    NSString     *versionNum =[infoDict objectForKey:@"CFBundleShortVersionString"];
    
    return versionNum;
}

-(NSArray*)getAreaList:(int)entry_id
{
	return _wxx_areaList[entry_id];
}
-(NSArray*)getCameraList:(int)entry_id
{
	return _wxx_cameraList[entry_id];
}

//fill PUID info (deviceId of VS), remove deviceId of CAM
-(void)_cleanupCamList
{
	for (NSMutableDictionary *dict in self.wxx_cameraList)
	{
        [dict setValue:[NSNumber numberWithInt:cur_entry] forKey:@"portal_entry"];//to know which entry the camera belonging to
		[dict removeObjectForKey:@"id"];
		[dict removeObjectForKey:@"deviceId"];
		
        /*  xinghua 20121030, now we will not release VSlist
		NSString *vsId = [dict valueForKey:@"vsId"];
		if (vsId == nil)continue;
		for  (NSDictionary *vsDict in self.vsList)
		{
			if ([vsId isEqualToString: [vsDict valueForKey:@"id"]])
			{
				[dict setValue:[vsDict valueForKey:@"deviceId"] forKey:@"PuId"];
				break;
			}
		}
		//[dict removeObjectForKey:@"vsId"]; //KEEP THIS!
        */
        
        ////////////////////////////////////////
        //xinghua 20121015, to fill in AccessControl into camera_dict
        NSString *cam_areaId = [dict valueForKey:@"areaId"];
        NSString *cam_currentAreaId = [dict valueForKey:@"currentAreaId"];
        BOOL bCameraBelongsArea = NO;
        
        //for (NSDictionary *dict_permission in self.userPermissionArray)
        NSDictionary *dict_permission = [self.userPermissionArray objectAtIndex:0]; 
        {
#if 1
            NSString *areaId = [dict_permission valueForKey:@"areaId"];
            
            if ([areaId isEqualToString:@"ROOT"])
            {
                bCameraBelongsArea = YES;
            }
            else {
                if (cam_areaId)
                {
                    NSRange rng = [cam_areaId rangeOfString:areaId ];
                    
                    if (NSLocationInRange(0, rng))//camera belongs to this area
                    {
                        bCameraBelongsArea = YES;
                        //break;
                    }
                }
                if (cam_currentAreaId && !bCameraBelongsArea)
                {
                    NSRange rng = [cam_currentAreaId rangeOfString:areaId ];
                    if (NSLocationInRange(0, rng))//camera belongs to this area
                    {
                        bCameraBelongsArea = YES;
                        //break;
                    }
                }
            }
#else
            bCameraBelongsArea = YES;   
#endif
        }
        if (bCameraBelongsArea)
        {
            NSNumber * accessRole = [dict_permission valueForKey:@"ControlPTZ"];
            if (accessRole)
            {
                [dict setValue:accessRole forKey:@"ControlPTZ"];
            }
            
            accessRole = [dict_permission valueForKey:@"SetVsAlarmConfiguration"];
            if (accessRole)
            {
                [dict setValue:accessRole forKey:@"SetVsAlarmConfiguration"];
            }
            
            accessRole = [dict_permission valueForKey:@"GetVsAlarmConfiguration"];
            if (accessRole)
            {
                [dict setValue:accessRole forKey:@"GetVsAlarmConfiguration"];
            }
            
            accessRole = [dict_permission valueForKey:@"hasAllPrivilege"];
            if (accessRole)
            {
                [dict setValue:accessRole forKey:@"hasAllPrivilege"];
            }
            
        }
	}
}

-(NSString*)findRootIdOfEntry: (int)entry_idx entry_key:(NSString*)key
{
	NSString *topAreaId=nil ;
	NSString *areaId,*_name;
	
	for (NSDictionary *dict in [self getAreaList:entry_idx])
	{
		_name = [dict valueForKey:@"name"];
		//areaId = [dict valueForKey:@"areaId"];
		//NSLog(@"%@,%@",_name,key);
		
		NSRange range;
		//NSRange range2;
		/*range = [areaId rangeOfString:@"<"];
		 range2 = [areaId rangeOfString:@"ROOT"];
		 if (range.location == NSNotFound && range2.location == NSNotFound)
		 continue;*/
		
		range = [_name rangeOfString:key];
		if (range.location == NSNotFound)
			continue;
		
		range = [_name rangeOfString:@"沃"];
		if (range.location == NSNotFound)
			continue;	
		
		
		topAreaId = [dict valueForKey:@"id"];
		break;
	}
	
	
	//xinghua 20111011, if no topAreaId found, we need to locate the shortest areaId
	int topareaId_len = 100;
	if (topAreaId == nil)
	{
		for (NSDictionary *dict in [self getAreaList:entry_idx])
		{
			int l;
			areaId = [dict valueForKey:@"areaId"];
			l = [areaId length];
			
			if (topareaId_len > l)
			{
				topareaId_len = l;
				topAreaId = areaId;
			}
			
		}			
	}
	
	return topAreaId;
}

-(NSArray *)filterArealistOfEntry:(int)entry_idx  withAreaId:(NSString*)_areaid
{
	NSMutableArray *result = [NSMutableArray array];
	cur_entry = entry_idx;
	
	for (NSDictionary *dict in [self getAreaList:entry_idx])
	{
		
		if ([_areaid isEqualToString:[dict valueForKey:@"areaId"]] == YES )
		{
			[result addObject:dict];
		}
	}
	return result;
}

-(NSArray *)filterSublistOfEntry:(int)entry_idx  withAreaId:(NSString*)_areaid
{
	NSMutableArray *result = [NSMutableArray array];
	cur_entry = entry_idx;
	
	for (NSDictionary *dict in [self getAreaList:entry_idx])
	{

		if ([_areaid isEqualToString:[dict valueForKey:@"areaId"]] == YES )
		{
			[result addObject:dict];
		}
	}
	for (NSDictionary *dict in [self getCameraList:entry_idx])
	{

		if ([_areaid isEqualToString:[dict valueForKey:@"areaId"]] == YES ||
			[_areaid isEqualToString:[dict valueForKey:@"currentAreaId"]] == YES)
		{
			[result addObject:dict];
		}
	}
	
	return result;
}


-(NSDictionary*)queryVSObj:(NSString *)vsId
{
    NSDictionary * vsDict = nil;
    if (vsId == nil) return nil;
    for  (vsDict in self.vsList)
    {
        if ([vsId isEqualToString: [vsDict valueForKey:@"id"]])
        {
            break;
        }
    }
    return vsDict;
}


-(NSArray *)filterCameras: (int)entry_idx byVsId: (NSString*)vsId
{
    NSMutableArray *result_array = [NSMutableArray array];
    
    NSArray *allCam = [self getCameraList:entry_idx];
    
    for (NSDictionary *camdict in allCam)
    {
        NSString *_vsId = [camdict valueForKey:@"vsId"];
        if ([vsId isEqualToString:_vsId])
            [result_array addObject:camdict];
    }
    return result_array;
}

-(NSString *)queryCameraName:(int)entry_idx withVsId: (NSString*)_vsId withVideoId:(NSString *)_videoId;
{
    for  (NSDictionary *dict in [self getCameraList:entry_idx])
    {
        if ([_vsId isEqualToString: [dict valueForKey:@"vsId"]] && 
            [_videoId isEqualToString:[dict valueForKey:@"videoId"]])
        {
            return [dict valueForKey:@"name"];
        }
    }
    
    return nil;
}



/*
 ------------------------------------------- -------------------------------------------
 */

/*
 This is the entry to start user login process...
 */
-(void) entryLogin: (int)entry_idx UserName:(NSString*)userName Psw:(NSString*)psw
{
    login_reason = 0;
	cur_entry = entry_idx;
    
	[self.delegate onLoggingProgressReport: LOG_LOGIN param:result_code ];
	
	NSString*feedURLString = [NSString stringWithFormat:@"http://%@:%@/viss/UserLogin?locale=zh_CN&password=%@&username=%@&cuVersion=%@&cuType=M_CU",
							  [[MCUEngine sharedObj] getCMSIPAddr], [MCUEngine getCMSPort],[MCUEngine calcMD5:psw],  userName,   [MCUEngine getCurrentVersion]];

    self.userName_login = userName;//saved for later use (GetUser)

    NSURLRequest *VSURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:VSURLRequest delegate:self];
    self.VSFeedConnection = conn;
	[conn release];
}

/*
 NOTE: 
 -if we can getVS for each vsId at initial logging process, it will take a very long time.
 -getVS islater called in case camera need to be controlled
 -before call it's better to check if vsLoginUsername, vsLoginPassword, vsPort are alrady query out
 -must login first
 */

-(void) entryQueryVSProcess: (NSMutableDictionary *)camdict
{
    login_reason = 1;
    
    NSString *cms_loginuser, *cms_password;
    NSNumber * entry_idx = [camdict valueForKey:@"portal_entry"];
    cms_loginuser = [MCUEngine getLoginUserName:[entry_idx intValue]] ;
    cms_password = [MCUEngine getLoginPassword:[entry_idx intValue]];

    cur_vs_dict = (NSMutableDictionary*)[[MCUEngine sharedObj] queryVSObj:[camdict valueForKey:@"vsId"]];
    
	NSString*feedURLString = [NSString stringWithFormat:@"http://%@:%@/viss/UserLogin?locale=zh_CN&password=%@&username=%@",
							  [[MCUEngine sharedObj] getCMSIPAddr], [MCUEngine getCMSPort],[MCUEngine calcMD5:cms_password],  cms_loginuser];
    
    NSURLRequest *VSURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:VSURLRequest delegate:self];
    self.VSFeedConnection = conn;
	[conn release];    
}



- (void)getVsAlarmConfiguration:(NSDictionary *)camdict
{
    NSString *cms_loginuser, *cms_password;
    NSNumber * entry_idx = [camdict valueForKey:@"portal_entry"];
    cms_loginuser = [MCUEngine getLoginUserName:[entry_idx intValue]] ;
    cms_password = [MCUEngine getLoginPassword:[entry_idx intValue]];
    
    cur_cam_dict = camdict;//save for later use
    camera_alarm_got = NO;
    
    NSDictionary *vsDict = [self queryVSObj:[camdict valueForKey:@"vsId"]];
    
	NSString *feedURLString = [NSString stringWithFormat:@"http://%@:%@/viss/GetVsAlarmConfiguration?__password=%@&__username=%@&vsDeviceId=%@&vsLoginPassword=%@&vsLoginUsername=%@&vsPort=%@&vsVendor=%@",[vsDict valueForKey:@"csg_IP"], [vsDict valueForKey:@"csg_Port"], [MCUEngine calcMD5:cms_password], cms_loginuser,[vsDict valueForKey:@"deviceId"],[vsDict valueForKey:@"vsLoginPassword"], [vsDict valueForKey:@"vsLoginUsername"], [vsDict valueForKey:@"vsPort"],[vsDict valueForKey:@"vendor"]];
    
    NSLog(@"%@", feedURLString);
    
    NSURLRequest *VSURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
	
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:VSURLRequest delegate:self];
    self.VSFeedConnection = conn;
	[conn release];
}

- (void)setVsAlarmConfiguration:(NSMutableDictionary *)camdict  config:(NSString *)_cfg
{
    NSLog(@"setVsAlarmConfiguration");
    
    NSString *cms_loginuser, *cms_password;
    NSNumber * entry_idx = [camdict valueForKey:@"portal_entry"];
    cms_loginuser = [MCUEngine getLoginUserName:[entry_idx intValue]] ;
    cms_password = [MCUEngine getLoginPassword:[entry_idx intValue]];
    
    NSDictionary *vsDict = [self queryVSObj:[camdict valueForKey:@"vsId"]];
    
	NSString *feedURLString = [NSString stringWithFormat:@"http://%@:%@/viss/SetVsAlarmConfiguration?__password=%@&__username=%@&%@&vsDeviceId=%@&vsLoginPassword=%@&vsLoginUsername=%@&vsPort=%@&vsVendor=%@",[vsDict valueForKey:@"csg_IP"], [vsDict valueForKey:@"csg_Port"], [MCUEngine calcMD5:cms_password], cms_loginuser,  _cfg ,[vsDict valueForKey:@"deviceId"],[vsDict valueForKey:@"vsLoginPassword"], [vsDict valueForKey:@"vsLoginUsername"], [vsDict valueForKey:@"vsPort"], [vsDict valueForKey:@"vendor"]];
    
    NSLog(@"%@", feedURLString);
    
    NSURLRequest *VSURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
	
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:VSURLRequest delegate:self];
    self.VSFeedConnection = conn;
	[conn release];

}


- (void)_requestDeviceData:(NSTimer *)timer
{

    NSLog(@"_requestDeviceData");
    [self.delegate onLoggingProgressReport: LOG_REQUESTDATA param:0 ];
	
	NSString *feedURLString = [NSString stringWithFormat:@"http://%@:%@/viss/RequestDeviceData?sessionId=%@&type=CAM&type=AREA&type=VS", 
							   [[MCUEngine sharedObj] getCMSIPAddr], [MCUEngine getCMSPort], self.session_id];
	NSURLRequest *VSURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:VSURLRequest delegate:self];
    self.VSFeedConnection = conn;
	[conn release];
}

//must be logged before!!!
//before requesting each camera preview/control, call getVS by passing vsId
- (void)_getVS:(NSTimer *)timer
{
    NSLog(@"_getVS");
    
    [self.delegate onLoggingProgressReport: LOG_GETVS param:0 ];

    NSString *vsId = [cur_vs_dict valueForKey:@"id"];//[cam_dict valueForKey:@"vsId"];
    
	NSString *feedURLString = [NSString stringWithFormat:@"http://%@:%@/viss/GetVS?sessionId=%@&id=%@", 
							  [[MCUEngine sharedObj] getCMSIPAddr], [MCUEngine getCMSPort], self.session_id, vsId];
    NSLog(@"%@", feedURLString);
	NSURLRequest *VSURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:VSURLRequest delegate:self];
    self.VSFeedConnection = conn;
	[conn release];
}

/*
- (void)_getCamera:(NSTimer *)timer
{
    NSLog(@"_getCamera");
    
    [self.delegate onLoggingProgressReport: LOG_GETCAMERA param:0 ];
    
    NSString *vsId = [cur_vs_dict valueForKey:@"deviceId"];
    
	NSString *feedURLString = [NSString stringWithFormat:@"http://%@:%@/viss/GetCamera?sessionId=%@&vsDeviceId=%@", 
                               [[MCUEngine sharedObj] getCMSIPAddr], [MCUEngine getCMSPort], self.session_id, vsId];
    NSLog(@"%@", feedURLString);
    
	NSURLRequest *VSURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:VSURLRequest delegate:self];
    self.VSFeedConnection = conn;
	[conn release];
}*/


- (void)_queryVsRoute:(NSTimer *)timer
{
    NSLog(@"_queryVsRoute");
    
    [self.delegate onLoggingProgressReport: LOG_QUERYVSROUTE param:0 ];
    
    NSString *vsDeviceId = [cur_vs_dict valueForKey:@"deviceId"];
    
    NSString *feedURLString = [NSString stringWithFormat:@"http://%@:%@/viss/QueryVsRoute?sessionId=%@&vsDeviceId=%@&queryType=CSG", 
							   [[MCUEngine sharedObj] getCMSIPAddr], [MCUEngine getCMSPort], self.session_id, vsDeviceId];
    
    NSLog(@"%@", feedURLString);
    
	NSURLRequest *VSURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:VSURLRequest delegate:self];
    self.VSFeedConnection = conn;
	[conn release];
}

- (void)_getVAU:(NSTimer *)timer
{
    
	NSLog(@"_getVAU");
    [self.delegate onLoggingProgressReport: LOG_GETVAU param:0 ];
    
	NSString *feedURLString = [NSString stringWithFormat:@"http://%@:%@/viss/GetVAU?sessionId=%@&domainId=%@", 
							  [[MCUEngine sharedObj] getCMSIPAddr], [MCUEngine getCMSPort], self.session_id, self.domain_id];
    NSLog(@"%@", feedURLString);
	NSURLRequest *VSURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
	
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:VSURLRequest delegate:self];
    self.VSFeedConnection = conn;
	[conn release];
	
}

- (void)_getUser:(NSTimer *)timer
{
    NSLog(@"_getUser");

    [self.delegate onLoggingProgressReport: LOG_GETUSER param:0 ];
	
	NSString *feedURLString = [NSString stringWithFormat:@"http://%@:%@/viss/GetUser?sessionId=%@&username=%@", 
							  [[MCUEngine sharedObj] getCMSIPAddr], [MCUEngine getCMSPort], self.session_id, self.userName_login];
    NSLog(@"%@", feedURLString);
	NSURLRequest *VSURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
	
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:VSURLRequest delegate:self];
    self.VSFeedConnection = conn;
	[conn release];
}

- (void)_getRole:(NSTimer *)timer
{
    
	NSLog(@"_getRole");
	[self.delegate onLoggingProgressReport: LOG_GETROLE param:0 ];
    
    NSDictionary *roledict = [self.userPermissionArray objectAtIndex:getQueryIndex];
    
	//NSString *roleId = [roledict valueForKey:@"roleId"];
	//NSString *feedURLString = [NSString stringWithFormat:@"http://%@:%@/viss/GetRole?sessionId=%@&id=%@", [[MCUEngine sharedObj] getCMSIPAddr], [MCUEngine getCMSPort], self.session_id, roleId];

    NSString *roleName = [roledict valueForKey:@"roleName"];
	NSString *feedURLString = [NSString stringWithFormat:@"http://%@:%@/viss/GetRole?sessionId=%@&name=%@", [[MCUEngine sharedObj] getCMSIPAddr], [MCUEngine getCMSPort], self.session_id, roleName];

    
    NSLog(@"%@", feedURLString);
    NSURLRequest *VSURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
	
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:VSURLRequest delegate:self];
    self.VSFeedConnection = conn;
	[conn release];
}


- (void)_userLogout:(NSTimer*)timer
{
	NSLog(@"_userLogout");  
 
    
	NSString *feedURLString = [NSString stringWithFormat:@"http://%@:%@/viss/UserLogout?sessionId=%@", [[MCUEngine sharedObj] getCMSIPAddr], [MCUEngine getCMSPort], self.session_id];
	NSURLRequest *VSURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
	
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:VSURLRequest delegate:self];
    self.VSFeedConnection = conn;
	[conn release];
	
}

- (void)parseVSResponseData:(NSData *)data 
{
	//NSLog(@"NSData %@", data);
	cmd_session = 0;
	result_code = 0;
	element_id = 0;
	
    //
    // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not desirable
    // because it gives less control over the network, particularly in responding to connection errors.
    //
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser parse];
	
    [parser release];        
	
	if (result_code != 0)
	{
        if (login_reason == 0)
            g_wxx_loginDone[cur_entry] = NO;

		[self.delegate onLoggingProgressReport: LOG_RESULTCODE_ERROR param:result_code ];
		
		NSLog(@"result_code %d", result_code);
	}
	else
	{
		if (cmd_session == CMDSESSION_USERLOGIN) //user login
		{
            if (login_reason == 0)
            {
                g_wxx_loginDone[cur_entry] = NO;
                self.wxx_areaList = [NSMutableArray array];
                self.wxx_cameraList = [NSMutableArray array];
                self.userPermissionArray = [NSMutableArray array];
                
                //[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(_requestDeviceData:) userInfo:nil repeats:NO];
                [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(_getUser:) userInfo:nil repeats:NO];
            }
            else if (login_reason == 1){
                
                self.gpio_out_array = [NSMutableArray array];//gpio_out_array will be retreived by getVS
                [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(_getVS:) userInfo:nil repeats:NO];
                //[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(_getCamera:) userInfo:nil repeats:NO];
            }
		}
		else if (cmd_session == CMDSESSION_REQUESTDEVICEDATA)//request device data
		{
            //Xinghua20121015 NOTE: dont'do getVS here, for it will take too much time
            //getQueryIndex = 0;
			//[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_getVS:) userInfo:nil repeats:NO];
			
            [self _cleanupCamList];
			[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_userLogout:) userInfo:nil repeats:NO];
		}
        else if (cmd_session == CMDSESSION_GETVS)
        {
            //store back into cur_vs_dict
            [cur_vs_dict setValue:self.gpio_out_array forKey:@"gpio_out_array"];
            self.gpio_out_array = nil;
            
            [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_queryVsRoute:) userInfo:nil repeats:NO];
        }
        /*else if (cmd_session == CMDSESSION_GETCAMERA)
        {
            [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_userLogout:) userInfo:nil repeats:NO];
        }*/
        else if (cmd_session == CMDSESSION_QUERYVSROUTE)
        {
            [cur_vs_dict setValue:[NSNumber numberWithBool:YES] forKey:@"getvs"];
            [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_userLogout:) userInfo:nil repeats:NO];
        }
		else if (cmd_session == CMDSESSION_GETVAU) 
		{
			[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_requestDeviceData:) userInfo:nil repeats:NO];
		}
		else if (cmd_session == CMDSESSION_GETUSER) 
		{			
            getQueryIndex = 0;
            [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_getRole:) userInfo:nil repeats:NO];
		}
		else if (cmd_session == CMDSESSION_GETROLE) 
		{
			getQueryIndex ++;
			
			if (getQueryIndex == [self.userPermissionArray count])//get role done
			{
				[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_getVAU:) userInfo:nil repeats:NO];
			}
			else 
				[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_getRole:) userInfo:nil repeats:NO];	
		}  
        else if (cmd_session == CMDSESSION_GETVSALARMCONFIGURATION)
        {
            [self.delegate onLoggingProgressReport: LOG_GETVSALARMCONFIGURATION param:0 ];  
        }
        else if (cmd_session == CMDSESSION_SETVSALARMCONFIGURATION)
        {
            [self.delegate onLoggingProgressReport: LOG_SETVSALARMCONFIGURATION param:0 ];  
        }
		/*else if (cmd_session == CMDSESSION_KEEPALIVE)//Keep Alive
		 {
		 [NSTimer scheduledTimerWithTimeInterval:6 target:self selector:@selector(_keepAlive:) userInfo:nil repeats:NO];
		 }*/
		else if (cmd_session == CMDSESSION_LOGOUT)
		{
            if (login_reason == 0)
                g_wxx_loginDone[cur_entry] = YES;
            [self.delegate onLoggingProgressReport: LOG_LOGOUT param:0 ];  
		}        
	}
	
}



#pragma mark NSURLConnection delegate methods

// The following are delegate methods for NSURLConnection. Similar to callback functions, this is how the connection object,
// which is working in the background, can asynchronously communicate back to its delegate on the thread from which it was
// started - in this case, the main thread.

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.VSData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.VSData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	

	NSLog(@"net connection eror %d",[error code] );

    if (login_reason == 0)
        g_wxx_loginDone[cur_entry] = NO;
	[self.delegate onLoggingProgressReport: LOG_NETWORK_FAIL param:[error code] ];
	
	self.VSData = nil;
    self.VSFeedConnection = nil;

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
    NSString *webpagecontent = [[NSString alloc] initWithData:VSData encoding:NSUTF8StringEncoding];
    NSLog(@"webpage: %@", webpagecontent);
    [webpagecontent release];
    
    [self parseVSResponseData:VSData];
	
	self.VSFeedConnection = nil;
	self.VSData = nil;

}



#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	
	//NSLog(@"didStartElement %@ %@ %@ %@",elementName,namespaceURI,qName,attributeDict );
	
	if ([elementName isEqualToString:@"response"])
	{
		NSString *rsp_command = [attributeDict valueForKey:@"command"];
		if ([rsp_command isEqualToString:@"UserLogin"])
			cmd_session = CMDSESSION_USERLOGIN;
		else if ([rsp_command isEqualToString:@"RequestDeviceData"])
			cmd_session = CMDSESSION_REQUESTDEVICEDATA;
		else if ([rsp_command isEqualToString:@"KeepAlive"])
			cmd_session = CMDSESSION_KEEPALIVE;
		else if ([rsp_command isEqualToString:@"UserLogout"])
			cmd_session = CMDSESSION_LOGOUT;
        else if ([rsp_command isEqualToString:@"GetVAU"])
			cmd_session = CMDSESSION_GETVAU;
		else if ([rsp_command isEqualToString:@"GetRole"])
			cmd_session = CMDSESSION_GETROLE;
		else if ([rsp_command isEqualToString:@"GetUser"])
			cmd_session = CMDSESSION_GETUSER;
		else if ([rsp_command isEqualToString:@"GetVS"])
			cmd_session = CMDSESSION_GETVS;        
		else if ([rsp_command isEqualToString:@"GetCamera"])
			cmd_session = CMDSESSION_GETCAMERA;        
		else if ([rsp_command isEqualToString:@"GetVsAlarmConfiguration"])
			cmd_session = CMDSESSION_GETVSALARMCONFIGURATION;        
		else if ([rsp_command isEqualToString:@"SetVsAlarmConfiguration"])
			cmd_session = CMDSESSION_SETVSALARMCONFIGURATION;      
        else if ([rsp_command isEqualToString:@"QueryVsRoute"])
            cmd_session = CMDSESSION_QUERYVSROUTE;      
		
		//NSLog(@"cmd_session %d", cmd_session);
	}
	else if ([elementName isEqualToString:@"result"] )
	{
		element_id = ELEMENT_result; //result
		NSString *result_code_str = [attributeDict valueForKey:@"code"];
		result_code = [result_code_str integerValue];
	}
	else if ([elementName isEqualToString:@"sessionId"])
	{
		element_id = ELEMENT_sessionId;
	}
	else if ([elementName isEqualToString:@"domainId"])
	{
		element_id = ELEMENT_domainId;
	}    
	//GetVAU
	else if ([elementName isEqualToString:@"natIp"] )
	{
		element_id = ELEMENT_natIp;
	}
	else if ([elementName isEqualToString:@"natPort"])
	{
		element_id = ELEMENT_natPort;
	}
	else if ([elementName isEqualToString:@"natRtspPort"] )
	{
		element_id = ELEMENT_natRtspPort;
	}
	//GetUser
	else if ([elementName isEqualToString:@"permission"] )
	{
		element_id = ELEMENT_permission;
		//new permission
		self.devDict = [NSMutableDictionary dictionary];
	}
	else if ([elementName isEqualToString:@"roleId"] )
	{
		element_id = ELEMENT_roleId;
	}
	else if ([elementName isEqualToString:@"roleName"] )
	{
		element_id = ELEMENT_roleName;
	}    
	//GetRole
	else if ([elementName isEqualToString:@"command"] )
	{
		element_id = ELEMENT_command;
	}    
    else if ([elementName isEqualToString:@"hasAllPrivilege"] )
    {
        element_id = ELEMENT_hasAllPrivilege;
    }
    //GetVS
    else if ([elementName isEqualToString:@"loginUsername"] )//vsLoginUsername
    {
        element_id = ELEMENT_loginUsername;
    }
    else if ([elementName isEqualToString:@"loginPassword"] )//vsLoginPassword
    {
        element_id = ELEMENT_loginPassword;
    }
    else if ([elementName isEqualToString:@"managementPort"] )//vsPort
    {
        element_id = ELEMENT_managementPort;
    }
    else if ([elementName isEqualToString:@"gpio"] )//new gpio
    {
        element_id = ELEMENT_gpio;
        if (cmd_session == CMDSESSION_GETVS)
        {
            sub_xml_session = SUBSESSION_GETVS_GPIO;
            self.devDict = [NSMutableDictionary dictionaryWithCapacity:4];
        }
    }
    else if ([elementName isEqualToString:@"vendor"] )
    {
        element_id = ELEMENT_vendor;
    }
    else if ([elementName isEqualToString:@"normalState"] )
    {
        element_id = ELEMENT_normalState;
    }
    else if ([elementName isEqualToString:@"channelNumber"] )
    {
        element_id = ELEMENT_channelNumber;
    }
    else if ([elementName isEqualToString:@"direction"] )
    {
        element_id = ELEMENT_direction;
    }
    
    //getvsAlarmConifguration
	else if ([elementName isEqualToString:@"cameraAlarm"])
    {
        element_id = ELEMENT_cameraAlarm;
        if (cmd_session == CMDSESSION_GETVSALARMCONFIGURATION && !camera_alarm_got)
        {
            //sub_xml_session = SUBSESSION_GETVSALARMCONFIGURATION_CAMERAALARM;
            self.camera_alarm_configuration = [NSMutableDictionary dictionaryWithCapacity:8];
            NSMutableArray *motionDectectionAlarmXXXArray;
            motionDectectionAlarmXXXArray = [NSMutableArray array];
            [self.camera_alarm_configuration setValue:motionDectectionAlarmXXXArray forKey:@"motionDetectionAlarmOutput"];

            motionDectectionAlarmXXXArray = [NSMutableArray array];
            [self.camera_alarm_configuration setValue:motionDectectionAlarmXXXArray forKey:@"motionDetectionAlarmRecord"];
            
            motionDectectionAlarmXXXArray = [NSMutableArray array];
            [self.camera_alarm_configuration setValue:motionDectectionAlarmXXXArray forKey:@"motionDetectionAlarmShoot"];
            
        }
    }    
    else if ([elementName isEqualToString:@"cameraNumber"])
    {
        element_id = ELEMENT_cameraNumber;
    }      
	else if ([elementName isEqualToString:@"motionDetectionAlarmEnabled"])
    {
        element_id = ELEMENT_motionDetectionAlarmEnabled;
    }    
    else if ([elementName isEqualToString:@"motionDetectionSensitivity"])
    {
        element_id = ELEMENT_motionDetectionSensitivity;
    }
    else if ([elementName isEqualToString:@"motionDetectionAlarmTime"])
    {
        element_id = ELEMENT_motionDetectionAlarmTime;
    }    
    else if ([elementName isEqualToString:@"motionDetectionFrequency"])
    {
        element_id = ELEMENT_motionDetectionFrequency;
    }    
    else if ([elementName isEqualToString:@"motionDetectionAlarmOutput"])
    {
        element_id = ELEMENT_motionDetectionAlarmOutput;
        if (cmd_session == CMDSESSION_GETVSALARMCONFIGURATION)
        {
            sub_xml_session = SUBSESSION_GETVSALARM_MITIONDETECTIONALARMOUTPUT;
            self.devDict = [NSMutableDictionary dictionaryWithCapacity:2];
        }
    }      
    else if ([elementName isEqualToString:@"motionDetectionAlarmRecord"])
    {
        element_id = ELEMENT_motionDetectionAlarmRecord;
        if (cmd_session == CMDSESSION_GETVSALARMCONFIGURATION)
        {
            self.devDict = [NSMutableDictionary dictionaryWithCapacity:1];
        }
    }          
    else if ([elementName isEqualToString:@"motionDetectionAlarmShoot"])
    {
        element_id = ELEMENT_motionDetectionAlarmShoot;
        if (cmd_session == CMDSESSION_GETVSALARMCONFIGURATION)
        {
            self.devDict = [NSMutableDictionary dictionaryWithCapacity:1];
        }
    }      	
	else if ([elementName isEqualToString:@"outputChannelNumber"])//motionDetectionAlarmOutput
    {
        element_id = ELEMENT_outputChannelNumber;
    }
    else if ([elementName isEqualToString:@"alarmState"])
    {
        element_id = ELEMENT_alarmState;
    }
    //Parse Device Data 
	else if ([elementName isEqualToString:@"device"])
	{
		element_id = ELEMENT_device;
		
		//new device
		self.devDict = [NSMutableDictionary dictionary];
		
	}
	else if ([elementName isEqualToString:@"type"])
	{
		element_id = ELEMENT_type;
	}
	else if ([elementName isEqualToString:@"name"])//requestdevicedata, getVS
	{
		element_id = ELEMENT_name;
	}
	else if ([elementName isEqualToString:@"areaId"])
	{
		element_id = ELEMENT_areaId;
	}
	else if ([elementName isEqualToString:@"currentAreaId"])
	{
		element_id = ELEMENT_currentAreaId;
	}	
	else if ([elementName isEqualToString:@"id"])
	{
		element_id = ELEMENT_id;
	}
	else if ([elementName isEqualToString:@"vsId"])
	{
		element_id = ELEMENT_vsId;
	}
	else if ([elementName isEqualToString:@"deviceId"])
	{
		element_id = ELEMENT_deviceId;
	}
	else if ([elementName isEqualToString:@"videoId"])
	{
		element_id = ELEMENT_videoId;
	}
	else if ([elementName isEqualToString:@"disabled"])
	{
		element_id = ELEMENT_disabled;
	}
	else if ([elementName isEqualToString:@"online"])
	{
		element_id = ELEMENT_online;
	}

}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {     
	
	//NSLog(@"didEndElement %@ %@ %@",elementName,namespaceURI,qName);
	
	if ([elementName isEqualToString:@"device"] && cmd_session == CMDSESSION_REQUESTDEVICEDATA)
	{
		//check this device type
		NSString *type = [self.devDict valueForKey:@"type"];
		if ([type isEqualToString:@"AREA"])
		{
			//NSLog(@"parser AREA");
            BOOL find = NO;
			for (NSDictionary *dict in self.wxx_areaList)
			{
				NSString *area_name = [dict valueForKey:@"name"];
				NSString *area_id = [dict valueForKey:@"id"]; 
				if ([area_name isEqualToString:[self.devDict valueForKey:@"name"]] &&
					[area_id isEqualToString:[self.devDict valueForKey:@"id"]])
				{
					find = YES;
					break;
				}
			}
			
			if (find == NO)
			[self.wxx_areaList addObject:self.devDict];
		}
		else if ([type isEqualToString:@"CAM"])
		{
			//NSLog(@"parser CAM");
            BOOL find = NO;
			for (NSDictionary *dict in self.wxx_cameraList)
			{
				NSString *cam_name = [dict valueForKey:@"name"];
				NSString *cam_id = [dict valueForKey:@"id"]; 
				if ([cam_name isEqualToString:[self.devDict valueForKey:@"name"]] &&
					[cam_id isEqualToString:[self.devDict valueForKey:@"id"]])
				{
					find = YES;
					break;
				}
			}
			
			if (find == NO)
			[self.wxx_cameraList addObject:self.devDict];
		}
		else if ([type isEqualToString:@"VS"])
		{
			//NSLog(@"parser VS");
            BOOL find = NO;
			for (NSDictionary *dict in vsList)//check duplicant
			{
				NSString *vs_name = [dict valueForKey:@"name"];
				NSString *vs_id = [dict valueForKey:@"id"]; 
				if ([vs_name isEqualToString:[self.devDict valueForKey:@"name"]] &&
					[vs_id isEqualToString:[self.devDict valueForKey:@"id"]])
				{
					find = YES;
					break;
				}
			}
			
			if (find == NO) 
			[self.vsList addObject:self.devDict];
		}
	}
	else if ([elementName isEqualToString:@"permission"] && cmd_session == CMDSESSION_GETUSER)
	{
		[self.userPermissionArray addObject:self.devDict];
	}
    else if ([elementName isEqualToString:@"gpio"] && cmd_session == CMDSESSION_GETVS)
    {
        NSNumber * direction = [devDict valueForKey:@"direction"];
        if (direction)
        {
            if([direction intValue] == 2)//output
            [self.gpio_out_array addObject:self.devDict];
        }
        sub_xml_session = 0;
    }
    else if (cmd_session == CMDSESSION_GETVSALARMCONFIGURATION)
    {
        if (!camera_alarm_got)
        {
            if ([elementName isEqualToString:@"cameraAlarm"])
            {
                NSString *cameraNumber = [self.camera_alarm_configuration valueForKey:@"cameraNumber"];
                NSString *videoId  = [cur_cam_dict valueForKey:@"videoId"];
                if (cameraNumber.intValue == videoId.intValue)
                {
                    camera_alarm_got = YES;
                }
            }
            else if ([elementName isEqualToString:@"motionDetectionAlarmOutput"])
            {
                NSMutableArray * motionDetectionAlarmOutput =  [self.camera_alarm_configuration valueForKey:@"motionDetectionAlarmOutput"];
                [motionDetectionAlarmOutput addObject:self.devDict];
            }
            else if ([elementName isEqualToString:@"motionDetectionAlarmRecord"])
            {
                NSMutableArray * motionDetectionAlarmRecord=  [self.camera_alarm_configuration valueForKey:@"motionDetectionAlarmRecord"];
                [motionDetectionAlarmRecord addObject:self.devDict];            
            }
            else if ([elementName isEqualToString:@"motionDetectionAlarmShoot"])
            {
                NSMutableArray * motionDetectionAlarmShoot=  [self.camera_alarm_configuration valueForKey:@"motionDetectionAlarmShoot"];
                [motionDetectionAlarmShoot addObject:self.devDict];            
            }
        }
    }
    
    
	element_id = 0;
	
}

// This method is called by the parser when it find parsed character data ("PCDATA") in an element. The parser is not
// guaranteed to deliver all of the parsed character data for an element in a single invocation, so it is necessary to
// accumulate character data until the end of the element is reached.
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	
	//NSLog(@"foundCharacters %@", string);
	
	if (element_id == ELEMENT_result)//result element
	{
		if (result_code == 0)
			self.result_errorStr = nil;
		else {
			self.result_errorStr = [NSString stringWithString:string];
		}
	}
    ////
	else if (element_id == ELEMENT_sessionId && cmd_session == CMDSESSION_USERLOGIN)//save session id for UserLogin
	{
		self.session_id = string;
	}
	else if (element_id == ELEMENT_domainId && cmd_session == CMDSESSION_USERLOGIN)//save domain id for UserLogin
	{
		self.domain_id = string;
	}
	//GetVAU
	else if (element_id == ELEMENT_natIp && cmd_session == CMDSESSION_GETVAU)
    {
        [VAUIPAddr release];
         VAUIPAddr = [string retain];
    }
    else if (element_id == ELEMENT_natPort && cmd_session == CMDSESSION_GETVAU)
    {
        VAUPort = string.intValue;
    }
    else if (element_id == ELEMENT_natRtspPort && cmd_session == CMDSESSION_GETVAU)
    {
        RtspPort = string.intValue;
    }
    //QueryVsRoute
	else if (element_id == ELEMENT_natIp && cmd_session == CMDSESSION_QUERYVSROUTE)    
    {
        [cur_vs_dict setValue:string forKey:@"csg_IP"];//getVSAlarm
    }
	else if (element_id == ELEMENT_natPort && cmd_session == CMDSESSION_QUERYVSROUTE)    
    {
        [cur_vs_dict setValue:string forKey:@"csg_Port"];//getVSAlarm
    }
    //GetVS
    else if (element_id == ELEMENT_loginUsername && cmd_session == CMDSESSION_GETVS)
    {
        [cur_vs_dict setValue:string forKey:@"vsLoginUsername"];
    }
    else if (element_id == ELEMENT_loginPassword && cmd_session == CMDSESSION_GETVS)
    {
        [cur_vs_dict setValue:string forKey:@"vsLoginPassword"];
    }
    else if (element_id == ELEMENT_managementPort && cmd_session == CMDSESSION_GETVS)
    {
        [cur_vs_dict setValue:string forKey:@"vsPort"];
    }
    else if (element_id == ELEMENT_vendor && cmd_session == CMDSESSION_GETVS)
    {
        [cur_vs_dict setValue:string forKey:@"vendor"];
    }
    else if (element_id == ELEMENT_name && sub_xml_session == SUBSESSION_GETVS_GPIO)
    {
        [self.devDict setValue:string forKey:@"name"];
    }
    else if (element_id == ELEMENT_normalState && sub_xml_session == SUBSESSION_GETVS_GPIO)
    {
        [self.devDict setValue:string forKey:@"normalState"];
    }
    else if (element_id == ELEMENT_channelNumber && sub_xml_session == SUBSESSION_GETVS_GPIO)
    {
        [self.devDict setValue:string forKey:@"channelNumber"];
    }
    else if (element_id == ELEMENT_direction && sub_xml_session == SUBSESSION_GETVS_GPIO)
    {
        [self.devDict setValue:string forKey:@"direction"];
    }
    //GetVSAlarmConfiguration
    else if (element_id == ELEMENT_cameraNumber && cmd_session == CMDSESSION_GETVSALARMCONFIGURATION)
    {
        if(!camera_alarm_got)
            [self.camera_alarm_configuration setValue:string forKey:@"cameraNumber"];
    }
    else if (element_id == ELEMENT_motionDetectionAlarmEnabled && cmd_session == CMDSESSION_GETVSALARMCONFIGURATION)
    {
        if(!camera_alarm_got)
            [self.camera_alarm_configuration setValue:string forKey:@"motionDetectionAlarmEnabled"];//true/false
    }
    else if (element_id == ELEMENT_motionDetectionAlarmTime && cmd_session == CMDSESSION_GETVSALARMCONFIGURATION)
    {
        if(!camera_alarm_got)
            [self.camera_alarm_configuration setValue:string forKey:@"motionDetectionAlarmTime"];//0000-0000
    }
    else if (element_id == ELEMENT_motionDetectionFrequency && cmd_session == CMDSESSION_GETVSALARMCONFIGURATION)
    {
        if(!camera_alarm_got)
            [self.camera_alarm_configuration setValue:string forKey:@"motionDetectionFrequency"];//10
    }
    else if (element_id == ELEMENT_motionDetectionSensitivity && cmd_session == CMDSESSION_GETVSALARMCONFIGURATION)
    {
        if(!camera_alarm_got)
            [self.camera_alarm_configuration setValue:string forKey:@"motionDetectionSensitivity"];//0
    }
    else if (element_id == ELEMENT_outputChannelNumber && sub_xml_session == SUBSESSION_GETVSALARM_MITIONDETECTIONALARMOUTPUT)
    {
        if(!camera_alarm_got)
            [self.devDict setValue:string forKey:@"outputChannelNumber"];
    }
    else if (element_id == ELEMENT_alarmState && sub_xml_session == SUBSESSION_GETVSALARM_MITIONDETECTIONALARMOUTPUT)
    {
        if(!camera_alarm_got)
            [self.devDict setValue:string forKey:@"alarmState"];
    }
    else if (element_id == ELEMENT_motionDetectionAlarmRecord || element_id == ELEMENT_motionDetectionAlarmShoot)
    {
        if(!camera_alarm_got)
            [self.devDict setValue:string forKey:@"channelNumber"];
    }
	//GetUser
    //NOTE: either roleId or roleName should work
	else if (element_id == ELEMENT_roleId && cmd_session == CMDSESSION_GETUSER)
	{
		//[self.devDict setValue:string forKey:@"roleId"];
	}
	else if (element_id == ELEMENT_roleName && cmd_session == CMDSESSION_GETUSER)
	{
		[self.devDict setValue:string forKey:@"roleName"];
	}
	else if (element_id == ELEMENT_areaId && cmd_session == CMDSESSION_GETUSER)
	{
        //NSLog(@"getuser: areaId %@", string);
        if (![string isEqualToString:@"<"] && ![string isEqualToString:@">"])
        {
            [self.devDict setValue:string forKey:@"areaId"]; //<ROOT>
        }
	}
	//GetRole
	else if (element_id == ELEMENT_command && cmd_session == CMDSESSION_GETROLE)
	{
		if ([string isEqualToString:@"ControlPTZ"])
		{
            NSMutableDictionary *roledict = [self.userPermissionArray objectAtIndex:getQueryIndex];
			[roledict setValue:[NSNumber numberWithBool:YES] forKey:@"ControlPTZ"];
		}
        else if ([string isEqualToString:@"SetVsAlarmConfiguration"])
        {
            NSMutableDictionary *roledict = [self.userPermissionArray objectAtIndex:getQueryIndex];
			[roledict setValue:[NSNumber numberWithBool:YES] forKey:@"SetVsAlarmConfiguration"];
        }
        else if ([string isEqualToString:@"GetVsAlarmConfiguration"])
        {
            NSMutableDictionary *roledict = [self.userPermissionArray objectAtIndex:getQueryIndex];
			[roledict setValue:[NSNumber numberWithBool:YES] forKey:@"GetVsAlarmConfiguration"];
        }
	}
    else if(element_id == ELEMENT_hasAllPrivilege && cmd_session == CMDSESSION_GETROLE)
    {
        if ([string isEqualToString:@"true"])
        {
            NSMutableDictionary *roledict = [self.userPermissionArray objectAtIndex:getQueryIndex];
			[roledict setValue:[NSNumber numberWithBool:YES] forKey:@"hasAllPrivilege"];
        }
    }
    //RequestDeviceData
	else if (element_id == ELEMENT_name && cmd_session == CMDSESSION_REQUESTDEVICEDATA)
	{
		//NSLog(@"parse name %@", string);
		[self.devDict setValue:string forKey:@"name"];
	}
	else if (element_id == ELEMENT_type && cmd_session == CMDSESSION_REQUESTDEVICEDATA)
	{
		//NSLog(@"parse type %@", string);
		[self.devDict setValue:string forKey:@"type"];
	}
	else if (element_id == ELEMENT_id && cmd_session == CMDSESSION_REQUESTDEVICEDATA)
	{
		//NSLog(@"parse id %@", string);
		
		[self.devDict setValue:string forKey:@"id"];
	}
	else if (element_id == ELEMENT_areaId && cmd_session == CMDSESSION_REQUESTDEVICEDATA)
	{
		//NSLog(@"parse areaId %@", string);
		
		[self.devDict setValue:string forKey:@"areaId"];
	}
	else if (element_id == ELEMENT_currentAreaId && cmd_session == CMDSESSION_REQUESTDEVICEDATA)
	{
		[self.devDict setValue:string forKey:@"currentAreaId"];
	}
	else if (element_id == ELEMENT_vsId && cmd_session == CMDSESSION_REQUESTDEVICEDATA)
	{
		//NSLog(@"parse vsId %@", string);
		[self.devDict setValue:string forKey:@"vsId"];
	}
	else if (element_id == ELEMENT_deviceId && cmd_session == CMDSESSION_REQUESTDEVICEDATA)
	{
		//NSLog(@"parse deviceId %@", string);

		[self.devDict setValue:string forKey:@"deviceId"];
	}
	else if (element_id == ELEMENT_videoId && cmd_session == CMDSESSION_REQUESTDEVICEDATA)
	{
		// NSLog(@"parse videoId %@", string);
		[self.devDict setValue:string forKey:@"videoId"];
	}
	else if (element_id == ELEMENT_disabled && cmd_session == CMDSESSION_REQUESTDEVICEDATA)
	{
		[self.devDict setValue:string forKey:@"disabled"];
	}
	else if (element_id == ELEMENT_online && cmd_session == CMDSESSION_REQUESTDEVICEDATA)
	{
		[self.devDict setValue:string forKey:@"online"];
	}
	
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	
	NSLog(@"parseErrorOccurred");
}

@end