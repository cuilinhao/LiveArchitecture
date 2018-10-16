//
//  MSPRtmpSocket.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSPStreamSocket.h"

@interface MSPRtmpSocket : NSObject<MSPStreamSocket>

- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
