//
//  UILabelExportProtocol.h
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/18.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#ifndef UILabelExportProtocol_h
#define UILabelExportProtocol_h

#import <JavaScriptCore/JavaScriptCore.h>

@protocol UILabelExportProtocol<JSExport>
@property (nullable, nonatomic, copy) NSString *text;
@end

#endif /* UILabelExportProtocol_h */
