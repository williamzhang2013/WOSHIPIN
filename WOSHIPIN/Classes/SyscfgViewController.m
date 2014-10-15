//
//  SyscfgViewController.m
//  WOSHIPIN
//
//  Created by Li Xinghua on 12-11-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SyscfgViewController.h"
#import "Common.h"

@interface SyscfgViewController ()

@end

@implementation SyscfgViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"系统配置";
	CMSIP_Field.text = [[MCUEngine sharedObj] getCMSIPAddr];
	CMSPORT_Field.text = [MCUEngine getCMSPort];
}



- (void)dealloc {
	[MCUEngine setCMSIPAddr:CMSIP_Field.text];
	[MCUEngine setCMSPort:CMSPORT_Field.text];
	[CMSIP_Field release];
    [CMSPORT_Field release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == CMSIP_Field) {
		[CMSIP_Field resignFirstResponder];
		[CMSPORT_Field becomeFirstResponder];
	}
    
	if (textField == CMSPORT_Field) {
     [CMSPORT_Field resignFirstResponder];
    }
	return YES;
}


@end
