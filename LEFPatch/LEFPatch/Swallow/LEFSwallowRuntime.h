//
//  LEFSwallowRuntime.h
//  LEFPatch
//
//  Created by wsy on 2018/7/7.
//  Copyright © 2018年 WSY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LEFSwallowDef.h"

@class JSValue;
@class JSContext;

@interface LEFSwallowRuntime : NSObject

@property (nonatomic, copy) LEFSwallowExceptionBlock exception;


- (NSDictionary *)defineClassWithDeclaration:(NSString *)declaration
                   instanceMethods:(JSValue *)instanceValue
                      classMethods:(JSValue *)classValue
                           context:(JSContext *)context;

+ (id)callSelectorWithClassName:(NSString *)className
                   selectorName:(NSString *)selectorName
                      arguments:(JSValue *)arguments
                       instance:(JSValue *)instance
                        isSuper:(BOOL)isSuper;

+ (LEFSwallowMethodArgumentType)argumentTypeWithEncode:(const char *)encode;

@end
