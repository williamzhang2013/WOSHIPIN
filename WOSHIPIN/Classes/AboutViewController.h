//
//  AboutViewController.h
//  Eeye
//
//  Created by Li Xinghua on 10-9-13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AboutViewController : UIViewController {
    UILabel *verLabel;
	UILabel *buildLabel;
    UILabel *contentLabel;
     
}


@property (retain, nonatomic) IBOutlet UILabel *verLabel;
@property (retain, nonatomic) IBOutlet UILabel *buildLabel;
@property (retain, nonatomic) IBOutlet UILabel *contentLabel;

@end
