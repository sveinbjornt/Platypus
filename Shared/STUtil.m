/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C) 2003-2010 Sveinbjorn Thordarson <sveinbjornt@gmail.com>

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
 
 A Swiss Army Knife class with a plethora of generic utility functions
 
 */
#import "STUtil.h"
#import <CoreServices/CoreServices.h>

@implementation STUtil

+ (BOOL)runningSnowLeopardOrLater
{
    SInt32 major = 0;
    SInt32 minor = 0;   
    
    Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);
    
    if ((major == 10 && minor >= 6) || major >= 11)
        return TRUE
        
    return FALSE
}

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
	
	if ([alert runModal] == NSAlertFirstButtonReturn) 
	{
		[alert release];
		return YES;
	}
	[alert release];
	return NO;
}

+ (UInt64) fileOrFolderSize: (NSString *)path
{
	UInt64			size = 0;
	NSFileManager	*manager = [NSFileManager defaultManager];
	BOOL			isDir;
	
	if (path == nil || ![manager fileExistsAtPath: path isDirectory: &isDir])
		return size;
	
	if (isDir)
	{
		NSDirectoryEnumerator	*dirEnumerator = [manager enumeratorAtPath: path];
		while ([dirEnumerator nextObject])
		{
			if ([NSFileTypeRegular isEqualToString:[[dirEnumerator fileAttributes] fileType]])
				size += [[dirEnumerator fileAttributes] fileSize];
		}
	}
	else
		size = [[manager fileAttributesAtPath: path traverseLink:YES] fileSize];
		
	return (UInt64)size;
}

+ (NSString *) fileOrFolderSizeAsHumanReadable: (NSString *)path
{
	return [self sizeAsHumanReadable: [self fileOrFolderSize: path]];
}

+ (NSString *) sizeAsHumanReadable: (UInt64)size
{
	NSString	*str;
	
	if( size < 1024ULL ) 
	{
		/* bytes */
		str = [NSString stringWithFormat:@"%u B", (unsigned int)size];
	} 
	else if( size < 1048576ULL) 
	{
		/* kbytes */
		str = [NSString stringWithFormat:@"%d KB", (long)size/1024];
	} 
	else if( size < 1073741824ULL ) 
	{
		/* megabytes */
		str = [NSString stringWithFormat:@"%.1f MB", size / 1048576.0];
	} 
	else 
	{
		/* gigabytes */
		str = [NSString stringWithFormat:@"%.1f GB", size / 1073741824.0];
	}
	return str;
}

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
			@"bmp",
			@"pcx",
			@"raw",
			@"pct",
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
			@"BMP",
			@"PCX",
			@"RAW",
			@"PCT",
			@"RSR",
			@"PXR",
			@"SCT",
			@"TGA", 
			NULL ];
}
@end
