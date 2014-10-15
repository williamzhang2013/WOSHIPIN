//
//  AlarmTimeCfgViewController.h
//  VISS_GX
//
//  Created by Li Xinghua on 12-11-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlarmTimeCfgViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource>
{
    IBOutlet UIPickerView * hmPicker;
    IBOutlet UITableView * atableView;
    
    unsigned char * alarmtime_i;
    
    int row_selected ;
}

- (id)initWithAlarmTime:(unsigned char*)t;
@end
