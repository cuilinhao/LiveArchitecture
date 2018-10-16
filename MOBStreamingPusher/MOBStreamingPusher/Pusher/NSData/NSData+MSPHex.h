//
//  NSData+MSPHex.h
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (MSPHex)

- (NSString *)msp_hexString;

- (NSString *)msp_hexString:(NSUInteger)size;

@end
