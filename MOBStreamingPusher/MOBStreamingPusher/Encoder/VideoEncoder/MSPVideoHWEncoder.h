//
//  MSPVideoHWEncoder.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/12.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPVideoBaseEncoder.h"

/// 使用苹果提供硬编码 <VideoToolbox/VideoToolbox.h>
/// 工作流程:
/// 1.创建Session、设置编码相关参数、开始编码
/// 2.循环输入源数据(yuv类型的数据，直接从摄像头获取)
/// 3.获取编码后的h264数据
/// 4.结束编码
@interface MSPVideoHWEncoder : NSObject<MSPVideoBaseEncoder>

/// 不允许访问 init 和 new
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
