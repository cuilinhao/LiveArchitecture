//
//  MSPLivePreview.m
//  MOBStreamingPusherDemo
//
//  Created by wkx on 2018/9/26.
//  Copyright © 2018年 testDemo. All rights reserved.
//

#import "MSPLivePreview.h"
#import "MOBStreamingPusher.h"
#import "UIView+MSPAdd.h"
#import "UIControl+MSPAdd.h"

inline static NSString *formatedSpeed(float bytes, float elapsed_milli) {
    if (elapsed_milli <= 0) {
        return @"N/A";
    }
    
    if (bytes <= 0) {
        return @"0 KB/s";
    }
    
    float bytes_per_sec = ((float)bytes) * 1000.f /  elapsed_milli;
    if (bytes_per_sec >= 1000 * 1000) {
        return [NSString stringWithFormat:@"%.2f MB/s", ((float)bytes_per_sec) / 1000 / 1000];
    } else if (bytes_per_sec >= 1000) {
        return [NSString stringWithFormat:@"%.1f KB/s", ((float)bytes_per_sec) / 1000];
    } else {
        return [NSString stringWithFormat:@"%ld B/s", (long)bytes_per_sec];
    }
}

@interface MSPLivePreview ()<MSPAVSessionDelegate>


@property (nonatomic, strong) UIButton *beautyButton;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *startLiveButton;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) MSPAVSession *session;
@property (nonatomic, strong) UILabel *stateLabel;


@end

@implementation MSPLivePreview

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self requestAccessForVideo];
        [self requestAccessForAudio];
        [self addSubview:self.containerView];
        [self.containerView addSubview:self.stateLabel];
        [self.containerView addSubview:self.closeButton];
        [self.containerView addSubview:self.cameraButton];
        [self.containerView addSubview:self.beautyButton];
        [self.containerView addSubview:self.startLiveButton];
    }
    return self;
}

#pragma mark -- Public Method
- (void)requestAccessForVideo {
    __weak typeof(self) _self = self;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status)
    {
        case AVAuthorizationStatusNotDetermined:
        {
            // 许可对话没有出现，发起授权许可
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_self.session setRunning:YES];
                    });
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:
        {
            // 已经开启授权，可继续
            dispatch_async(dispatch_get_main_queue(), ^{
                [_self.session setRunning:YES];
            });
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            // 用户明确地拒绝授权，或者相机设备无法访问
            
            break;
        default:
            break;
    }
}

- (void)requestAccessForAudio
{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status)
    {
        case AVAuthorizationStatusNotDetermined:
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:
        {
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            break;
        default:
            break;
    }
}

#pragma mark -- LFStreamingSessionDelegate
/** live status changed will callback */
- (void)AVSession:(nullable MSPAVSession *)session stateDidChange:(MSPSocketState)state
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"liveStateDidChange: %ld", state);
        switch (state) {
            case MSPSocketState_Ready:
                weakSelf.stateLabel.text = @"未连接";
                break;
            case MSPSocketState_Pending:
                weakSelf.stateLabel.text = @"连接中";
                break;
            case MSPSocketState_Start:
                weakSelf.stateLabel.text = @"已连接";
                break;
            case MSPSocketState_Error:
                weakSelf.stateLabel.text = @"连接错误";
                break;
            case MSPSocketState_Stop:
                weakSelf.stateLabel.text = @"未连接";
                break;
            default:
                break;
        }
    });
    
}

/** callback socket errorcode */
- (void)AVSession:(nullable MSPAVSession *)session errorCode:(MSPSocketErrorCode)errorCode
{
    NSLog(@"errorCode: %ld", errorCode);
}

#pragma mark -- Getter Setter
- (MSPAVSession *)session
{
    if (!_session)
    {
        
        /***   默认分辨率368 ＊ 640  音频：44.1 iphone6以上48  双声道  方向竖屏 ***/
        MSPVideoConfiguration *videoConfiguration = [MSPVideoConfiguration new];
        videoConfiguration.videoSize = CGSizeMake(360, 640);
        videoConfiguration.videoBitRate = 800*1024;
        videoConfiguration.videoMaxBitRate = 1000*1024;
        videoConfiguration.videoMinBitRate = 500*1024;
        videoConfiguration.videoFrameRate = 24;
        videoConfiguration.videoMaxKeyframeInterval = 48;
        videoConfiguration.outputImageOrientation = UIInterfaceOrientationPortrait;
        videoConfiguration.autorotate = NO;
        videoConfiguration.sessionPreset = MSPCaptureSessionPreset720x1280;
        _session = [[MSPAVSession alloc] initWithAudioConfiguration:[MSPAudioConfiguration defaultConfiguration] videoConfiguration:videoConfiguration];
        
        
        _session.delegate = self;
        _session.preView = self;
        
    }
    return _session;
}

