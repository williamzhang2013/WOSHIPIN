//
//  AlarmXXXViewController.h
//  VISS_GX
//
//  Created by Li Xinghua on 12-11-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlarmXXXViewController : UITableViewController
{
    NSDictionary *cur_camera;
    NSArray *all_channelinfos;  //avaialbe alarm config inputs
    int mode; //0: AlarmOutput 1: AlarmRecord/AlarmShoot
}

- (id)initForAlarmOutput: (NSArray *)_alarmxxx ;
- (id)initForAlarmRecord: (NSArray *)_alarmxxx;
- (id)initForAlarmShoot: (NSArray *)_alarmxxx ;

@end
