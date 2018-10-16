//
//  MSPGPUImageBeautyFilter.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/14.
//  Copyright © 2018年 Mob. All rights reserved.
//

#if __has_include(<GPUImage/GPUImageFramework.h>)
#import <GPUImage/GPUImageFramework.h>
#else
#import "GPUImage.h"
#endif

@interface MSPGPUImageBeautyFilter : GPUImageFilter

@property (nonatomic, assign) CGFloat beautyLevel;
@property (nonatomic, assign) CGFloat brightLevel;
@property (nonatomic, assign) CGFloat toneLevel;

@end
