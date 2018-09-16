//
//  Member.m
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/16.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "Member.h"

@implementation Member

- (instancetype)initWithName:(NSString *)name
                         age:(NSInteger)age
{
    if (self = [super init]) {
        _name = name;
        _age = age;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"name: %@, age: %@", self.name, @(self.age)];
}

+ (Member *)member
{
    Member *aMember = [Member new];
    aMember.name = @"Lefe_x";
    aMember.age = 25;
    return aMember;
}

@end
