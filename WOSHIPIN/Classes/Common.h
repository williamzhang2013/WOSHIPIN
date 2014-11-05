//
//  Common.h
//  EyeRecording
//
//  Created by MKevin on 4/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/////////////////////////////////////////////////////////////////////
//                             Macro                               //
/////////////////////////////////////////////////////////////////////
#define SCREEN_WIDTH             ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT            ([UIScreen mainScreen].bounds.size.height)
#define IOS_VERSION              [[[UIDevice currentDevice] systemVersion] floatValue]
#define CURR_SYS_VER             ([[UIDevice currentDevice] systemVersion])
#define CURR_LANG                ([[NSLocale preferredLanguages] objectAtIndex:0])


/////////////////////////////////////////////////////////////////////
//                        extern variable                          //
/////////////////////////////////////////////////////////////////////
extern NSString * const RCRecordingFileExtension;
extern int const RCRecordingFileExtensionLength;

extern NSString * const RCRecordingFileDatePartFormat;
extern int const RCRecordingFileDatePartFormatLength;

extern const NSString *kPort_CMS ;

extern int g_ptzPort;
extern int g_rtspPort;
extern int g_streamType;
extern int g_CameraControlLength1;
extern int g_CameraControlLength2;

extern BOOL g_wxx_loginDone[];

#define PORTAL_ENTRY_NUM 3

enum {
    LOG_NETWORK_FAIL	=	-2,
    LOG_RESULTCODE_ERROR =	-1,
    LOG_LOGIN				,
    LOG_REQUESTDATA			,
    LOG_LOGOUT				,
    LOG_GETUSER             ,
    LOG_GETROLE             ,
    LOG_GETVAU  ,
    LOG_GETVS  ,
    LOG_GETCAMERA,
    LOG_GETVSALARMCONFIGURATION,
    LOG_SETVSALARMCONFIGURATION,
    LOG_QUERYVSROUTE    ,
};

@protocol MCUEngineDelegate

-(void)onLoggingProgressReport: (int) state param:(int) para;

@end



@interface MCUEngine : NSObject 
{

	//NSString * _wxx_user[PORTAL_ENTRY_NUM];
	//NSString * _wxx_psw[PORTAL_ENTRY_NUM];
	
	NSMutableArray *_wxx_areaList[PORTAL_ENTRY_NUM];
	NSMutableArray *_wxx_cameraList[PORTAL_ENTRY_NUM];
	//NSMutableArray *_wxx_userPermission[PORTAL_ENTRY_NUM];//GetUser  , array of dictionary "roleName", "areaId", "ControlPTZ" , "SetVsAlaramConfiguration"
	
	//these are prviately used during loggin and data parsing process
	//http connection and access
	NSURLConnection *VSFeedConnection;
    NSMutableData *VSData;	
	int cur_entry;
	
	int cmd_session;
    int sub_xml_session;
	unsigned char element_id;
	NSInteger result_code; //command result code. 0: ok ; others fail
	NSString *result_errorStr;
    
    
    //these two fields will be used by many commands
	NSString *session_id;
    NSString *domain_id;
	
	NSMutableDictionary *devDict; //
    
	NSMutableArray *vsList;// VS list of all portal entries
	NSMutableArray *userPermissionArray;//getUser/GetRole  array of dictionary "roleName", "areaId", "ControlPTZ" , "SetVsAlaramConfiguration"
    
    
	NSObject<MCUEngineDelegate> *_delegate;
	
	NSArray *arrayCMSIP;
	//NSArray *arrayVAUIP;
	
    int getQueryIndex;
    NSString *userName_login;
    
    NSString * VAUIPAddr;
    int VAUPort;//??? where it is used?
    int RtspPort;
    
    NSMutableDictionary *cur_vs_dict;   //point to vslist
    NSDictionary *cur_cam_dict;     //point to camlist

    NSMutableArray *gpio_out_array;     //temp
    
    NSMutableDictionary *camera_alarm_configuration;//one of cameraAlaram of GetVSAlaramConfiguration
    BOOL camera_alarm_got;//only need to parse one cameraAlarm from multiple vsalarmconfig list
    //NSMutableArray *vs_alarm_config;
}


@property (nonatomic, retain) NSURLConnection *VSFeedConnection;
@property (nonatomic, retain) NSMutableData *VSData;
@property (nonatomic, retain) NSMutableArray *vsList, *userPermissionArray,*gpio_out_array;
@property (nonatomic, retain) NSMutableDictionary *devDict, *camera_alarm_configuration;
@property (nonatomic, copy) NSString *session_id, *domain_id, *userName_login;
@property (nonatomic, copy) NSString *result_errorStr;

@property (readonly) int RtspPort;
@property (readonly) int VAUPort;
//@property (readonly) NSString *VAUIPAddr;
@property (assign, readwrite) NSObject<MCUEngineDelegate> *delegate;

+(MCUEngine*)sharedObj;

-(void) load;
-(void) unload;


-(NSString*)getCMSIPAddr;
+(void)setCMSIPAddr:(NSString *)cms_ip;
+(NSString *)getCMSPort;
+(void)setCMSPort:(NSString *)cms_port;

-(NSString*)getVAUIPAddr;
//+(int)getIPSettingIndex;
//+(void)setIPSettingIndex:(int)idx;

+(NSString*)calcMD5:(NSString*)instr;

+(NSString*)getLoginUserName:(int)entry_id;
+(NSString*)getLoginPassword:(int)entry_id;
+(BOOL)getLoginAccountSaved:(int)entry_id;
+(void)setLoginUserName:(NSString*)s entry:(int)entry_id;
+(void)setLoginPassword:(NSString*)s entry:(int)entry_id;
+(void)setLoginAccountSaved:(BOOL)b entry:(int)entry_id;
-(NSArray*)getCameraList:(int)entry_id;

-(void) entryLogin: (int)entry_idx UserName:(NSString*)userName Psw:(NSString*)psw;

-(NSString *)findRootIdOfEntry:(int)entry_idx  entry_key:(NSString*)str;
-(NSArray *)filterArealistOfEntry:(int)entry_idx  withAreaId:(NSString*)_areaid;
-(NSArray *)filterSublistOfEntry:(int)entry_idx  withAreaId:(NSString*)_areaid;
-(NSDictionary*)queryVSObj:(NSString *)vsId;
-(NSArray *)filterCameras: (int)entry_idx byVsId: (NSString*)vsId;
-(NSString *)queryCameraName:(int)entry_idx withVsId: (NSString*)_vsId withVideoId:(NSString *)_videoId;


- (void)entryQueryVSProcess: (NSMutableDictionary *)dict;
- (void)getVsAlarmConfiguration:(NSDictionary *)dict;
- (void)setVsAlarmConfiguration:(NSDictionary *)dict  config:(NSString *)_cfg;

+ (BOOL)isCurrentSystemOSVersionAbove70;
@end
