//
//  MSPFLVDefine.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

/*
 *
 *             Header                                       Body
 *              /\                                          /\
 * FLV      - -   - -    - - - - - - - - - - - - - - - - - -  - - - - - - - - - - - ··· - - - - - - - - - - - --
 *        /          \ /                                                                                         \
 *        +------------+----------+-----------+----------+-----------+----------+--- ··· ---+-----------+----------+
 *        |            |          |           |          |           |          |           |           |          |
 *        |     FLV    | TagSize0 |    Tag1   | TagSize1 |    Tag2   | TagSize2 |    ···    |    TagN   | TagSizeN |
 *        |   Hearder  |          |           |          |           |          |           |           |          |
 *        +------------+----------+-----------+----------+-----------+----------+--- ··· ---+-----------+----------+
 *bytes   |    9bytes  |  4bytes  | TagSize1  |   4bytes | TagSize2  |  4bytes  |    ···    | TagSizeN  |  4bytes  |
 *        |            |  value=0 |   bytes   |          |   bytes   |          |           |  bytes    |          |
 *
 *
 * flv = flv header + flv body
 *
 * flv header 9bytes，flv的类型、版本等信息,Signature(3bytes)+Version(1bytes)+Flags(1bytes)+DataOffset(4bytes)
 *       Signature：固定FLV三个字符作为标示，一般发现前3个字符为 FLV 时就认为是 flv文件
 *         Version：标示 FLV 的版本号
 *           Flags：内容标示，第0位和第2位，分别表示 video与 audio存在的情况(1表示存在，0表示不存在) 如0x05(00000101)，代表即有视频，也有音频
 *      DataOffset：表示 FLV 的 header长度。这里固定是9
 *
 * flv body  ： TagSize0+Tag1+TagSize1+Tag2+TagSize2+...+TagN+TagSizeN，有若干个Tag组成，每个Tag后面紧跟TagSize(4bytes)记录tag长度,第一个TagSize0值为0
 *
 * Tag = Tag Header + Tag Data, Tag分三种类型，video、audio、scripts(元数据)
 *           脚本tag就是描述视频或音频的信息的数据，如宽度、高度、时间等等
 *           音频tag和视频tag就是音视频信息，采样、声道、频率、编码等信息
 *
 * Tag Header： 11bytes，存放当前Tag类型、TagData(数据区)的长度等信息
 *         Tag类型： 1byte，8 = 音频，9 = 视频，18(0x12) = 脚本， 其他 = 保留
 *         数据区长度(tag data size)： 3bytes
 *          时间戳： 3bytes  整数单位毫秒，脚本类型Tag为0
 *       时间戳扩展： 1bytes
 *      StreamsID： 3bytes 总是0
 *
 * Tag Data  ： 数据区，音频数据(Audio Tag Data)、视频数据(Video Tag Data)、脚本数据(scripts Tag Data)
 *       Audio Tag Data：第一个byte音频信息
 *                  音频格式：4bits,0 = Linear PCM, platform endian
 *                                1 = ADPCM
 *                                2 = MP3
 *                                3 = Linear PCM, little endian
 *                                4 = Nellymoser 16-kHz mono
 *                                5 = Nellymoser 8-kHz mono
 *                                6 = Nellymoser
 *                                7 = G.711 A-law logarithmic PCM
 *                                8 = G.711 mu-law logarithmic PCM
 *                                9 = reserved
 *                                10 = AAC
 *                                11 = Speex
 *                                14 = MP3 8-Khz
 *                                15 = Device-specific sound
 *                    采样率：2bits,0 = 5.5-kHz
 *                                1 = 11-kHz
 *                                2 = 22-kHz
 *                                3 = 44-kHz
 *                                对于AAC总是3
 *                  采样的长度：1bit,0 = snd8Bit
 *                                1 = snd16Bit
 *                                压缩过的音频都是16bit
 *                    音频类型：1bit,0 = sndMono
 *                                1 = sndStereo
 *                                对于AAC总是1
 *               如果音频格式为AAC 后面跟1byte 0x00/0x01
 *                              如果0x00 后面跟 audio config data 数据 需要作为第一个 audio tag 发送
 *                              如果0x01 后面跟 audio frame data 数据
 *
 *
 *      video Tag Data：第一个byte视频信息
 *                    帧类型：4bits,1： keyframe (for AVC, a seekable frame)
 *                                2： inter frame (for AVC, a non-seekable frame)
 *                                3： disposable inter frame (H.263 only)
 *                                4： generated keyframe (reserved for server use only)
 *                                5： video info/command frame
 *                    编码ID：4bits,1： JPEG (currently unused)
 *                                2： Sorenson H.263
 *                                3： Screen video
 *                                4： On2 VP6
 *                                5： On2 VP6 with alpha channel
 *                                6： Screen video version 2
 *                                7： AVC
 *             如果视频格式为 AVC(H.264)的话，后面为4个字节信息，AVCPacketType和 CompositionTime
 *                    AVCPacketType 1byte，0：AVCDecoderConfigurationRecord(AVC sequence header)
 *                                         1：AVC NALU
 *                                         2：AVC end of sequence(lower level NALU sequence ender is not required or supported)
 *                                AVCDecoderConfigurationRecord.包含着是H.264解码相关比较重要的sps和pps信息，再给AVC解码器送数据流之前一定要把sps和pps信息送出，
 *                                否则的话解码器不能正常解码。而且在解码器stop之后再次start之前，如seek、快进快退状态切换等，都需要重新送一遍sps和pps的信息.
 *                                AVCDecoderConfigurationRecord在FLV文件中一般情况也是出现1次，也就是第一个video tag.
 *                    CompositionTime 3byte,AVCPacketType ==1   Composition time offset
 *                                          AVCPacketType !=1   0
 *                                如果AVCPacketType = 0 后面三个字节也是0，说明这个tag记录的是AVCDecoderConfigurationRecord。包含sps和pps数据。
 *                                          后面数据为：0x01+sps[1]+sps[2]+sps[3]+0xFF+0xE1+sps_size+sps+01+pps_size+pps
 *                                如果AVCPacketType = 1 后面三个字节，这是一个视频帧数据
 *                                          后面数据为：帧数据（NALU DATA）
 *
 *
 *     scripts Tag Data：脚本Tag一般只有一个，是flv的第一个Tag，用于存放flv的信息，比如duration、audiodatarate、creator、width等。
 *                      数据类型+（数据长度）+数据，数据类型占1byte,数据长度根据数据类型
 *                        数据类型：0 = Number type
 *                                1 = Boolean type
 *                                2 = String type
 *                                3 = Object type
 *                                4 = MovieClip type
 *                                5 = Null type
 *                                6 = Undefined type
 *                                7 = Reference type
 *                                8 = ECMA array type
 *                                10 = Strict array type
 *                                11 = Date type
 *                                12 = Long string type
 *                        如果为 String type ,那么数据长度占2bytes(Long string type 占 4bytes)，后面就是字符串数据 举个栗子：0x02(String 类型)+0x000a("onMetaData"长度) + "onMetaData"
 *                        如果为 Number type ,没有数据长度，后面直接为8bytes的 Double 类型数据
 *                        如果为 Boolean type,没有数据长度，后面直接为1byte的 Bool 类型数据
 *                        如果为 ECMA array type,数据长度占4bytes 值表示数组长度，后面 键是 String 类型的，开头0x02被省略，直接跟字符串长度，然后是字符串，在是值类型（根据上面来）
 */

