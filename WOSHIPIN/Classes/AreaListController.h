//
//  AreaListController.h
//  VISS
//
//  Created by Li Xinghua on 11-5-4.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


/*
 total areaList 
 
 Main area: array of Dictionary - area_index
								- subarea_array : 
 Sub area:								array of Dictionary  - area_index	
 												 - sub2area_array : 
 Sub2 arae:														array of area_index	
								
 
 */


@interface AreaListController : UITableViewController {
	
	NSArray *areaList;	//main area
	NSArray *subareaList;	//sub area
	
}

@property (nonatomic, retain) NSArray *areaList;
@property (nonatomic, retain) NSArray *subareaList;

//-(void) refreshAreaTreeList;

@end
