//
//  MSPAVSession.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPAVSession.h"
#import "MSPAudioCapture.h"
#import "MSPVideoCapture.h"
#import "MSPAudioHWEncoder.h"
#import "MSPVideoHWEncoder.h"
#import "MSPStreamSocket.h"
#import "MSPRtmpSocket.h"
#import "MSPTestSocket.h"


/**  时间戳 */
#define NOW (CACurrentMediaTime()*1000)

@interface MSPAVSession ()<MSPVideoCaptureDelegate,MSPAudioCaptureDelegate,MSPVideoEncoderDelegate,MSPAudioEncoderDelegate,MSPStreamSocketDelegate>

/// 音频配置
@property (nonatomic, strong) MSPAudioConfiguration *audioConfiguration;
/// 视频配置
@property (nonatomic, strong) MSPVideoConfiguration *videoConfiguration;
/// 声音采集
@property (nonatomic, strong) MSPAudioCapture *audioCaptureSource;
/// 视频采集
@property (nonatomic, strong) MSPVideoCapture *videoCaptureSource;
/// 音频编码
@property (nonatomic, strong) id<MSPAudioBaseEncoder> audioEncoder;
/// 视频编码
@property (nonatomic, strong) id<MSPVideoBaseEncoder> videoEncoder;
/// 推流
@property (nonatomic, strong) id<MSPStreamSocket> socket;

/// 流信息
@property (nonatomic, strong) MSPStreamConfig *streamConfig;

/// 当前状态
@property (nonatomic, assign, readwrite) MSPSocketState state;

/// 时间戳锁
@property (nonatomic, strong) dispatch_semaphore_t lock;

/// 推流相对时间戳
@property (nonatomic, assign) uint64_t relativeTimestamps;
/// 当前是否采集到了音频
@property (nonatomic, assign) BOOL hasCaptureAudio;
/// 当前是否采集到了关键帧
@property (nonatomic, assign) BOOL hasKeyFrameVideo;
/// 音视频是否对齐
@property (nonatomic, assign) BOOL AVAlignment;

@property (nonatomic, assign) BOOL isPushStream;


@end

@implementation MSPAVSession

- (nullable instancetype)initWithAudioConfiguration:(nullable MSPAudioConfiguration *)audioConfiguration videoConfiguration:(nullable MSPVideoConfiguration *)videoConfiguration
{
    if (self = [super init])
    {
        _audioConfiguration = audioConfiguration;
        _videoConfiguration = videoConfiguration;
    }
    
    return self;
}

- (void)dealloc
{
    self.videoCaptureSource.running = NO;
    self.audioCaptureSource.running = NO;
}

- (void)startLive:(nonnull MSPStreamConfig *)streamConfig
{
    if (!streamConfig) return;
    _isPushStream = YES;
    _streamConfig = streamConfig;
    _streamConfig.videoConfiguration = _videoConfiguration;
    _streamConfig.audioConfiguration = _audioConfiguration;
    [self.socket start];
}

- (void)stopLive
{
    _isPushStream = NO;
    [self.socket stop];
    self.socket = nil;
}

#pragma mark - CaptureDelegate:MSPVideoCaptureDelegate、MSPAudioCaptureDelegate

- (void)captureOutput:(id)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (self.isPushStream)
    {
        [self.videoEncoder encodeVideoData:pixelBuffer timeStamp:NOW];
    }
}

- (void)captureOutput:(id)capture audioData:(NSData *)audioData
{
    if (self.isPushStream)
    {
        [self.audioEncoder encodeAudioData:audioData timeStamp:NOW];
    }
    
}

#pragma mark - EncoderDelegate:MSPVideoEncoderDelegate、MSPAudioEncoderDelegate

- (void)videoEncoder:(id<MSPVideoBaseEncoder>)encoder videoFrame:(MSPVideoFrame *)frame
{
    if (self.isPushStream)
    {
        
        if (frame.isKeyFrame && self.hasCaptureAudio)
        {
            self.hasKeyFrameVideo = YES;
        }
        
        if (self.AVAlignment)
        {
            [self pushSendBuffer:frame];
        }
    }
}

