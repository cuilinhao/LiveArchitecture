//
//  MSPVideoHWEncoder.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/12.
//  Copyright © 2018年 Mob. All rights reserved.
//

/*
 * H.264 stream consists of a sequence of NAL Units(NALUs)
 * +----------+ +----------+ +-------------------+ +----------+ +----------+ +----------+ +-------------------+ +----------+
 * | +------+ | | +------+ | | +------+ +------+ | | +------+ | | +------+ | | +------+ | | +------+ +------+ | | +------+ |
 * | |      | | | |      | | | |      | |      | | | |      | | | |      | | | |      | | | |      | |      | | | |      | |
 * | | NALU | | | | NALU | | | | NALU | | NALU | | | | NALU | | | | NALU | | | | NALU | | | | NALU | | NALU | | | | NALU | |
 * | |      | | | |      | | | |      | |      | | | |      | | | |      | | | |      | | | |      | |      | | | |      | |
 * | +------+ | | +------+ | | +------+ +------+ | | +------+ | | +------+ | | +------+ | | +------+ +------+ | | +------+ |
 * |    SPS   | |    PPS   | |      I Frame      | |  P Frame | |  B Frame | |  B Frame | |      P Frame      | |  P Frame |
 * +----------+ +----------+ +-------------------+ +----------+ +----------+ +----------+ +-------------------+ +----------+
 * H264码流结构
 * SPS：序列参数集(Sequence Parameter Set)
 * PPS：图像参数集(Picture Parameter Set)
 * I帧：完整编码的帧，也叫关键帧
 * P帧：参考之前的I 帧生成的只包含差异部分编码的帧
 * B帧：参考前后的帧编码的帧叫B帧
 * H264采用的核心算法的帧内压缩和帧间压缩，帧内压缩是生成I帧的算法，帧间压缩是生成B帧和P帧的算法
 * H264原始码流是由一个接一个的NALU(Nal Unit)组成的，NALU = 开始码 + NAL类型 + 视频数据
 * 开始码用于标示这是一个NALU单元的开始，必须是"00 00 00 01"或"00 00 01"
 * NALU类型如下：0 未规定，1 非IDR图像中不采用数据划分的片段，2 非IDR图像中A类数据划分片段，3 非IDR图像中B类数据划分片段
 *             4 非IDR图像中C类数据划分片段，5 IDR图像的片段，6 补充增强信息（SEI），7 序列参数集（SPS）
 *             8 图像参数集（PPS），9 分割符，10 序列结束符，11 流结束符
 *             12 填充数据，13 序列参数集扩展，14 带前缀的NAL单元，15 子序列参数集
 *             16-18 保留，19 不采用数据划分的辅助编码图像片段，20 编码片段扩展，21–23 保留
 *             24–31 未规定
 *             一般我们只用到了1、5、7、8这4个类型就够了。类型为5表示这是一个I帧，I帧前面必须有SPS和PPS数据，也就是类型为7和8，类型为1表示这是一个P帧或B帧。
 * 帧率：单位为fps(frame pre second)，视频画面每秒有多少帧画面，数值越大画面越流畅
 * 码率：单位为bps(bit pre second)，视频每秒输出的数据量，数值越大画面越清晰
 * 分辨率：视频画面像素密度，例如常见的720P、1080P等
 * 关键帧间隔：每隔多久编码一个关键帧
 * 软编码：使用CPU进行编码，性能较差
 * 硬编码：不使用CPU进行编码，使用显卡GPU，专用的DSP、FPGA、ASIC芯片等硬件进行编码，性能较好
 */

#import "MSPVideoHWEncoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface MSPVideoHWEncoder ()
{
    VTCompressionSessionRef compressionSession;//压缩编码会话
    NSInteger frameCount;
    NSData *sps;
    NSData *pps;
    FILE *fp;
    BOOL enabledWriteVideoFile;
}

@property (nonatomic, strong) MSPVideoConfiguration *configuration;
@property (nonatomic, weak) id<MSPVideoEncoderDelegate> h264Delegate;
@property (nonatomic) NSInteger currentVideoBitRate;
@property (nonatomic) BOOL isBackGround;

