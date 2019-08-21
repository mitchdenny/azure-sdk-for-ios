//
//  ColorUtil.h
//  DemoAppObjC
//
//  Created by Travis Prescott on 8/14/19.
//  Copyright © 2019 Travis Prescott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ColorUtil : NSObject

+ (UIColor *)colorFromHexString:(NSString *)string;
+ (NSString *)hexStringFromColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
