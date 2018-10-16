//
//  MSPFLVAudioTag.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPFLVBaseTag.h"

@interface MSPFLVAudioTag : MSPFLVBaseTag

@property (nonatomic, assign) int soundFormat;
@property (nonatomic, assign) int soundRate;
@property (nonatomic, assign) int soundSize;
@property (nonatomic, assign) int packetType;
@property (nonatomic, assign) int soundType;

@end
