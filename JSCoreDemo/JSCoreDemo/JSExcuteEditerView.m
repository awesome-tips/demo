//
//  JSExcuteEditerView.m
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/3.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "JSExcuteEditerView.h"

@implementation JSExcuteEditerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self createView];
    }
    return self;
}

- (void)createView
{
    _textView = ({
        UITextView *view = [[UITextView alloc] initWithFrame:self.bounds];
        view.autocorrectionType = UITextAutocorrectionTypeNo;
        view.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [self addSubview:view];
        view;
    });
}

@end
