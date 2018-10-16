//
//  MSPAVSession.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MSPAudioConfiguration.h"
#import "MSPVideoConfiguration.h"
#import "MSPStreamConfig.h"

@class MSPAVSession;
@protocol MSPAVSessionDelegate <NSObject>

@optional
/** live status changed will callback */
- (void)AVSession:(nullable MSPAVSession *)session stateDidChange:(MSPSocketState)state;

/** callback socket errorcode */
- (void)AVSession:(nullable MSPAVSession *)session errorCode:(MSPSocketErrorCode)errorCode;
@end

@interface MSPAVSession : NSObject

@property (nullable, nonatomic, weak) id<MSPAVSessionDelegate> delegate;

// 捕获数据开关
@property (nonatomic, assign) BOOL running;

// 本地画面显示
@property (nonatomic, strong, null_resettable) UIView *preView;

// 控制使用前置摄像头还是后摄像头 默认前
@property (nonatomic, assign) AVCaptureDevicePosition captureDevicePosition;

// 是否开启美颜
@property (nonatomic, assign) BOOL beautyFace;
// beautyFace Level,Default is 0.5, between 0.0 ~ 1.0
@property (nonatomic, assign) CGFloat beautyLevel;
// 亮度 Default is 0.5, between 0.0 ~ 1.0
@property (nonatomic, assign) CGFloat brightLevel;
// 摄像头缩放 zoom scale default 1.0, between 1.0 ~ 3.0
@property (nonatomic, assign) CGFloat zoomScale;
// 是否开启闪光灯
@property (nonatomic, assign) BOOL torch;
// The mirror control mirror of front camera is on or off
@property (nonatomic, assign) BOOL mirror;
// 自动码率
@property (nonatomic, assign) BOOL autoBitrate;
// 控制 是否静音
@property (nonatomic, assign) BOOL muted;

// 重连间隔
@property (nonatomic, assign) NSUInteger reconnectInterval;
// 重连次数
@property (nonatomic, assign) NSUInteger reconnectCount;

// 视频是否保存本地
@property (nonatomic, assign) BOOL saveLocalVideo;

// 音频是否保存本地
@property (nonatomic, strong, nullable) NSURL *saveLocalVideoPath;

- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

- (nullable instancetype)initWithAudioConfiguration:(nullable MSPAudioConfiguration *)audioConfiguration videoConfiguration:(nullable MSPVideoConfiguration *)videoConfiguration;

- (void)startLive:(nonnull MSPStreamConfig *)streamConfig;

- (void)stopLive;

@end
