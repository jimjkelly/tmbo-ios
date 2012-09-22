//
//  UIColor+TMBOTheme.m
//  TMBO
//
//  Created by Scott Perry on 09/20/12.
//  Copyright © 2012 Scott Perry (http://numist.net)
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