#ifndef MSPFLVDefine_h
#define MSPFLVDefine_h

// flv tag type 占1byte
typedef NS_ENUM (NSUInteger, msp_flv_tag_type)
{
    msp_flv_tag_type_audio             = 0x08, // = 8 音频
    msp_flv_tag_type_video             = 0x09, // = 9 视频
    msp_flv_tag_type_script            = 0x12, // = 18 脚本
};


#pragma mark - video Tag Data

// 帧类型 占4bits 这里只用到了 key、inner
typedef NS_ENUM (NSUInteger, msp_flv_video_frametype)
{
    msp_flv_video_frametype_key         = 1,// keyframe (for AVC, a seekable frame)
    msp_flv_video_frametype_inner       = 2,// inter frame (for AVC, a non-seekable frame)
    //msp_flv_video_frametype_inner_d     = 3,// disposable inter frame (H.263 only)
    //msp_flv_video_frametype_key_g       = 4,// generated keyframe (reserved for server use only)
    //msp_flv_video_frametype_vi_cf       = 5,// video info/command frame
};

// 编码(格式)ID 占4bits 只用到了H264
typedef NS_ENUM (NSUInteger, msp_flv_video_codecid)
{
    //msp_flv_video_codecid_JPEG          = 1,// JPEG (currently unused)
    msp_flv_video_codecid_H263          = 2,// Sorenson H.263
    //msp_flv_video_codecid_ScreenVideo   = 3,// Screen video
    //msp_flv_video_codecid_On2VP6        = 4,// On2 VP6
    //msp_flv_video_codecid_On2VP6_AC     = 5,// On2 VP6 with alpha channel
    //msp_flv_video_codecid_ScreenVideo2  = 6,// Screen video version 2
    msp_flv_video_codecid_H264          = 7,// AVC
    //msp_flv_video_codecid_RealH263      = 8,
    //msp_flv_video_codecid_MPEG4         = 9,
};

