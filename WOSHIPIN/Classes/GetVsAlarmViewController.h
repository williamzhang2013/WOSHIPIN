//
//  GetVsAlarmViewController.h
//  VISS_GX
//
//  Created by Li Xinghua on 12-11-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Common.h"

@interface GetVsAlarmViewController : UITableViewController <MCUEngineDelegate>
{
    NSDictionary *curCamDict;
    BOOL getVSIng;
    UIBarButtonItem * setvsBtn; 
}

- (id)initWithCamera:(NSDictionary*)dict;

@end
