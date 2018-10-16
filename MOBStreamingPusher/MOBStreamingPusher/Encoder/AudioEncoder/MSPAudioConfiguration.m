//
//  MSPAudioConfiguration.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/11.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPAudioConfiguration.h"

@implementation MSPAudioConfiguration

+ (instancetype)defaultConfiguration
{
    MSPAudioConfiguration *audioConfig = [MSPAudioConfiguration defaultConfigurationForQuality:MSPAudioQuality_Default];
    return audioConfig;
}

+ (instancetype)defaultConfigurationForQuality:(MSPAudioQuality)audioQuality
{
    MSPAudioConfiguration *audioConfig = [MSPAudioConfiguration new];
    audioConfig.numberOfChannels = 2;
    switch (audioQuality)
    {
        case MSPAudioQuality_Low:
        {
            audioConfig.audioBitRate = audioConfig.numberOfChannels == 1 ? MSPAudioBitRate_32Kbps : MSPAudioBitRate_64Kbps;
            audioConfig.audioSampleRate = MSPAudioSampleRate_16000Hz;
        }
            break;
        case MSPAudioQuality_Medium:
        {
            audioConfig.audioBitRate = MSPAudioBitRate_96Kbps;
            audioConfig.audioSampleRate = MSPAudioSampleRate_44100Hz;
        }
            break;
        case MSPAudioQuality_Hight:
        {
            audioConfig.audioBitRate = MSPAudioBitRate_128Kbps;
            audioConfig.audioSampleRate = MSPAudioSampleRate_44100Hz;
        }
            break;
        case MSPAudioQuality_VeryHight:
        {
            audioConfig.audioBitRate = MSPAudioBitRate_128Kbps;
            audioConfig.audioSampleRate = MSPAudioSampleRate_48000Hz;
        }
            break;
        default:
        {
            audioConfig.audioBitRate = MSPAudioBitRate_96Kbps;
            audioConfig.audioSampleRate = MSPAudioSampleRate_44100Hz;
        }
            break;
    }
    return audioConfig;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _asc = malloc(2);
    }
    return self;
}

- (void)dealloc
{
    if (_asc)
    {
        free(_asc);
    }
}

#pragma mark - Setter

- (void)setAudioSampleRate:(MSPAudioSampleRate)audioSampleRate
{
    _audioSampleRate = audioSampleRate;
    NSInteger sampleRateIndex = [self sampleRateIndex:audioSampleRate];
    self.asc[0] = 0x10 | ((sampleRateIndex>>1) & 0x7);
    self.asc[1] = ((sampleRateIndex & 0x1)<<7) | ((self.numberOfChannels & 0xF) << 3);
}

- (void)setNumberOfChannels:(NSUInteger)numberOfChannels
{
    _numberOfChannels = numberOfChannels;
    NSInteger sampleRateIndex = [self sampleRateIndex:self.audioSampleRate];
    self.asc[0] = 0x10 | ((sampleRateIndex>>1) & 0x7);
    self.asc[1] = ((sampleRateIndex & 0x1)<<7) | ((numberOfChannels & 0xF) << 3);
}

- (NSUInteger)bufferLength
{
    return 1024 * 2 * self.numberOfChannels;
}

#pragma mark - Encoder

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:@(self.numberOfChannels) forKey:@"numberOfChannels"];
    [aCoder encodeObject:@(self.audioSampleRate) forKey:@"audioSampleRate"];
    [aCoder encodeObject:@(self.audioBitRate) forKey:@"audioBitRate"];
    [aCoder encodeObject:[NSString stringWithUTF8String:self.asc] forKey:@"asc"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    _numberOfChannels = [[aDecoder decodeObjectForKey:@"numberOfChannels"] unsignedIntegerValue];
    _audioSampleRate = [[aDecoder decodeObjectForKey:@"audioSampleRate"] unsignedIntegerValue];
    _audioBitRate = [[aDecoder decodeObjectForKey:@"audioBitRate"] unsignedIntegerValue];
    _asc = strdup([[aDecoder decodeObjectForKey:@"asc"] cStringUsingEncoding:NSUTF8StringEncoding]);
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (object == self)
    {
        return YES;
    }
    else if (![super isEqual:object])
    {
        return NO;
    }
    else
    {
        MSPAudioConfiguration *tmp = object;
        return tmp.numberOfChannels == self.numberOfChannels &&
               tmp.audioBitRate == self.audioBitRate &&
               strcmp(tmp.asc, self.asc) == 0 &&
               tmp.audioSampleRate == self.audioSampleRate;
    }
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    NSArray *values = @[@(_numberOfChannels),
                        @(_audioSampleRate),
                        [NSString stringWithUTF8String:self.asc],
                        @(_audioBitRate)];
    for (NSObject *value in values)
    {
        hash ^= value.hash;
    }
    return hash;
}

- (id)copyWithZone:(NSZone *)zone
{
    MSPAudioConfiguration *other = [self.class defaultConfiguration];
    return other;
}

- (NSString *)description {
    NSMutableString *desc = @"".mutableCopy;
    [desc appendFormat:@"<MSPAudioConfiguration: %p>", self];
    [desc appendFormat:@" numberOfChannels:%lu", (unsigned long)self.numberOfChannels];
    [desc appendFormat:@" audioSampleRate:%lu", (unsigned long)self.audioSampleRate];
    [desc appendFormat:@" audioBitRate:%lu", (unsigned long)self.audioBitRate];
    [desc appendFormat:@" audioHeader:%@", [NSString stringWithUTF8String:self.asc]];
    return desc;
}


#pragma mark - Private

- (NSInteger)sampleRateIndex:(NSInteger)frequencyInHz
{
    NSInteger sampleRateIndex = 0;
    switch (frequencyInHz)
    {
        case 96000:
            sampleRateIndex = 0;
            break;
        case 88200:
            sampleRateIndex = 1;
            break;
        case 64000:
            sampleRateIndex = 2;
            break;
        case 48000:
            sampleRateIndex = 3;
            break;
        case 44100:
            sampleRateIndex = 4;
            break;
        case 32000:
            sampleRateIndex = 5;
            break;
        case 24000:
            sampleRateIndex = 6;
            break;
        case 22050:
            sampleRateIndex = 7;
            break;
        case 16000:
            sampleRateIndex = 8;
            break;
        case 12000:
            sampleRateIndex = 9;
            break;
        case 11025:
            sampleRateIndex = 10;
            break;
        case 8000:
            sampleRateIndex = 11;
            break;
        case 7350:
            sampleRateIndex = 12;
            break;
        default:
            sampleRateIndex = 15;
            break;
    }
    return sampleRateIndex;
}


@end
