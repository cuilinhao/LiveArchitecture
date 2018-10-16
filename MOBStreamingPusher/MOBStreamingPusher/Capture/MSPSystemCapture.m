//
//  MSPSystemCapture.m
//  MOBStreamingPusher
//
//  Created by wkx on 2018/9/25.
//  Copyright © 2018年 testDemo. All rights reserved.
//

#import "MSPSystemCapture.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@interface MSPSystemCapture ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

//前后摄像头
@property (nonatomic, strong) AVCaptureDeviceInput *frontCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *backCamera;

//当前使用的视频设备
@property (nonatomic, weak) AVCaptureDeviceInput *videoInputDevice;
//音频设备
@property (nonatomic, strong) AVCaptureDeviceInput *audioInputDevice;

//输出数据接收
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;

//会话
@property (nonatomic, strong) AVCaptureSession *captureSession;

//预览
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, assign) BOOL capturePaused;

@property (nonatomic, strong) dispatch_queue_t videoTaskQueue;
@property (nonatomic, strong) dispatch_queue_t audioTaskQueue;

@end

@implementation MSPSystemCapture
@synthesize running = _running;
@synthesize captureDevicePosition = _captureDevicePosition;
@synthesize preview = _preview;
@synthesize videoFrameRate = _videoFrameRate;
@synthesize torch = _torch;
@synthesize mirror = _mirror;
@synthesize zoomScale = _zoomScale;

- (void)onInit
{
//    self.audioTaskQueue = dispatch_queue_create("com.mob.streamingPusher.audioCapture.Queue", NULL);
//    self.videoTaskQueue = dispatch_queue_create("com.mob.streamingPusher.videoCapture.Queue", NULL);
//
    
    self.capturePaused = NO;
    [self createCaptureDevice];
    [self createOutput];
    [self createCaptureSession];
    //[self createPreviewLayer];
    
    //更新fps
    [self updateFps: self.videoConfiguration.videoFrameRate];
    
    //route变化监听
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleRouteChange:)
                                                 name: AVAudioSessionRouteChangeNotification
                                               object: self.captureSession];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleInterruption:)
                                                 name: AVAudioSessionInterruptionNotification
                                               object: self.captureSession];
}

