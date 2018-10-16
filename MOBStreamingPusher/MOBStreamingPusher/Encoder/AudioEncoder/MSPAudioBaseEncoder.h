//
//  MSPAudioBaseEncoder.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/11.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSPAudioConfiguration.h"
#import "MSPAudioFrame.h"
#import <AVFoundation/AVFoundation.h>

@protocol MSPAudioBaseEncoder;

/// 编码器编码回调
@protocol MSPAudioEncoderDelegate <NSObject>
@required
- (void)audioEncoder:(nullable id<MSPAudioBaseEncoder>)encoder audioFrame:(nullable MSPAudioFrame *)frame;
@end

/// 编码器抽象接口
@protocol MSPAudioBaseEncoder <NSObject>
@required
- (void)encodeAudioData:(nullable NSData*)audioData timeStamp:(uint64_t)timeStamp;
- (void)stopEncoder;

@optional
- (nullable instancetype)initWithAudioStreamConfiguration:(nullable MSPAudioConfiguration *)configuration;
- (void)setDelegate:(nullable id<MSPAudioEncoderDelegate>)delegate;
- (nullable NSData *)adtsData:(NSInteger)channel rawDataLength:(NSInteger)rawDataLength;

@end
