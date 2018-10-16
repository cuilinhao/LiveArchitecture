//
//  MSPVideoConfiguration.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/11.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// 视频分辨率
typedef NS_ENUM (NSUInteger, MSPVideoSessionPreset)
{
    /// 低分辨率
    MSPCaptureSessionPreset360x640      = 0,
    /// 中分辨率
    MSPCaptureSessionPreset540x960      = 1,
    /// 高分辨率
    MSPCaptureSessionPreset720x1280     = 2
};

/// 视频质量
typedef NS_ENUM (NSUInteger, MSPVideoQuality)
{
    /// 分辨率：360 * 640， 帧数：15， 码率：500Kps
    MSPVideoQuality_Low1                = 0,
    /// 分辨率：360 * 640， 帧数：24， 码率：800Kps
    MSPVideoQuality_Low2                = 1,
    /// 分辨率：360 * 640， 帧数：30， 码率：800Kps
    MSPVideoQuality_Low3                = 2,
    /// 分辨率：540 * 960， 帧数：15， 码率：800Kps
    MSPVideoQuality_Medium1             = 3,
    /// 分辨率：540 * 960， 帧数：24， 码率：800Kps
    MSPVideoQuality_Medium2             = 4,
    /// 分辨率：540 * 960， 帧数：30， 码率：800Kps
    MSPVideoQuality_Medium3             = 5,
    /// 分辨率：720 * 1280，帧数：15， 码率：1000Kps
    MSPVideoQuality_High1               = 6,
    /// 分辨率：720 * 1280，帧数：24， 码率：1200Kps
    MSPVideoQuality_High2               = 7,
    /// 分辨率：720 * 1280，帧数：30， 码率：1200Kps
    MSPVideoQuality_High3               = 8,
    /// 默认
    MSPVideoQuality_Default             = MSPVideoQuality_Low2
};

@interface MSPVideoConfiguration : NSObject<NSCoding, NSCopying>

/// 视频的分辨率
@property (nonatomic, assign) CGSize videoSize;
/// 输出图像是否等比例,默认为NO
@property (nonatomic, assign) BOOL videoSizeRespectingAspectRatio;
/// 视频输出方向
@property (nonatomic, assign) UIInterfaceOrientation outputImageOrientation;
/// 自动旋转(这里只支持 left 变 right  portrait 变 portraitUpsideDown)
@property (nonatomic, assign) BOOL autorotate;
/// 视频帧率 fps
@property (nonatomic, assign) NSUInteger videoFrameRate;
/// 视频最大帧率  max fps
@property (nonatomic, assign) NSUInteger videoMaxFrameRate;
/// 视频最小帧率  min fps
@property (nonatomic, assign) NSUInteger videoMinFrameRate;
/// 最大关键帧间隔  关键帧(GOPsize)
@property (nonatomic, assign) NSUInteger videoMaxKeyframeInterval;
/// 视频码率(单位 bps)
@property (nonatomic, assign) NSUInteger videoBitRate;
/// 视频最大码率(单位 bps)
@property (nonatomic, assign) NSUInteger videoMaxBitRate;
/// 视频最小码率(单位 bps)
@property (nonatomic, assign) NSUInteger videoMinBitRate;
/// 分辨率
@property (nonatomic, assign) MSPVideoSessionPreset sessionPreset;
/// ≈sde3分辨率
@property (nonatomic, copy, readonly) NSString *avSessionPreset;
/// 是否是横屏
@property (nonatomic, assign, readonly) BOOL landscape;

+ (instancetype)defaultConfiguration;

+ (instancetype)defaultConfigurationForQuality:(MSPVideoQuality)videoQuality;

+ (instancetype)defaultConfigurationForQuality:(MSPVideoQuality)videoQuality outputImageOrientation:(UIInterfaceOrientation)outputImageOrientation;

@end
