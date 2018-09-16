//
//  Person.m
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/4/5.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "Person.h"

@implementation Person

@synthesize sum = _sum;

- (NSInteger)add:(NSInteger)a andB:(NSInteger)b
{
    NSLog(@"js call add");
    return a+b;
}

- (void)setSum:(NSInteger)sum
{
    NSLog(@"js call sum: %@", @(sum));
    _sum = sum;
}

@end
