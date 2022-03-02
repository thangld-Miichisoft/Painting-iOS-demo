//
//  ObjcUtility.h
//  Photoruction
//
//  Created by Yuta Fujita on 2016/11/21.
//  Copyright © 2016年 jp.co.concores. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

@interface ObjcUtility : NSObject

+ (CIContext *)cicontextWithOptions:(NSDictionary<NSString *, id> *)options;
- (UIBezierPath *)bezierPath:(NSAttributedString *)attrString rect:(CGRect)rect;
- (UIBezierPath *)singleLineStringBezierPath:(NSString *)string fontSize:(CGFloat)fontSize;
- (UIBezierPath *)bezierPath:(NSAttributedString *)attrString;
- (UIBezierPath *)bezierPath:(NSAttributedString *)attrString maxSize:(CGSize)maxSize;
@end
