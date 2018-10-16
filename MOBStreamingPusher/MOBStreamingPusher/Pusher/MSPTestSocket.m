//
//  MSPTestSocket.m
//  MOBStreamingPusher
//
//  Created by wkx on 2018/9/26.
//  Copyright © 2018年 testDemo. All rights reserved.
//

#import "MSPTestSocket.h"

#import "MSPStreamBuffer.h"
#import "MSPVideoFrame.h"
#import "MSPAudioFrame.h"
#import "MSPFLVWrite.h"
#import "MSPFLVMetadata.h"
#import "MSPFLVDefine.h"
#import "NSMutableData+MSPBytes.h"

//#if __has_include(<pili-librtmp/rtmp.h>)
//#import <pili-librtmp/rtmp.h>
//#else
//#import "rtmp.h"
//#endif

#define RTMP_RECEIVE_TIMEOUT    2

static const NSInteger RetryTimesBreaken = 5;  ///<  重连1分钟  3秒一次 一共20次
static const NSInteger RetryTimesMargin = 3;

@interface MSPTestSocket ()<MSPStreamBufferDelegate>
{
    //PILI_RTMP *_rtmp;
}

@property (nonatomic, weak) id<MSPStreamSocketDelegate> delegate;
@property (nonatomic, strong) MSPStreamConfig *streamConfig;
@property (nonatomic, strong) MSPStreamBuffer *buffer;
@property (nonatomic, strong) dispatch_queue_t rtmpSendQueue;

@property (nonatomic, assign) NSInteger retryTimes4netWorkBreaken;
@property (nonatomic, assign) NSInteger reconnectInterval;
@property (nonatomic, assign) NSInteger reconnectCount;

@property (atomic, assign) BOOL isSending;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) BOOL isConnecting;
@property (nonatomic, assign) BOOL isReconnecting;

@property (nonatomic, assign) BOOL isSendVideoConfRecord;
@property (nonatomic, assign) BOOL isSendAudioConfRecord;

@property (nonatomic, strong) NSFileHandle *outputFileHandle;

@property (nonatomic, strong) MSPFLVWrite *flvWrite;

@end

@implementation MSPTestSocket

#pragma mark - MSPStreamSocket

- (nullable instancetype)initWithStream:(nullable MSPStreamConfig *)streamConfig
{
    return [self initWithStream:streamConfig reconnectInterval:0 reconnectCount:0];
}

- (nullable instancetype)initWithStream:(nullable MSPStreamConfig *)streamConfig reconnectInterval:(NSInteger)reconnectInterval reconnectCount:(NSInteger)reconnectCount
{
    if (!streamConfig) @throw [NSException exceptionWithName:@"MSPRtmpSocket init error" reason:@"stream is nil" userInfo:nil];
    if (self = [super init]) {
        _streamConfig = streamConfig;
        if (reconnectInterval > 0) _reconnectInterval = reconnectInterval;
        else _reconnectInterval = RetryTimesMargin;
        
        if (reconnectCount > 0) _reconnectCount = reconnectCount;
        else _reconnectCount = RetryTimesBreaken;
        
        [self addObserver:self forKeyPath:@"isSending" options:NSKeyValueObservingOptionNew context:nil];//这里改成observer主要考虑一直到发送出错情况下，可以继续发送
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"isSending"];
}

- (void)start
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.rtmpSendQueue, ^{
        [weakSelf _start];
    });
}

- (void)_start
{
    if (!_streamConfig) return;
    if (_isConnecting) return;
    if (_isConnecting) return;
    
    _isConnecting = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketStatus:status:)])
    {
        [self.delegate socketStatus:self status:MSPSocketState_Pending];
    }
    

    [self RTMP264_Connect:(char *)[_streamConfig.url cStringUsingEncoding:NSASCIIStringEncoding]];
}

- (void)stop
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.rtmpSendQueue, ^{
        [weakSelf _stop];
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    });
}

- (void)_stop
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketStatus:status:)])
    {
        [self.delegate socketStatus:self status:MSPSocketState_Stop];
    }
    
    [self _clean];
}

- (void)_clean
{
    if (_outputFileHandle)
    {
        [_outputFileHandle closeFile];
        _outputFileHandle = nil;
    }
    
    _isConnecting = NO;
    _isReconnecting = NO;
    _isSending = NO;
    _isConnected = NO;
    _isSendAudioConfRecord = NO;
    _isSendVideoConfRecord = NO;
    [self.buffer removeAllObject];
    self.retryTimes4netWorkBreaken = 0;
}

- (void)setDelegate:(nullable id <MSPStreamSocketDelegate>)delegate
{
    _delegate = delegate;
}

- (void)sendFLVHeader
{
    [self.flvWrite writeHeader];
    [self _sendData:self.flvWrite.packet];
    NSLog(@"flv=================FLVHeader length：%ld",self.flvWrite.packet.length);
    NSLog(@"flv=================FLVHeader data：%@",self.flvWrite.packet);
    [self.flvWrite reset];
}

