//
//  JSExcuteConsoleView.h
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/3.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JSExcuteConsoleView : UIView

@property (nonatomic, strong) UILabel *showLabel;
@property (nonatomic, strong) UITextView *errorTextView;

@property (nonatomic, copy) NSString *log;
@property (nonatomic, copy) NSString *errorlog;

- (void)addLog:(NSString *)log;

@end
