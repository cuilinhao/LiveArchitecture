//
//  MSPStreamConfig.h
//  MOBStreamingPusher
//
//  Created by wukexiu on 2018/9/21.
//  Copyright © 2018年 testDemo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSPVideoConfiguration.h"
#import "MSPAudioConfiguration.h"

/// 流状态
typedef NS_ENUM (NSUInteger, MSPSocketState)
{
    /// 准备
    MSPSocketState_Ready         = 0,
    /// 连接中
    MSPSocketState_Pending       = 1,
    /// 已连接
    MSPSocketState_Start         = 2,
    /// 已断开
    MSPSocketState_Stop          = 3,
    /// 连接出错
    MSPSocketState_Error         = 4,
    /// 正在刷新
    MSPSocketState_Refresh       = 5,
};

typedef NS_ENUM (NSUInteger, MSPSocketErrorCode)
{
    /// 预览失败
    MSPSocketErrorCode_PreView          = 201,
    /// 获取流媒体信息失败
    MSPSocketErrorCode_GetStreamInfo    = 202,
    /// 连接socket失败
    MSPSocketErrorCode_ConnectSocket    = 203,
    /// 验证服务器失败
    MSPSocketErrorCode_Verification     = 204,
    /// 重新连接服务器超时
    MSPSocketErrorCode_ReConnectTimeOut = 205,
};

@interface MSPStreamConfig : NSObject

@property (nonatomic, copy) NSString *streamId;

#pragma mark -- FLV
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) NSInteger port;
#pragma mark -- RTMP
@property (nonatomic, copy) NSString *url;          ///< 上传地址 (RTMP用就好了)
///音频配置
@property (nonatomic, strong) MSPAudioConfiguration *audioConfiguration;
///视频配置
@property (nonatomic, strong) MSPVideoConfiguration *videoConfiguration;

@end
