//
//  NSMutableData+MSPAMF.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    MSPAMFDataTypeNumber          = 0x00,
    MSPAMFDataTypeBool            = 0x01,
    MSPAMFDataTypeString          = 0x02,
    MSPAMFDataTypeObject          = 0x03,
    MSPAMFDataTypeNull            = 0x05,
    MSPAMFDataTypeUndefined       = 0x06,
    MSPAMFDataTypeReference       = 0x07,
    MSPAMFDataTypeMixedArray      = 0x08,
    MSPAMFDataTypeObjectEnd       = 0x09,
    MSPAMFDataTypeArray           = 0x0a,
    MSPAMFDataTypeDate            = 0x0b,
    MSPAMFDataTypeLongString      = 0x0c,
    MSPAMFDataTypeUnsupported     = 0x0d,
} MSPAMFDataType;

typedef enum {
    MSPAMFValueFalse      = 0x00,
    MSPAMFValueTrue       = 0x01,
} MSPAMFBoolValue;


@interface NSMutableData (MSPAMF)

- (void)msp_writeAMFString:(NSString *)str;
- (void)msp_putAMFString:(NSString *)str;
- (void)msp_putAMFDouble:(double)d;
- (void)msp_putAMFBool:(BOOL)b;
- (void)msp_putParam:(NSString *)key d:(double)d;
- (void)msp_putParam:(NSString *)key str:(NSString *)str;
- (void)msp_putParam:(NSString *)key b:(BOOL)b;

@end