#pragma mark - audio Tag Data

// 音频编码(音频格式)ID 占4bits 只用到了AAC
typedef NS_ENUM (NSUInteger, msp_flv_audio_codecid)
{
    //msp_flv_audio_codecid_PCM           = 0,// Linear PCM, platform endian
    //msp_flv_audio_codecid_ADPCM         = 1,// ADPCM
    msp_flv_audio_codecid_MP3           = 2,// MP3
    //msp_flv_audio_codecid_PCM_LE        = 3,// Linear PCM, little endian
    //msp_flv_audio_codecid_N16           = 4,// Nellymoser 16-kHz mono
    //msp_flv_audio_codecid_N8            = 5,// Nellymoser 8-kHz mono
    //msp_flv_audio_codecid_N             = 6,// Nellymoser
    //msp_flv_audio_codecid_PCM_ALAW      = 7,// G.711 A-law logarithmic PCM
    //msp_flv_audio_codecid_PCM_MULAW     = 8,// G.711 mu-law logarithmic PCM
    //msp_flv_audio_codecid_RESERVED      = 9,// reserved
    msp_flv_audio_codecid_AAC           = 10,// AAC
    //msp_flv_audio_codecid_SPEEX         = 11,// Speex
    //msp_flv_audio_codecid_MP3_8         = 14,// MP3 8-Khz
    //msp_flv_audio_codecid_DSS           = 15,// Device-specific sound
};

// soundSize 8bit/16bit 采样长度 压缩过的音频都是16bit  占1bit
typedef NS_ENUM (NSUInteger, msp_flv_audio_soundsize)
{
    msp_flv_audio_soundsize_8bit        = 0,// snd8Bit
    msp_flv_audio_soundsize_16bit       = 1,// snd16Bit
};

// sound rate 5.5 11 22 44 kHz 采样率 对于AAC总是3
typedef NS_ENUM (NSUInteger, msp_flv_audio_soundrate)
{
    msp_flv_audio_soundrate_5_5kHZ      = 0,// 5.5-kHz
    msp_flv_audio_soundrate_11kHZ       = 1,// 11-kHz
    msp_flv_audio_soundrate_22kHZ       = 2,// 22-kHz
    msp_flv_audio_soundrate_44kHZ       = 3,// 44-kHz
};

// sound type mono/stereo  对于AAC总是1
typedef NS_ENUM (NSUInteger, msp_flv_audio_soundtype)
{
    msp_flv_audio_soundtype_mono        = 0,// sndMono
    msp_flv_audio_soundtype_stereo      = 1,// sndStereo
};


typedef NS_ENUM(NSUInteger, msp_flv_video_h264_packettype)
{
    msp_flv_video_h264_packettype_seqHeader     = 0,
    msp_flv_video_h264_packettype_nalu          = 1,
    msp_flv_video_h264_packettype_endOfSeq      = 2,
};

typedef NS_ENUM(NSUInteger, msp_flv_audio_aac_packettype)
{
    msp_flv_audio_aac_packettype_seqHeader      = 0,
    msp_flv_audio_aac_packettype_raw            = 1,
};

#endif /* MSPFLVDefine_h */
