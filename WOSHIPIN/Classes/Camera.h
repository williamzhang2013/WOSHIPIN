//
//  Camera.h
//  Eeye
//
//  Created by Near on 10-5-5.
//  Copyright 2010 Exmart. All rights reserved.
//

#import <Foundation/Foundation.h>

//Camera
//	Camera object that return from webservice
//
@interface Camera : NSObject {
    NSDictionary *cam_dict;
    
    /*NSString *_puname;
    NSString *_rtspurl;//rstpURL address 
	NSString *_ptzIP;	 //PTZ IP
	unsigned int _ptzport;
	NSString *_rtspIP;
	unsigned int _rtspPort;
	
    int streamType_;
    NSString * puid_ChannelNo_;*/
}

@property (nonatomic, readonly)NSString *puName;
@property (nonatomic, readonly)NSString *rtspURL;

@property (nonatomic, readonly) int streamType;
@property (nonatomic, readonly)NSString * puid_ChannelNo;
@property (nonatomic, readonly) int ptzPort;
@property (nonatomic, readonly)NSString *ptzIP;
@property (nonatomic, readonly) int rtspPort;
@property (nonatomic, readonly)NSString *rtspIP;
@property (nonatomic, readonly)BOOL bControlPtz;
@property (nonatomic, readonly)BOOL bSetVsAlaramConfiguration;

//- (id)initWithFullDescription:(NSString*)urllink withStreamType:(int )type;
-(id)initWithCAMDict:(NSDictionary*)dict;

@end
