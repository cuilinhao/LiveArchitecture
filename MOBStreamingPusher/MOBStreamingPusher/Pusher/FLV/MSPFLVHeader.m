//
//  MSPFLVHeader.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPFLVHeader.h"
#import "NSMutableData+MSPBytes.h"

// Signature
static const char *kMPSSignature = "FLV";

// FLV Version
static const Byte kMPSVersion = 0x01;

// Reserved flag, one
//static const Byte kMPSFlagReserved01 = 0x00;

// Reserved flag, one
//static const Byte kMPSFlagReserved02 = 0x00;

static const int kMPSFlvHeaderFlagHasAudio = 4;

static const int kMPSFlvHeaderFlagHasVideo = 1;

//static const Byte kMPSDataOffset = 0x00;

@implementation MSPFLVHeader

- (id)init
{
    if (self = [super init])
    {
        _version = kMPSVersion;
    }
    return self;
}

- (NSData *)output
{
    // flv header 9bytes，flv的类型、版本等信息,Signature(3bytes)+Version(1bytes)+Flags(1bytes)+DataOffset(4bytes)
    // first tag size 0 (占4bytes)
    // 9 + 4
    NSMutableData *buffer = [[NSMutableData alloc] initWithCapacity:13];
    // FLV
    [buffer appendBytes:kMPSSignature length:3];
    // Version
    [buffer msp_putInt8:_version];
    // flags
    [buffer msp_putInt8:(Byte)(kMPSFlvHeaderFlagHasAudio * (_flagAudio ? 1 : 0) + kMPSFlvHeaderFlagHasVideo * (_flagVideo ? 1 : 0))];
    // data offset
    [buffer msp_putInt32:9];
    // previous tag size 0 (this is the "first" tag)
    [buffer msp_putInt32:0];
    
    return buffer;
}

@end
