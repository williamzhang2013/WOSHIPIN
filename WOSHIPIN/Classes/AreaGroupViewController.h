//
//  AreaGroupViewController.h
//  VISS_gx3
//
//  Created by Li Xinghua on 11-8-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AreaGroupViewController : UITableViewController {
	NSArray *mainAreaList;
	NSMutableArray *subDevicesList;
}

@property (readwrite,retain) NSArray *mainAreaList;
//@property (readwrite,retain) NSMutableArray *subDevicesList;

@end
