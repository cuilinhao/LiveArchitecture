//
//  MSPAudioConfiguration.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/11.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>

/// 音频码率 (默认96Kbps)
typedef NS_ENUM (NSUInteger, MSPAudioBitRate)
{
    MSPAudioBitRate_32Kbps          = 32000,
    MSPAudioBitRate_64Kbps          = 64000,
    MSPAudioBitRate_96Kbps          = 96000,
    MSPAudioBitRate_128Kbps         = 128000,
    MSPAudioBitRate_Default         = MSPAudioBitRate_96Kbps
};

/// 音频采样率 (默认44.1KHz)
typedef NS_ENUM (NSUInteger, MSPAudioSampleRate)
{
    MSPAudioSampleRate_16000Hz      = 16000,
    MSPAudioSampleRate_44100Hz      = 44100,
    MSPAudioSampleRate_48000Hz      = 48000,
    MSPAudioSampleRate_Default      = MSPAudioSampleRate_44100Hz
};

/// 音频质量
typedef NS_ENUM (NSUInteger, MSPAudioQuality)
{
    /// MSPAudioSampleRate_16000Hz,MSPAudioBitRate_32Kbps|MSPAudioBitRate_64Kbps
    MSPAudioQuality_Low             = 0,
    /// MSPAudioSampleRate_44100Hz,MSPAudioBitRate_96Kbps
    MSPAudioQuality_Medium          = 1,
    /// MSPAudioSampleRate_44100Hz,MSPAudioBitRate_128Kbps
    MSPAudioQuality_Hight           = 2,
    /// MSPAudioSampleRate_48000Hz,MSPAudioBitRate_128Kbps
    MSPAudioQuality_VeryHight       = 3,
    /// MSPAudioSampleRate_44100Hz,MSPAudioBitRate_128Kbps
    MSPAudioQuality_Default         = MSPAudioQuality_Hight
};

@interface MSPAudioConfiguration : NSObject<NSCoding, NSCopying>

/// 声道数目
@property (nonatomic, assign) NSUInteger numberOfChannels;
/// 采样率
@property (nonatomic, assign) MSPAudioSampleRate audioSampleRate;
/// 码率
@property (nonatomic, assign) MSPAudioBitRate audioBitRate;
/// flv 编码音频头
@property (nonatomic, assign, readonly) char *asc;
/// 缓存区长度
@property (nonatomic, assign, readonly) NSUInteger bufferLength;

+ (instancetype)defaultConfiguration;

+ (instancetype)defaultConfigurationForQuality:(MSPAudioQuality)audioQuality;

- (NSInteger)sampleRateIndex:(NSInteger)frequencyInHz;

@end
