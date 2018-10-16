//
//  NSData+MSPBytes.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "NSData+MSPBytes.h"

@implementation NSData (MSPBytes)

int _msp_position = 0;

- (int64_t)msp_getInt64
{
    int64_t i = 0;
    NSRange range;
    range.length = 8;
    range.location = _msp_position;
    [self getBytes:(void *)&i range:range];
    _msp_position += range.length;
    return i;
}

- (int32_t)msp_getInt32
{
    int32_t i = 0;
    NSRange range;
    range.length = 4;
    range.location = _msp_position;
    [self getBytes:(void *)&i range:range];
    _msp_position += range.length;
    return CFSwapInt32HostToBig(i);
}

- (int16_t)msp_getInt16
{
    int16_t i = 0;
    NSRange range;
    range.length = 2;
    range.location = _msp_position;
    [self getBytes:(void *)&i range:range];
    _msp_position += range.length;
    return CFSwapInt16HostToBig(i);
}

- (int8_t)msp_getInt8
{
    int8_t i = 0;
    NSRange range;
    range.length = 1;
    range.location = _msp_position;
    [self getBytes:(void *)&i range:range];
    _msp_position += range.length;
    return i;
}

- (NSString *)msp_getString:(int)size
{
    NSRange range;
    range.length = size;
    range.location = _msp_position;
    char *buf = malloc(size + 1);
    [self getBytes:buf range:range];
    _msp_position += size;
    buf[size] = 0;
    NSString *str = [NSString stringWithUTF8String:buf];
    free(buf);
    return str;
}

- (NSData *)msp_getBytes:(int)size
{
    NSRange range;
    range.length = size;
    range.location = _msp_position;
    char *buf = malloc(size);
    [self getBytes:buf range:range];
    _msp_position += size;
    NSData *data = [NSData dataWithBytes:buf length:size];
    free(buf);
    return data;
}

- (void)msp_skip:(int)p
{
    _msp_position += p;
}

- (void)msp_resetPosition
{
    _msp_position = 0;
}

- (int)msp_position
{
    return _msp_position;
}

@end
