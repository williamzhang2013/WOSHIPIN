//
//  DeviceListController.h
//  VISS
//
//  Created by Li Xinghua on 11-4-26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DeviceListController : UITableViewController {

	NSArray *camList;//xinghua 20110723. This could be array of cameras or areas
}



@property (nonatomic, retain) NSArray *camList;

@end
