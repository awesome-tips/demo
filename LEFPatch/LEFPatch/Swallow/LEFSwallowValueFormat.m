//
//  LEFSwallowValueFormat.m
//  LEFPatch
//
//  Created by wsy on 2018/7/20.
//  Copyright © 2018年 WSY. All rights reserved.
//

#import "LEFSwallowValueFormat.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "LEFSwallowDef.h"
#import "LEFSwallowWrap.h"
#import "LEFSwallow.h"

@implementation LEFSwallowValueFormat

+ (id)formatJSToOC:(JSValue *)value
{
    id obj = [value toObject];
    // 如果是空，直接返回空对象
    if (!obj || [obj isKindOfClass:[NSNull class]]) {
        return [LEFSwallow shareInstance].nilObj;
    }
    
    // 如果是 LEFSwallowWrap 对象，返回被包裹的实例
    if ([obj isKindOfClass:[LEFSwallowWrap class]]) {
        LEFSwallowWrap *wrap = (LEFSwallowWrap *)obj;
        return [wrap unwrap];
    }
    
    // 如果是数组，递归每一个数组中的成员
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [[NSMutableArray alloc] init];
        for (int i = 0; i < [(NSArray *)obj count]; i++) {
            // 这里是 value[i] 不是 obj[i]
            [result addObject:[self formatJSToOC: value[i]]];
        }
        return result;
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *objDict = (NSDictionary *)obj;
        if (objDict[@"__obj"]) {
            id ocObj = [objDict objectForKey:@"__obj"];
            if ([ocObj isKindOfClass:[LEFSwallowWrap class]]) {
                LEFSwallowWrap *wrap = (LEFSwallowWrap *)ocObj;
                return [wrap unwrap];
            }
        } else if (objDict[@"__clsName"]) {
            return NSStringFromClass(objDict[@"__clsName"]);
        }
        
        if (objDict[@"__isBlock"]) {
            NSLog(@"TODO: ====================");
        }
        
        NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
        for (NSString *key in [objDict allKeys]) {
            [newDict setObject:[self formatJSToOC:value[key]] forKey:key];
        }
        return newDict;
    }
    return obj;
}

+ (id)formatOCToJSList:(NSArray *)list
{
    NSMutableArray *arr = [NSMutableArray array];
    for (id obj in list) {
        [arr addObject: [self formatOCToJS:obj]];
    }
    return arr;
}

+ (id)formatOCToJS:(id)obj
{
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDate class]]) {
        return _autoConvert ? obj : [self wrapObj:[LEFSwallowWrap wrapObj:obj]];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        // 是否自动把 NSNumber 类型转换成 string 类型
        return _convertOCNumberTOString ? [(NSNumber*)obj stringValue] : obj;
    }
    if ([obj isKindOfClass:NSClassFromString(@"NSBlock")] || [obj isKindOfClass:[JSValue class]]) {
        return obj;
    }
    return [self wrapObj:obj];
}

+ (NSDictionary *)wrapObj:(id)obj
{
    if (!obj || obj == [LEFSwallow shareInstance].nilObj) {
        return @{@"__isNil" : @(YES)};
    }
    return @{
             @"__obj" : obj,
             @"__clsName" : NSStringFromClass([obj isKindOfClass:[LEFSwallowWrap class]] ? [[(LEFSwallowWrap *)obj unwrap] class] : [obj class])
             };
}

+ (id)unBoxOCObejctToJS:(id)obj
{
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *newArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < [(NSArray *)obj count]; i++) {
            [newArr addObject:[self unBoxOCObejctToJS:obj[i]]];
        }
        return newArr;
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
        for (NSString *key in [obj allKeys]) {
            [newDict setObject:[self unBoxOCObejctToJS:obj[key]] forKey:key];
        }
        return newDict;
    }
    
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSDate class]] || [obj isKindOfClass:NSClassFromString(@"NSBlock")]) {
        return obj;
    }
    return [self wrapObj:obj];
}

@end
