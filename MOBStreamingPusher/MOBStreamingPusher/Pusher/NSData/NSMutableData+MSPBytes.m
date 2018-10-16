//
//  NSMutableData+MSPBytes.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "NSMutableData+MSPBytes.h"

@implementation NSMutableData (MSPBytes)

- (void)msp_putInt8:(Byte)b
{
    NSData *data = [NSData dataWithBytes:&b length:1];
    [self appendData:data];
    //  [self appendBytes:(const void *)&b length:1];
}

- (void)msp_putInt16:(short)s
{
    short fliped = CFSwapInt16HostToBig(s);
    // [self appendBytes:(const void *)&fliped length:2];
    NSData *data = [NSData dataWithBytes:&fliped length:2];
    [self appendData:data];
}

- (void)msp_putInt24:(int)i
{
    [self msp_putInt8:i >> 16];
    [self msp_putInt16:i & 0xffff];
}

- (void)msp_putInt32:(int)i
{
    int fliped = CFSwapInt32HostToBig(i);
    [self appendBytes:(const void *)&fliped length:4];
}

- (void)msp_putInt64:(int64_t)i
{
    [self msp_putInt32:i & 0xffffffff];
    [self msp_putInt32:i >> 32];
}

@end
