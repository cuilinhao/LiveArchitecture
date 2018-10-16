//
//  MSPBaseCapture.m
//  MOBStreamingPusher
//
//  Created by wkx on 2018/9/25.
//  Copyright © 2018年 testDemo. All rights reserved.
//

#import "MSPBaseCapture.h"

@interface MSPBaseCapture ()

@property (nonatomic, strong) MSPAudioConfiguration *audioConfiguration;
@property (nonatomic, strong) MSPVideoConfiguration *videoConfiguration;
@property (nonatomic, strong) dispatch_queue_t taskQueue;

//进入后台后，不推视频流
@property (nonatomic, assign) BOOL inBackground;

@end

@implementation MSPBaseCapture

- (nullable instancetype)initWithAudioConfiguration:(nullable MSPAudioConfiguration *)audioConfiguration
                                 videoConfiguration:(nullable MSPVideoConfiguration *)videoConfiguration
{
    if (self = [super init])
    {
        _audioConfiguration = audioConfiguration;
        _videoConfiguration = videoConfiguration;
        [self onInit];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}

- (void) onInit{}

//修改fps
- (void) updateFps:(NSInteger) fps
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *vDevice in videoDevices)
    {
        float maxRate = [(AVFrameRateRange *)[vDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0] maxFrameRate];
        if (maxRate >= fps)
        {
            if ([vDevice lockForConfiguration:NULL])
            {
                _videoFrameRate = fps;
                vDevice.activeVideoMinFrameDuration = CMTimeMake(10, (int)(fps * 10));
                vDevice.activeVideoMaxFrameDuration = vDevice.activeVideoMinFrameDuration;
                [vDevice unlockForConfiguration];
            }
        }
    }
}

#pragma mark - Getter Setter

-(UIView *)preview
{
    if (!_preview)
    {
        _preview = [UIView new];
        _preview.bounds = [UIScreen mainScreen].bounds;
    }
    return _preview;
}

#pragma mark Notification

- (void)willEnterBackground:(NSNotification *)notification
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)willEnterForeground:(NSNotification *)notification
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)statusBarChanged:(NSNotification *)notification
{
    NSLog(@"UIApplicationWillChangeStatusBarOrientationNotification. UserInfo: %@", notification.userInfo);
    //UIInterfaceOrientation statusBar = [[UIApplication sharedApplication] statusBarOrientation];
}

@end
