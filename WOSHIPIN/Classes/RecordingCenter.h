//
//  RecordingCenter.h
//  EyeRecording
//
//  Created by MKevin on 4/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RecordingCenter : NSObject {
  
}

+ (NSString *)filePathForTempPic;
+ (NSString *)filePathWithCameraName:(NSString *)cameraName;
+ (BOOL)saveRecording:(NSData *)content withCameraName:(NSString *)cameraName;

//+ (NSArray *)recordingsFilePaths;
+ (NSArray *)recordingFiles;

@end
