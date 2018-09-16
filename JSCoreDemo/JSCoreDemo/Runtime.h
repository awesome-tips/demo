//
//  Runtime.h
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/4/7.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Runtime : NSObject

@property (nonatomic, strong) NSInvocation *invocation;

- (void)invokeMethod;

@end
