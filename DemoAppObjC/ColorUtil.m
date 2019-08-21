//
//  ColorUtil.m
//  DemoAppObjC
//
//  Created by Travis Prescott on 8/14/19.
//  Copyright © 2019 Travis Prescott. All rights reserved.
//

#import "ColorUtil.h"

@implementation ColorUtil

+ (UIColor *)colorFromHexString:(NSString *)string {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+ (NSString *)hexStringFromColor:(UIColor *)color {
    CGFloat r, g, b, a;
    int ri, gi, bi;
    BOOL success = [color getRed:&r green:&g blue:&b alpha:&a];
    if (success) {
        ri = (int)(255.0 * r);
        gi = (int)(255.0 * g);
        bi = (int)(255.0 * b);
        return [NSString stringWithFormat:@"#%02x%02x%02x", ri, gi, bi];
    }
    return @"";
}

@end
