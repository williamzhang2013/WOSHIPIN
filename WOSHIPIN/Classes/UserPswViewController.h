//
//  EILoginViewController.h
//  Eeye
//
//  Created by MKevin on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UserPswViewController : UIViewController <UITextFieldDelegate, UIWebViewDelegate>{
  IBOutlet UITextField * nameField_;
  IBOutlet UITextField * passwordField_;
  IBOutlet UISegmentedControl *rememberPassword_;
 
	BOOL editChanged;
}


- (IBAction)login:(id)sender;
- (IBAction)changeRememberPasswordSetting:(id)sender;


@end