- (UIView *)containerView
{
    if (!_containerView)
    {
        _containerView = [UIView new];
        _containerView.frame = self.bounds;
        _containerView.backgroundColor = [UIColor clearColor];
        _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _containerView;
}

- (UILabel *)stateLabel
{
    if (!_stateLabel)
    {
        _stateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 80, 40)];
        _stateLabel.text = @"未连接";
        _stateLabel.textColor = [UIColor whiteColor];
        _stateLabel.font = [UIFont boldSystemFontOfSize:14.f];
    }
    return _stateLabel;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton new];
        _closeButton.size = CGSizeMake(44, 44);
        _closeButton.left = self.width - 10 - _closeButton.width;
        _closeButton.top = 20;
        [_closeButton setImage:[UIImage imageNamed:@"close_preview"] forState:UIControlStateNormal];
        _closeButton.exclusiveTouch = YES;
        [_closeButton addBlockForControlEvents:UIControlEventTouchUpInside block:^(id sender) {
            
        }];
    }
    return _closeButton;
}

- (UIButton *)cameraButton {
    if (!_cameraButton) {
        _cameraButton = [UIButton new];
        _cameraButton.size = CGSizeMake(44, 44);
        _cameraButton.origin = CGPointMake(_closeButton.left - 10 - _cameraButton.width, 20);
        [_cameraButton setImage:[UIImage imageNamed:@"camra_preview"] forState:UIControlStateNormal];
        _cameraButton.exclusiveTouch = YES;
        __weak typeof(self) _self = self;
        [_cameraButton addBlockForControlEvents:UIControlEventTouchUpInside block:^(id sender) {
            AVCaptureDevicePosition devicePositon = _self.session.captureDevicePosition;
            _self.session.captureDevicePosition = (devicePositon == AVCaptureDevicePositionBack) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
        }];
    }
    return _cameraButton;
}

- (UIButton *)beautyButton {
    if (!_beautyButton) {
        _beautyButton = [UIButton new];
        _beautyButton.size = CGSizeMake(44, 44);
        _beautyButton.origin = CGPointMake(_cameraButton.left - 10 - _beautyButton.width, 20);
        [_beautyButton setImage:[UIImage imageNamed:@"camra_beauty"] forState:UIControlStateNormal];
        [_beautyButton setImage:[UIImage imageNamed:@"camra_beauty_close"] forState:UIControlStateSelected];
        _beautyButton.exclusiveTouch = YES;
        __weak typeof(self) _self = self;
        [_beautyButton addBlockForControlEvents:UIControlEventTouchUpInside block:^(id sender) {
            _self.session.beautyFace = !_self.session.beautyFace;
            _self.beautyButton.selected = !_self.session.beautyFace;
        }];
    }
    return _beautyButton;
}

- (UIButton *)startLiveButton {
    if (!_startLiveButton) {
        _startLiveButton = [UIButton new];
        _startLiveButton.size = CGSizeMake(self.width - 60, 44);
        _startLiveButton.left = 30;
        _startLiveButton.bottom = self.height - 50;
        _startLiveButton.layer.cornerRadius = _startLiveButton.height/2;
        [_startLiveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_startLiveButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [_startLiveButton setTitle:@"开始直播" forState:UIControlStateNormal];
        [_startLiveButton setBackgroundColor:[UIColor colorWithRed:50 green:32 blue:245 alpha:1]];
        _startLiveButton.exclusiveTouch = YES;
        __weak typeof(self) _self = self;
        [_startLiveButton addBlockForControlEvents:UIControlEventTouchUpInside block:^(id sender) {
            _self.startLiveButton.selected = !_self.startLiveButton.selected;
            if (_self.startLiveButton.selected) {
                [_self.startLiveButton setTitle:@"结束直播" forState:UIControlStateNormal];
                MSPStreamConfig *stream = [MSPStreamConfig new];
                stream.url = @"rtmp://192.168.103.167:1935/MSPLive/room000001";
                [_self.session startLive:stream];
            } else {
                [_self.startLiveButton setTitle:@"开始直播" forState:UIControlStateNormal];
                [_self.session stopLive];
            }
        }];
    }
    return _startLiveButton;
}

@end
