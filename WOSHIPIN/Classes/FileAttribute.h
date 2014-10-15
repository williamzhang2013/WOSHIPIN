//
//  FileAttribute.h
//  EyeRecording
//
//  Created by MKevin on 4/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FileAttribute : NSObject {
  NSString * fullFilePath_;
  
  NSString * fileSize_;
  NSString * createTime_;
  NSString * cameraName_;
  
  NSDate * date_;
}

- (id)initWithFullFilePath:(NSString *)fullFilePath;

/*
- (NSString *)fileSize;
- (NSString *)createTime;
- (NSString *)cameraName;
*/
- (NSString *)fullPath;


@property (nonatomic, retain) NSString * fileSize;
@property (nonatomic, retain) NSString * createTime;
@property (nonatomic, retain) NSString * cameraName;
@property (nonatomic, retain) NSDate * date;
- (BOOL)deleteFile;

- (void)getAttribute;

- (NSComparisonResult)createTimeDESCCompare:(FileAttribute *)object;
@end
