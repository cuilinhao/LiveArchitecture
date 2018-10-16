//
//  MSPStreamSocket.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSPBaseFrame.h"
#import "MSPStreamConfig.h"
#import "MSPStreamBuffer.h"

@protocol MSPStreamSocket;
@protocol MSPStreamSocketDelegate <NSObject>

/** callback buffer current status (回调当前缓冲区情况，可实现相关切换帧率 码率等策略)*/
- (void)socketBufferStatus:(nullable id <MSPStreamSocket>)socket status:(MSPStreamBuffferState)status;
/** callback socket current status (回调当前网络情况) */
- (void)socketStatus:(nullable id <MSPStreamSocket>)socket status:(MSPSocketState)status;
/** callback socket errorcode */
- (void)socketDidError:(nullable id <MSPStreamSocket>)socket errorCode:(MSPSocketErrorCode)errorCode;

@end

@protocol MSPStreamSocket <NSObject>

- (void)start;
- (void)stop;
- (void)sendFrame:(nullable MSPBaseFrame *)frame;
- (void)setDelegate:(nullable id <MSPStreamSocketDelegate>)delegate;

@optional
- (nullable instancetype)initWithStream:(nullable MSPStreamConfig *)streamConfig;
- (nullable instancetype)initWithStream:(nullable MSPStreamConfig *)streamConfig reconnectInterval:(NSInteger)reconnectInterval reconnectCount:(NSInteger)reconnectCount;

@end
