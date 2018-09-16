//
//  Member.h
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/16.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class Member;
@protocol JSMemberExportProtocol<JSExport>
- (instancetype)initWithName:(NSString *)name
                         age:(NSInteger)age;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
+ (Member *)member;
@end

NS_ASSUME_NONNULL_BEGIN

@interface Member : NSObject<JSMemberExportProtocol>
- (instancetype)initWithName:(NSString *)name
                         age:(NSInteger)age;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;

+ (Member *)member;

@end

NS_ASSUME_NONNULL_END
