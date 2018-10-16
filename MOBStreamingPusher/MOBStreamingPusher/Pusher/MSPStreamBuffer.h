//
//  MSPStreamBuffer.h
//  MOBStreamingPusher
//
//  Created by wukexiu on 2018/9/21.
//  Copyright © 2018年 testDemo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSPBaseFrame.h"

typedef NS_ENUM (NSUInteger, MSPStreamBuffferState) {
    MSPStreamBuffferUnknown   = 0,      ///< 未知
    MSPStreamBuffferIncrease  = 1,      ///< 缓冲区状态差应该降低码率
    MSPStreamBuffferDecline   = 2       ///< 缓冲区状态好应该提升码率
};

@class MSPStreamBuffer;

@protocol MSPStreamBufferDelegate <NSObject>
@optional
/** 当前buffer变动（增加or减少） 根据buffer中的updateInterval时间回调*/
- (void)streamBuffer:(nullable MSPStreamBuffer *)buffer bufferState:(MSPStreamBuffferState)state;
@end


@interface MSPStreamBuffer : NSObject

@property (nullable, nonatomic, weak) id <MSPStreamBufferDelegate> delegate;

@property (nonatomic, strong, readonly) NSMutableArray <MSPBaseFrame *> *_Nonnull list;

@property (nonatomic, assign) NSUInteger maxCount;

@property (nonatomic, assign) NSInteger lastDropFrames;

- (void)appendObject:(nullable MSPBaseFrame *)frame;
- (nullable MSPBaseFrame *)popFirstObject;
- (void)removeAllObject;

@end
