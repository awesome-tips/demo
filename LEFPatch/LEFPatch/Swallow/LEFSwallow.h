//
//  LEFSwallow.h
//  LEFPatch
//
//  Created by wsy on 2018/7/7.
//  Copyright © 2018年 WSY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LEFSwallowDef.h"
#import "LEFSwallowJSCore.h"

@interface LEFSwallow : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, copy) LEFSwallowExceptionBlock exception;
@property (nonatomic, strong, readonly) NSObject *nilObj;
@property (nonatomic, strong, readonly) NSObject *nullObj;


+ (LEFSwallowJSCore *)excuteCore;

@end
