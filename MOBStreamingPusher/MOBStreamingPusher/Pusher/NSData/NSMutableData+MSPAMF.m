//
//  NSMutableData+MSPAMF.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "NSMutableData+MSPAMF.h"
#import "NSMutableData+MSPBytes.h"

@implementation NSMutableData (MSPAMF)

- (void)msp_writeAMFString:(NSString *)str
{
    short length = [str length];
    [self msp_putInt16:length];
    [self appendBytes:[str cStringUsingEncoding:NSUTF8StringEncoding]
               length:length];
}

- (void)msp_putAMFString:(NSString *)str
{
    [self msp_putInt8:MSPAMFDataTypeString];
    [self msp_writeAMFString:str];
}

- (void)msp_putAMFDouble:(double)d
{
    [self msp_putInt8:MSPAMFDataTypeNumber];
    char output[8] = {0, };
    unsigned char *ci, *co;
    ci = (unsigned char *)&d;
    co = (unsigned char *)output;
    co[0] = ci[7];
    co[1] = ci[6];
    co[2] = ci[5];
    co[3] = ci[4];
    co[4] = ci[3];
    co[5] = ci[2];
    co[6] = ci[1];
    co[7] = ci[0];
    /*
     #if __FLOAT_WORD_ORDER == __BYTE_ORDER
     #if __BYTE_ORDER == __BIG_ENDIAN
     memcpy(output, &d, 8);
     #elif __BYTE_ORDER == __LITTLE_ENDIAN
     {
     unsigned char *ci, *co;
     ci = (unsigned char *)&d;
     co = (unsigned char *)output;
     co[0] = ci[7];
     co[1] = ci[6];
     co[2] = ci[5];
     co[3] = ci[4];
     co[4] = ci[3];
     co[5] = ci[2];
     co[6] = ci[1];
     co[7] = ci[0];
     }
     #endif
     #else
     #if __BYTE_ORDER == __LITTLE_ENDIAN
     {
     unsigned char *ci, *co;
     ci = (unsigned char *)&d;
     co = (unsigned char *)output;
     co[0] = ci[3];
     co[1] = ci[2];
     co[2] = ci[1];
     co[3] = ci[0];
     co[4] = ci[7];
     co[5] = ci[6];
     co[6] = ci[5];
     co[7] = ci[4];
     }
     #else
     {
     unsigned char *ci, *co;
     ci = (unsigned char *)&d;
     co = (unsigned char *)output;
     co[0] = ci[4];
     co[1] = ci[5];
     co[2] = ci[6];
     co[3] = ci[7];
     co[4] = ci[0];
     co[5] = ci[1];
     co[6] = ci[2];
     co[7] = ci[3];
     }
     #endif
     #endif
     */
    [self appendBytes:output length:8];
}

- (void)msp_putAMFBool:(BOOL)b
{
    [self msp_putInt8:MSPAMFDataTypeBool];
    [self msp_putInt8:b ? MSPAMFValueTrue : MSPAMFValueFalse];
}

- (void)msp_putParam:(NSString *)key d:(double)d
{
    [self msp_writeAMFString:key];
    [self msp_putAMFDouble:d];
}

- (void)msp_putParam:(NSString *)key str:(NSString *)str
{
    [self msp_writeAMFString:key];
    [self msp_putAMFString:str];
}

- (void)msp_putParam:(NSString *)key b:(BOOL)b
{
    [self msp_writeAMFString:key];
    [self msp_putAMFBool:b];
}

@end
