//
//  MSPBytesData.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSPBytesData : NSObject

+ (MSPBytesData *)dataWithNSData:(NSData *)data;

- (int8_t)getInt8;
- (int16_t)getInt16;
- (int32_t)getInt32;
- (int64_t)getInt64;
- (NSData *)getBytes:(NSUInteger)size;
- (NSString *)getString:(NSUInteger)size;
- (void)skip:(int)pos;
- (void)reset;
- (const void *)bytes;
- (NSUInteger)length;

@property (atomic, readonly) NSUInteger position;

@end
