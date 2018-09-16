//
//  TeachSet.m
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/16.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "TeachSet.h"
#import "Member.h"

@interface TeachSet ()
@property (nonatomic, strong) NSMutableArray<Member *> *members;
@end


@implementation TeachSet

- (instancetype)initWithName:(NSString *)name members:(NSArray<Member *> *)members
{
    self = [super init];
    if (self) {
        _members = [members mutableCopy];
        _name = name;
    }
    return self;
}

+ (TeachSet *)teachSet
{
    TeachSet *teach = [[TeachSet alloc] initWithName:@"TeachSet" members:@[]];
    return teach;
}

- (BOOL)addMember:(Member *)member
{
    if (member) {
        [self.members addObject:member];
        return YES;
    }
    return NO;
}

- (NSArray<Member *> *)currentMembers
{
    return [self.members copy];
}

+ (BOOL)maxMemberCount
{
    return 10;
}

- (NSString *)info
{
    return @"关注知识小集公众号";
}

@end
