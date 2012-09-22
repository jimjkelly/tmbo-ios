//
//  UIColor+TMBOTheme.m
//  TMBO
//
//  Created by Scott Perry on 09/20/12.
//  Copyright (c) 2012 Scott Perry. All rights reserved.
//

#import "UIColor+TMBOTheme.h"

#define hex2float(x) ((CGFloat)(x)/(CGFloat)0xff)

@implementation UIColor (TMBOTheme)
+ (UIColor *)tableRowLightBackgroundColor;
{
    return [UIColor colorWithRed:hex2float(0xCC) green:hex2float(0xCC) blue:hex2float(0xFF) alpha:1.0];
}

+ (UIColor *)tableRowDarkBackgroundColor;
{
    return [UIColor colorWithRed:hex2float(0xBB) green:hex2float(0xBB) blue:hex2float(0xEE) alpha:1.0];
}

+ (UIColor *)defaultLinkColor;
{
    return [UIColor colorWithRed:hex2float(0x00) green:hex2float(0x00) blue:hex2float(0x99) alpha:1.0];
}

@end
