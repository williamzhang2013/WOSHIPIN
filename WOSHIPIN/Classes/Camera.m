//
//  Camera.m
//  Eeye
//
//  Created by Near on 10-5-5.
//  Copyright 2010 Exmart. All rights reserved.
//

#import "Camera.h"
#import "Common.h"

static unsigned char HEX2D(h)
{
	if (h <= '9' && h >= '0')
	{
		return h - '0';
	}
	else if (h<='F' && h>='A')
	{
		return h - 'A' + 10;
	}
	else if (h<='f' && h>='a')
	{
		return h - 'a' + 10;
	}
	else {
		return 0;
	}
	
}


@implementation Camera
/*@synthesize puName = _puname;
@synthesize rtspURL = _rtspurl;
@synthesize streamType = streamType_;
@synthesize puid_ChannelNo = puid_ChannelNo_;
@synthesize ptzPort = _ptzport;
@synthesize ptzIP = _ptzIP;
@synthesize rtspPort = _rtspPort, rtspIP= _rtspIP;
 */

@dynamic puName;
@dynamic rtspIP;
@dynamic rtspPort;
@dynamic streamType;
@dynamic puid_ChannelNo;
@dynamic ptzPort;
@dynamic ptzIP;
@dynamic rtspURL;
@dynamic bControlPtz;
@dynamic bSetVsAlaramConfiguration;

#pragma mark -
#pragma mark Initialize



/* 
- (id)initWithFullDescription:(NSString*)urllink  withStreamType :(int) type
{
	if (self = [super init]) 
	{
		NSArray * array = [urllink componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"?&"]];
		NSString *rtspstr;
		for (NSString * object in array) 
		{
			if ([object hasPrefix:@"rtsp://"]) 
			{
				rtspstr = object ;
			}
			else if ([object hasPrefix:@"PuId-ChannelNo="]) 
			{
				puid_ChannelNo_ = [[object substringFromIndex:15] copy];
			}
			else if ([object hasPrefix:@"StreamingType="])
			{
				//streamType_ = [[object substringFromIndex:14] intValue];;
			}
			else if ([object hasPrefix:@"VauPtzAdd="])
			{
				_ptzIP = [[object substringFromIndex:10] copy];
			}
			else if ([object hasPrefix:@"VauPtzPort="])
			{
				_ptzport = [[object substringFromIndex:11] intValue];
			}
			else if ([object hasPrefix:@"VauRtspAdd="])
			{
				_rtspIP = [[object substringFromIndex:11] copy]; 
			}
			else if ([object hasPrefix:@"VauRtspPort="])
			{
				_rtspPort = [[object substringFromIndex:12] intValue];
			}
			
			else if (([object hasPrefix:@"PuName="]))
			{
				//_puname = [[object substringFromIndex:7] copy];
				
				//xinghua 20101227
				NSString *puname = [object substringFromIndex:7];
				//xinghua 20101227, PuName coded in UTF-8 or possibly %HEX%HEX%HEX 
				
				char *s = (char*)[puname UTF8String];
				char d[128] = {0};
				int i,j;
				for (i=0,j=0;s[i]!='\0';)
				{
					if (s[i] == '%')
					{
						d[j] = HEX2D(s[i+1]) * 16 + HEX2D(s[i+2]);
						i += 3;
						j ++;
					}
					else
					{
						d[j] = s[i];
						i ++;
						j ++;
					}
				}
				_puname = [[NSString stringWithUTF8String:(const char*)d] copy];
				
			}
			
		}
		streamType_ = type;
		_rtspurl = [[NSString  alloc] initWithFormat:@"%@?PuId-ChannelNo=%@&StreamingType=%d",rtspstr,puid_ChannelNo_,streamType_];
		
		
	}
	return self;
}
*/

-(id)initWithCAMDict:(NSDictionary*)dict
{
	if (self = [super init]) 
	{
        cam_dict = [dict retain];
        
#if 0
        camera.ptzIP = /*(NSString*)kIPAddress_VAU*/ [[MCUEngine sharedObj]getVAUIPAddr];
		camera.puName = [dict valueForKey:@"name"];;
		camera.ptzPort = g_ptzPort;
		camera.puid_ChannelNo = [NSString stringWithFormat:@"%@-%@", [dict valueForKey:@"PuId"],[dict valueForKey:@"videoId"] ];
		camera.streamType = g_streamType;
		camera.rtspPort = /*g_rtspPort*/[MCUEngine sharedObj].RtspPort;
		camera.rtspIP = /*(NSString*)kIPAddress_VAU*/[[MCUEngine sharedObj] getVAUIPAddr];
#endif
    }    
    return self;
}


-(NSString*)rtspIP
{
    return [[MCUEngine sharedObj] getVAUIPAddr];
}

-(int)rtspPort
{
    return [MCUEngine sharedObj].RtspPort;
}


-(NSString*)ptzIP
{
    return [[MCUEngine sharedObj] getVAUIPAddr];
}

-(int)ptzPort
{
    return g_ptzPort;
}

-(NSString*)puName
{
    return [cam_dict valueForKey:@"name"];
}

-(NSString *)puid_ChannelNo
{
    NSDictionary *vs_dict = [[MCUEngine sharedObj] queryVSObj:[cam_dict valueForKey:@"vsId"]];
    if (vs_dict== nil) return nil;
    return [NSString stringWithFormat:@"%@-%@", [vs_dict valueForKey:@"deviceId"],[cam_dict valueForKey:@"videoId"] ];
}

-(int)streamType
{
    return g_streamType; 
}

-(NSString *)rtspURL
{
    //return [NSString stringWithFormat:@"rtsp://%@:%d/server?PuId-ChannelNo=%@&StreamingType=%d",self.rtspIP,self.rtspPort,self.puid_ChannelNo,self.streamType];
    
    NSNumber * portal_entry = [cam_dict valueForKey:@"portal_entry"];
    NSString * loginUsername = [MCUEngine getLoginUserName:[portal_entry intValue]];
    NSString * loginPassword = [MCUEngine getLoginPassword:[portal_entry intValue]];
    
    return [NSString stringWithFormat:@"rtsp://%@:%d/service?UserId=%@&UserPassword=%@&PuId-ChannelNo=%@&StreamingType=%d",self.rtspIP,self.rtspPort,loginUsername,[MCUEngine calcMD5:loginPassword],self.puid_ChannelNo,self.streamType];
}

-(BOOL)bControlPtz
{
    NSNumber * bb = [cam_dict valueForKey:@"ControlPtz"];
    if (bb) 
        return YES;
    else 
        return NO;
}

-(BOOL)bSetVsAlaramConfiguration
{
    NSNumber * bb = [cam_dict valueForKey:@"SetVSAlaramConfiguration"];
    if (bb) 
        return YES;
    else 
        return NO;    
}

- (void)dealloc{
	
	[cam_dict release];
    [super dealloc];
}

@end
