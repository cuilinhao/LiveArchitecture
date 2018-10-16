//
//  MSPSystemAVCapture.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPSystemAVCapture.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface MSPSystemAVCapture ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

// 前后摄像头
@property(nonatomic, strong) AVCaptureDeviceInput *frontCamera;
@property(nonatomic, strong) AVCaptureDeviceInput *backCamera;

// 视频设备
@property(nonatomic, strong) AVCaptureDeviceInput *videoInputDevice;
// 音频设备
//@property(nonatomic, strong) AVCaptureDeviceInput *audioInputDevice;

// 输出设备
@property(nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
//@property(nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;

// 会话
@property(nonatomic, strong) AVCaptureSession *captureSession;

@property(nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (null_resettable, nonatomic, strong) UIView *preView;

@property (nonatomic, strong) MSPVideoConfiguration *configuration;

@property (nonatomic, unsafe_unretained) BOOL inBackground;

@end


@implementation MSPSystemAVCapture

- (nullable instancetype)initWithVideoConfiguration:(nullable MSPVideoConfiguration *)configuration
{
    if (self = [super init])
    {
        _configuration = configuration;
        [self onInit];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
        
        
    }
    return self;
}

- (void)onInit
{
    [self createCaptureDevice];
    [self createOutput];
    [self createCaptureSession];
    [self createPreviewLayer];
    
    //更新fps
    //[self updateFps: self.configuration.videoFrameRate];
}

//初始化视频设备
-(void) createCaptureDevice{
    //创建视频设备
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //初始化摄像头
    self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.firstObject error:nil];
    self.backCamera =[AVCaptureDeviceInput deviceInputWithDevice:videoDevices.lastObject error:nil];
    
    //麦克风
    //AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    //self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    self.videoInputDevice = self.frontCamera;
}

//切换摄像头
-(void)setVideoInputDevice:(AVCaptureDeviceInput *)videoInputDevice{
    if ([videoInputDevice isEqual:_videoInputDevice]) {
        return;
    }
    //modifyinput
    [self.captureSession beginConfiguration];
    if (_videoInputDevice) {
        [self.captureSession removeInput:_videoInputDevice];
    }
    if (videoInputDevice) {
        [self.captureSession addInput:videoInputDevice];
    }
    
    [self setVideoOutConfig];
    
    [self.captureSession commitConfiguration];
    
    _videoInputDevice = videoInputDevice;
}

-(void) setVideoOutConfig{
    for (AVCaptureConnection *conn in self.videoDataOutput.connections) {
        if (conn.isVideoStabilizationSupported) {
            [conn setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
        }
        if (conn.isVideoOrientationSupported) {
            [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
        if (conn.isVideoMirrored) {
            [conn setVideoMirrored: YES];
        }
    }
}

//创建预览
-(void) createPreviewLayer{
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = self.preView.bounds;
    [self.preView.layer addSublayer:self.previewLayer];
}

//创建会话
-(void) createCaptureSession{
    self.captureSession = [AVCaptureSession new];
    
    [self.captureSession beginConfiguration];
    
    if ([self.captureSession canAddInput:self.videoInputDevice]) {
        [self.captureSession addInput:self.videoInputDevice];
    }
    
//    if ([self.captureSession canAddInput:self.audioInputDevice]) {
//        [self.captureSession addInput:self.audioInputDevice];
//    }
    
    if([self.captureSession canAddOutput:self.videoDataOutput]){
        [self.captureSession addOutput:self.videoDataOutput];
        [self setVideoOutConfig];
    }
    
//    if([self.captureSession canAddOutput:self.audioDataOutput]){
//        [self.captureSession addOutput:self.audioDataOutput];
//    }
    
    if (![self.captureSession canSetSessionPreset:self.captureSessionPreset]) {
        @throw [NSException exceptionWithName:@"Not supported captureSessionPreset" reason:[NSString stringWithFormat:@"captureSessionPreset is [%@]", self.captureSessionPreset] userInfo:nil];
    }
    
    self.captureSession.sessionPreset = self.captureSessionPreset;
    
    [self.captureSession commitConfiguration];
    
    [self.captureSession startRunning];
}

//销毁会话
-(void) destroyCaptureSession{
    if (self.captureSession) {
//        [self.captureSession removeInput:self.audioInputDevice];
        [self.captureSession removeInput:self.videoInputDevice];
        [self.captureSession removeOutput:self.self.videoDataOutput];
//        [self.captureSession removeOutput:self.self.audioDataOutput];
    }
    self.captureSession = nil;
}

//输出设备
-(void) createOutput{
    
    dispatch_queue_t captureQueue = dispatch_queue_create("msp.systemCapture.queue", DISPATCH_QUEUE_SERIAL);
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoDataOutput setSampleBufferDelegate:self queue:captureQueue];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoDataOutput setVideoSettings:@{
                                             (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                                             }];
//    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
//    [self.audioDataOutput setSampleBufferDelegate:self queue:captureQueue];
}

-(NSString *)captureSessionPreset{
    NSString *captureSessionPreset = nil;
    if(self.configuration.videoSize.width == 480 && self.configuration.videoSize.height == 640){
        captureSessionPreset = AVCaptureSessionPreset640x480;
    }else if(self.configuration.videoSize.width == 540 && self.configuration.videoSize.height == 960){
        captureSessionPreset = AVCaptureSessionPresetiFrame960x540;
    }else if(self.configuration.videoSize.width == 720 && self.configuration.videoSize.height == 1280){
        captureSessionPreset = AVCaptureSessionPreset1280x720;
    }
    return captureSessionPreset;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if ([self.videoDataOutput isEqual:captureOutput])
    {
        __weak typeof(self) _self = self;
        @autoreleasepool {
            CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            if (pixelBuffer && _self.delegate && [_self.delegate respondsToSelector:@selector(captureOutput:pixelBuffer:)])
            {
                [_self.delegate captureOutput:_self pixelBuffer:pixelBuffer];
            }
        }
    }
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
    UIInterfaceOrientation statusBar = [[UIApplication sharedApplication] statusBarOrientation];
}

@end
