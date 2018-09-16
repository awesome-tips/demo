//
//  Runtime.m
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/4/7.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "Runtime.h"
#import <objc/runtime.h>

@implementation Runtime

+ (void)testResponseSe
{
    // 4 个有啥区别
    // 某个实例是否实现或继承了某个实例方法
    NSLog(@"== %@", @([self respondsToSelector:@selector(add:andB:)]));
    // 某个类是否实现或继承了某个类方法
    NSLog(@"== %@", @([self.class respondsToSelector:@selector(add:andB:)]));
    // 某个实例是否实现或继承了某个实例方法
    NSLog(@"== %@", @([self.class instancesRespondToSelector:@selector(add:andB:)]));
    // Error
    // [self instancesRespondToSelector:@selector(add:andB:)];
    
    /**
     if (![self respondsToSelector:selector] && ![self.class instancesRespondToSelector:selector]){
     }
     **/
}

- (int)add:(int)a andB:(int)b
{
    [self.class testResponseSe];
    NSLog(@"add a : %@, and b :%@", @(a), @(b));
    return a + b;
}

- (void)invokeMethod
{
    NSString *SELString = NSStringFromSelector(@selector(add:andB:));
    NSMethodSignature *signature = [self methodSignatureForSelector:NSSelectorFromString(SELString)];
    if (!signature) {
        NSLog(@"Method is not found");
        return;
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = self;
    invocation.selector = @selector(add:andB:);
    int arg1 = 3;
    int arg2 = 4;
    [invocation setArgument:&arg1 atIndex:2];
    [invocation setArgument:&arg2 atIndex:3];
    [invocation invoke];
    int result = 0;
    [invocation getReturnValue:&result];
    NSLog(@"reslut: %@", @(result));
}

@end
