//
//  SearchCamViewController.h
//  VISS
//
//  Created by Li Xinghua on 11-5-4.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SearchCamViewController : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate>
{
	NSMutableArray *filteredListContent;
	NSMutableArray *allCameraList;
}
@property (nonatomic, retain, readonly) NSMutableArray *filteredListContent;
@property (nonatomic, retain) NSMutableArray *allCameraList;
@end
