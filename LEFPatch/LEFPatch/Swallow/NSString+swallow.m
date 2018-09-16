//
//  NSString+swallow.m
//  LEFPatch
//
//  Created by wsy on 2018/7/7.
//  Copyright © 2018年 WSY. All rights reserved.
//

#import "NSString+swallow.h"

@implementation NSString (swallow)

- (NSString *)trim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)toObjectCSelectorName
{
    NSString *tmpJSMethodName = [self stringByReplacingOccurrencesOfString:@"__" withString:@"-"];
    NSString *selectorName = [tmpJSMethodName stringByReplacingOccurrencesOfString:@"_" withString:@":"];
    return [selectorName stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
}


@end
