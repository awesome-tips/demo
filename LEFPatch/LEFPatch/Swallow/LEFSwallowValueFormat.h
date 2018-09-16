//
//  LEFSwallowValueFormat.h
//  LEFPatch
//
//  Created by wsy on 2018/7/20.
//  Copyright © 2018年 WSY. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JSValue;

@interface LEFSwallowValueFormat : NSObject

+ (id)formatJSToOC:(JSValue *)value;

+ (id)formatOCToJS:(id)obj;

+ (NSDictionary *)wrapObj:(id)obj;

+ (id)formatOCToJSList:(NSArray *)list;

+ (id)unBoxOCObejctToJS:(id)obj;

@end
