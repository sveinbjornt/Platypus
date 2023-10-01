/*
    Copyright (c) 2003-2023, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
    All rights reserved.

    Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this
    list of conditions and the following disclaimer in the documentation and/or other
    materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may
    be used to endorse or promote products derived from this software without specific
    prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
    IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
    INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
    NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
    WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/

#import "NSColor+HexTools.h"

@implementation NSColor (HexTools)

+ (NSColor *)colorFromHexString:(NSString *)inColorString {
    NSString *charStr = [inColorString substringFromIndex:1];
    NSColor *result = NULL;
    unsigned int colorCode = 0;
    unsigned char redByte = 0;
    unsigned char greenByte = 0;
    unsigned char blueByte = 0;
    
    if (charStr != NULL) {
        NSScanner *scanner = [NSScanner scannerWithString:charStr];
        (void)[scanner scanHexInt:&colorCode]; // Ignore error
    }
    
    redByte = (unsigned char)(colorCode >> 16);
    greenByte = (unsigned char)(colorCode >> 8);
    blueByte = (unsigned char)(colorCode); // Masks off high bits
    
    result = [NSColor colorWithCalibratedRed:(float)redByte / 0xff
                                       green:(float)greenByte / 0xff
                                        blue:(float)blueByte / 0xff
                                       alpha:1.0];
    return result;
}

- (NSString *)hexString {
    CGFloat redFloatValue, greenFloatValue, blueFloatValue;
    int redIntValue, greenIntValue, blueIntValue;
    NSString *redHexValue, *greenHexValue, *blueHexValue;
    
    // Convert the NSColor to the RGB color space before we can access its components
    NSColor *convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    if (!convertedColor) {
        return nil;
    }
    
    // Get the red, green, and blue components of the color
    [convertedColor getRed:&redFloatValue green:&greenFloatValue blue:&blueFloatValue alpha:NULL];
    
    // Convert the components to numbers (unsigned decimal integer) between 0 and 255
    redIntValue = (int)(redFloatValue * 255.99999f);
    greenIntValue = (int)(greenFloatValue * 255.99999f);
    blueIntValue = (int)(blueFloatValue * 255.99999f);
    
    // Convert the numbers to hex strings
    redHexValue = [NSString stringWithFormat:@"%02x", redIntValue];
    greenHexValue = [NSString stringWithFormat:@"%02x", greenIntValue];
    blueHexValue = [NSString stringWithFormat:@"%02x", blueIntValue];
    
    // Concatenate the red, green, and blue components' hex strings together with a "#"
    return [NSString stringWithFormat:@"#%@%@%@", redHexValue, greenHexValue, blueHexValue];
}

@end
