//
//  LEFSwallowDef.h
//  LEFPatch
//
//  Created by wsy on 2018/7/7.
//  Copyright © 2018年 WSY. All rights reserved.
//

#ifndef LEFSwallowDef_h
#define LEFSwallowDef_h

typedef void(^LEFSwallowExceptionBlock)(NSString *msg);

typedef NS_ENUM(NSInteger, LEFSwallowMethodArgumentType) {
    LEFSwallowMethodArgumentTypeUnknown             = 0,
    LEFSwallowMethodArgumentTypeChar,
    LEFSwallowMethodArgumentTypeInt,
    LEFSwallowMethodArgumentTypeShort,
    LEFSwallowMethodArgumentTypeLong,
    LEFSwallowMethodArgumentTypeLongLong,
    LEFSwallowMethodArgumentTypeUnsignedChar,
    LEFSwallowMethodArgumentTypeUnsignedInt,
    LEFSwallowMethodArgumentTypeUnsignedShort,
    LEFSwallowMethodArgumentTypeUnsignedLong,
    LEFSwallowMethodArgumentTypeUnsignedLongLong,
    LEFSwallowMethodArgumentTypeFloat,
    LEFSwallowMethodArgumentTypeDouble,
    LEFSwallowMethodArgumentTypeBool,
    LEFSwallowMethodArgumentTypeVoid,
    LEFSwallowMethodArgumentTypeCharacterString,
    LEFSwallowMethodArgumentTypeCGPoint,
    LEFSwallowMethodArgumentTypeCGSize,
    LEFSwallowMethodArgumentTypeCGRect,
    LEFSwallowMethodArgumentTypeUIEdgeInsets,
    LEFSwallowMethodArgumentTypeObject,
    LEFSwallowMethodArgumentTypeClass,
    LEFSwallowMethodArgumentTypeSEL,
    LEFSwallowMethodArgumentTypeIMP,
    LEFSwallowMethodArgumentTypeNSRange,
};

static NSLock              *_JSMethodSignatureLock;
static NSRecursiveLock     *_JSMethodForwardCallLock;
static NSMutableDictionary *_currInvokeSuperClsName;
static BOOL _autoConvert;
static BOOL _convertOCNumberTOString;



#endif /* LEFSwallowDef_h */
