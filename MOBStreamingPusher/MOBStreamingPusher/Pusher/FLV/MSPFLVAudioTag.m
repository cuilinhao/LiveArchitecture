//
//  MSPFLVAudioTag.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPFLVAudioTag.h"
#import "MSPFLVDefine.h"

@implementation MSPFLVAudioTag

- (instancetype)init
{
    if (self = [super init])
    {
        _soundFormat = msp_flv_audio_codecid_AAC;
        _soundRate = msp_flv_audio_soundrate_44kHZ;
        _soundSize = msp_flv_audio_soundsize_16bit;
        _soundType = msp_flv_audio_soundtype_stereo;
        _packetType = msp_flv_audio_aac_packettype_raw;
        self.typeData = msp_flv_tag_type_audio;
        self.flagsSize = 2;
    }
    return self;
}

@end
