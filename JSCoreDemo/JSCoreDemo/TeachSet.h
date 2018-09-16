//
//  TeachSet.h
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/16.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class Member;
@class TeachSet;

@protocol JSTeachSetExportProtocol<JSExport>
@property (nonatomic, copy) NSString *name;
+ (TeachSet *)teachSet;
- (void)initWithName:(NSString *)name
             members:(NSArray<Member *> *)members;
- (NSArray<Member *> *)currentMembers;
JSExportAs(add, -(BOOL)addMember:(Member *)member);
@end


NS_ASSUME_NONNULL_BEGIN


@interface TeachSet : NSObject<JSTeachSetExportProtocol>

@property (nonatomic, copy) NSString *name;

+ (TeachSet *)teachSet;
- (instancetype)initWithName:(NSString *)name
                     members:(NSArray<Member *> *)members;

- (BOOL)addMember:(Member *)member;
- (NSArray<Member *> *)currentMembers;
+ (BOOL)maxMemberCount;

@end

NS_ASSUME_NONNULL_END
