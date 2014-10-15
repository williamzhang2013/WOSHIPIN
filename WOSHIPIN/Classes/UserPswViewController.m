//
//  EILoginViewController.m
//  Eeye
//
//  Created by MKevin on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "UserPswViewController.h"
#import "Common.h"

extern int g_current_active_entry;

@implementation UserPswViewController


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  //NSLog(@"view did load");
  [super viewDidLoad];
	//self.title = @"登录账户";

	editChanged = NO;
    rememberPassword_.frame = CGRectMake(rememberPassword_.frame.origin.x, 
                                    rememberPassword_.frame.origin.y + 6, 
                                    rememberPassword_.frame.size.width,
                                    31);
	rememberPassword_.selectedSegmentIndex = [MCUEngine getLoginAccountSaved:g_current_active_entry] ? 0 : 1;

	if (rememberPassword_.selectedSegmentIndex == 0)
	{
		nameField_.text = [MCUEngine  getLoginUserName:g_current_active_entry ];
		passwordField_.text = [MCUEngine  getLoginPassword:g_current_active_entry];
	}
 }


- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

}


/*
- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}*/


- (void)dealloc {
  [super dealloc];

}
#pragma mark -
#pragma mark IBAction

- (IBAction)login:(id)sender {
	
	if (nameField_.text == nil)
		return;
	if ([nameField_.text isEqualToString:@""])
		return;
	if (passwordField_.text == nil)
		return;
	if ([passwordField_.text isEqualToString:@""])
		return;
	
	[self.navigationController popViewControllerAnimated:NO];

    
    //always save actullay
    [MCUEngine setLoginUserName:nameField_.text entry:g_current_active_entry];
    [MCUEngine setLoginPassword:passwordField_.text entry:g_current_active_entry];
	
    //update autosave flag 
	if (rememberPassword_.selectedSegmentIndex == 1)//to unsave password
	{
		[MCUEngine setLoginAccountSaved: NO entry:g_current_active_entry];	
	}
	else if ( rememberPassword_.selectedSegmentIndex == 0)
	{
		[MCUEngine setLoginAccountSaved: YES entry:g_current_active_entry ];
	}
    
    [[MCUEngine sharedObj] entryLogin:g_current_active_entry UserName:nameField_.text Psw:passwordField_.text];
}

- (IBAction)changeRememberPasswordSetting:(id)sender 
{
	//BOOL b = rememberPassword_.selectedSegmentIndex==1 ? NO : YES;
	//[MCUEngine setLoginAccountSaved: b entry:g_current_active_entry ];
	editChanged = YES;
}

#pragma mark -
#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField == nameField_) {
    [nameField_ resignFirstResponder];
    [passwordField_ becomeFirstResponder];
  }
  if (textField == passwordField_) {
    [passwordField_ resignFirstResponder];
  }
  return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	editChanged = YES;
}

@end
