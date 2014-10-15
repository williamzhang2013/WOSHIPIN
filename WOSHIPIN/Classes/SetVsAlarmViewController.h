//
//  SetVsAlarmViewController.h
//  VISS_GX
//
//  Created by Li Xinghua on 12-11-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Common.h"

@interface SetVsAlarmViewController : UITableViewController<MCUEngineDelegate>
{
    NSDictionary *curCamDict;
    //BOOL setVSIng;
    UIBarButtonItem * applyBtn; 
    UISwitch * switchCtl;
    //NSMutableDictionary * vsalarm_config_copy;
    
    /*unsigned char alarmtime_start_hour;
    unsigned char alarmtime_start_min;
    unsigned char alarmtime_end_hour;
    unsigned char alarmtime_end_min;
    */
    
    unsigned char alarmtime_i[4];//starthour, startmin, endhour, endmin
    
    NSMutableArray *mdAlarmOutputCfg;  
    NSMutableArray *mdAlarmRecordShootCfg;
}

- (id)initWithCamera:(NSDictionary*)dict;

@end
