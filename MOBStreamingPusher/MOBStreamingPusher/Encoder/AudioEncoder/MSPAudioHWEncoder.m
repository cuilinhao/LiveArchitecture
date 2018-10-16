//
//  MSPAudioHWEncoder.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/11.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPAudioHWEncoder.h"

@interface MSPAudioHWEncoder ()
{
    AudioConverterRef m_converter;
    char *leftBuffer;
    char *aacBuffer;
    NSInteger leftLength;
    FILE *fp;
    BOOL enabledWriteVideoFile;
}

@property (nonatomic, strong) MSPAudioConfiguration *configuration;
@property (nonatomic, weak) id<MSPAudioEncoderDelegate> aacDelegate;

@end

@implementation MSPAudioHWEncoder

#pragma mark - MSPAudioBaseEncoder(@protocol) @optional

- (nullable instancetype)initWithAudioStreamConfiguration:(nullable MSPAudioConfiguration *)configuration
{
    if (self = [super init])
    {
        _configuration = configuration;
        if (!leftBuffer)
        {
            leftBuffer = malloc(_configuration.bufferLength);
        }
        if (!aacBuffer)
        {
            aacBuffer = malloc(_configuration.bufferLength);
        }
        
//#ifdef DEBUG
        enabledWriteVideoFile = YES;
        [self initForFilePath];
//#endif
    }
    return self;
}

- (void)dealloc
{
    if (aacBuffer)
    {
        free(aacBuffer);
    }
    if (leftBuffer)
    {
        free(leftBuffer);
    }
}

- (void)setDelegate:(nullable id<MSPAudioEncoderDelegate>)delegate
{
    _aacDelegate = delegate;
}

