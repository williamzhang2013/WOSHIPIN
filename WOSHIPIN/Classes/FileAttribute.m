//
//  FileAttribute.m
//  EyeRecording
//
//  Created by MKevin on 4/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FileAttribute.h"
#import "Debug.h"
#import "Common.h"

@implementation FileAttribute

@synthesize fileSize = fileSize_;
@synthesize cameraName = cameraName_;
@synthesize createTime = createTime_;
@synthesize date = date_;

- (id)initWithFullFilePath:(NSString *)fullFilePath {
  if (self = [super init]) {
    if ([fullFilePath length] == 0 ||
        ![[NSFileManager defaultManager] fileExistsAtPath:fullFilePath]) {
      Assert(NO);
      [self autorelease];
      return nil;
    }
    fullFilePath_ = [fullFilePath retain];
    [self getAttribute];
  }
  return self;
}

/*
- (NSString *)fileSize {
  if (!self.fileSize) {
    [self getAttribute];
  }
  return self.fileSize;
}

- (NSString *)createTime {
  if (!self.createTime) {
    [self getAttribute];
  }
  return self.createTime;
}

- (NSString *)cameraName {
  if (!self.cameraName) {
    [self getAttribute];
  }
  return self.cameraName;  
}
*/
- (NSString *)fullPath {
  return fullFilePath_;
}
 

- (BOOL)deleteFile {
  BOOL result = [[NSFileManager defaultManager] removeItemAtPath:fullFilePath_ error:nil];
  Assert(result);
  return result;
}

- (NSString *)stringFromFileSize:(int)theSize
{
	float floatSize = theSize;
	if (theSize<1023)
		return([NSString stringWithFormat:@"%i bytes",theSize]);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1f KB",floatSize]);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1f MB",floatSize]);
	floatSize = floatSize / 1024;
  
	// Add as many as you like
  
	return([NSString stringWithFormat:@"%1.1f GB",floatSize]);
}

- (void)getAttribute {
  // get related attibutes
  NSDictionary * dictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:fullFilePath_ error:nil];
  
  self.date = [dictionary objectForKey:NSFileModificationDate];
  NSNumber * fileSize = [dictionary objectForKey:NSFileSize];
  NSString * name = [[NSFileManager defaultManager] displayNameAtPath:fullFilePath_];

  // get camera name
  int length = [name length] - RCRecordingFileDatePartFormatLength - RCRecordingFileExtensionLength - 1;
  if (length <= 0) {
    DebugLog(@"error - parse camera name - length < 0");
    self.cameraName = @"unknown";
  } else {
    self.cameraName = [name substringWithRange:NSMakeRange(0, length)];
  }
  
  // get file size
  self.fileSize = [self stringFromFileSize:[fileSize intValue]];
  
  // get create time
  NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
  [formatter setDateStyle:NSDateFormatterMediumStyle];
  [formatter setTimeStyle:NSDateFormatterMediumStyle];
  self.createTime = [formatter stringFromDate:self.date];
}

- (NSComparisonResult)createTimeDESCCompare:(FileAttribute *)object {
  return [object.date compare:self.date];
}

- (void)dealloc {
  self.fileSize = nil;
  self.createTime = nil;
  self.cameraName = nil;
  
  [fullFilePath_ release];
  fullFilePath_ = nil;
  
  [super dealloc];
}
@end
