//
//  LEFSwallowWrap.h
//  LEFPatch
//
//  Created by wsy on 2018/7/10.
//  Copyright © 2018年 WSY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LEFSwallowWrap : NSObject

@property (nonatomic) id obj;
@property (nonatomic) void *pointer;
@property (nonatomic) Class cls;
@property (nonatomic, weak) id weakObj;
@property (nonatomic, assign) id assignObj;

- (id)unwrap;
- (void *)unwrapPointer;
- (Class)unwrapClass;

+ (LEFSwallowWrap *)wrapObj:(id)obj;
+ (LEFSwallowWrap *)wrapPointer:(void *)obj;
+ (LEFSwallowWrap *)wrapCls:(Class)obj;
+ (LEFSwallowWrap *)wrapWaakObj:(id)obj;
+ (LEFSwallowWrap *)wrapAssignObj:(id)obj;

@end
