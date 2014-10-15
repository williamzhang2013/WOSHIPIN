//
//  EISettingViewController.m
//  Eeye
//
//  Created by MKevin on 6/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Common.h"
#import "EISettingViewController.h"


@implementation EISettingViewController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    serverAddress_.text = [defaults objectForKey:RCServerAddressKey];
	serverPort_.text = [defaults objectForKey:RCServerPortKey];
	serverAddrSuffix.text = [defaults objectForKey:RCServerAddrSuffixKey];
    userDomain_.text = [defaults objectForKey:RCUserDomainKey];
    cameraControlDelta1.value = [defaults integerForKey:RCCameraLength1Key];
    cameraControlDelta2.value = [defaults integerForKey:RCCameraLength2Key];  
    cameraControlText1.text = [NSString stringWithFormat:@"%1.0f", cameraControlDelta1.value];
    cameraControlText2.text = [NSString stringWithFormat:@"%1.0f", cameraControlDelta2.value];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField == serverAddress_) {
        
        [userDomain_ becomeFirstResponder];
    }
    return YES;
}

- (IBAction)cameraControlValueDidChange:(id)sender {
    if (sender == cameraControlDelta1) {
        cameraControlText1.text = [NSString stringWithFormat:@"%1.0f", cameraControlDelta1.value];
    }
    if (sender == cameraControlDelta2) {
        cameraControlText2.text = [NSString stringWithFormat:@"%1.0f", cameraControlDelta2.value];
    }
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:serverAddress_.text forKey:RCServerAddressKey];
    [defaults setObject:serverPort_.text forKey:RCServerPortKey];
	[defaults setObject:serverAddrSuffix.text forKey:RCServerAddrSuffixKey];
	
    [defaults setObject:userDomain_.text forKey:RCUserDomainKey];
    [defaults setInteger:(int)cameraControlDelta1.value forKey:RCCameraLength1Key];
    [defaults setInteger:(int)cameraControlDelta2.value forKey:RCCameraLength2Key];
    [defaults synchronize];
}

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
    [super dealloc];
}


@end
