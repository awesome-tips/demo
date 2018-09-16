//
//  LEFSwallowJSCore.h
//  LEFPatch
//
//  Created by wsy on 2018/7/7.
//  Copyright © 2018年 WSY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LEFSwallowDef.h"

@class JSContext;

@interface LEFSwallowJSCore : NSObject

@property (nonatomic, strong, readonly) JSContext *context;

@property (nonatomic, copy) LEFSwallowExceptionBlock exception;

- (void)startJSCore;

- (void)excuteAtFilePath:(NSString *)filepath;
- (void)excuetAtMainBundleFileWithName:(NSString *)filename;

@end
