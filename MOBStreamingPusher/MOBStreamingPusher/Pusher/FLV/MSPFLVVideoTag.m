//
//  MSPFLVVideoTag.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPFLVVideoTag.h"
#import "MSPFLVDefine.h"

@implementation MSPFLVVideoTag

- (instancetype)init
{
    if (self = [super init])
    {
        _packetType = msp_flv_video_h264_packettype_nalu;
        _codecId = msp_flv_video_codecid_H264;
        _frameType = msp_flv_video_frametype_inner;
        self.typeData = msp_flv_tag_type_video;
        self.flagsSize = 5;
        self.cts = 0;
    }
    return self;
}

@end
