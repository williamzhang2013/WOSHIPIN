    //
//  CfgViewController.m
//  VISS_gx3
//
//  Created by Li Xinghua on 11-10-11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CfgViewController.h"
#import "Common.h"

@implementation CfgViewController1

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"系统配置";
	CMSIP_Field.text = [[MCUEngine sharedObj] getCMSIPAddr];
	VAUIP_Field.text = [[MCUEngine sharedObj] getVAUIPAddr];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[MCUEngine setCMSIPAddr:CMSIP_Field.text];
	//[MCUEngine setVAUIPAddr:VAUIP_Field.text];
	
    [super dealloc];
}
#pragma mark -
#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == CMSIP_Field) {
		[CMSIP_Field resignFirstResponder];
		//[VAUIP_Field becomeFirstResponder];
	}
	/*if (textField == VAUIP_Field) {
		[VAUIP_Field resignFirstResponder];
	}*/
	return YES;
}


@end
