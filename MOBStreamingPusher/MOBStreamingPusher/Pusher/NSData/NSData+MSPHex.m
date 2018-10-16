//
//  NSData+MSPHex.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/20.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "NSData+MSPHex.h"

@implementation NSData (MSPHex)

- (NSString *)msp_hexString:(NSUInteger)size
{
    const unsigned char *buf = (const unsigned char *)[self bytes];
    if (!buf)
    {
        return [NSString string];
    }
    
    NSUInteger length = MIN([self length], size);
    NSMutableString *hexContainer = [NSMutableString stringWithString:@""];
    
    int i = 0;
    [hexContainer appendFormat:@"\n%08d:  ", 0];
    
    for ( ; i < length; ++i)
    {
        [hexContainer appendFormat:@"%02lx ", (unsigned long)buf[i]];
        if ((i + 1) % 16 == 0)
        {
            [hexContainer appendFormat:@"  "];
            
            // Display ascii mode
            for (int k = 0; k < 16; k++)
            {
                unsigned char c = buf[i - (15 - k)];
                if ((c >= 0x00 && c <= 0x0d) || c > 0x7f)
                {
                    c = '.';
                }
                
                [hexContainer appendFormat:@"%c", c];
            }
            
            [hexContainer appendFormat:@"\n%08lx:  ", (unsigned long)(i + 1)];
        }
        else if ((i + 1) % 8 == 0)
        {
            [hexContainer appendFormat:@" "];
        }
    }
    
    int leftOver = i % 16;
    if (leftOver > 0)
    {
        for (int j = 0; j < 16 - leftOver; ++j)
        {
            [hexContainer appendFormat:@"   "];
        }
        
        [hexContainer appendFormat:@"  "];
        
        // Display ascii mode
        for (int k = 0; k < leftOver; k++)
        {
            unsigned char c = buf[i - (leftOver - k)];
            if ((c >= 0x00 && c <= 0x0d) || c > 0x7f)
            {
                c = '.';
            }
            
            [hexContainer appendFormat:@"%c", c];
        }
        
        [hexContainer appendFormat:@"\n"];
    }
    
    return hexContainer;
}

- (NSString *)msp_hexString
{
    return [self msp_hexString:[self length]];
}

@end
