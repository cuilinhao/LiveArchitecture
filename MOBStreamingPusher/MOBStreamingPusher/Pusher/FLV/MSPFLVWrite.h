//
//  MSPFLVWrite.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MSPFLVBaseTag;
@class MSPFLVMetadata;

@interface MSPFLVWrite : NSObject

@property (nonatomic, readonly) NSMutableData *packet;

- (void)writeHeader;

- (void)writeTag:(MSPFLVBaseTag *)tag;

- (void)writeMetaTag:(MSPFLVMetadata *)metaTag;

- (void)writeVideoPacket:(NSData *)data timestamp:(unsigned long)timestamp
                keyFrame:(BOOL)keyFrame
     compositeTimeOffset:(int)compositeTimeOffset;

- (void)writeAudioPacket:(NSData *)data timestamp:(unsigned long)timestamp;

- (void)writeAudioDecoderConfRecord:(NSData *)decoderBytes;

- (void)writeVideoDecoderConfRecord:(NSData *)decoderBytes;

- (void)reset;

@end
