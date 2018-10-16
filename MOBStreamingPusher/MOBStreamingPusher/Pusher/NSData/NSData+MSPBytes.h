//
//  NSData+MSPBytes.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (MSPBytes)

- (int8_t)msp_getInt8;
- (int16_t)msp_getInt16;
- (int32_t)msp_getInt32;
- (int64_t)msp_getInt64;
- (NSData *)msp_getBytes:(int)size;
- (NSString *)msp_getString:(int)size;
- (void)msp_skip:(int)pos;
- (int)msp_position;
- (void)msp_resetPosition;

@end
