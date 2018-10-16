//
//  MSPVideoBaseEncoder.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/11.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSPVideoConfiguration.h"
#import "MSPVideoFrame.h"
#import <AVFoundation/AVFoundation.h>

@protocol MSPVideoBaseEncoder;

/// 编码器编码回调
@protocol MSPVideoEncoderDelegate <NSObject>
@required
- (void)videoEncoder:(nullable id<MSPVideoBaseEncoder>)encoder videoFrame:(nullable MSPVideoFrame *)frame;
@end

/// 编码器抽象接口
@protocol MSPVideoBaseEncoder <NSObject>
@required
- (void)encodeVideoData:(nullable CVPixelBufferRef)pixelBuffer timeStamp:(uint64_t)timeStamp;
- (void)stopEncoder;

@optional
- (nullable instancetype)initWithVideoStreamConfiguration:(nullable MSPVideoConfiguration *)configuration;
- (void)setDelegate:(nullable id<MSPVideoEncoderDelegate>)delegate;
@property (nonatomic, assign) NSInteger videoBitRate;

@end
