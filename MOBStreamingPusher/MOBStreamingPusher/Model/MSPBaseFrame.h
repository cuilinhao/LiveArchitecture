//
//  MSPBaseFrame.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/11.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSPBaseFrame : NSObject

@property (nonatomic, assign) uint64_t timestamp;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSData *header;

@end
