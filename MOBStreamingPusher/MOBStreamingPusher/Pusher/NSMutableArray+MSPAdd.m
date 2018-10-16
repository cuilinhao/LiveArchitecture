//
//  NSMutableArray+MSPAdd.m
//  MOBStreamingPusher
//
//  Created by wukexiu on 2018/9/24.
//  Copyright © 2018年 testDemo. All rights reserved.
//

#import "NSMutableArray+MSPAdd.h"

@implementation NSMutableArray (MSPAdd)

- (void)lfRemoveFirstObject {
    if (self.count) {
        [self removeObjectAtIndex:0];
    }
}

- (id)lfPopFirstObject {
    id obj = nil;
    if (self.count) {
        obj = self.firstObject;
        [self lfRemoveFirstObject];
    }
    return obj;
}

@end
