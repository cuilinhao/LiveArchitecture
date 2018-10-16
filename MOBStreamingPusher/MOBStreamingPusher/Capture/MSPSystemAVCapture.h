//
//  MSPSystemAVCapture.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSPVideoConfiguration.h"
#import "MSPVideoCapture.h"
#import "MSPAudioCapture.h"

@interface MSPSystemAVCapture : NSObject

@property (nullable, nonatomic, weak) id<MSPVideoCaptureDelegate> delegate;

// 不允许访问 init 和 new
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

- (nullable instancetype)initWithVideoConfiguration:(nullable MSPVideoConfiguration *)configuration;

@end