- (void)audioEncoder:(id<MSPAudioBaseEncoder>)encoder audioFrame:(MSPAudioFrame *)frame
{
    if (self.isPushStream)
    {
        self.hasCaptureAudio = YES;
        
        if (self.AVAlignment)
        {
            [self pushSendBuffer:frame];
        }
    }
}

#pragma mark - MSPStreamSocketDelegate

/** callback socket current status (回调当前网络情况) */
- (void)socketStatus:(nullable id <MSPStreamSocket>)socket status:(MSPSocketState)status
{
    if (status == MSPSocketState_Start)
    {
        if (!self.isPushStream)
        {
            self.hasCaptureAudio = NO;
            self.hasKeyFrameVideo = NO;
            self.relativeTimestamps = 0;
            self.isPushStream = YES;
        }
    }
    else if(status == MSPSocketState_Stop || status == MSPSocketState_Error)
    {
        self.isPushStream = NO;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.state = status;
        if (self.delegate && [self.delegate respondsToSelector:@selector(AVSession:stateDidChange:)])
        {
            [self.delegate AVSession:self stateDidChange:status];
        }
    });
}

/** callback socket errorcode */
- (void)socketDidError:(nullable id <MSPStreamSocket>)socket errorCode:(MSPSocketErrorCode)errorCode
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(AVSession:errorCode:)])
        {
            [self.delegate AVSession:self errorCode:errorCode];
        }
    });
}

- (void)socketBufferStatus:(nullable id <MSPStreamSocket>)socket status:(MSPStreamBuffferState)status
{
    if(self.autoBitrate)
    {
        NSUInteger videoBitRate = [self.videoEncoder videoBitRate];
        if (status == MSPStreamBuffferDecline)
        {
            if (videoBitRate < _videoConfiguration.videoMaxBitRate)
            {
                videoBitRate = videoBitRate + 50 * 1000;
                [self.videoEncoder setVideoBitRate:videoBitRate];
                NSLog(@"Increase bitrate %@", @(videoBitRate));
            }
        }
        else
        {
            if (videoBitRate > self.videoConfiguration.videoMinBitRate)
            {
                videoBitRate = videoBitRate - 100 * 1000;
                [self.videoEncoder setVideoBitRate:videoBitRate];
                NSLog(@"Decline bitrate %@", @(videoBitRate));
            }
        }
    }
}

#pragma mark - SendBuffer

- (void)pushSendBuffer:(MSPBaseFrame *)frame
{
    if(self.relativeTimestamps == 0)
    {
        self.relativeTimestamps = frame.timestamp;
    }
    frame.timestamp = [self uploadTimestamp:frame.timestamp];
    [self.socket sendFrame:frame];
}

#pragma mark - Setter Getter

- (void)setRunning:(BOOL)running
{
    if (_running == running) return;
    _running = running;

    self.videoCaptureSource.running = _running;
    self.audioCaptureSource.running = _running;
    
}

- (void)setPreView:(UIView *)preView
{
    [self.videoCaptureSource setPreView:preView];
}
- (UIView *)preView
{
    return self.videoCaptureSource.preView;
}

- (void)setCaptureDevicePosition:(AVCaptureDevicePosition)captureDevicePosition
{
    [self.videoCaptureSource setCaptureDevicePosition:captureDevicePosition];
}

- (AVCaptureDevicePosition)captureDevicePosition
{
    return self.videoCaptureSource.captureDevicePosition;
}

- (void)setBeautyFace:(BOOL)beautyFace
{
    [self.videoCaptureSource setBeautyFace:beautyFace];
}

- (BOOL)beautyFace
{
    return self.videoCaptureSource.beautyFace;
}

- (void)setBeautyLevel:(CGFloat)beautyLevel
{
    [self.videoCaptureSource setBeautyLevel:beautyLevel];
}

- (CGFloat)beautyLevel
{
    return self.videoCaptureSource.beautyLevel;
}

