//
//  Person.h
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/4/5.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol JSExportProtocol<JSExport>
@property (nonatomic, assign) NSInteger sum;
//- (NSInteger)add:(NSInteger)a andB:(NSInteger)b;
JSExportAs(addLefex, -(NSInteger)add:(NSInteger)a andB:(NSInteger)b);
@end

@interface Person : NSObject<JSExportProtocol>

@property (nonatomic, assign) NSInteger sum;
- (NSInteger)add:(NSInteger)a andB:(NSInteger)b;

@end
