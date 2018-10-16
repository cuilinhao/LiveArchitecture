//
//  MSPFLVHeader.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSPFLVHeader : NSObject

@property (nonatomic, assign) BOOL flagAudio;
@property (nonatomic, assign) BOOL flagVideo;
@property (nonatomic, assign) Byte version;

- (NSData *)output;

@end
