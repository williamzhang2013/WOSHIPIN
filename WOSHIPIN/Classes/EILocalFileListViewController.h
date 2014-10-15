//
//  EILocalFileListViewController.h
//  EyeRecording
//
//  Created by MKevin on 4/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface EILocalFileListViewController : UITableViewController 
  <UISearchDisplayDelegate, UISearchBarDelegate>
{
	NSMutableArray	*listContent;			// The master content.
	NSMutableArray	*filteredListContent;	// The content filtered as a result of a search.
	
	// The saved state of the search UI if a memory warning removed the view.
  NSString		*savedSearchTerm;
  NSInteger		savedScopeButtonIndex;
  BOOL			searchWasActive;
	
	MPMoviePlayerController *moviePlayer;
}


- (void)setArrayToDisplay:(NSArray *)array;

@property (nonatomic, retain) NSMutableArray *listContent;
@property (nonatomic, retain) NSMutableArray *filteredListContent;

@property (nonatomic, copy) NSString *savedSearchTerm;
@property (nonatomic) NSInteger savedScopeButtonIndex;
@property (nonatomic) BOOL searchWasActive;

@property (readwrite, retain) MPMoviePlayerController *moviePlayer;
@end
