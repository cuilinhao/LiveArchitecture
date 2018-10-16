//
//  MSPVideoCapture.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/13.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MSPVideoConfiguration.h"

@class MSPVideoCapture;

/// 获取视频数据回调
@protocol MSPVideoCaptureDelegate <NSObject>

- (void)captureOutput:(nullable id)capture pixelBuffer:(nullable CVPixelBufferRef)pixelBuffer;

@end

/// 视频获取类
@interface MSPVideoCapture : NSObject

@property (nullable, nonatomic, weak) id<MSPVideoCaptureDelegate> delegate;

@property (nonatomic, assign) BOOL running;

@property (null_resettable, nonatomic, strong) UIView *preView;

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

// 不允许访问 init 和 new
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

- (nullable instancetype)initWithVideoConfiguration:(nullable MSPVideoConfiguration *)configuration;

@end