- (void)setBrightLevel:(CGFloat)brightLevel
{
    [self.videoCaptureSource setBrightLevel:brightLevel];
}

- (CGFloat)brightLevel
{
    return self.videoCaptureSource.brightLevel;
}

- (void)setZoomScale:(CGFloat)zoomScale
{
    [self.videoCaptureSource setZoomScale:zoomScale];
}

- (CGFloat)zoomScale
{
    return self.videoCaptureSource.zoomScale;
}

- (void)setTorch:(BOOL)torch
{
    [self.videoCaptureSource setTorch:torch];
}

- (BOOL)torch
{
    return self.videoCaptureSource.torch;
}

- (void)setMirror:(BOOL)mirror
{
    [self.videoCaptureSource setMirror:mirror];
}

- (BOOL)mirror {
    return self.videoCaptureSource.mirror;
}

- (void)setSaveLocalVideo:(BOOL)saveLocalVideo
{
    [self.videoCaptureSource setSaveLocalVideo:saveLocalVideo];
}

- (BOOL)saveLocalVideo
{
    return self.videoCaptureSource.saveLocalVideo;
}

- (void)setSaveLocalVideoPath:(NSURL *)saveLocalVideoPath
{
    [self.videoCaptureSource setSaveLocalVideoPath:saveLocalVideoPath];
}

- (NSURL *)saveLocalVideoPath
{
    return self.videoCaptureSource.saveLocalVideoPath;
}

- (void)setMuted:(BOOL)muted
{
    [self.audioCaptureSource setMuted:muted];
}

- (BOOL)muted
{
    return self.audioCaptureSource.muted;
}

- (MSPAudioCapture *)audioCaptureSource
{
    if (!_audioCaptureSource)
    {
        _audioCaptureSource = [[MSPAudioCapture alloc] initWithAudioConfiguration:_audioConfiguration];
        _audioCaptureSource.delegate = self;
    }
    return _audioCaptureSource;
}

- (MSPVideoCapture *)videoCaptureSource
{
    if (!_videoCaptureSource)
    {
        _videoCaptureSource = [[MSPVideoCapture alloc] initWithVideoConfiguration:_videoConfiguration];
        _videoCaptureSource.delegate = self;
    }
    return _videoCaptureSource;
}

- (id<MSPAudioBaseEncoder>)audioEncoder
{
    if (!_audioEncoder)
    {
        _audioEncoder = [[MSPAudioHWEncoder alloc] initWithAudioStreamConfiguration:_audioConfiguration];
        [_audioEncoder setDelegate:self];
    }
    return _audioEncoder;
}

- (id<MSPVideoBaseEncoder>)videoEncoder
{
    if (!_videoEncoder)
    {
        _videoEncoder = [[MSPVideoHWEncoder alloc] initWithVideoStreamConfiguration:_videoConfiguration];
        [_videoEncoder setDelegate:self];
    }
    return _videoEncoder;
}

- (id<MSPStreamSocket>)socket
{
    if (!_socket)
    {
        _socket = [[MSPRtmpSocket alloc] initWithStream:self.streamConfig reconnectInterval:self.reconnectInterval reconnectCount:self.reconnectCount];
//        _socket = [[MSPTestSocket alloc] initWithStream:self.streamConfig reconnectInterval:self.reconnectInterval reconnectCount:self.reconnectCount];
        [_socket setDelegate:self];
    }
    return _socket;
}

#pragma mark - Private

- (dispatch_semaphore_t)lock
{
    if(!_lock)
    {
        _lock = dispatch_semaphore_create(1);
    }
    return _lock;
}

- (uint64_t)uploadTimestamp:(uint64_t)captureTimestamp
{
    dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
    uint64_t currentts = 0;
    currentts = captureTimestamp - self.relativeTimestamps;
    dispatch_semaphore_signal(self.lock);
    return currentts;
}

- (BOOL)AVAlignment
{
    if(self.hasKeyFrameVideo && self.hasCaptureAudio)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
