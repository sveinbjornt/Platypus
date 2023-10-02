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

#import "AGIconFamily.h"

size_t IFPixelSizeForElement(AGIconFamilyElement elementType);

size_t IFPixelSizeForElement(AGIconFamilyElement elementType)
{
	switch (elementType) {
		case AGIconFamilyElement512: return 512;
		case AGIconFamilyElement256: return 256;
		case AGIconFamilyElement128: return 128;
		case AGIconFamilyElement48:	 return  48;
		case AGIconFamilyElement32:	 return  32;
		case AGIconFamilyElement16:	 return  16;
	}
	return 0;
}

NSUInteger IFIndexOfElementInImageSource(CGImageSourceRef imageSourceRef, AGIconFamilyElement elementType);

NSUInteger IFIndexOfElementInImageSource(CGImageSourceRef imageSourceRef, AGIconFamilyElement elementType)
{
	size_t expectedWidth = IFPixelSizeForElement(elementType);
	if ((expectedWidth == 0) || !imageSourceRef) return NSNotFound;
	
	size_t imageCount = CGImageSourceGetCount(imageSourceRef);
	NSUInteger i;
	
	for (i = 0; i < imageCount; i++) {
		NSDictionary * props = [(NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSourceRef, i, nil) autorelease];
		size_t width  = [[props objectForKey:(id)kCGImagePropertyPixelWidth] integerValue];
		size_t depth  = [[props objectForKey:(id)kCGImagePropertyDepth] integerValue];
		
		if ((width == expectedWidth) && (depth == 8)) {
			return i;
		}
	}
	
	return NSNotFound;
}





@interface NSImage (BitmapImageRepCreator)
- (NSBitmapImageRep *)bitmapImageRepOfSize:(NSSize)bitmapSize imageInterpolation:(NSImageInterpolation)interpolation;
@end



@interface AGIconFamily (Private)
- (CGImageSourceRef)imageSource;
@end



@implementation AGIconFamily

+ (AGIconFamily *)iconFamily;
{
	return [[[AGIconFamily alloc] init] autorelease];
}

+ (AGIconFamily *)iconFamilyWithContentsOfURL:(NSURL *)url;
{
	return [[[AGIconFamily alloc] initWithContentsOfURL:url] autorelease];
}

+ (AGIconFamily *)iconFamilyWithThumbnailsOfImage:(NSImage *)image imageInterpolation:(NSImageInterpolation)imageInterpolation;
{
	return [[[AGIconFamily alloc] initWithThumbnailsOfImage:image imageInterpolation:imageInterpolation] autorelease];
}



- (id)initWithContentsOfURL:(NSURL *)url;
{
	if (self = [super init]) {
		
		mIconFamilyData = [[NSData alloc] initWithContentsOfURL:url options:0 error:nil];
		if (!mIconFamilyData) {
			[self release];
			return nil;
		}
		
	}
	
	return self;
}

- (id)initWithThumbnailsOfImage:(NSImage *)image imageInterpolation:(NSImageInterpolation)imageInterpolation;
{
	NSImage * imageCopy = [[image copy] autorelease];
	NSBitmapImageRep * bitmapRep = nil;
	
	
	// Start with a new, empty IconFamily.
	if (!(self = [self init])) {
		return nil;
	}
	
	// Add elements to it
	NSSize sizes[] = {{512, 512}, {256, 256}, {128, 128}, {48, 48}, {32, 32}, {16, 16}};
	AGIconFamilyElement elements[] = {kIconServices512PixelDataARGB, kIconServices256PixelDataARGB, kIconServices128PixelDataARGB,
						 kIconServices48PixelDataARGB,  kIconServices32PixelDataARGB,  kIconServices16PixelDataARGB};
	int i, numSizes = (sizeof(sizes) / sizeof(NSSize));
	
	for (i = 0; i < numSizes; i++) {
		[imageCopy setSize:sizes[i]];
		bitmapRep = [image bitmapImageRepOfSize:sizes[i] imageInterpolation:imageInterpolation];
		if (bitmapRep) {
			[self setBitmapImageRep:bitmapRep forElement:elements[i]];
		}
	}
	
	return self;
}



- (void)dealloc;
{
	[mIconFamilyData release];
	if (mImageSourceRef) CFRelease(mImageSourceRef);
	[super dealloc];
}





#pragma mark  
#pragma mark Image I/O

- (CGImageRef)CGImageForElement:(AGIconFamilyElement)elementType;
{
	NSUInteger sourceIndex = IFIndexOfElementInImageSource([self imageSource], elementType);
	return (CGImageRef)[(id)((sourceIndex == NSNotFound) ? NULL : CGImageSourceCreateImageAtIndex([self imageSource], sourceIndex, nil)) autorelease];
}



