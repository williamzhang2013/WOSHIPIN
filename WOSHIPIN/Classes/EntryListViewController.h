//
//  EntryListViewController.h
//  VISS_gx3
//
//  Created by Li Xinghua on 11-8-27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Common.h"


@interface EntryListViewController : UITableViewController <MCUEngineDelegate>{
	NSArray *entryList;
	NSArray *filterKeyList;
	NSArray *entryImageList;
	BOOL logging;
	int selCellRow;
	
	NSString * loggingStatus;
}

@property (nonatomic, copy) NSString *loggingStatus;
@end
