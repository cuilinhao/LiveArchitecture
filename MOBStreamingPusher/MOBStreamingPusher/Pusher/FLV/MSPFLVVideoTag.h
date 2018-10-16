//
//  MSPFLVVideoTag.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPFLVBaseTag.h"

@interface MSPFLVVideoTag : MSPFLVBaseTag

@property (nonatomic, assign) int frameType;
@property (nonatomic, assign) int codecId;
@property (nonatomic, assign) int packetType;
@property (nonatomic, assign) int cts;

@end
