//
//  LEFSwallowWrap.m
//  LEFPatch
//
//  Created by wsy on 2018/7/10.
//  Copyright © 2018年 WSY. All rights reserved.
//

#import "LEFSwallowWrap.h"

@implementation LEFSwallowWrap

+ (LEFSwallowWrap *)wrapObj:(id)obj
{
    LEFSwallowWrap *wrap = [[LEFSwallowWrap alloc] init];
    wrap.obj = obj;
    return wrap;
}

+ (LEFSwallowWrap *)wrapPointer:(void *)obj
{
    LEFSwallowWrap *wrap = [[LEFSwallowWrap alloc] init];
    wrap.pointer = obj;
    return wrap;
}

+ (LEFSwallowWrap *)wrapCls:(Class)obj
{
    LEFSwallowWrap *wrap = [[LEFSwallowWrap alloc] init];
    wrap.cls = obj;
    return wrap;
}

+ (LEFSwallowWrap *)wrapWaakObj:(id)obj
{
    LEFSwallowWrap *wrap = [[LEFSwallowWrap alloc] init];
    wrap.weakObj = obj;
    return wrap;
}

+ (LEFSwallowWrap *)wrapAssignObj:(id)obj
{
    LEFSwallowWrap *wrap = [[LEFSwallowWrap alloc] init];
    wrap.assignObj = obj;
    return wrap;
}

- (id)unwrap
{
    if (self.obj) return self.obj;
    if (self.weakObj) return self.weakObj;
    if (self.assignObj) return self.assignObj;
    if (self.cls) return self.cls;
    return self;
}

- (void *)unwrapPointer
{
    return self.pointer;
}

- (Class)unwrapClass
{
    return self.cls;
}

- (NSString *)description {
    if (self.obj) return NSStringFromClass([self.obj class]);
    if (self.weakObj) return NSStringFromClass([self.weakObj class]);
    if (self.assignObj) return NSStringFromClass([self.assignObj class]);
    if (self.cls) return NSStringFromClass(self.cls);
    return NSStringFromClass([self class]);
}

@end
