//
//  MSPAudioHWEncoder.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/11.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPAudioBaseEncoder.h"

@interface MSPAudioHWEncoder : NSObject<MSPAudioBaseEncoder>

/// 不允许访问 init 和 new
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
