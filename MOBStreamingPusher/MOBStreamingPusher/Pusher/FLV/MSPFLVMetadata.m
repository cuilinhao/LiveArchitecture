//
//  MSPFLVMetadata.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPFLVMetadata.h"

@implementation MSPFLVMetadata

- (id)init
{
    if (self = [super init])
    {
        _audioCodecId = -1;
        _videoCodecId = -1;
    }
    return self;
}

@end
