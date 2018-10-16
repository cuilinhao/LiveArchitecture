//
//  MSPTestSocket.h
//  MOBStreamingPusher
//
//  Created by wkx on 2018/9/26.
//  Copyright © 2018年 testDemo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSPStreamSocket.h"

@interface MSPTestSocket : NSObject<MSPStreamSocket>

- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
