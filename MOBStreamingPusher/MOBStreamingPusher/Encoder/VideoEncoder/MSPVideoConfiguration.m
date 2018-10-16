//
//  MSPVideoConfiguration.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/11.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPVideoConfiguration.h"
#import <AVFoundation/AVFoundation.h>

@implementation MSPVideoConfiguration

+ (instancetype)defaultConfiguration
{
    MSPVideoConfiguration *configuration = [MSPVideoConfiguration defaultConfigurationForQuality:MSPVideoQuality_Default];
    return configuration;
}

+ (instancetype)defaultConfigurationForQuality:(MSPVideoQuality)videoQuality
{
    MSPVideoConfiguration *configuration = [MSPVideoConfiguration defaultConfigurationForQuality:videoQuality outputImageOrientation:UIInterfaceOrientationPortrait];
    return configuration;
}

+ (instancetype)defaultConfigurationForQuality:(MSPVideoQuality)videoQuality outputImageOrientation:(UIInterfaceOrientation)outputImageOrientation
{
    MSPVideoConfiguration *configuration = [MSPVideoConfiguration new];
    switch (videoQuality)
    {
        case MSPVideoQuality_Low1:
            {
                configuration.sessionPreset = MSPCaptureSessionPreset360x640;
                configuration.videoFrameRate = 15;
                configuration.videoMaxFrameRate = 15;
                configuration.videoMinFrameRate = 10;
                configuration.videoBitRate = 500 * 1000;
                configuration.videoMaxBitRate = 600 * 1000;
                configuration.videoMinBitRate = 400 * 1000;
                configuration.videoSize = CGSizeMake(360, 640);
            }
            break;
        case MSPVideoQuality_Low2:
        {
            configuration.sessionPreset = MSPCaptureSessionPreset360x640;
            configuration.videoFrameRate = 24;
            configuration.videoMaxFrameRate = 24;
            configuration.videoMinFrameRate = 12;
            configuration.videoBitRate = 600 * 1000;
            configuration.videoMaxBitRate = 720 * 1000;
            configuration.videoMinBitRate = 500 * 1000;
            configuration.videoSize = CGSizeMake(360, 640);
        }
            break;
        case MSPVideoQuality_Low3:
        {
            configuration.sessionPreset = MSPCaptureSessionPreset360x640;
            configuration.videoFrameRate = 30;
            configuration.videoMaxFrameRate = 30;
            configuration.videoMinFrameRate = 15;
            configuration.videoBitRate = 800 * 1000;
            configuration.videoMaxBitRate = 960 * 1000;
            configuration.videoMinBitRate = 600 * 1000;
            configuration.videoSize = CGSizeMake(360, 640);
        }
            break;
        case MSPVideoQuality_Medium1:
        {
            configuration.sessionPreset = MSPCaptureSessionPreset540x960;
            configuration.videoFrameRate = 15;
            configuration.videoMaxFrameRate = 15;
            configuration.videoMinFrameRate = 10;
            configuration.videoBitRate = 800 * 1000;
            configuration.videoMaxBitRate = 960 * 1000;
            configuration.videoMinBitRate = 500 * 1000;
            configuration.videoSize = CGSizeMake(540, 960);
        }
            break;
        case MSPVideoQuality_Medium2:
        {
            configuration.sessionPreset = MSPCaptureSessionPreset540x960;
            configuration.videoFrameRate = 24;
            configuration.videoMaxFrameRate = 24;
            configuration.videoMinFrameRate = 12;
            configuration.videoBitRate = 800 * 1000;
            configuration.videoMaxBitRate = 960 * 1000;
            configuration.videoMinBitRate = 500 * 1000;
            configuration.videoSize = CGSizeMake(540, 960);
        }
            break;
        case MSPVideoQuality_Medium3:
        {
            configuration.sessionPreset = MSPCaptureSessionPreset540x960;
            configuration.videoFrameRate = 30;
            configuration.videoMaxFrameRate = 30;
            configuration.videoMinFrameRate = 15;
            configuration.videoBitRate = 1000 * 1000;
            configuration.videoMaxBitRate = 1200 * 1000;
            configuration.videoMinBitRate = 500 * 1000;
            configuration.videoSize = CGSizeMake(540, 960);
        }
            break;
        case MSPVideoQuality_High1:
        {
            configuration.sessionPreset = MSPCaptureSessionPreset720x1280;
            configuration.videoFrameRate = 15;
            configuration.videoMaxFrameRate = 15;
            configuration.videoMinFrameRate = 10;
            configuration.videoBitRate = 1000 * 1000;
            configuration.videoMaxBitRate = 1200 * 1000;
            configuration.videoMinBitRate = 500 * 1000;
            configuration.videoSize = CGSizeMake(720, 1280);
        }
            break;
        case MSPVideoQuality_High2:
        {
            configuration.sessionPreset = MSPCaptureSessionPreset720x1280;
            configuration.videoFrameRate = 24;
            configuration.videoMaxFrameRate = 24;
            configuration.videoMinFrameRate = 12;
            configuration.videoBitRate = 1200 * 1000;
            configuration.videoMaxBitRate = 1440 * 1000;
            configuration.videoMinBitRate = 800 * 1000;
            configuration.videoSize = CGSizeMake(720, 1280);
        }
            break;
        case MSPVideoQuality_High3:
        {
            configuration.sessionPreset = MSPCaptureSessionPreset720x1280;
            configuration.videoFrameRate = 30;
            configuration.videoMaxFrameRate = 30;
            configuration.videoMinFrameRate = 15;
            configuration.videoBitRate = 1200 * 1000;
            configuration.videoMaxBitRate = 1440 * 1000;
            configuration.videoMinBitRate = 500 * 1000;
            configuration.videoSize = CGSizeMake(720, 1280);
        }
            break;
        default:
            break;
    }
    configuration.sessionPreset = [configuration supportSessionPreset:configuration.sessionPreset];
    configuration.videoMaxKeyframeInterval = configuration.videoFrameRate * 2;
    configuration.outputImageOrientation = outputImageOrientation;
    CGSize size = configuration.videoSize;
    if (configuration.landscape)
    {
        configuration.videoSize = CGSizeMake(size.height, size.width);
    }
    else
    {
        configuration.videoSize = CGSizeMake(size.width, size.height);
    }
    return configuration;
}

