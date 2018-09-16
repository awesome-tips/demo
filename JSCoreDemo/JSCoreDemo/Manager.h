//
//  Manager.h
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/16.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "Member.h"
#import <JavaScriptCore/JavaScriptCore.h>

typedef NS_ENUM(NSUInteger, ManagerType) {
    ManagerTypeMin,
    ManagerTypeMid,
    ManagerTypeMax,
};

@protocol JSManagerExportProtocol<JSExport>
@property (nonatomic, assign) ManagerType type;
@end

NS_ASSUME_NONNULL_BEGIN

@interface Manager : Member

@property (nonatomic, assign) ManagerType type;

@end

NS_ASSUME_NONNULL_END
