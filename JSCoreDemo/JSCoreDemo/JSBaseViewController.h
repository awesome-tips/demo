//
//  JSBaseViewController.h
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/16.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>


NS_ASSUME_NONNULL_BEGIN

@interface JSBaseViewController : UIViewController

@property (nonatomic, strong) JSContext *context;

@end

NS_ASSUME_NONNULL_END