@end

@implementation MSPVideoHWEncoder

#pragma mark - MSPVideoBaseEncoder(@protocol) @optional

- (nullable instancetype)initWithVideoStreamConfiguration:(nullable MSPVideoConfiguration *)configuration
{
    if (self = [super init])
    {
        _configuration = configuration;
        [self resetCompressionSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
//#ifdef DEBUG
        enabledWriteVideoFile = YES;
        [self initForFilePath];
//#endif
    }
    return self;
}

- (void)setDelegate:(nullable id<MSPVideoEncoderDelegate>)delegate
{
    _h264Delegate = delegate;
}

- (void)setVideoBitRate:(NSInteger)videoBitRate
{
    if(_isBackGround) return;
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(videoBitRate));
    NSArray *limit = @[@(videoBitRate * 1.5/8), @(1)];
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)limit);
    _currentVideoBitRate = videoBitRate;
}

- (NSInteger)videoBitRate {
    return _currentVideoBitRate;
}

- (void)dealloc
{
    if (compressionSession != NULL)
    {
        VTCompressionSessionCompleteFrames(compressionSession, kCMTimeInvalid);
        
        VTCompressionSessionInvalidate(compressionSession);
        CFRelease(compressionSession);
        compressionSession = NULL;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)resetCompressionSession
{
    if (compressionSession) {
        VTCompressionSessionCompleteFrames(compressionSession, kCMTimeInvalid);
        
        VTCompressionSessionInvalidate(compressionSession);
        CFRelease(compressionSession);
        compressionSession = NULL;
    }
    
    // 创建CompressionSession对象，该对象用于对画面进行编码
    // kCMVideoCodecType_H264 : 表示使用h.264进行编码
    // VideoCompressonOutputCallback : 当一次编码结束会在该函数进行回调,可以在该函数中将数据,写入文件中
    OSStatus status = VTCompressionSessionCreate(NULL, (int32_t)_configuration.videoSize.width, (int32_t)_configuration.videoSize.height, kCMVideoCodecType_H264, NULL, NULL, NULL, VideoCompressonOutputCallback, (__bridge void *)self, &compressionSession);
    if (status != noErr) {
        return;
    }
    
    // 设置I帧(关键帧)间隔 即gop size
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(_configuration.videoMaxKeyframeInterval));
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, (__bridge CFTypeRef)@(_configuration.videoMaxKeyframeInterval/_configuration.videoFrameRate));
    
    // 设置帧率fps(每秒多少帧,如果帧率过低,会造成画面卡顿) 非实际帧率
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(_configuration.videoFrameRate));
    
    // 设置码率(码率：编码效率,码率越高,则画面越清晰,如果码率较低会引起马赛克 --> 码率高有利于还原原始画面,但是也不利于传输)
    _currentVideoBitRate = _configuration.videoBitRate;
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(_configuration.videoBitRate));
    NSArray *limit = @[@(_configuration.videoBitRate * 1.5/8), @(1)];
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)limit);
    
    // 设置实时编码输出(直播必然是实时输出，否则会有延迟)
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    
    // 设置对于编码流指定配置和标准 直播一般使用baseline，可减少由于b帧带来的延时
    // 实时直播： 低清 = Baseline Level 1.3,  标清 = Baseline Level 3,   半高清 = Baseline Level 3.1,   全高清 = Baseline Level 4.1
    // 存储媒体： 低清 = Main Level 1.3,      标清 = Main Level 3,       半高清 = Main Level 3.1,       全高清 = Main Level 4.1
    // 高清存储：半高清 = High Level 3.1,    全高清 = High Level 4.1
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel);//kVTProfileLevel_H264_Main_AutoLevel/kVTProfileLevel_H264_Baseline_AutoLevel
    
    // 设置允许帧重新排序,默认为True 配置是否产生B帧，High profile支持B帧
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanTrue);
    
    // 设置H264的编码模式
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC);
    
    // 基本设置结束,准备进行编码
    VTCompressionSessionPrepareToEncodeFrames(compressionSession);
}