- (nullable NSData *)adtsData:(NSInteger)channel rawDataLength:(NSInteger)rawDataLength
{
    int adtsLength = 7;
    char *packet = malloc(sizeof(char) * adtsLength);
    // Variables Recycled by addADTStoPacket
    int profile = 2;  //AAC LC
    //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
    NSInteger freqIdx = [self.configuration sampleRateIndex:self.configuration.audioSampleRate];  //44.1KHz
    int chanCfg = (int)channel;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    NSUInteger fullLength = adtsLength + rawDataLength;
    // fill in ADTS data
    packet[0] = (char)0xFF;     // 11111111     = syncword
    packet[1] = (char)0xF9;     // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

#pragma mark - MSPAudioBaseEncoder(@protocol) @required
- (void)encodeAudioData:(nullable NSData*)audioData timeStamp:(uint64_t)timeStamp
{
    if (![self createAudioConvert])
    {
        return;
    }
    
    if(leftLength + audioData.length >= self.configuration.bufferLength)
    {
        ///<  发送
        NSInteger totalSize = leftLength + audioData.length;
        NSInteger encodeCount = totalSize / self.configuration.bufferLength;
        char *totalBuf = malloc(totalSize);
        char *p = totalBuf;
        
        memset(totalBuf, (int)totalSize, 0);
        memcpy(totalBuf, leftBuffer, leftLength);
        memcpy(totalBuf + leftLength, audioData.bytes, audioData.length);
        
        for(NSInteger index = 0;index < encodeCount;index++){
            [self encodeBuffer:p  timeStamp:timeStamp];
            p += self.configuration.bufferLength;
        }
        
        leftLength = totalSize%self.configuration.bufferLength;
        memset(leftBuffer, 0, self.configuration.bufferLength);
        memcpy(leftBuffer, totalBuf + (totalSize -leftLength), leftLength);
        
        free(totalBuf);
        
    }
    else
    {
        ///< 积累
        memcpy(leftBuffer+leftLength, audioData.bytes, audioData.length);
        leftLength = leftLength + audioData.length;
    }
}

- (void)encodeBuffer:(char *)buffer timeStamp:(uint64_t)timeStamp
{
    AudioBuffer inBuffer;
    inBuffer.mNumberChannels = 1;
    inBuffer.mData = buffer;
    inBuffer.mDataByteSize = (UInt32)self.configuration.bufferLength;
    
    AudioBufferList buffers;
    buffers.mNumberBuffers = 1;
    buffers.mBuffers[0] = inBuffer;
    
    
    // 初始化一个输出缓冲列表
    AudioBufferList outBufferList;
    outBufferList.mNumberBuffers = 1;
    outBufferList.mBuffers[0].mNumberChannels = inBuffer.mNumberChannels;
    outBufferList.mBuffers[0].mDataByteSize = inBuffer.mDataByteSize;   // 设置缓冲区大小
    outBufferList.mBuffers[0].mData = aacBuffer;           // 设置AAC缓冲区
    UInt32 outputDataPacketSize = 1;
    if (AudioConverterFillComplexBuffer(m_converter, inputDataProc, &buffers, &outputDataPacketSize, &outBufferList, NULL) != noErr) {
        return;
    }
    
    MSPAudioFrame *audioFrame = [MSPAudioFrame new];
    audioFrame.timestamp = timeStamp;
    audioFrame.data = [NSData dataWithBytes:aacBuffer length:outBufferList.mBuffers[0].mDataByteSize];
    
    char exeData[2];
    exeData[0] = _configuration.asc[0];
    exeData[1] = _configuration.asc[1];
    audioFrame.configRecordData = [NSData dataWithBytes:exeData length:2];
    if (self.aacDelegate && [self.aacDelegate respondsToSelector:@selector(audioEncoder:audioFrame:)]) {
        [self.aacDelegate audioEncoder:self audioFrame:audioFrame];
    }
    
//    if (self->enabledWriteVideoFile)
//    {
//        NSData *adts = [self adtsData:_configuration.numberOfChannels rawDataLength:audioFrame.data.length];
//        fwrite(adts.bytes, 1, adts.length, self->fp);
//        fwrite(audioFrame.data.bytes, 1, audioFrame.data.length, self->fp);
//    }
}

- (void)stopEncoder
{
    
}

/// 创建 Audio 编码转换器
- (BOOL)createAudioConvert
{
    if (m_converter != nil)
    {
        return YES;
    }
    AudioStreamBasicDescription inputFormat = {0};
    inputFormat.mSampleRate = _configuration.audioSampleRate;
    inputFormat.mFormatID = kAudioFormatLinearPCM;
    inputFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    inputFormat.mChannelsPerFrame = (UInt32)_configuration.numberOfChannels;
    inputFormat.mFramesPerPacket = 1;
    inputFormat.mBitsPerChannel = 16;
    inputFormat.mBytesPerFrame = inputFormat.mBitsPerChannel / 8 * inputFormat.mChannelsPerFrame;
    inputFormat.mBytesPerPacket = inputFormat.mBytesPerFrame * inputFormat.mFramesPerPacket;
    
    AudioStreamBasicDescription outputFormat; // 这里开始是输出音频格式
    memset(&outputFormat, 0, sizeof(outputFormat));
    outputFormat.mSampleRate = inputFormat.mSampleRate;       // 采样率保持一致
    outputFormat.mFormatID = kAudioFormatMPEG4AAC;            // AAC编码 kAudioFormatMPEG4AAC kAudioFormatMPEG4AAC_HE_V2
    outputFormat.mChannelsPerFrame = (UInt32)_configuration.numberOfChannels;;
    outputFormat.mFramesPerPacket = 1024;                     // AAC一帧是1024个字节
    
    const OSType subtype = kAudioFormatMPEG4AAC;
    AudioClassDescription requestedCodecs[2] = {
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleSoftwareAudioCodecManufacturer
        },
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleHardwareAudioCodecManufacturer
        }
    };
    
    OSStatus result = AudioConverterNewSpecific(&inputFormat, &outputFormat, 2, requestedCodecs, &m_converter);;
    UInt32 outputBitrate = _configuration.audioBitRate;
    UInt32 propSize = sizeof(outputBitrate);
    
    
    if(result == noErr) {
        result = AudioConverterSetProperty(m_converter, kAudioConverterEncodeBitRate, propSize, &outputBitrate);
    }
    
    return YES;
}

#pragma mark -- AudioCallBack
OSStatus inputDataProc(AudioConverterRef inConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription * *outDataPacketDescription, void *inUserData)
{
    ///AudioConverterFillComplexBuffer 编码过程中，会要求这个函数来填充输入数据，也就是原始PCM数据
    AudioBufferList bufferList = *(AudioBufferList *)inUserData;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData = bufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = bufferList.mBuffers[0].mDataByteSize;
    return noErr;
}


#pragma mark - fopen

- (void)initForFilePath {
    NSString *path = [self GetFilePathByfileName:@"IOSCamDemo_HW.aac"];
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