#pragma mark - setter getter

- (NSString *)avSessionPreset
{
    NSString *avSessionPreset = nil;
    switch (self.sessionPreset)
    {
        case MSPCaptureSessionPreset360x640:
            {
                avSessionPreset = AVCaptureSessionPreset640x480;
            }
            break;
        case MSPCaptureSessionPreset540x960:
        {
            avSessionPreset = AVCaptureSessionPresetiFrame960x540;
        }
            break;
        case MSPCaptureSessionPreset720x1280:
        {
            avSessionPreset = AVCaptureSessionPreset1280x720;
        }
            break;
        default:
        {
            avSessionPreset = AVCaptureSessionPreset640x480;
        }
            break;
    }
    return avSessionPreset;
}

- (BOOL)landscape
{
    return (self.outputImageOrientation == UIInterfaceOrientationLandscapeLeft || self.outputImageOrientation == UIInterfaceOrientationLandscapeRight) ? YES : NO;
}

- (CGSize)videoSize
{
    if (_videoSizeRespectingAspectRatio)
    {
        return self.aspectRatioVideoSize;
    }
    return _videoSize;
}

- (void)setVideoMaxBitRate:(NSUInteger)videoMaxBitRate {
    if (videoMaxBitRate <= _videoBitRate) return;
    _videoMaxBitRate = videoMaxBitRate;
}

- (void)setVideoMinBitRate:(NSUInteger)videoMinBitRate {
    if (videoMinBitRate >= _videoBitRate) return;
    _videoMinBitRate = videoMinBitRate;
}

- (void)setVideoMaxFrameRate:(NSUInteger)videoMaxFrameRate {
    if (videoMaxFrameRate <= _videoFrameRate) return;
    _videoMaxFrameRate = videoMaxFrameRate;
}

- (void)setVideoMinFrameRate:(NSUInteger)videoMinFrameRate {
    if (videoMinFrameRate >= _videoFrameRate) return;
    _videoMinFrameRate = videoMinFrameRate;
}

- (void)setSessionPreset:(MSPVideoSessionPreset)sessionPreset{
    _sessionPreset = sessionPreset;
    _sessionPreset = [self supportSessionPreset:sessionPreset];
}