#pragma mark - MSPVideoBaseEncoder(@protocol) @required

- (void)encodeVideoData:(nullable CVPixelBufferRef)pixelBuffer timeStamp:(uint64_t)timeStamp
{
    if(_isBackGround) return;
    frameCount++;
    CMTime presentationTimeStamp = CMTimeMake(frameCount, (int32_t)_configuration.videoFrameRate);
    VTEncodeInfoFlags flags;
    CMTime duration = CMTimeMake(1, (int32_t)_configuration.videoFrameRate);
    
    NSDictionary *properties = nil;
    if (frameCount % (int32_t)_configuration.videoMaxKeyframeInterval == 0)
    {
        // 设置是否为I帧
        properties = @{(__bridge NSString *)kVTEncodeFrameOptionKey_ForceKeyFrame: @YES};
    }
    NSNumber *timeNumber = @(timeStamp);
    
    // 数据放入编码器编码
    OSStatus status = VTCompressionSessionEncodeFrame(compressionSession, pixelBuffer, presentationTimeStamp, duration, (__bridge CFDictionaryRef)properties, (__bridge_retained void *)timeNumber, &flags);
    if(status != noErr)
    {
        [self resetCompressionSession];
    }
}

- (void)stopEncoder
{
    if (NULL == compressionSession)
    {
        return;
    }
    OSStatus status = VTCompressionSessionCompleteFrames(compressionSession, kCMTimeIndefinite);
    if (noErr != status)
    {
        NSLog(@"VTCompressionSessionCompleteFrames failed! status:%d", (int)status);
    }
}


#pragma mark - Notification

- (void)willEnterBackground:(NSNotification *)notification
{
    _isBackGround = YES;
}

- (void)willEnterForeground:(NSNotification *)notification
{
    [self resetCompressionSession];
    _isBackGround = NO;
}

#pragma mark - VideoCallBack

