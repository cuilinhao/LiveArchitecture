//
//  MSPAudioCapture.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/13.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPAudioCapture.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

NSString *const MSPAudioComponentFailedToCreateNotification = @"MSPAudioComponentFailedToCreateNotification";

@interface MSPAudioCapture ()

@property (nonatomic, assign) AudioComponentInstance componentInstance;
@property (nonatomic, assign) AudioComponent component;
@property (nonatomic, strong) dispatch_queue_t taskQueue;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, strong, nullable) MSPAudioConfiguration *configuration;

@end

@implementation MSPAudioCapture

- (nullable instancetype)initWithAudioConfiguration:(nullable MSPAudioConfiguration *)configuration
{
    if (self = [super init])
    {
        _configuration = configuration;
        self.isRunning = NO;
        self.taskQueue = dispatch_queue_create("com.mob.streamingPusher.audioCapture.Queue", NULL);
        
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        //route变化监听
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleRouteChange:)
                                                     name: AVAudioSessionRouteChangeNotification
                                                   object: session];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleInterruption:)
                                                     name: AVAudioSessionInterruptionNotification
                                                   object: session];
        
        //对Audio Unit的设置
        
        ///用于描述音频组件的唯一标识和标识的结构
        AudioComponentDescription acd;
        ///一个音频组件的通用的独特的四字节码标识
        acd.componentType = kAudioUnitType_Output;
        ///根据componentType设置相应的类型*/
        //acd.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
        acd.componentSubType = kAudioUnitSubType_RemoteIO;
        ///厂商的身份验证
        acd.componentManufacturer = kAudioUnitManufacturer_Apple;
        //如果没有一个明确指定的值，那么它必须被设置为0
        acd.componentFlags = 0;
        acd.componentFlagsMask = 0;
        
        self.component = AudioComponentFindNext(NULL, &acd);
        
        OSStatus status = noErr;
        status = AudioComponentInstanceNew(self.component, &_componentInstance);
        
        if (noErr != status) {
            [self handleAudioComponentCreationFailure];
        }
        
        UInt32 flagOne = 1;
        
        AudioUnitSetProperty(self.componentInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flagOne, sizeof(flagOne));
        
        AudioStreamBasicDescription desc = {0};
        desc.mSampleRate = _configuration.audioSampleRate;
        desc.mFormatID = kAudioFormatLinearPCM;
        desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
        desc.mChannelsPerFrame = (UInt32)_configuration.numberOfChannels;
        desc.mFramesPerPacket = 1;
        desc.mBitsPerChannel = 16;
        desc.mBytesPerFrame = desc.mBitsPerChannel / 8 * desc.mChannelsPerFrame;
        desc.mBytesPerPacket = desc.mBytesPerFrame * desc.mFramesPerPacket;
        
        AURenderCallbackStruct cb;
        cb.inputProcRefCon = (__bridge void *)(self);
        cb.inputProc = handleInputBuffer;
        AudioUnitSetProperty(self.componentInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &desc, sizeof(desc));
        AudioUnitSetProperty(self.componentInstance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &cb, sizeof(cb));
        
        status = AudioUnitInitialize(self.componentInstance);
        
        if (noErr != status) {
            [self handleAudioComponentCreationFailure];
        }
        
        [session setPreferredSampleRate:_configuration.audioSampleRate error:nil];
        if (@available(iOS 9.0, *))
        {
            [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers error:nil];
        } else {
            // Fallback on earlier versions
        }
        [session setActive:YES withOptions:kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation error:nil];
        
        [session setActive:YES error:nil];
        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    dispatch_sync(self.taskQueue, ^{
        if (self.componentInstance) {
            self.isRunning = NO;
            AudioOutputUnitStop(self.componentInstance);
            AudioComponentInstanceDispose(self.componentInstance);
            self.componentInstance = nil;
            self.component = nil;
        }
    });
}

#pragma mark - Setter

- (void)setRunning:(BOOL)running {
    if (_running == running) return;
    _running = running;
    if (_running)
    {
        dispatch_async(self.taskQueue, ^{
            self.isRunning = YES;
            NSLog(@"MicrophoneSource: startRunning");
            if (@available(iOS 9.0, *))
            {
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers error:nil];
            } else {
                // Fallback on earlier versions
            }
            AudioOutputUnitStart(self.componentInstance);
        });
    }
    else
    {
        dispatch_sync(self.taskQueue, ^{
            self.isRunning = NO;
            NSLog(@"MicrophoneSource: stopRunning");
            AudioOutputUnitStop(self.componentInstance);
        });
    }
}

