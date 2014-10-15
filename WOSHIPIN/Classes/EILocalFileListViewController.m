//
//  EILocalFileListViewController.m
//  EyeRecording
//
//  Created by MKevin on 4/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EILocalFileListViewController.h"
#import "FileAttribute.h"

#import "RecordingCenter.h"
#import "EIFilePlayViewController.h"

@implementation EILocalFileListViewController

@synthesize listContent, filteredListContent, savedSearchTerm, savedScopeButtonIndex, searchWasActive;
@synthesize moviePlayer;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
  //NSLog((@"%s %s:%d"), __func__, __FILE__, __LINE__);
  self.title = @"录像";
  
  if (self.tableView.editing == NO) {
    UIBarButtonItem * editItem = [[UIBarButtonItem alloc] 
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(beginEditing)];
    
    self.navigationItem.rightBarButtonItem = editItem;
    [editItem release];
  } else {
    UIBarButtonItem * doneItem = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(endEditing)];
    self.navigationItem.rightBarButtonItem = doneItem;
    [doneItem release];
  }
  
  
  // create a filtered list that will contain products for the search results table.
  self.filteredListContent = [NSMutableArray arrayWithCapacity:[self.listContent count]];
  
  // restore search settings if they were saved in didReceiveMemoryWarning.
  if (self.savedSearchTerm)
  {
    [self.searchDisplayController setActive:self.searchWasActive];
    [self.searchDisplayController.searchBar setSelectedScopeButtonIndex:self.savedScopeButtonIndex];
    [self.searchDisplayController.searchBar setText:savedSearchTerm];
    
    self.savedSearchTerm = nil;
  }
  
  [self.tableView reloadData];
  self.tableView.scrollEnabled = YES;
}

- (void)setArrayToDisplay:(NSArray *)array {
  self.listContent = 
  [NSMutableArray arrayWithArray:[array sortedArrayUsingSelector:@selector(createTimeDESCCompare:)]];
}


- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  //NSLog((@"%s %s:%d"), __func__, __FILE__, __LINE__);
  [self setArrayToDisplay:[RecordingCenter recordingFiles]];
  [self.tableView reloadData];
}


/*
 - (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 }
 */
/*
 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */
/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */
/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  // Return the number of sections.
  return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  // Return the number of rows in the section.
  /*
   If the requesting table view is the search display controller's table view, return the count of the filtered list, otherwise return the count of the main list.
   */
  if (tableView == self.searchDisplayController.searchResultsTableView)
  {
    return [self.filteredListContent count];
  }
  else
  {
    return [self.listContent count];
  }
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *kCellID = @"cellID";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
  if (cell == nil)
  {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellID] autorelease];
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
  /*
   If the requesting table view is the search display controller's table view, configure the cell using the filtered content, otherwise use the main list.
   */
  FileAttribute *object = nil;
  if (tableView == self.searchDisplayController.searchResultsTableView)
  {
    object = [self.filteredListContent objectAtIndex:indexPath.row];
  }
  else
  {
    object = [self.listContent objectAtIndex:indexPath.row];
  }
  
  cell.textLabel.text = object.cameraName;
  cell.detailTextLabel.text = [NSString stringWithFormat:@"%@   %@",object.createTime,object.fileSize];
  return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  // Return NO if you do not want the specified item to be editable.
  return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    // Delete the row from the data source
    [[listContent objectAtIndex:indexPath.row] deleteFile];
    [listContent removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
  }   
}


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */



// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  // Return NO if you do not want the item to be re-orderable.
  return NO;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // Navigation logic may go here. Create and push another view controller.
  
  FileAttribute *object = nil;
  if (tableView == self.searchDisplayController.searchResultsTableView)
  {
    object = [self.filteredListContent objectAtIndex:indexPath.row];
  }
  else
  {
    object = [self.listContent objectAtIndex:indexPath.row];
  } 

#if 0
  MPMoviePlayerController * mp = [[MPMoviePlayerController alloc] 
                                           initWithContentURL:[NSURL fileURLWithPath:[object fullPath]]];
  
	if (mp)
	{
		self.moviePlayer = mp;
		[mp release];
		[self.moviePlayer play];

	}
#else
	EIFilePlayViewController *filePlayer = [[EIFilePlayViewController alloc] initWithFilePath:[object fullPath]];
	filePlayer.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentModalViewController:filePlayer animated:YES];
	[filePlayer release];
	
#endif	
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
  // Save the state of the search UI so that it can be restored if the view is re-created.
  self.searchWasActive = [self.searchDisplayController isActive];
  self.savedSearchTerm = [self.searchDisplayController.searchBar text];
  self.savedScopeButtonIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
  
  self.filteredListContent = nil;
}


- (void)dealloc {
  
  [listContent release];
  [filteredListContent release];
  
	[moviePlayer release]; 
  [super dealloc];
}


#pragma mark -
#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
  
  /*
   Update the filtered array based on the search text and scope.
   */
  
  [self.filteredListContent removeAllObjects]; // First clear the filtered array.
  
  /*
   Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
   */
  
  for (FileAttribute *object in listContent)
  {
#if 0	  
    NSComparisonResult result = [object.cameraName compare:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchText length])];
    if (result == NSOrderedSame)
    {
      [self.filteredListContent addObject:object];
    }
#else//xinghua 20110512
	  NSRange r = [object.cameraName rangeOfString: searchText options:NSCaseInsensitiveSearch];
	  if (!NSEqualRanges( NSMakeRange(NSNotFound, 0) , r))
		  [self.filteredListContent addObject:object];	  
#endif
  }
  
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
  /*
   [self filterContentForSearchText:searchString scope:
   [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
   */
  [self filterContentForSearchText:searchString scope:nil];
  // Return YES to cause the search result table view to be reloaded.
  return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
  /*
   [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
   [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
   */
  // Return YES to cause the search result table view to be reloaded.
  return NO;
}


#pragma mark -
- (void)beginEditing {
  [self.searchDisplayController setActive:NO];
  [self.tableView setEditing:YES animated:YES];
  
  UIBarButtonItem * doneItem = [[UIBarButtonItem alloc]
                                initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(endEditing)];
  self.navigationItem.rightBarButtonItem = doneItem;
  [doneItem release];
}


- (void)endEditing {
  [self.tableView setEditing:NO animated:YES];
  
  UIBarButtonItem * editItem = [[UIBarButtonItem alloc] 
                                initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(beginEditing)];
  
  self.navigationItem.rightBarButtonItem = editItem;
  [editItem release];
  
}
@end

