//
//  EISettingViewController.h
//  Eeye
//
//  Created by MKevin on 6/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EISettingViewController : UIViewController <UITextFieldDelegate>{

	IBOutlet UITextField *serverAddress_;
	IBOutlet UITextField *serverPort_;
	IBOutlet UITextField *serverAddrSuffix;
	IBOutlet UITextField *userDomain_;
	IBOutlet UISlider *cameraControlDelta1;
	IBOutlet UISlider *cameraControlDelta2;
    IBOutlet UILabel *cameraControlText1;
    IBOutlet UILabel *cameraControlText2;
}


- (IBAction)cameraControlValueDidChange:(id)sender;


@end
