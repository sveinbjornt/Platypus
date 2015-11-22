//
//  AppDelegate.m
//  MakeThumbnail
//
//  Created by Alex Zielenski on 4/7/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "AppDelegate.h"
#import "IconFamily.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	IconFamily *family = [IconFamily iconFamilyWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"appStore"]];
//	[family writeToFile:@"/Users/Alex/Desktop/appStore.icns"];
	
	IconFamily *cpy = [IconFamily iconFamily];
	
	[cpy setIconFamilyElement:kIconServices1024PixelDataARGB fromBitmapImageRep:[family bitmapImageRepWithAlphaForIconFamilyElement:kIconServices1024PixelDataARGB]];
	[cpy setIconFamilyElement:kIconServices512PixelDataARGB fromBitmapImageRep:[family bitmapImageRepWithAlphaForIconFamilyElement:kIconServices512PixelDataARGB]];
	[cpy setIconFamilyElement:kIconServices256PixelDataARGB fromBitmapImageRep:[family bitmapImageRepWithAlphaForIconFamilyElement:kIconServices256PixelDataARGB]];
	[cpy setIconFamilyElement:kIconServices128PixelDataARGB fromBitmapImageRep:[family bitmapImageRepWithAlphaForIconFamilyElement:kIconServices128PixelDataARGB]];	
	[cpy setIconFamilyElement:kIconServices48PixelDataARGB fromBitmapImageRep:[family bitmapImageRepWithAlphaForIconFamilyElement:kIconServices48PixelDataARGB]];	
	[cpy setIconFamilyElement:kIconServices32PixelDataARGB fromBitmapImageRep:[family bitmapImageRepWithAlphaForIconFamilyElement:kIconServices32PixelDataARGB]];	
	[cpy setIconFamilyElement:kIconServices16PixelDataARGB fromBitmapImageRep:[family bitmapImageRepWithAlphaForIconFamilyElement:kIconServices16PixelDataARGB]];	
	
	
//	[cpy writeToFile:@"/Users/Alex/Desktop/appStore2.icns"];
}

@end