// 编码回调，每当系统编码完一帧之后，会异步调用该方法
static void VideoCompressonOutputCallback(void *VTref,
                                          void *VTFrameRef,
                                          OSStatus status,
                                          VTEncodeInfoFlags infoFlags,
                                          CMSampleBufferRef sampleBuffer)
{
    if (!sampleBuffer) return;
    CFArrayRef array = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    if (!array) return;
    CFDictionaryRef dic = (CFDictionaryRef)CFArrayGetValueAtIndex(array, 0);
    if (!dic) return;
    
    // 判断是否是关键帧
    BOOL keyframe = !CFDictionaryContainsKey(dic, kCMSampleAttachmentKey_NotSync);
    uint64_t timeStamp = [((__bridge_transfer NSNumber *)VTFrameRef) longLongValue];
    
    MSPVideoHWEncoder *videoEncoder = (__bridge MSPVideoHWEncoder *)VTref;
    if (status != noErr)
    {
        return;
    }
    
    
    // 首先获取sps 和pps
    // sps pss 也是h264的一部分，可以认为它们是特别的h264视频帧，保存了h264视频的一些必要信息。
    // 没有这部分数据h264视频很难解析出来。
    // 数据处理时，sps pps 数据可以作为一个普通h264帧，放在h264视频流的最前面。
    if (keyframe && !videoEncoder->sps)
    {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        // 关键帧需要加上SPS、PPS信息
        // 如果保存到文件中，需要将此数据前加上 [0 0 0 1] 4个字节，写入到h264文件的最前面。
        // 如果推流，将此数据放入flv数据区即可。
        size_t sParameterSetSize, sParameterSetCount;
        const uint8_t *sParameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sParameterSet, &sParameterSetSize, &sParameterSetCount, 0);
        if (statusCode == noErr)
        {
            size_t pParameterSetSize, pParameterSetCount;
            const uint8_t *pParameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pParameterSet, &pParameterSetSize, &pParameterSetCount, 0);
            if (statusCode == noErr)
            {
                // sps数据加上开始码组成NALU
                videoEncoder->sps = [NSData dataWithBytes:sParameterSet length:sParameterSetSize];
                // pps数据加上开始码组成NALU
                videoEncoder->pps = [NSData dataWithBytes:pParameterSet length:pParameterSetSize];
                
                if (videoEncoder->enabledWriteVideoFile)
                {
                    NSMutableData *data = [[NSMutableData alloc] init];
                    uint8_t header[] = {0x00, 0x00, 0x00, 0x01};
                    [data appendBytes:header length:4];
                    [data appendData:videoEncoder->sps];
                    [data appendBytes:header length:4];
                    [data appendData:videoEncoder->pps];
                    fwrite(data.bytes, 1, data.length, videoEncoder->fp);
                }
            }
        }
    }
    
    // 获取视频帧数据
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr)
    {
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4;
        while (bufferOffset < totalLength - AVCCHeaderLength)
        {
            // 读取NAL单元长度
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            
            // 大端转小端
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            // videoFrame.data 即为一帧h264数据。
            // 如果保存到文件中，需要将此数据前加上 [0 0 0 1] 4个字节，按顺序写入到h264文件中。
            // 如果推流，需要将此数据前加上4个字节表示数据长度的数字，此数据需转为大端字节序。
            // 关于大端和小端模式，请参考此网址：http://blog.csdn.net/hackbuteer1/article/details/7722667
            MSPVideoFrame *videoFrame = [MSPVideoFrame new];
            videoFrame.timestamp = timeStamp;
            videoFrame.data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            videoFrame.isKeyFrame = keyframe;
            videoFrame.sps = videoEncoder->sps;
            videoFrame.pps = videoEncoder->pps;
            
            
            
            // 这里是个坑 如果没有给sps pps及视频数据头部加入{0x00, 0x00, 0x00, 0x01}会导致 VLC无法播放画面 可能是Mac版 VLC没有avc1的吧
            // MP4视频H264封装有两种格式：avc1和h264
            // avc1 不带起始码0x00000001
            // h264   带起始码0x00000001
            // 对于起始码的操作最好在 rtmpsocket 内处理， 测试方便直接在这边处理了
            /*========================================================*/
            NSMutableData *data_sps = [[NSMutableData alloc] init];
            NSMutableData *data_pps = [[NSMutableData alloc] init];
            NSMutableData *data_frame = [[NSMutableData alloc] init];
            uint8_t header[] = {0x00, 0x00, 0x00, 0x01};
            [data_sps appendBytes:header length:4];
            [data_pps appendBytes:header length:4];
            [data_sps appendData:videoFrame.sps];
            [data_pps appendData:videoFrame.pps];
            videoFrame.sps = data_sps;
            videoFrame.pps = data_pps;

            [data_frame appendBytes:header length:4];
            [data_frame appendData:videoFrame.data];
            videoFrame.data = data_frame;
            /*========================================================*/
            
            
            if (videoEncoder.h264Delegate && [videoEncoder.h264Delegate respondsToSelector:@selector(videoEncoder:videoFrame:)])
            {
                [videoEncoder.h264Delegate videoEncoder:videoEncoder videoFrame:videoFrame];
            }
            
            if (videoEncoder->enabledWriteVideoFile)
            {
                NSMutableData *data = [[NSMutableData alloc] init];
//                if (keyframe)
//                {
//                    uint8_t header[] = {0x00, 0x00, 0x00, 0x01};
//                    [data appendBytes:header length:4];
//                }
//                else
//                {
//                    uint8_t header[] = {0x00, 0x00, 0x01};
//                    [data appendBytes:header length:3];
//                }
                [data appendData:videoFrame.data];
                
                fwrite(data.bytes, 1, data.length, videoEncoder->fp);
                
                
            }
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
    }
}


#pragma mark - fopen

- (void)initForFilePath {
    NSString *path = [self GetFilePathByfileName:@"IOSCamDemo.h264"];
    NSLog(@"%@", path);
    self->fp = fopen([path cStringUsingEncoding:NSUTF8StringEncoding], "wb");
}

- (NSString *)GetFilePathByfileName:(NSString*)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:filename];
    return writablePath;
}

@end