//初始化视频设备
-(void) createCaptureDevice
{
    //创建视频设备
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //初始化摄像头
    for (AVCaptureDevice *device in videoDevices)
    {
        switch (device.position)
        {
            case AVCaptureDevicePositionFront:
                self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
                break;
            case AVCaptureDevicePositionBack:
                 self.backCamera =[AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            default:
                break;
        }
    }

    
    //麦克风
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    if (self.frontCamera)
    {
        self.videoInputDevice = self.frontCamera;
        _captureDevicePosition = AVCaptureDevicePositionFront;
    }
    else if (self.backCamera)
    {
        self.videoInputDevice = self.backCamera;
        _captureDevicePosition = AVCaptureDevicePositionBack;
    }
    
}

//切换摄像头
-(void)setVideoInputDevice:(AVCaptureDeviceInput *)videoInputDevice
{
    if ([videoInputDevice isEqual:_videoInputDevice])
    {
        return;
    }
    //modifyinput
    [self.captureSession beginConfiguration];
    if (_videoInputDevice)
    {
        [self.captureSession removeInput:_videoInputDevice];
    }
    if (videoInputDevice)
    {
        [self.captureSession addInput:videoInputDevice];
    }
    
    [self setVideoOutConfig];
    
    [self.captureSession commitConfiguration];
    
    _videoInputDevice = videoInputDevice;
}

//创建预览
-(void) createPreviewLayer
{
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = self.preview.bounds;
    [self.preview.layer addSublayer:self.previewLayer];
}

-(void) setVideoOutConfig
{
    for (AVCaptureConnection *conn in self.videoDataOutput.connections)
    {
        if (conn.isVideoStabilizationSupported)
        {
            [conn setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
        }
        if (conn.isVideoOrientationSupported)
        {
            [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
        if (conn.isVideoMirrored)
        {
            [conn setVideoMirrored: YES];
        }
    }
}

//创建会话
-(void) createCaptureSession
{
    self.captureSession = [AVCaptureSession new];
    
    [self.captureSession beginConfiguration];
    
    if ([self.captureSession canAddInput:self.videoInputDevice])
    {
        [self.captureSession addInput:self.videoInputDevice];
    }
    
    if([self.captureSession canAddOutput:self.videoDataOutput])
    {
        [self.captureSession addOutput:self.videoDataOutput];
        [self setVideoOutConfig];
    }
    
    if ([self.captureSession canAddInput:self.audioInputDevice])
    {
        [self.captureSession addInput:self.audioInputDevice];
    }
    
    if([self.captureSession canAddOutput:self.audioDataOutput])
    {
        [self.captureSession addOutput:self.audioDataOutput];
        [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    
    if (![self.captureSession canSetSessionPreset:self.videoConfiguration.avSessionPreset])
    {
        @throw [NSException exceptionWithName:@"Not supported captureSessionPreset" reason:[NSString stringWithFormat:@"captureSessionPreset is [%@]", self.videoConfiguration.avSessionPreset] userInfo:nil];
    }
    
    self.captureSession.sessionPreset = self.videoConfiguration.avSessionPreset;
    
    [self.captureSession commitConfiguration];
    
    [self.captureSession startRunning];
}

//销毁会话
-(void) destroyCaptureSession
{
    if (self.captureSession)
    {
        [self.captureSession stopRunning];
        [self.captureSession removeInput:self.audioInputDevice];
        [self.captureSession removeInput:self.videoInputDevice];
        [self.captureSession removeOutput:self.self.videoDataOutput];
        [self.captureSession removeOutput:self.self.audioDataOutput];
    }
    self.captureSession = nil;
}

-(void) createOutput{
    
    self.audioTaskQueue = dispatch_queue_create("msp.audioCapture.queue", DISPATCH_QUEUE_SERIAL);
    self.videoTaskQueue = dispatch_queue_create("msp.videoCapture.queue", DISPATCH_QUEUE_SERIAL);
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoTaskQueue];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoDataOutput setVideoSettings:@{
                                             (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                                             }];
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioDataOutput setSampleBufferDelegate:self queue:self.audioTaskQueue];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.capturePaused)
    {
        return;
    }
//    if (self.isRunning)
//    {
        if ([self.videoDataOutput isEqual:captureOutput])
        {
            
            CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureOutput:audioData:)])
            {
                [self.delegate captureOutput:captureOutput pixelBuffer:pixelBuffer];
            }
        }
        else if([self.audioDataOutput isEqual:captureOutput])
        {

            NSMutableData *data = [[NSMutableData alloc] init];
            CMBlockBufferRef blockBuffer = nil;
            AudioBufferList audioBufferList;
            if(CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer) != noErr)
            {
                return;
            }
            
            for (int y = 0; y < audioBufferList.mNumberBuffers; y++)
            {
                AudioBuffer audioBuffer = audioBufferList.mBuffers[y];
                Float32 *frame = (Float32 *)audioBuffer.mData;
//                NSData *data_temp = [[NSData alloc] initWithBytes:audioBuffer.mData length:audioBuffer.mDataByteSize];
//                [data appendData:data_temp];
                [data appendBytes:frame length:audioBuffer.mDataByteSize];
            }
//            if (self.muted)
//            {
//                for (int i = 0; i < audioBufferList.mNumberBuffers; i++)
//                {
//                    AudioBuffer ab = audioBufferList.mBuffers[i];
//                    memset(ab.mData, 0, ab.mDataByteSize);
//                }
//            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureOutput:audioData:)])
            {
                
//               NSData *datatmp = [[NSData alloc] initWithBytes:audioBufferList.mBuffers[0].mData length:audioBufferList.mBuffers[0].mDataByteSize];
                [self.delegate captureOutput:captureOutput audioData:data];
            }
            CFRelease(blockBuffer);
            
            
//            // 获取pcm数据大小
//            NSInteger audioDataSize = CMSampleBufferGetTotalSampleSize(sampleBuffer);
//            // 分配空间
//            int8_t *audio_data = malloc(audioDataSize);
//            memset(audio_data, 0, audioDataSize);
//
//            //获取CMBlockBufferRef
//            //这个结构里面保存了PCM数据
//            CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
//            //将数据copy至我们自己分配的内存中
//            CMBlockBufferCopyDataBytes(dataBuffer, 0, audioDataSize, audio_data);
//
//            NSData *data = [NSData dataWithBytesNoCopy:audio_data length:audioDataSize];
//            if (self.delegate && [self.delegate respondsToSelector:@selector(captureOutput:audioData:)])
//            {
//                [self.delegate captureOutput:captureOutput audioData:data];
//            }
            

        }
        else
        {
            NSLog(@"......");
        }
//    }
}

#pragma mark - Getter Setter

- (void)setCaptureDevicePosition:(AVCaptureDevicePosition)captureDevicePosition
{
    if(captureDevicePosition == _captureDevicePosition) return;
    switch (captureDevicePosition)
    {
        case AVCaptureDevicePositionFront:
            self.videoInputDevice = self.frontCamera;
            break;
        case AVCaptureDevicePositionBack:
            self.videoInputDevice = self.backCamera;
            break;
        default:
            break;
    }
    _captureDevicePosition = captureDevicePosition;
    [self updateFps: self.videoConfiguration.videoFrameRate];
    [self reloadMirror];
}