- (void)sendMetaData
{
    MSPFLVMetadata *metadata = [[MSPFLVMetadata alloc] init];
    
    // set video encoding metadata
    metadata.width = _streamConfig.videoConfiguration.videoSize.width;
    metadata.height = _streamConfig.videoConfiguration.videoSize.height;
    metadata.videoBitrate = _streamConfig.videoConfiguration.videoBitRate / 1024.0;
    metadata.framerate = _streamConfig.videoConfiguration.videoFrameRate;
    metadata.videoCodecId = msp_flv_video_codecid_H264;
    
    // set audio encoding metadata
    metadata.audioBitrate = _streamConfig.audioConfiguration.audioBitRate;
    metadata.sampleRate = _streamConfig.audioConfiguration.audioSampleRate;
    metadata.sampleSize = 16;// * 1024; // 16K
    metadata.stereo = _streamConfig.audioConfiguration.numberOfChannels == 2;
    metadata.audioCodecId = msp_flv_audio_codecid_AAC;
    
    [self.flvWrite writeMetaTag:metadata];
    [self _sendData:self.flvWrite.packet];
    NSLog(@"flv=================Metadata length：%ld",self.flvWrite.packet.length);
    NSLog(@"flv=================Metadata data：%@",self.flvWrite.packet);
    [self.flvWrite reset];
}

- (void)sendFrame:(nullable MSPBaseFrame *)frame
{
    if (!frame) return;
    [self.buffer appendObject:frame];
    
    if (!self.isSending)
    {
        [self _sendFrame];
    }
}

- (void)_sendFrame
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.rtmpSendQueue, ^{
        if (!weakSelf.isSending && weakSelf.buffer.list.count > 0)
        {
            weakSelf.isSending = YES;
            if (!weakSelf.isConnected || weakSelf.isReconnecting || weakSelf.isConnecting)
            {
                weakSelf.isSending = NO;
                return;
            }
            MSPBaseFrame *frame =  [weakSelf.buffer popFirstObject];
            if ([frame isKindOfClass:[MSPVideoFrame class]])
            {
                if (!weakSelf.isSendVideoConfRecord)
                {
                    weakSelf.isSendVideoConfRecord = YES;
                    if (!((MSPVideoFrame *)frame).sps || !((MSPVideoFrame *)frame).pps)
                    {
                        weakSelf.isSending = NO;
                        return;
                    }
                    [weakSelf _send_video_sps_pps:(MSPVideoFrame *)frame];
                }
                else
                {
                    [weakSelf _send_video:(MSPVideoFrame *)frame];
                }
            }
            else
            {
                if (!weakSelf.isSendAudioConfRecord)
                {
                    weakSelf.isSendAudioConfRecord = YES;
                    if (!((MSPAudioFrame *)frame).configRecordData)
                    {
                        weakSelf.isSending = NO;
                        return;
                    }
                    [weakSelf _send_audio_specific_config:(MSPAudioFrame *)frame];
                }
                else
                {
                    [weakSelf _send_audio:(MSPAudioFrame *)frame];
                }
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                weakSelf.isSending = NO;
            });
        }
    });
}

- (void)_send_video:(MSPVideoFrame *)frame
{
    [self.flvWrite writeVideoPacket:frame.data timestamp:frame.timestamp keyFrame:frame.isKeyFrame compositeTimeOffset:0];
    
    [self _sendData:self.flvWrite.packet];
    NSLog(@"flv=================video frame length：%ld",self.flvWrite.packet.length);
    [self.flvWrite reset];
}

- (void)_send_video_sps_pps:(MSPVideoFrame *)frame
{
    //0x01+sps[1]+sps[2]+sps[3]+0xFF+0xE1+sps_size+sps+01+pps_size+pps
    const char *sps = frame.sps.bytes;
    const char *pps = frame.pps.bytes;
    NSInteger sps_len = frame.sps.length;
    NSInteger pps_len = frame.pps.length;
    
    NSMutableData *body = [[NSMutableData alloc] init];
    [body msp_putInt8:0x01];
    [body msp_putInt8:sps[1]];
    [body msp_putInt8:sps[2]];
    [body msp_putInt8:sps[3]];
    [body msp_putInt8:0xff];
    
    /*sps*/
    [body msp_putInt8:0xe1];
    [body msp_putInt8:((sps_len >> 8) & 0xff)];
    [body msp_putInt8:(sps_len & 0xff)];
    [body appendBytes:sps length:sps_len];
    
    /*pps*/
    [body msp_putInt8:0x01];
    [body msp_putInt8:((pps_len >> 8) & 0xff)];
    [body msp_putInt8:(pps_len & 0xff)];
    [body appendBytes:pps length:pps_len];
    
    
    [self.flvWrite writeVideoDecoderConfRecord:body];
    
    [self _sendData:self.flvWrite.packet];
    NSLog(@"flv=================video sps_pps length：%ld",self.flvWrite.packet.length);
    NSLog(@"flv=================video sps_pps data：%@",self.flvWrite.packet);
    [self.flvWrite reset];
}