- (BOOL)setCGImage:(CGImageRef)imageRef forElement:(AGIconFamilyElement)elementType;
{
	size_t expectedWidth = IFPixelSizeForElement(elementType);
	size_t imageWidth = CGImageGetWidth(imageRef);
	if ((expectedWidth == 0) || (imageWidth != expectedWidth)) {
		return NO;
	}
	
	CGImageSourceRef imageSourceRef = [self imageSource];
	NSUInteger indexToBeReplaced = IFIndexOfElementInImageSource(imageSourceRef, elementType);
	size_t srcImageCount = (imageSourceRef ? CGImageSourceGetCount(imageSourceRef) : 0);
	size_t dstImageCount = (indexToBeReplaced == NSNotFound) ? srcImageCount + 1 : srcImageCount;
	NSUInteger i;
	
	// Create a destination
	NSMutableData * destData = [NSMutableData data];
	CGImageDestinationRef imageDestRef = CGImageDestinationCreateWithData((CFMutableDataRef)destData, kUTTypeAppleICNS, dstImageCount, nil);
	
	// Copy source images to the destination
	if (imageSourceRef) {
		for (i = 0; i < srcImageCount; i++) {
			if (i != indexToBeReplaced) {
				CGImageDestinationAddImageFromSource(imageDestRef, imageSourceRef, i, NULL);
			}
		}
	}
	
	// Add the new image
	CGImageDestinationAddImage(imageDestRef, imageRef, NULL);
	
	// Copy the destination data to the icon family
	CGImageDestinationFinalize(imageDestRef);
	CFRelease(imageDestRef);
	
	// Save the data
	[mIconFamilyData release];
	mIconFamilyData = [destData retain];
	
	// Clear the source -- it'll be recreated when needed
	if (mImageSourceRef) {
		CFRelease(mImageSourceRef);
		mImageSourceRef = NULL;
	}
	
	return YES;
}



- (NSImage *)imageWithAllElements;
{
	return [[[NSImage alloc] initWithData:mIconFamilyData] autorelease];
}


- (BOOL)setBitmapImageRep:(NSBitmapImageRep *)bitmapImageRep forElement:(AGIconFamilyElement)elementType;
{
	return [self setCGImage:[bitmapImageRep CGImage] forElement:elementType];
}


- (NSBitmapImageRep *)bitmapImageRepForElement:(AGIconFamilyElement)elementType;
{
	CGImageRef cgImage = [self CGImageForElement:elementType];
	return (cgImage ? [[[NSBitmapImageRep alloc] initWithCGImage:cgImage] autorelease] : NULL);
}





#pragma mark  
#pragma mark File I/O

- (BOOL)writeToURL:(NSURL *)url error:(NSError **)error;
{
	return [mIconFamilyData writeToURL:url options:NSAtomicWrite error:error];
}


- (BOOL)setAsCustomIconForURL:(NSURL *)url;
{
	return [[NSWorkspace sharedWorkspace] setIcon:[self imageWithAllElements] forFile:[url relativePath] options:0];
}


+ (BOOL)removeCustomIconFromURL:(NSURL *)url;
{
	return [[NSWorkspace sharedWorkspace] setIcon:nil forFile:[url relativePath] options:0];
}


@end





#pragma mark  
@implementation AGIconFamily (Private)

- (CGImageSourceRef)imageSource;
{
	if (!mImageSourceRef) {
		if (mIconFamilyData) {
			mImageSourceRef = CGImageSourceCreateWithData((CFDataRef)mIconFamilyData, nil);
		}
	}
	
	return mImageSourceRef;
}

@end





#pragma mark  
@implementation NSImage (BitmapImageRepCreator)

- (NSBitmapImageRep *)bitmapImageRepOfSize:(NSSize)bitmapSize imageInterpolation:(NSImageInterpolation)interpolation;
{
	NSSize size = [self size];
	size_t pixelsWide = (size_t)bitmapSize.width;
	size_t pixelsHigh = (size_t)bitmapSize.height;
	
	
	// Create the new bitmap image rep
	NSBitmapImageRep * newImageRep = [[[NSBitmapImageRep alloc]
		  initWithBitmapDataPlanes:NULL
						pixelsWide:pixelsWide
						pixelsHigh:pixelsHigh
					 bitsPerSample:8
				   samplesPerPixel:4
						  hasAlpha:YES
						  isPlanar:NO
					colorSpaceName:NSDeviceRGBColorSpace
					  bitmapFormat:NSAlphaFirstBitmapFormat
					   bytesPerRow:pixelsWide * 4
					  bitsPerPixel:32] autorelease];
	
	// Draw ourself into the new bitmap image rep to convert to its format
	[NSGraphicsContext saveGraphicsState];
		[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:newImageRep]];
		[[NSGraphicsContext currentContext] setShouldAntialias:YES];
		[[NSGraphicsContext currentContext] setImageInterpolation:interpolation];
		
		NSSize outSize = bitmapSize;
		
		if (size.width > size.height) {
			outSize.width  = bitmapSize.width;
			outSize.height = floor(bitmapSize.width * size.height / size.width + 0.5);
		} else if (size.width < size.height) {
			outSize.height = bitmapSize.height;
			outSize.width  = floor(bitmapSize.height * size.width / size.height + 0.5);
		}
		
		
		// Composite the working image into the icon bitmap, centered.
		NSRect targetRect = NSMakeRect( (bitmapSize.width  - outSize.width ) / 2.0,
										(bitmapSize.height - outSize.height) / 2.0,
										outSize.width, outSize.height);
		
    [self drawInRect:targetRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
	[NSGraphicsContext restoreGraphicsState];
	
	return newImageRep;
}

@end