- (AVCaptureDevicePosition)captureDevicePosition
{
    return _captureDevicePosition;
}

- (void)reloadMirror
{
    AVCaptureConnection *connection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if(self.mirror && self.captureDevicePosition == AVCaptureDevicePositionFront)
    {
        connection.videoMirrored = YES;
    }
    else
    {
        connection.videoMirrored = NO;
    }
}

- (void)setRunning:(BOOL)running
{
    if (_running == running) return;
    _running = running;
    
    if (!_running)
    {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        [self.captureSession stopRunning];
    }
    else
    {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        [self.captureSession isRunning];
        [self.captureSession startRunning];
    }
}

- (void)setPreview:(UIView *)preview
{
    _preview = preview;
    if (!self.captureSession)
    {
        return;
    }
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = preview.bounds;
    //[_preview.layer addSublayer:self.previewLayer];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_preview.layer insertSublayer:self.previewLayer atIndex:0];
    });
    
}

- (void)setVideoFrameRate:(NSInteger)videoFrameRate
{
    if (videoFrameRate <= 0) return;
    if (videoFrameRate == _videoFrameRate) return;
    [self updateFps:videoFrameRate];
}

- (NSInteger)videoFrameRate
{
    return _videoFrameRate;
}

- (void)setTorch:(BOOL)torch
{
    BOOL ret = NO;
    if (!_captureSession) return;
    [_captureSession beginConfiguration];
    if (_videoInputDevice.device)
    {
        if (_videoInputDevice.device.torchAvailable)
        {
             NSError *err = nil;
            if ([_videoInputDevice.device lockForConfiguration:&err]) {
                [_videoInputDevice.device setTorchMode:(torch ? AVCaptureTorchModeOn : AVCaptureTorchModeOff) ];
                [_videoInputDevice.device unlockForConfiguration];
                ret = (_videoInputDevice.device.torchMode == AVCaptureTorchModeOn);
            }
            else
            {
                NSLog(@"Error while locking device for torch: %@", err);
                ret = false;
            }
        }
    }
    [_captureSession commitConfiguration];
    _torch = ret;
}

- (BOOL)torch
{
    return _videoInputDevice.device.torchMode;
}

- (void)setMirror:(BOOL)mirror
{
    _mirror = mirror;
}

- (void)setBeautyFace:(BOOL)beautyFace
{
}

- (void)setBeautyLevel:(CGFloat)beautyLevel
{
}

- (CGFloat)beautyLevel
{
    return 0;
}

- (void)setBrightLevel:(CGFloat)brightLevel
{
}

- (CGFloat)brightLevel
{
    return 0;
}

- (void)setZoomScale:(CGFloat)zoomScale
{
    if (_videoInputDevice && _videoInputDevice.device)
    {
        AVCaptureDevice *device = (AVCaptureDevice *)_videoInputDevice.device;
        if ([device lockForConfiguration:nil])
        {
            device.videoZoomFactor = zoomScale;
            [device unlockForConfiguration];
            _zoomScale = zoomScale;
        }
    }
}

- (CGFloat)zoomScale
{
    return _zoomScale;
}

- (void)setWarterMarkView:(UIView *)warterMarkView
{
}


#pragma mark Notification

- (void)willEnterBackground:(NSNotification *)notification
{
    [super willEnterBackground:notification];
    self.capturePaused = YES;
}

- (void)willEnterForeground:(NSNotification *)notification
{
    [super willEnterForeground:notification];
    self.capturePaused = NO;
}

- (void)statusBarChanged:(NSNotification *)notification
{
    [super statusBarChanged:notification];
}

- (void)handleRouteChange:(NSNotification *)notification
{
    AVAudioSession *session = [ AVAudioSession sharedInstance];
    NSString *seccReason = @"";
    NSInteger reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    //  AVAudioSessionRouteDescription* prevRoute = [[notification userInfo] objectForKey:AVAudioSessionRouteChangePreviousRouteKey];
    switch (reason)
    {
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            seccReason = @"The route changed because no suitable route is now available for the specified category.";
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            seccReason = @"The route changed when the device woke up from sleep.";
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            seccReason = @"The output route was overridden by the app.";
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            seccReason = @"The category of the session object changed.";
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            seccReason = @"The previous audio output path is no longer available.";
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            seccReason = @"A preferred new audio output path is now available.";
            break;
        case AVAudioSessionRouteChangeReasonUnknown:
        default:
            seccReason = @"The reason for the change is unknown.";
            break;
    }
    NSLog(@"handleRouteChange reason is %@", seccReason);
    
    AVAudioSessionPortDescription *input = [[session.currentRoute.inputs count] ? session.currentRoute.inputs : nil objectAtIndex:0];
    if (input.portType == AVAudioSessionPortHeadsetMic)
    {
        
    }
}

