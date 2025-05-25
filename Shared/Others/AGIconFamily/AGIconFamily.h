//
//  AGIconFamily
//  
//  Created by Seth Willits
//  Copyright 2009 Araelium Group.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.
//
//  -------------------------------------------------------
//	Version:    1.0, 2009/09/28
//  Requires:   Mac OS X 10.5
//
//  The fundamental assumption of using this class is that
//  it is used in a modern 10.5+ context, where only 32-bit
//  icon data is used.
//	
//	Valid element types are:
//		AGIconFamilyElement512
//		AGIconFamilyElement256
//		AGIconFamilyElement128
//		AGIconFamilyElement48
//		AGIconFamilyElement32
//		AGIconFamilyElement16
//
//	The basis of this class uses CGImageSource/Destination
//	to read and write from icns files and IconFamily data,
//  instead of using the IconServices API because
//	  - IconServices is broken in 10.6 (maybe others) when
//	    dealing with 256 and 512 sized icons.
//    - IconServices is old, and this doesn't use it
//    - It's far less code
//

@import Cocoa;
@import Carbon;

enum {
	AGIconFamilyElement512	= kIconServices512PixelDataARGB,
	AGIconFamilyElement256	= kIconServices256PixelDataARGB,
	AGIconFamilyElement128	= kIconServices128PixelDataARGB,
	AGIconFamilyElement48	= kIconServices48PixelDataARGB,
	AGIconFamilyElement32	= kIconServices32PixelDataARGB,
	AGIconFamilyElement16	= kIconServices16PixelDataARGB
};
typedef OSType AGIconFamilyElement;



@interface AGIconFamily : NSObject
{
	NSData * mIconFamilyData;
	CGImageSourceRef mImageSourceRef;
}


// -------------------------------------------------------------------------------
//	Creation
// -------------------------------------------------------------------------------

+ (AGIconFamily *)iconFamily;
+ (AGIconFamily *)iconFamilyWithContentsOfURL:(NSURL *)url;
+ (AGIconFamily *)iconFamilyWithThumbnailsOfImage:(NSImage *)image imageInterpolation:(NSImageInterpolation)imageInterpolation;

- (id)initWithContentsOfURL:(NSURL *)url;

// Resizes the image to create each element
- (id)initWithThumbnailsOfImage:(NSImage *)image imageInterpolation:(NSImageInterpolation)imageInterpolation;



// -------------------------------------------------------------------------------
//	Image I/O
// -------------------------------------------------------------------------------

// Returns an image that contains the icon family's elements as its NSImageReps.
- (NSImage *)imageWithAllElements;

- (NSBitmapImageRep *)bitmapImageRepForElement:(AGIconFamilyElement)elementType;
- (BOOL)setBitmapImageRep:(NSBitmapImageRep *)bitmapImageRep forElement:(AGIconFamilyElement)elementType;

- (CGImageRef)CGImageForElement:(AGIconFamilyElement)elementType;
- (BOOL)setCGImage:(CGImageRef)imageRef forElement:(AGIconFamilyElement)elementType;



// -------------------------------------------------------------------------------
//	File I/O
// -------------------------------------------------------------------------------

- (BOOL)setAsCustomIconForURL:(NSURL *)url;
+ (BOOL)removeCustomIconFromURL:(NSURL *)url;

// Writes the icon family to an .icns file.
- (BOOL)writeToURL:(NSURL *)url error:(NSError **)error;

@end