- (void)_send_audio:(MSPAudioFrame *)frame
{
    [self.flvWrite writeAudioPacket:frame.data timestamp:frame.timestamp];
    
    [self _sendData:self.flvWrite.packet];
    NSLog(@"flv=================audio frame length：%ld",self.flvWrite.packet.length);
    [self.flvWrite reset];
}


- (void)_send_audio_specific_config:(MSPAudioFrame *)frames
{
    NSInteger rtmpLength = frames.configRecordData.length + 2;     /*spec data长度,一般是2*/
    NSMutableData *body = [[NSMutableData alloc] initWithCapacity:rtmpLength];
//    [body msp_putInt8:0xAF];
//    [body msp_putInt8:0x00];
    [body appendData:frames.configRecordData];
    
    [self.flvWrite writeAudioDecoderConfRecord:body];
    
    [self _sendData:self.flvWrite.packet];
    NSLog(@"flv=================audio specific_config length：%ld",self.flvWrite.packet.length);
    NSLog(@"flv=================audio specific_config data：%@",self.flvWrite.packet);
    [self.flvWrite reset];
}

- (void)_sendData:(NSData *)data
{
    [self.outputFileHandle writeData:data];
}

#pragma mark - RTMP

- (NSInteger)RTMP264_Connect:(char *)push_url
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketStatus:status:)])
    {
        [self.delegate socketStatus:self status:(MSPSocketState_Start)];
    }
    
    if (_outputFileHandle)
    {
        [_outputFileHandle closeFile];
        _outputFileHandle = nil;
    }
    
    NSString *path = NSTemporaryDirectory();
    NSString *filePath =  [path stringByAppendingPathComponent:
                           [NSString stringWithFormat:@"test_flvout-%05d.flv", (int)(rand() % 99999)]];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    self.outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    NSLog(@"filePath: %@", filePath);
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.rtmpSendQueue, ^{
        [weakSelf sendFLVHeader];
        [weakSelf sendMetaData];
        _isConnected = YES;
        _isConnecting = NO;
        _isReconnecting = NO;
        _isSending = NO;
    });
    
    
    
    return 0;
}

// 断线重连
- (void)reconnect
{
    dispatch_async(self.rtmpSendQueue, ^{
        if (self.retryTimes4netWorkBreaken++ < self.reconnectCount && !self.isReconnecting)
        {
            self.isConnected = NO;
            self.isConnecting = NO;
            self.isReconnecting = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSelector:@selector(_reconnect) withObject:nil afterDelay:self.reconnectInterval];
            });
            
        }
        else if (self.retryTimes4netWorkBreaken >= self.reconnectCount)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(socketStatus:status:)])
            {
                [self.delegate socketStatus:self status:MSPSocketState_Error];
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(socketDidError:errorCode:)])
            {
                [self.delegate socketDidError:self errorCode:MSPSocketErrorCode_ReConnectTimeOut];
            }
        }
    });
}

- (void)_reconnect{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    _isReconnecting = NO;
    if(_isConnected) return;
    
    _isReconnecting = NO;
    if (_isConnected) return;
    
    _isSendAudioConfRecord = NO;
    _isSendVideoConfRecord = NO;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketStatus:status:)])
    {
        [self.delegate socketStatus:self status:MSPSocketState_Refresh];
    }
    
    [self RTMP264_Connect:(char *)[_streamConfig.url cStringUsingEncoding:NSASCIIStringEncoding]];
}

#pragma mark -- Observer

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"isSending"])
    {
        if(!self.isSending)
        {
            [self _sendFrame];
        }
    }
}

#pragma mark -- MSPStreamBufferDelegate
- (void)streamBuffer:(nullable MSPStreamBuffer *)buffer bufferState:(MSPStreamBuffferState)state
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(socketBufferStatus:status:)])
    {
        [self.delegate socketBufferStatus:self status:state];
    }
}

#pragma mark - Getter Setter

- (MSPStreamBuffer *)buffer
{
    if (!_buffer)
    {
        _buffer = [[MSPStreamBuffer alloc] init];
    }
    return _buffer;
}

- (dispatch_queue_t)rtmpSendQueue
{
    if(!_rtmpSendQueue)
    {
        _rtmpSendQueue = dispatch_queue_create("com.mob.MOBStreamingPusher.RtmpSendQueue", NULL);
    }
    return _rtmpSendQueue;
}

- (MSPFLVWrite *)flvWrite
{
    if (_flvWrite == nil)
    {
        _flvWrite = [[MSPFLVWrite alloc] init];
    }
    return _flvWrite;
}

@end
