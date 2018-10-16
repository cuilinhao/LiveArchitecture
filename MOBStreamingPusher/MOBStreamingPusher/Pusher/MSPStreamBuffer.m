//
//  MSPStreamBuffer.m
//  MOBStreamingPusher
//
//  Created by wukexiu on 2018/9/21.
//  Copyright © 2018年 testDemo. All rights reserved.
//

#import "MSPStreamBuffer.h"
#import "NSMutableArray+MSPAdd.h"
#import "MSPVideoFrame.h"
#import "MSPAudioFrame.h"

static const NSUInteger defaultSortBufferMaxCount = 5;///< 排序10个内
static const NSUInteger defaultUpdateInterval = 1;///< 更新频率为1s
static const NSUInteger defaultCallBackInterval = 5;///< 5s计时一次
static const NSUInteger defaultSendBufferMaxCount = 600;///< 最大缓冲区为600

@interface MSPStreamBuffer ()
{
    dispatch_semaphore_t _lock;
}

@property (nonatomic, strong) NSMutableArray <MSPBaseFrame *> *list;
@property (nonatomic, strong) NSMutableArray <MSPBaseFrame *> *sortList;
@property (nonatomic, strong) NSMutableArray *thresholdList;

/** 处理buffer缓冲区情况 */
@property (nonatomic, assign) NSInteger currentInterval;
@property (nonatomic, assign) NSInteger callBackInterval;
@property (nonatomic, assign) NSInteger updateInterval;
@property (nonatomic, assign) BOOL startTimer;

@end

@implementation MSPStreamBuffer

- (instancetype)init
{
    if (self = [super init])
    {
        _lock = dispatch_semaphore_create(1);
        self.updateInterval = defaultUpdateInterval;
        self.callBackInterval = defaultCallBackInterval;
        self.maxCount = defaultSendBufferMaxCount;
        self.lastDropFrames = 0;
        self.startTimer = NO;
    }
    return self;
}

- (void)appendObject:(MSPBaseFrame *)frame
{
    if (!frame) return;
    if (!_startTimer)
    {
        _startTimer = YES;
        [self tick];
    }
    
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    if (self.sortList.count < defaultSortBufferMaxCount)
    {
        [self.sortList addObject:frame];
    }
    else
    {
        ///< 排序
        [self.sortList addObject:frame];
        [self.sortList sortUsingFunction:frameDataCompare context:nil];
        /// 丢帧
        [self removeExpireFrame];
        /// 添加至缓冲区
        MSPBaseFrame *firstFrame = [self.sortList lfPopFirstObject];
        
        if (firstFrame) [self.list addObject:firstFrame];
    }
    dispatch_semaphore_signal(_lock);
}

- (MSPBaseFrame *)popFirstObject
{
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    MSPBaseFrame *firstFrame = [self.list lfPopFirstObject];
    dispatch_semaphore_signal(_lock);
    return firstFrame;
}

- (void)removeAllObject
{
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [self.list removeAllObjects];
    dispatch_semaphore_signal(_lock);
}

- (void)removeExpireFrame
{
    if (self.list.count < self.maxCount) return;
    
    NSArray *pFrames = [self expirePFrames];///< 第一个P到第一个I之间的p帧
    self.lastDropFrames += [pFrames count];
    if (pFrames && pFrames.count > 0)
    {
        [self.list removeObjectsInArray:pFrames];
        return;
    }
    
    NSArray *iFrames = [self expireIFrames];///<  删除一个I帧（但一个I帧可能对应多个nal）
    self.lastDropFrames += [iFrames count];
    if (iFrames && iFrames.count > 0)
    {
        [self.list removeObjectsInArray:iFrames];
        return;
    }
    
    [self.list removeAllObjects];
}

- (NSArray *)expirePFrames
{
    NSMutableArray *pframes = [[NSMutableArray alloc] init];
    for (NSInteger index = 0; index < self.list.count; index++)
    {
        MSPBaseFrame *frame = [self.list objectAtIndex:index];
        if ([frame isKindOfClass:[MSPVideoFrame class]])
        {
            MSPVideoFrame *videoFrame = (MSPVideoFrame *)frame;
            if (videoFrame.isKeyFrame && pframes.count > 0)
            {
                break;
            }
            else if (!videoFrame.isKeyFrame)
            {
                [pframes addObject:frame];
            }
        }
    }
    return pframes;
}

- (NSArray *)expireIFrames
{
    NSMutableArray *iframes = [[NSMutableArray alloc] init];
    uint64_t timeStamp = 0;
    for (NSInteger index = 0; index < self.list.count; index++)
    {
        MSPBaseFrame *frame = [self.list objectAtIndex:index];
        if ([frame isKindOfClass:[MSPVideoFrame class]] && ((MSPVideoFrame *)frame).isKeyFrame)
        {
            if (timeStamp != 0 && timeStamp != frame.timestamp) break;
            [iframes addObject:frame];
            timeStamp = frame.timestamp;
        }
    }
    return iframes;
}

NSInteger frameDataCompare(id obj1, id obj2, void *context)
{
    MSPBaseFrame *frame1 = (MSPBaseFrame *)obj1;
    MSPBaseFrame *frame2 = (MSPBaseFrame *)obj2;
    
    if (frame1.timestamp == frame2.timestamp)
        return NSOrderedSame;
    else if (frame1.timestamp > frame2.timestamp)
        return NSOrderedDescending;
    return NSOrderedAscending;
}

- (MSPStreamBuffferState)currentBufferState
{
    NSInteger currentCount = 0;
    NSInteger increaseCount = 0;
    NSInteger decreaseCount = 0;
    
    for (NSNumber *number in self.thresholdList)
    {
        if (number.integerValue > currentCount)
        {
            increaseCount++;
        }
        else
        {
            decreaseCount++;
        }
        currentCount = [number integerValue];
    }
    
    if (increaseCount >= self.callBackInterval)
    {
        return MSPStreamBuffferIncrease;
    }
    
    if (decreaseCount >= self.callBackInterval)
    {
        return MSPStreamBuffferDecline;
    }
    
    return MSPStreamBuffferUnknown;
}

#pragma mark -- Setter Getter
- (NSMutableArray *)list
{
    if (!_list)
    {
        _list = [[NSMutableArray alloc] init];
    }
    return _list;
}

- (NSMutableArray *)sortList
{
    if (!_sortList)
    {
        _sortList = [[NSMutableArray alloc] init];
    }
    return _sortList;
}

- (NSMutableArray *)thresholdList
{
    if (!_thresholdList)
    {
        _thresholdList = [[NSMutableArray alloc] init];
    }
    return _thresholdList;
}

#pragma mark -- 采样
- (void)tick
{
    /** 采样 3个阶段   如果网络都是好或者都是差给回调 */
    _currentInterval += self.updateInterval;
    
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [self.thresholdList addObject:@(self.list.count)];
    dispatch_semaphore_signal(_lock);
    
    if (self.currentInterval >= self.callBackInterval)
    {
        MSPStreamBuffferState state = [self currentBufferState];
        if (state == MSPStreamBuffferIncrease)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(streamBuffer:bufferState:)])
            {
                [self.delegate streamBuffer:self bufferState:MSPStreamBuffferIncrease];
            }
        } else if (state == MSPStreamBuffferDecline)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(streamBuffer:bufferState:)])
            {
                [self.delegate streamBuffer:self bufferState:MSPStreamBuffferDecline];
            }
        }
        
        self.currentInterval = 0;
        [self.thresholdList removeAllObjects];
    }
    __weak typeof(self) _self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.updateInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(_self) self = _self;
        [self tick];
    });
}

@end
