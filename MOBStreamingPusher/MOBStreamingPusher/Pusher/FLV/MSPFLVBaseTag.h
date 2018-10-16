//
//  MSPFLVBaseTag.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/18.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSPFLVBaseTag : NSObject

//// Tag type
//@property (nonatomic, assign) Byte type;

// Tag type data 
@property (nonatomic, assign) Byte typeData;

// Timestamp
@property (nonatomic, assign) unsigned long timestamp;

// Tag body size
@property (nonatomic, assign) int bodySize;

// Tag body as NSData
@property (nonatomic, retain) NSData *body;

// Previous tag size
@property (nonatomic, assign) int previuosTagSize;

// Bit flags
@property (nonatomic, assign) Byte bitflags;

@property (nonatomic, assign) int flagsSize;

@end