- (void)handleInterruption:(NSNotification *)notification
{
    NSInteger reason = 0;
    NSString *reasonStr = @"";
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification])
    {
        //Posted when an audio interruption occurs.
        reason = [[[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
        if (reason == AVAudioSessionInterruptionTypeBegan)
        {
            if (self.isRunning)
            {
 
                    NSLog(@"MicrophoneSource: stopRunning");
              
            }
        }
        
        if (reason == AVAudioSessionInterruptionTypeEnded)
        {
            reasonStr = @"AVAudioSessionInterruptionTypeEnded";
            NSNumber *seccondReason = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
            switch ([seccondReason integerValue])
            {
                case AVAudioSessionInterruptionOptionShouldResume:
                    if (self.isRunning) {
                            NSLog(@"MicrophoneSource: startRunning");
                    }
                    // Indicates that the audio session is active and immediately ready to be used. Your app can resume the audio operation that was interrupted.
                    break;
                default:
                    break;
            }
        }
        
    }
    ;
    NSLog(@"handleInterruption: %@ reason %@", [notification name], reasonStr);
}

//-(NSData *)convertVideoSmapleBufferToYuvData:(CMSampleBufferRef) videoSample
//{
//    // 获取yuv数据
//    // 通过CMSampleBufferGetImageBuffer方法，获得CVImageBufferRef。
//    // 这里面就包含了yuv420数据的指针
//    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(videoSample);
//
//    //表示开始操作数据
//    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//
//    //图像宽度（像素）
//    size_t pixelWidth = aw_stride(CVPixelBufferGetWidth(pixelBuffer));
//    //图像高度（像素）
//    size_t pixelHeight = CVPixelBufferGetHeight(pixelBuffer);
//    //yuv中的y所占字节数
//    size_t y_size = pixelWidth * pixelHeight;
//    //yuv中的u和v分别所占的字节数
//    size_t uv_size = y_size / 4;
//
//    uint8_t *yuv_frame = aw_alloc(uv_size * 2 + y_size);
//
//    //获取CVImageBufferRef中的y数据
//    uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
//    memcpy(yuv_frame, y_frame, y_size);
//
//    //获取CMVImageBufferRef中的uv数据
//    uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
//    memcpy(yuv_frame + y_size, uv_frame, uv_size * 2);
//
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//
//    NSData *nv12Data = [NSData dataWithBytesNoCopy:yuv_frame length:y_size + uv_size * 2];
//
//    return nv12Data;
//}
//
//- (CVPixelBufferRef)convertYuvDataToCVPixelBufferRef:(NSData *)yuvData
//{
//    //yuv 变成 转CVPixelBufferRef
//    OSStatus status = noErr;
//
//    //视频宽度
//    size_t pixelWidth = self.videoConfig.pushStreamWidth;
//    //视频高度
//    size_t pixelHeight = self.videoConfig.pushStreamHeight;
//
//    //现在要把NV12数据放入 CVPixelBufferRef中，因为 硬编码主要调用VTCompressionSessionEncodeFrame函数，此函数不接受yuv数据，但是接受CVPixelBufferRef类型。
//    CVPixelBufferRef pixelBuf = NULL;
//    //初始化pixelBuf，数据类型是kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange，此类型数据格式同NV12格式相同。
//    CVPixelBufferCreate(NULL, pixelWidth, pixelHeight, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, NULL, &pixelBuf);
//
//    // Lock address，锁定数据，应该是多线程防止重入操作。
//    if(CVPixelBufferLockBaseAddress(pixelBuf, 0) != kCVReturnSuccess){
//        [self onErrorWithCode:AWEncoderErrorCodeLockSampleBaseAddressFailed des:@"encode video lock base address failed"];
//        return NULL;
//    }
//
//    //将yuv数据填充到CVPixelBufferRef中
//    size_t y_size = aw_stride(pixelWidth) * pixelHeight;
//    size_t uv_size = y_size / 4;
//    uint8_t *yuv_frame = (uint8_t *)yuvData.bytes;
//
//    //处理y frame
//    uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuf, 0);
//    memcpy(y_frame, yuv_frame, y_size);
//
//    uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuf, 1);
//    memcpy(uv_frame, yuv_frame + y_size, uv_size * 2);
//
//    CVPixelBufferUnlockBaseAddress(pixelBuf, 0);
//    return pixelBuf;
//}

@end
