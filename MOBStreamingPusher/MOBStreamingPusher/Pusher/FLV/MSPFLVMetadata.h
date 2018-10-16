//
//  MSPFLVMetadata.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSPFLVMetadata : NSObject

@property (nonatomic, assign) double duration;
@property (nonatomic, assign) double width;
@property (nonatomic, assign) double height;
@property (nonatomic, assign) double videoBitrate;
@property (nonatomic, assign) double framerate;
@property (nonatomic, assign) int videoCodecId;
@property (nonatomic, assign) double audioBitrate;
@property (nonatomic, assign) double sampleRate;
@property (nonatomic, assign) double sampleSize;
@property (nonatomic, assign) BOOL stereo;
@property (nonatomic, assign) int audioCodecId;

@end
