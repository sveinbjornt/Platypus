/*
 
 NSColor+HexTools - Functions for getting hex string from color and vice versa
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 
 */

#import "NSColor+HexTools.h"

@implementation NSColor (HexTools)
/*
 
 NSColor: Instantiate from Web-like Hex RRGGBB string
 Original Source: <http://cocoa.karelia.com/Foundation_Categories/NSColor__Instantiat.m>
 
 */

+ (NSColor *) colorFromHex:(NSString *) inColorString
{
	NSString *charStr		= [inColorString substringFromIndex: 1];
	NSColor *result			= NULL;
	unsigned int colorCode	= 0;
	unsigned char redByte	= 0;
	unsigned char greenByte = 0;
	unsigned char blueByte	= 0;
	
	if (charStr != NULL)
	{
		NSScanner *scanner = [NSScanner scannerWithString: charStr];
		(void) [scanner scanHexInt: &colorCode];	// ignore error
	}
	
	redByte		= (unsigned char) (colorCode >> 16);
	greenByte	= (unsigned char) (colorCode >> 8);
	blueByte	= (unsigned char) (colorCode);	// masks off high bits
	
	result = [NSColor
			  colorWithCalibratedRed:		(float)redByte	/ 0xff
			  green:						(float)greenByte/ 0xff
			  blue:							(float)blueByte	/ 0xff
			  alpha:						1.0];
	
	return result;
}

- (NSString *)hexString
{
	CGFloat		redFloatValue, greenFloatValue, blueFloatValue;
	int			redIntValue, greenIntValue, blueIntValue;
	NSString	*redHexValue, *greenHexValue, *blueHexValue;
	
	//Convert the NSColor to the RGB color space before we can access its components
	NSColor *convertedColor = [self colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	
	if(!convertedColor)
		return nil;
	
	// Get the red, green, and blue components of the color
	[convertedColor getRed: &redFloatValue green: &greenFloatValue blue: &blueFloatValue alpha: NULL];
		
	// Convert the components to numbers (unsigned decimal integer) between 0 and 255
	redIntValue = redFloatValue * 255.99999f;
	greenIntValue = greenFloatValue* 255.99999f;
	blueIntValue = blueFloatValue * 255.99999f;
		
	// Convert the numbers to hex strings
	redHexValue = [NSString stringWithFormat:@"%02x", redIntValue];
	greenHexValue = [NSString stringWithFormat:@"%02x", greenIntValue];
	blueHexValue = [NSString stringWithFormat:@"%02x", blueIntValue];
		
	// Concatenate the red, green, and blue components' hex strings together with a "#"
	return [NSString stringWithFormat:@"#%@%@%@", redHexValue, greenHexValue, blueHexValue];
}

@end