- (MSPVideoSessionPreset)supportSessionPreset:(MSPVideoSessionPreset)sessionPreset
{
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    AVCaptureDevice *inputCamera;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == AVCaptureDevicePositionFront)
        {
            inputCamera = device;
        }
    }
    AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:nil];
    
    if ([session canAddInput:videoInput])
    {
        [session addInput:videoInput];
    }
    
    if (![session canSetSessionPreset:self.avSessionPreset]) {
        if (sessionPreset == MSPCaptureSessionPreset720x1280) {
            sessionPreset = MSPCaptureSessionPreset540x960;
            if (![session canSetSessionPreset:self.avSessionPreset]) {
                sessionPreset = MSPCaptureSessionPreset360x640;
            }
        } else if (sessionPreset == MSPCaptureSessionPreset540x960) {
            sessionPreset = MSPCaptureSessionPreset360x640;
        }
    }
    return sessionPreset;
}

- (CGSize)captureOutVideoSize
{
    CGSize videoSize = CGSizeZero;
    switch (_sessionPreset)
    {
        case MSPCaptureSessionPreset360x640:
        {
            videoSize = CGSizeMake(360, 640);
        }
            break;
        case MSPCaptureSessionPreset540x960:
        {
            videoSize = CGSizeMake(540, 960);
        }
            break;
        case MSPCaptureSessionPreset720x1280:
        {
            videoSize = CGSizeMake(720, 1280);
        }
            break;
        default:
        {
            videoSize = CGSizeMake(360, 640);
        }
            break;
    }
    
    if (self.landscape)
    {
        return CGSizeMake(videoSize.height, videoSize.width);
    }
    return videoSize;
}

- (CGSize)aspectRatioVideoSize
{
    CGSize size = AVMakeRectWithAspectRatioInsideRect(self.captureOutVideoSize, CGRectMake(0, 0, _videoSize.width, _videoSize.height)).size;
    NSInteger width = ceil(size.width);
    NSInteger height = ceil(size.height);
    if (width % 2 != 0)
    {
        width = width - 1;
    }
    if (height % 2 != 0)
    {
        height = height - 1;
    }
    return CGSizeMake(width, height);
}

#pragma mark - encoder

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[NSValue valueWithCGSize:self.videoSize] forKey:@"videoSize"];
    [aCoder encodeObject:@(self.videoFrameRate) forKey:@"videoFrameRate"];
    [aCoder encodeObject:@(self.videoMaxFrameRate) forKey:@"videoMaxFrameRate"];
    [aCoder encodeObject:@(self.videoMinFrameRate) forKey:@"videoMinFrameRate"];
    [aCoder encodeObject:@(self.videoMaxKeyframeInterval) forKey:@"videoMaxKeyframeInterval"];
    [aCoder encodeObject:@(self.videoBitRate) forKey:@"videoBitRate"];
    [aCoder encodeObject:@(self.videoMaxBitRate) forKey:@"videoMaxBitRate"];
    [aCoder encodeObject:@(self.videoMinBitRate) forKey:@"videoMinBitRate"];
    [aCoder encodeObject:@(self.sessionPreset) forKey:@"sessionPreset"];
    [aCoder encodeObject:@(self.outputImageOrientation) forKey:@"outputImageOrientation"];
    [aCoder encodeObject:@(self.autorotate) forKey:@"autorotate"];
    [aCoder encodeObject:@(self.videoSizeRespectingAspectRatio) forKey:@"videoSizeRespectingAspectRatio"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    _videoSize = [[aDecoder decodeObjectForKey:@"videoSize"] CGSizeValue];
    _videoFrameRate = [[aDecoder decodeObjectForKey:@"videoFrameRate"] unsignedIntegerValue];
    _videoMaxFrameRate = [[aDecoder decodeObjectForKey:@"videoMaxFrameRate"] unsignedIntegerValue];
    _videoMinFrameRate = [[aDecoder decodeObjectForKey:@"videoMinFrameRate"] unsignedIntegerValue];
    _videoMaxKeyframeInterval = [[aDecoder decodeObjectForKey:@"videoMaxKeyframeInterval"] unsignedIntegerValue];
    _videoBitRate = [[aDecoder decodeObjectForKey:@"videoBitRate"] unsignedIntegerValue];
    _videoMaxBitRate = [[aDecoder decodeObjectForKey:@"videoMaxBitRate"] unsignedIntegerValue];
    _videoMinBitRate = [[aDecoder decodeObjectForKey:@"videoMinBitRate"] unsignedIntegerValue];
    _sessionPreset = [[aDecoder decodeObjectForKey:@"sessionPreset"] unsignedIntegerValue];
    _outputImageOrientation = [[aDecoder decodeObjectForKey:@"outputImageOrientation"] unsignedIntegerValue];
    _autorotate = [[aDecoder decodeObjectForKey:@"autorotate"] boolValue];
    _videoSizeRespectingAspectRatio = [[aDecoder decodeObjectForKey:@"videoSizeRespectingAspectRatio"] unsignedIntegerValue];
    return self;
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    NSArray *values = @[[NSValue valueWithCGSize:self.videoSize],
                        @(self.videoFrameRate),
                        @(self.videoMaxFrameRate),
                        @(self.videoMinFrameRate),
                        @(self.videoMaxKeyframeInterval),
                        @(self.videoBitRate),
                        @(self.videoMaxBitRate),
                        @(self.videoMinBitRate),
                        self.avSessionPreset,
                        @(self.sessionPreset),
                        @(self.outputImageOrientation),
                        @(self.autorotate),
                        @(self.videoSizeRespectingAspectRatio)];
    
    for (NSObject *value in values) {
        hash ^= value.hash;
    }
    return hash;
}

