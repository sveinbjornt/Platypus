/*
 Platypus - program for creating Mac OS X application wrappers around scripts
 Copyright (C) 2003-2012 Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 
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

/*
 
 A Swiss Army Knife class with a plethora of utility functions
 
 */
#import "PlatypusUtility.h"
#import <CoreServices/CoreServices.h>
#import <ctype.h>

@implementation PlatypusUtility

/*****************************************
 - //return the bundle identifier for the application to be generated
 -  based on username etc. e.g. org.username.AppName
 *****************************************/

+ (NSString *)standardBundleIdForAppName: (NSString *)name  usingDefaults: (BOOL)def;
{
    NSString *defaults = def ? [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultBundleIdentifierPrefix"] : @"";    
    
    NSString *pre = (!def || [defaults isEqualToString: @""]) ? [NSString stringWithFormat: @"org.%@.", NSUserName()] : defaults;
    
	NSString *bundleId = [NSString stringWithFormat: @"%@%@", pre , name];
	bundleId = [PlatypusUtility removeWhitespaceInString: bundleId];//no spaces
	
    return bundleId;
}

+ (NSString *)removeWhitespaceInString: (NSString *)str
{
    str = [str stringByReplacingOccurrencesOfString: @" " withString: @""];
    str = [str stringByReplacingOccurrencesOfString: @"\t" withString: @""];
    return str;
}

+ (BOOL)isTextFile: (NSString *)path
{
    NSString *str = [NSString stringWithContentsOfFile: path encoding: [[[NSUserDefaults standardUserDefaults] objectForKey: @"DefaultTextEncoding"] intValue] error: nil];
    return (str != nil);
}

//+ (NSMutableArray *)splitOnCapitalLetters: (NSString *)str
//{
//    if ([str length] < 2)
//        return [NSMutableArray arrayWithObject: str];
//    
//    NSMutableArray *wrds = [NSMutableArray array];
//    
//    int start = 0;
//    int i;
//    for (i = 1; i < [str length]; i++)
//    {
//        unichar letter = [str characterAtIndex: i];
//        if (isupper(letter) || i == [str length]-1)
//        {
//            int len = i - start;
//            NSRange range = NSMakeRange(start, len);
//            [wrds addObject: [str substringWithRange: range]];
//            start = i;
//        }
//    }
//    
//    return wrds;
//}

//+ (BOOL)runningSnowLeopardOrLater
//{
//    SInt32 major = 0;
//    SInt32 minor = 0;   
//    
//    Gestalt(gestaltSystemVersionMajor, &major);
//    Gestalt(gestaltSystemVersionMinor, &minor);
//    
//    if ((major == 10 && minor >= 6) || major > 10)
//        return TRUE;
//    
//    return FALSE;
//}

+ (void)alert: (NSString *)message subText: (NSString *)subtext
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText: message];
	[alert setInformativeText: subtext];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert runModal]; 
	[alert release];
}

+ (void)fatalAlert: (NSString *)message subText: (NSString *)subtext
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText: message];
	[alert setInformativeText: subtext];
	[alert setAlertStyle: NSCriticalAlertStyle];
	[alert runModal];
	[alert release];
	[[NSApplication sharedApplication] terminate: self];
}

+ (void)sheetAlert: (NSString *)message subText: (NSString *)subtext forWindow: (NSWindow *)window
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText: message];
	[alert setInformativeText: subtext];
	[alert setAlertStyle:NSCriticalAlertStyle];
	[alert beginSheetModalForWindow: window modalDelegate:self didEndSelector: nil contextInfo:nil];
	[alert release];
}

+ (BOOL) proceedWarning: (NSString *)message subText: (NSString *)subtext withAction: (NSString *)action
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle: action];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText: message];
	[alert setInformativeText: subtext];
	[alert setAlertStyle: NSWarningAlertStyle];
	
	BOOL ret = ([alert runModal] == NSAlertFirstButtonReturn) ? YES : NO; 
	[alert release];
	return ret;
}

+ (UInt64) fileOrFolderSize: (NSString *)path
{
	UInt64			size = 0;
	NSFileManager	*fmgr = [NSFileManager defaultManager];
	BOOL			isDir;
	
	if (path == nil || ![fmgr fileExistsAtPath: path isDirectory: &isDir])
		return size;
	
	if (isDir)
	{
		NSDirectoryEnumerator *dirEnumerator = [fmgr enumeratorAtPath: path];
		while ([dirEnumerator nextObject])
		{
			if ([NSFileTypeRegular isEqualToString:[[dirEnumerator fileAttributes] fileType]])
				size += [[dirEnumerator fileAttributes] fileSize];
		}
	}
	else
		size = [[fmgr fileAttributesAtPath: path traverseLink:YES] fileSize];
    
	return size;
}

+ (NSString *) fileOrFolderSizeAsHumanReadable: (NSString *)path
{
	return [self sizeAsHumanReadable: [self fileOrFolderSize: path]];
}

+ (NSString *) sizeAsHumanReadable: (UInt64)size
{
	NSString	*str;
	
	if (size < 1024ULL) 
		str = [NSString stringWithFormat:@"%u bytes", (unsigned int)size];
	else if (size < 1048576ULL) 
		str = [NSString stringWithFormat:@"%d KB", (long)size/1024];
	else if (size < 1073741824ULL) 
		str = [NSString stringWithFormat:@"%.1f MB", size / 1048576.0];
	else 
		str = [NSString stringWithFormat:@"%.1f GB", size / 1073741824.0];

	return str;
}

// array with suffix of all image types supported by Cocoa
+ (NSArray *)imageFileSuffixes
{
	return [NSArray arrayWithObjects: 
			@"icns",
			@"pdf",
			@"jpg",
			@"png",
			@"jpeg",
			@"gif",
			@"tif",
            @"tiff",
			@"bmp",
			@"pcx",
			@"raw",
			@"pct",
            @"pict",
			@"rsr",
			@"pxr",
			@"sct",
			@"tga",
			@"ICNS",
			@"PDF",
			@"JPG",
			@"PNG",
			@"JPEG",
			@"GIF",
			@"TIF",
            @"TIFF",
			@"BMP",
			@"PCX",
			@"RAW",
			@"PCT",
            @"PICT",
			@"RSR",
			@"PXR",
			@"SCT",
			@"TGA", 
			NULL ];
}
@end