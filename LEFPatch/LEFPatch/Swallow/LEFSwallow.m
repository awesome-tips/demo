//
//  LEFSwallow.m
//  LEFPatch
//
//  Created by wsy on 2018/7/7.
//  Copyright © 2018年 WSY. All rights reserved.
//

#import "LEFSwallow.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface LEFSwallow()

@property (nonatomic, strong) LEFSwallowJSCore *jscore;
@property (nonatomic, strong) NSObject *nilObj;
@property (nonatomic, strong) NSObject *nullObj;

@end

@implementation LEFSwallow

+ (instancetype)shareInstance
{
    static LEFSwallow *_swallow = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _swallow = [[self alloc] init];
    });
    
    return _swallow;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _nilObj = [[NSObject alloc] init];
        _nullObj = [[NSObject alloc] init];
        
        _jscore = [[LEFSwallowJSCore alloc] init];
        _JSMethodSignatureLock = [[NSLock alloc] init];
        _JSMethodForwardCallLock = [[NSRecursiveLock alloc] init];
        _currInvokeSuperClsName = [[NSMutableDictionary alloc] init];
        __weak typeof(self) weakself = self;
        _jscore.exception = ^(NSString *msg) {
            if (weakself.exception) {
                weakself.exception(msg);
            }
        };
    }
    return self;
}

+ (LEFSwallowJSCore *)excuteCore
{
    return [LEFSwallow shareInstance].jscore;
}

@end
