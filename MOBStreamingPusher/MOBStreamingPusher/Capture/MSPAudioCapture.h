//
//  MSPAudioCapture.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/13.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSPAudioConfiguration.h"

/** compoentFialed will post the notification */
extern NSString *_Nullable const MSPAudioComponentFailedToCreateNotification;

@class MSPAudioCapture;

/// 获取音频数据回调
@protocol MSPAudioCaptureDelegate <NSObject>

- (void)captureOutput:(nullable id)capture audioData:(nullable NSData*)audioData;

@end

/// 音频捕获管理类
@interface MSPAudioCapture : NSObject

@property (nonatomic, weak) id<MSPAudioCaptureDelegate> delegate;

// 控制 是否静音
@property (nonatomic, assign) BOOL muted;

// 控制 开始或停止捕获音频数据
@property (nonatomic, assign) BOOL running;

// 不允许访问 init 和 new
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

- (nullable instancetype)initWithAudioConfiguration:(nullable MSPAudioConfiguration *)configuration;

@end
