/*
 Copyright (c) 2003-2015, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
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

#import "Utils.h"
#import <CoreServices/CoreServices.h>
#import <ctype.h>

@implementation Utils

+ (NSString *)removeWhitespaceInString:(NSString *)str {
    str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    return str;
}

+ (BOOL)isTextFile:(NSString *)path {
    NSString *str = [NSString stringWithContentsOfFile:path encoding:[[DEFAULTS objectForKey:@"DefaultTextEncoding"] intValue] error:nil];
    return (str != nil);
}

+ (NSString *)ibtoolPath {
    NSString *ibtoolPath = nil;

    if ([[NSFileManager defaultManager] fileExistsAtPath:IBTOOL_PATH_2])
        ibtoolPath = IBTOOL_PATH_2;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:IBTOOL_PATH])
        ibtoolPath = IBTOOL_PATH;
    
    return [ibtoolPath autorelease];
}

+ (NSMutableArray *)splitOnCapitalLetters:(NSString *)str {
    if ([str length] < 2)
        return [NSMutableArray arrayWithObject:str];
    
    NSMutableArray *wrds = [NSMutableArray array];
    
    int start = 0;
    int i;
    for (i = 1; i < [str length]; i++) {
        unichar letter = [str characterAtIndex:i];
        if (isupper(letter) || i == [str length] - 1) {
            int len = i - start;
            NSRange range = NSMakeRange(start, len);
            [wrds addObject:[str substringWithRange:range]];
            start = i;
        }
    }
    
    return wrds;
}

+ (BOOL)setPermissions:(short)pp forFile:(NSString *)path {
    NSDictionary *attrDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithShort:pp] forKey:NSFilePosixPermissions];
    NSError *err;
    [[NSFileManager defaultManager] setAttributes:attrDict ofItemAtPath:path error:&err];
    
    return (err == nil);
}

+ (void)alert:(NSString *)message subText:(NSString *)subtext {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:message];
    [alert setInformativeText:subtext];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
    [alert release];
}

+ (void)fatalAlert:(NSString *)message subText:(NSString *)subtext {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:message];
    [alert setInformativeText:subtext];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert runModal];
    [alert release];
    [[NSApplication sharedApplication] terminate:self];
}

+ (void)sheetAlert:(NSString *)message subText:(NSString *)subtext forWindow:(NSWindow *)window {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:message];
    [alert setInformativeText:subtext];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:nil];
    [alert release];
}

+ (BOOL)proceedWarning:(NSString *)message subText:(NSString *)subtext withAction:(NSString *)action {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:action];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:message];
    [alert setInformativeText:subtext];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    BOOL ret = ([alert runModal] == NSAlertFirstButtonReturn) ? YES : NO;
    [alert release];
    return ret;
}

+ (UInt64)fileOrFolderSize:(NSString *)path {
    UInt64 size = 0;
    BOOL isDir;
    
    if (path == nil || ![FILEMGR fileExistsAtPath:path isDirectory:&isDir])
        return size;
    
    if (isDir) {
        NSDirectoryEnumerator *dirEnumerator = [FILEMGR enumeratorAtPath:path];
        while ([dirEnumerator nextObject]) {
            if ([NSFileTypeRegular isEqualToString:[[dirEnumerator fileAttributes] fileType]])
                size += [[dirEnumerator fileAttributes] fileSize];
        }
    }
    else
        size = [[FILEMGR attributesOfItemAtPath:path error:nil] fileSize];
    
    return size;
}

+ (NSString *)fileOrFolderSizeAsHumanReadable:(NSString *)path {
    return [self sizeAsHumanReadable:[self fileOrFolderSize:path]];
}

+ (NSString *)sizeAsHumanReadable:(UInt64)size {
    NSString *str;
    
    if (size < 1024ULL)
        str = [NSString stringWithFormat:@"%u bytes", (unsigned int)size];
    else if (size < 1048576ULL)
        str = [NSString stringWithFormat:@"%llu KB", (UInt64)size / 1024];
    else if (size < 1073741824ULL)
        str = [NSString stringWithFormat:@"%.1f MB", size / 1048576.0];
    else
        str = [NSString stringWithFormat:@"%.1f GB", size / 1073741824.0];
    
    return str;
}

+ (BOOL)openPathInDefaultBrowser:(NSString *)path {
    NSURL *url = [NSURL URLWithString:@"http://"];
    CFURLRef fromPathURL = NULL;
    OSStatus err = LSGetApplicationForURL((CFURLRef)url, kLSRolesAll, NULL, &fromPathURL);
    NSString *app = nil;
    
    if (err == noErr) {
        app = [(NSURL *)fromPathURL path];
        CFRelease(fromPathURL);
    }
    
    if (!app || err) {
        NSLog(@"Unable to find default browser");
        return FALSE;
    }
    
    [[NSWorkspace sharedWorkspace] openFile:path withApplication:app];
    return TRUE;
}

+ (NSString *)loadBundledTemplate:(NSString *)templateFileName usingDictionary:(NSDictionary *)dict {
    
    NSString *fullPath = [[NSBundle mainBundle] pathForResource:templateFileName ofType:nil];
    NSString *templateStr = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];
    if (!templateStr) {
        NSLog(@"Unable to read template %@", templateFileName);
        return nil;
    }
    
    for (NSString *key in dict) {
        NSString *placeholder = [NSString stringWithFormat:@"%%%%%@%%%%", key];
        templateStr = [templateStr stringByReplacingOccurrencesOfString:placeholder withString:[dict objectForKey:key]];
    }
    return templateStr;
}

// array with suffix of all image types supported by Cocoa
+ (NSArray *)imageFileSuffixes {
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
            nil];
}

@end