- (BOOL)isEqual:(id)object
{
    if (object == self)
    {
        return YES;
    }
    else if (![super isEqual:object])
    {
        return NO;
    }
    else
    {
        MSPVideoConfiguration *other = object;
        return CGSizeEqualToSize(other.videoSize, self.videoSize) &&
               other.videoFrameRate == self.videoFrameRate &&
               other.videoMaxFrameRate == self.videoMaxFrameRate &&
               other.videoMinFrameRate == self.videoMinFrameRate &&
               other.videoMaxKeyframeInterval == self.videoMaxKeyframeInterval &&
               other.videoBitRate == self.videoBitRate &&
               other.videoMaxBitRate == self.videoMaxBitRate &&
               other.videoMinBitRate == self.videoMinBitRate &&
               [other.avSessionPreset isEqualToString:self.avSessionPreset] &&
               other.sessionPreset == self.sessionPreset &&
               other.outputImageOrientation == self.outputImageOrientation &&
               other.autorotate == self.autorotate &&
               other.videoSizeRespectingAspectRatio == self.videoSizeRespectingAspectRatio;
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    MSPVideoConfiguration *other = [self.class defaultConfiguration];
    return other;
}

- (NSString *)description
{
    NSMutableString *desc = @"".mutableCopy;
    [desc appendFormat:@"<LFLiveVideoConfiguration: %p>", self];
    [desc appendFormat:@" videoSize:%@", NSStringFromCGSize(self.videoSize)];
    [desc appendFormat:@" videoSizeRespectingAspectRatio:%lu",(unsigned long)self.videoSizeRespectingAspectRatio];
    [desc appendFormat:@" videoFrameRate:%lu", (unsigned long)self.videoFrameRate];
    [desc appendFormat:@" videoMaxFrameRate:%lu", (unsigned long)self.videoMaxFrameRate];
    [desc appendFormat:@" videoMinFrameRate:%lu", (unsigned long)self.videoMinFrameRate];
    [desc appendFormat:@" videoMaxKeyframeInterval:%lu", (unsigned long)self.videoMaxKeyframeInterval];
    [desc appendFormat:@" videoBitRate:%lu", (unsigned long)self.videoBitRate];
    [desc appendFormat:@" videoMaxBitRate:%lu", (unsigned long)self.videoMaxBitRate];
    [desc appendFormat:@" videoMinBitRate:%lu", (unsigned long)self.videoMinBitRate];
    [desc appendFormat:@" avSessionPreset:%@", self.avSessionPreset];
    [desc appendFormat:@" sessionPreset:%lu", (unsigned long)self.sessionPreset];
    [desc appendFormat:@" outputImageOrientation:%li", (long)self.outputImageOrientation];
    [desc appendFormat:@" autorotate:%lu", (unsigned long)self.autorotate];
    return desc;
}

@end
