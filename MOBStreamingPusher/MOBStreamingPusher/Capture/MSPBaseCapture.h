//
//  MSPBaseCapture.h
//  MOBStreamingPusher
//
//  Created by wkx on 2018/9/25.
//  Copyright © 2018年 testDemo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MSPAudioConfiguration.h"
#import "MSPVideoConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

/// 获取音频视频数据回调
@protocol MSPAVCaptureDelegate <NSObject>

- (void)captureOutput:(nullable id)capture audioData:(nullable NSData*)audioData;

- (void)captureOutput:(nullable id)capture pixelBuffer:(nullable CVPixelBufferRef)pixelBuffer;

@end


@interface MSPBaseCapture : NSObject

@property (nonatomic, weak) id<MSPAVCaptureDelegate> delegate;

@property (nonatomic, assign) BOOL running;

//预览view
@property (nonatomic, strong) UIView *preview;

@property (nonatomic, strong, readonly) MSPAudioConfiguration *audioConfiguration;
@property (nonatomic, strong, readonly) MSPVideoConfiguration *videoConfiguration;

@property (nonatomic, assign) AVCaptureDevicePosition captureDevicePosition;

@property (nonatomic, assign) BOOL beautyFace;

@property (nonatomic, assign) BOOL torch;

@property (nonatomic, assign) BOOL mirror;

@property (nonatomic, assign) CGFloat beautyLevel;

@property (nonatomic, assign) CGFloat brightLevel;

@property (nonatomic, assign) CGFloat zoomScale;

@property (nonatomic, assign) NSInteger videoFrameRate;

@property (nonatomic, strong, nullable) UIView *warterMarkView;

@property (nonatomic, strong, nullable) UIImage *currentImage;

@property (nonatomic, assign) BOOL saveLocalVideo;

@property (nonatomic, strong, nullable) NSURL *saveLocalVideoPath;

// 控制 是否静音
@property (nonatomic, assign) BOOL muted;


// 不允许访问 init 和 new
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

- (nullable instancetype)initWithAudioConfiguration:(nullable MSPAudioConfiguration *)audioConfiguration
                                 videoConfiguration:(nullable MSPVideoConfiguration *)videoConfiguration;

- (void) onInit;

//修改fps
-(void) updateFps:(NSInteger) fps;

- (void)willEnterBackground:(NSNotification *)notification;
- (void)willEnterForeground:(NSNotification *)notification;
- (void)statusBarChanged:(NSNotification *)notification;

@end

NS_ASSUME_NONNULL_END
