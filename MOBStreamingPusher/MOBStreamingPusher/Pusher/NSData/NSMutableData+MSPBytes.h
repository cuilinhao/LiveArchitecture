//
//  NSMutableData+MSPBytes.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableData (MSPBytes)

- (void)msp_putInt8:(Byte)b;
- (void)msp_putInt16:(short)s;
- (void)msp_putInt24:(int)i;
- (void)msp_putInt32:(int)i;
- (void)msp_putInt64:(int64_t)i;

@end
