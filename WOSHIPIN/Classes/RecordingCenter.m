//
//  RecordingCenter.m
//  EyeRecording
//
//  Created by MKevin on 4/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RecordingCenter.h"
#import "FileAttribute.h"
#import "Debug.h"
#import "Common.h"

@implementation RecordingCenter


+ (void)initialize {
	
	/* //xinghua 20101020
  NSString * path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] 
                     stringByAppendingPathComponent:@"Recordings"];
  BOOL isDirectory;
  if (!([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory)) {
    BOOL result = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    if(!result) DebugLog(@"error - creating folder - failed"); else DebugLog(@"create folder - done!");
    Assert(result);
  }*/
  
  NSString * picPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] 
                     stringByAppendingPathComponent:@"Pics"];
  BOOL isPicDirectory;
  if (!([[NSFileManager defaultManager] fileExistsAtPath:picPath isDirectory:&isPicDirectory] && isPicDirectory)) {
    BOOL result = [[NSFileManager defaultManager] createDirectoryAtPath:picPath withIntermediateDirectories:YES attributes:nil error:NULL];
    if(!result) DebugLog(@"error - creating folder - failed"); else DebugLog(@"create folder - done!");
    Assert(result);
  }
	 
}

#pragma mark -
#pragma mark RecordingSaver

+ (NSString *)applicationRecordingsDirectory 
{
  NSString * document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
  //return [document stringByAppendingPathComponent:@"Recordings"];
	return document; //xinghua 20101019
}

+ (NSString *)applicationPicsDirectory 
{
  NSString * document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
  return [document stringByAppendingPathComponent:@"Pics"];
	

}

+ (NSString *)filePathForTempPic {
  NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:RCRecordingFileDatePartFormat];
  NSString * dateString = [formatter stringFromDate:[NSDate date]];
  [formatter release];
  
  NSString * filePath = [[RecordingCenter applicationPicsDirectory] stringByAppendingPathComponent:
                         [NSString stringWithFormat:@"%@.png",dateString]];
  
  return filePath;
}

+ (NSString *)filePathWithCameraName:(NSString *)cameraName {
  if ([cameraName length] == 0) {
    Assert(NO);
    return nil;
  }
  
  NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:RCRecordingFileDatePartFormat];
  NSString * dateString = [formatter stringFromDate:[NSDate date]];
  [formatter release];
  
  NSString * filePath = [[RecordingCenter applicationRecordingsDirectory] stringByAppendingPathComponent:
                         [NSString stringWithFormat:@"%@%@.%@",cameraName,dateString,RCRecordingFileExtension]];
  
  return filePath;
    
}

+ (BOOL)saveRecording:(NSData *)content withCameraName:(NSString *)cameraName {
  if ([content length] == 0) {
    Assert(NO);
    return NO;
  }
  
  if ([cameraName length] == 0) {
    Assert(NO);
    return NO;
  }
  
  NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:RCRecordingFileDatePartFormat];
  NSString * dateString = [formatter stringFromDate:[NSDate date]];
  [formatter release];
  
  NSString * filePath = [[RecordingCenter applicationRecordingsDirectory] stringByAppendingPathComponent:
                         [NSString stringWithFormat:@"%@%@.%@",cameraName,dateString,RCRecordingFileExtension]];
  
  if ([[NSFileManager defaultManager] createFileAtPath:filePath contents:content attributes:nil]) {
    DebugLog(@"suc:%@",filePath);
    return YES;
  }else {
    DebugLog(@"fail@%@",filePath);
    return NO;
  }
}

#pragma mark -
#pragma mark RecordingReader

+ (NSArray *)readRecordingsWithFlag:(BOOL)objectOrNot {
  NSString * path = [RecordingCenter applicationRecordingsDirectory];
  NSError * error;
  
  NSMutableArray * results = [[NSMutableArray alloc] init];
  
  NSFileManager * manager = [NSFileManager defaultManager];
  NSArray * subpaths = [manager subpathsOfDirectoryAtPath:path error:&error];

  if (objectOrNot) {
    for ( NSString * subpath in subpaths ) {
		if ([[subpath pathExtension] isEqualToString:RCRecordingFileExtension])//xinghua 20101020
		{
			NSString *fullpath = [path stringByAppendingPathComponent:subpath];
			
			//xinghua 20101126, to delete file with size < 32K --->
			
			NSDictionary * dictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:fullpath error:nil];
			
			NSNumber * fileSize = [dictionary objectForKey:NSFileSize];
			if ([fileSize intValue] < 32768)
			{
				[[NSFileManager defaultManager] removeItemAtPath:fullpath error:nil];
				continue;
			}

			[results addObject:
				[[FileAttribute alloc] initWithFullFilePath:fullpath]
				];
		}
    }
  } else {
    for ( NSString * subpath in subpaths ) {
      [results addObject:[path stringByAppendingPathComponent:subpath]];
    }
  }
  
  return [results autorelease];
}

/*
+ (NSArray *)recordingsFilePaths {
  return [RecordingCenter readRecordingsWithFlag:NO];
}
 */

+ (NSArray *)recordingFiles {
  return [RecordingCenter readRecordingsWithFlag:YES];
}
@end
