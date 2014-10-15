//
//  Utilities.m
//  Eeye
//
//  Created by Near on 10-4-20.
//  Copyright 2010 Exmart. All rights reserved.
//

#import "Utilities.h"


@implementation Utilities

+ (NSString *)convertSecondesToTimeString:(NSTimeInterval)seconds{
  NSString *result = nil;
  
  NSDateComponents *component = [[NSDateComponents alloc] init];
  [component setSecond:seconds];
  NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:component];
  [component release];
  
  NSDateFormatter *dateFormatter =[[NSDateFormatter alloc] init];
  if (seconds < 3600) {
	[dateFormatter setDateFormat:@"mm:ss"];
  }
  else {
	[dateFormatter setDateFormat:@"HH:mm:ss"];
  }
  result = [dateFormatter stringFromDate:date];
  [dateFormatter release];
  
  return result;
}


@end
