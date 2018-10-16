//
//  MSPFLVWrite.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPFLVWrite.h"
#import "MSPFLVDefine.h"
#import "MSPFLVHeader.h"
#import "MSPFLVBaseTag.h"
#import "MSPFLVAudioTag.h"
#import "MSPFLVVideoTag.h"
#import "MSPFLVMetadata.h"
#import "NSMutableData+MSPBytes.h"
#import "NSMutableData+MSPAMF.h"

@interface MSPFLVWrite ()

@property(nonatomic, retain) MSPFLVMetadata *metaTag;

@end

@implementation MSPFLVWrite

// Length of the flv header in bytes
//static const int kMSPFlvHeaderLength = 9;

// Length of the flv tag in bytes
static const int kMSPFlvTagHeaderLength = 11;

- (id)init
{
    if (self = [super init])
    {
        _packet = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)dealloc
{
    
}

- (void)writeHeader
{
    MSPFLVHeader *h = [[MSPFLVHeader alloc] init];
    h.flagVideo = YES;
    h.flagAudio = YES;
    NSData *header = [h output];
    [_packet appendData:header];
}

- (void)writeTag:(MSPFLVBaseTag *)tag
{
    // Tag = Tag Header + Tag Data
    //      Tag Header： 11bytes，存放当前Tag类型、TagData(数据区)的长度等信息
    //              Tag类型： 1byte，8 = 音频，9 = 视频，18(0x12) = 脚本， 其他 = 保留
    //              数据区长度(tag data size)： 3bytes
    //                时间戳： 3bytes  整数单位毫秒，脚本类型Tag为0
    //             时间戳扩展： 1bytes
    //            StreamsID： 3bytes 总是0
    //      Tag Data：  variable bytes
    // Previous Tag = 4 bytes (Tag Header Size + Tag Data Size)
    // 
    
    size_t bodySize = tag.bodySize;
    if (bodySize > 0)
    {
        int flags = 0;
        size_t flagsSize = tag.flagsSize;
        
        if (tag.typeData == msp_flv_tag_type_video)
        {
            MSPFLVVideoTag *videoTag = (MSPFLVVideoTag *)tag;
            flags = (videoTag.frameType << 4 ) | (videoTag.codecId << 0);
        }
        else if (tag.typeData == msp_flv_tag_type_audio)
        {
            MSPFLVAudioTag *audioTag = (MSPFLVAudioTag *)tag;
            flags = (audioTag.soundFormat << 4) | (audioTag.soundRate << 2) | (audioTag.soundSize << 1) | (audioTag.soundType << 0);
        }
        
        NSMutableData *buf = [[NSMutableData alloc] initWithCapacity:(kMSPFlvTagHeaderLength + flagsSize + bodySize + 4 )];
        
        // tag header
        [buf msp_putInt8:tag.typeData];
        [buf msp_putInt24:(int)(flagsSize + bodySize)];
        [buf msp_putInt24:(int)tag.timestamp];
        [buf msp_putInt8:(tag.timestamp >> 24) & 0x7F];
        [buf msp_putInt24:0];
        
        if (tag.typeData != msp_flv_tag_type_script)
        {
            [buf msp_putInt8:flags];
            if (tag.typeData == msp_flv_tag_type_video && _metaTag.videoCodecId == msp_flv_video_codecid_H264)
            {
                MSPFLVVideoTag *videoTag = (MSPFLVVideoTag *)tag;
                [buf msp_putInt8:videoTag.packetType];  // AVC NALU
                [buf msp_putInt24:videoTag.cts]; // pts - dts
            }
            else if (tag.typeData == msp_flv_tag_type_audio && _metaTag.audioCodecId == msp_flv_audio_codecid_AAC)
            {
                // If aac body size is less than 3, we assume it is
                // AVCDecoderConfigurationRecord
                // See ISO 14496-15, 5.2.4.1 for the description of
                // AVCDecoderConfigurationRecord. This contains the same information
                // that would be stored in an avcC box in an MP4/FLV file.
                MSPFLVAudioTag *audioTag = (MSPFLVAudioTag *)tag;
                [buf msp_putInt8:audioTag.packetType];  // AAC
            }
        }
        [buf appendData:tag.body];
        
        int previousTagSize = (int)(kMSPFlvTagHeaderLength + flagsSize + bodySize);
        [buf msp_putInt32:previousTagSize];
        
        [_packet appendData:buf];
    }
}

- (void)reset
{
    if (_packet) _packet = nil;
    _packet = [[NSMutableData alloc] init];
}

- (void)writeMetaTag:(MSPFLVMetadata *)metaTag
{
    NSMutableData *buf = [[NSMutableData alloc] init];

    //[buf msp_putAMFString:@"setDataFrame"];
    [buf msp_putAMFString:@"onMetaData"];
    
    [buf msp_putInt8:MSPAMFDataTypeMixedArray];
    //[buf msp_putInt8:MSPAMFDataTypeObject];
    self.metaTag = metaTag;
    // 数组个数
    int metadataCount = (metaTag.videoCodecId >= 0 ? 5 : 0) + (metaTag.audioCodecId >= 0 ? 5 : 0) + 2;
    [buf msp_putInt32:metadataCount];
    
    [buf msp_putParam:@"duration" d:0];
   
    
    // FLV encoder information
    // [buf msp_putParam:@"encoder" str:@"ifFLVEncoder"];
    
    // video encoding information
    if (metaTag.videoCodecId >= 0)
    {
        [buf msp_putParam:@"width" d:metaTag.width];
        [buf msp_putParam:@"height" d:metaTag.height];
        [buf msp_putParam:@"videodatarate" d:metaTag.videoBitrate];
        [buf msp_putParam:@"framerate" d:metaTag.framerate];
        [buf msp_putParam:@"videocodecid" d:metaTag.videoCodecId];
    }
    
    // Audio encoding information
    if (metaTag.audioCodecId >= 0)
    {
        [buf msp_putParam:@"audiodatarate" d:metaTag.audioBitrate];
        [buf msp_putParam:@"audiosamplerate" d:metaTag.sampleRate];
        [buf msp_putParam:@"audiosamplesize" d:metaTag.sampleSize];
        [buf msp_putParam:@"stereo" b:metaTag.stereo];
        [buf msp_putParam:@"audiocodecid" d:metaTag.audioCodecId];
    }
    
    // File size
    [buf msp_putParam:@"filesize" d:0];
    
//    [buf msp_putInt8:0];
//    [buf msp_putInt8:0];
//    [buf msp_putInt8:0];
//    [buf msp_putInt32:MSPAMFDataTypeObjectEnd];
    [buf msp_putInt24:MSPAMFDataTypeObjectEnd];
    
    MSPFLVBaseTag *tag = [[MSPFLVBaseTag alloc] init];
    tag.typeData = msp_flv_tag_type_script;
    tag.timestamp = 0;
    tag.previuosTagSize = 0;
    tag.body = buf;
    tag.bodySize = [buf length];
    tag.bitflags = 0;
    
    [self writeTag:tag];
}

- (void)writeVideoPacket:(NSData *)data
               timestamp:(unsigned long)timestamp
                keyFrame:(BOOL)keyFrame
     compositeTimeOffset:(int)compositeTimeOffset
{
    MSPFLVVideoTag *tag = [[MSPFLVVideoTag alloc] init];
    tag.timestamp = timestamp;
    tag.previuosTagSize = 0;
    tag.body = data;
    tag.bodySize = [data length];
    tag.cts = 0;
    
    // If frame type is seekable we need to modify frame type in video tag.
    if (((Byte)(*((char *)[data bytes] + 4))) == 0x06 || keyFrame) {
        tag.frameType = msp_flv_video_frametype_key;
        tag.cts = compositeTimeOffset;
    }
    
    tag.bitflags = 0;
    [self writeTag:tag];
}

- (void)writeAudioPacket:(NSData *)data timestamp:(unsigned long)timestamp
{
    MSPFLVAudioTag *tag = [[MSPFLVAudioTag alloc] init];
    tag.timestamp = timestamp;
    tag.previuosTagSize = 0;
    tag.body = data;
    tag.bodySize = [data length];
    tag.bitflags = 0;
    [self writeTag:tag];
}

- (void)writeVideoDecoderConfRecord:(NSData *)decoderBytes
{
    MSPFLVVideoTag *tag = [[MSPFLVVideoTag alloc] init];
    tag.timestamp = 0;
    tag.previuosTagSize = 0;
    tag.body = decoderBytes;
    tag.bodySize = [decoderBytes length];
    tag.packetType = msp_flv_video_h264_packettype_seqHeader;
    tag.frameType = msp_flv_video_frametype_key;
    tag.bitflags = 0;
    [self writeTag:tag];
}

-(void)writeAudioDecoderConfRecord:(NSData *)decoderBytes
{
    MSPFLVAudioTag *tag = [[MSPFLVAudioTag alloc] init];
    tag.timestamp = 0;
    tag.previuosTagSize = 0;
    tag.body = decoderBytes;
    tag.bodySize = [decoderBytes length];
    tag.bitflags = 0;
    tag.packetType = msp_flv_audio_aac_packettype_seqHeader;
    [self writeTag:tag];
}











@end