#pragma mark - CallBack

///采集音频数据的输入回调
static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    @autoreleasepool {
        MSPAudioCapture *source = (__bridge MSPAudioCapture *)inRefCon;
        if (!source) return -1;
        
        AudioBuffer buffer;
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        buffer.mNumberChannels = 1;
        
        AudioBufferList buffers;
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0] = buffer;
        
        OSStatus status = AudioUnitRender(source.componentInstance,
                                          ioActionFlags,
                                          inTimeStamp,
                                          inBusNumber,
                                          inNumberFrames,
                                          &buffers);
        
        if (source.muted)
        {
            for (int i = 0; i < buffers.mNumberBuffers; i++)
            {
                AudioBuffer ab = buffers.mBuffers[i];
                memset(ab.mData, 0, ab.mDataByteSize);
            }
        }
        
        if (!status)
        {
            if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioData:)])
            {
                [source.delegate captureOutput:source audioData:[NSData dataWithBytes:buffers.mBuffers[0].mData length:buffers.mBuffers[0].mDataByteSize]];
                 //[source.delegate captureOutput:source audioData:[NSData dataWithBytesNoCopy:buffers.mBuffers[0].mData length:buffers.mBuffers[0].mDataByteSize freeWhenDone:NO]];
            }
        }
        return status;
    }
}

#pragma mark - NSNotification

- (void)handleRouteChange:(NSNotification *)notification
{
    AVAudioSession *session = [ AVAudioSession sharedInstance ];
    NSString *seccReason = @"";
    NSInteger reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    //  AVAudioSessionRouteDescription* prevRoute = [[notification userInfo] objectForKey:AVAudioSessionRouteChangePreviousRouteKey];
    switch (reason)
    {
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            seccReason = @"The route changed because no suitable route is now available for the specified category.";
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            seccReason = @"The route changed when the device woke up from sleep.";
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            seccReason = @"The output route was overridden by the app.";
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            seccReason = @"The category of the session object changed.";
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            seccReason = @"The previous audio output path is no longer available.";
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            seccReason = @"A preferred new audio output path is now available.";
            break;
        case AVAudioSessionRouteChangeReasonUnknown:
        default:
            seccReason = @"The reason for the change is unknown.";
            break;
    }
    NSLog(@"handleRouteChange reason is %@", seccReason);
    
    AVAudioSessionPortDescription *input = [[session.currentRoute.inputs count] ? session.currentRoute.inputs : nil objectAtIndex:0];
    if (input.portType == AVAudioSessionPortHeadsetMic)
    {
        
    }
}

- (void)handleInterruption:(NSNotification *)notification
{
    NSInteger reason = 0;
    NSString *reasonStr = @"";
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification])
    {
        //Posted when an audio interruption occurs.
        reason = [[[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
        if (reason == AVAudioSessionInterruptionTypeBegan)
        {
            if (self.isRunning)
            {
                dispatch_sync(self.taskQueue, ^{
                    NSLog(@"MicrophoneSource: stopRunning");
                    AudioOutputUnitStop(self.componentInstance);
                });
            }
        }
        
        if (reason == AVAudioSessionInterruptionTypeEnded)
        {
            reasonStr = @"AVAudioSessionInterruptionTypeEnded";
            NSNumber *seccondReason = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
            switch ([seccondReason integerValue])
            {
                case AVAudioSessionInterruptionOptionShouldResume:
                    if (self.isRunning) {
                        dispatch_async(self.taskQueue, ^{
                            NSLog(@"MicrophoneSource: startRunning");
                            AudioOutputUnitStart(self.componentInstance);
                        });
                    }
                    // Indicates that the audio session is active and immediately ready to be used. Your app can resume the audio operation that was interrupted.
                    break;
                default:
                    break;
            }
        }
        
    }
    ;
    NSLog(@"handleInterruption: %@ reason %@", [notification name], reasonStr);
}

#pragma mark - Private

- (void)handleAudioComponentCreationFailure
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MSPAudioComponentFailedToCreateNotification object:nil];
    });
}
@end
