//
//  MSPGPUImageEmptyFilter.m
//  MOBStreamingPusher
//
//  Created by wukx on 2018/9/14.
//  Copyright © 2018年 Mob. All rights reserved.
//

#import "MSPGPUImageEmptyFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kMSPGPUImageEmptyFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main(){
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4((textureColor.rgb), textureColor.w);
 }
 
 );
#else
NSString *const kMSPGPUImageEmptyFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main(){
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4((textureColor.rgb), textureColor.w);
 }
 
 );
#endif

@implementation MSPGPUImageEmptyFilter


- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kMSPGPUImageEmptyFragmentShaderString])) {
        return nil;
    }
    
    return self;
}

@end
