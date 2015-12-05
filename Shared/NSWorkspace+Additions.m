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

#import "NSWorkspace+Additions.h"
#import <sys/stat.h>
#import <sys/types.h>
#import <dirent.h>

@implementation NSWorkspace (Additions)

#pragma mark - File/folder size

//  Copyright (c) 2015 Nikolai Ruhe. All rights reserved.
//
// This method calculates the accumulated size of a directory on the volume in bytes.
//
// As there's no simple way to get this information from the file system it has to crawl the entire hierarchy,
// accumulating the overall sum on the way. The resulting value is roughly equivalent with the amount of bytes
// that would become available on the volume if the directory would be deleted.
//
// Caveat: There are a couple of oddities that are not taken into account (like symbolic links, meta data of
// directories, hard links, ...).

- (BOOL)getAllocatedSize:(unsigned long long *)size ofDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(size != NULL);
    NSParameterAssert(directoryURL != nil);
    
    // We'll sum up content size here:
    unsigned long long accumulatedSize = 0;
    
    // prefetching some properties during traversal will speed up things a bit.
    NSArray *prefetchedProperties = @[NSURLIsRegularFileKey,
                                      NSURLFileAllocatedSizeKey,
                                      NSURLTotalFileAllocatedSizeKey];
    
    // The error handler simply signals errors to outside code.
    __block BOOL errorDidOccur = NO;
    BOOL (^errorHandler)(NSURL *, NSError *) = ^(NSURL *url, NSError *localError) {
        if (error != NULL) {
            *error = localError;
        }
        errorDidOccur = YES;
        return NO;
    };
    
    // We have to enumerate all directory contents, including subdirectories.
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:directoryURL
                                                             includingPropertiesForKeys:prefetchedProperties
                                                                                options:(NSDirectoryEnumerationOptions)0
                                                                           errorHandler:errorHandler];
    
    // Start the traversal:
    for (NSURL *contentItemURL in enumerator) {
        
        // Bail out on errors from the errorHandler.
        if (errorDidOccur)
            return NO;
        
        // Get the type of this item, making sure we only sum up sizes of regular files.
        NSNumber *isRegularFile;
        if (! [contentItemURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:error])
            return NO;
        if (! [isRegularFile boolValue])
            continue; // Ignore anything except regular files.
        
        // To get the file's size we first try the most comprehensive value in terms of what the file may use on disk.
        // This includes metadata, compression (on file system level) and block size.
        NSNumber *fileSize;
        if (! [contentItemURL getResourceValue:&fileSize forKey:NSURLTotalFileAllocatedSizeKey error:error])
            return NO;
        
        // In case the value is unavailable we use the fallback value (excluding meta data and compression)
        // This value should always be available.
        if (fileSize == nil) {
            if (! [contentItemURL getResourceValue:&fileSize forKey:NSURLFileAllocatedSizeKey error:error])
                return NO;
            
            NSAssert(fileSize != nil, @"huh? NSURLFileAllocatedSizeKey should always return a value");
        }
        
        // We're good, add up the value.
        accumulatedSize += [fileSize unsignedLongLongValue];
    }
    
    // Bail out on errors from the errorHandler.
    if (errorDidOccur)
        return NO;
    
    // We finally got it.
    *size = accumulatedSize;
    return YES;
}

- (unsigned long long)nrCalculateFolderSize:(NSString *)folderPath {
    unsigned long long size = 0;
    NSURL *url = [NSURL fileURLWithPath:folderPath];
    [self getAllocatedSize:&size ofDirectoryAtURL:url error:nil];
    return size;
}

- (UInt64)fileOrFolderSize:(NSString *)path {
    NSString *fileOrFolderPath = [path copy];
#if !__has_feature(objc_arc)
    [fileOrFolderPath autorelease];
#endif
    
    BOOL isDir;
    if (path == nil || ![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
        return 0;
    }
    
    // resolve if symlink
    NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:fileOrFolderPath error:nil];
    if (fileAttrs) {
        NSString *fileType = [fileAttrs fileType];
        if ([fileType isEqualToString:NSFileTypeSymbolicLink]) {
            NSError *err;
            fileOrFolderPath = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:fileOrFolderPath error:&err];
            if (fileOrFolderPath == nil) {
                NSLog(@"Error resolving symlink %@: %@", path, [err localizedDescription]);
                fileOrFolderPath = path;
            }
        }
    }
    
    UInt64 size = 0;
    if (isDir) {
        NSDirectoryEnumerator *dirEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:fileOrFolderPath];
        while ([dirEnumerator nextObject]) {
            if ([NSFileTypeRegular isEqualToString:[[dirEnumerator fileAttributes] fileType]]) {
                size += [[dirEnumerator fileAttributes] fileSize];
            }
        }
        size = [[NSWorkspace sharedWorkspace] nrCalculateFolderSize:fileOrFolderPath];
    } else {
        size = [[[NSFileManager defaultManager] attributesOfItemAtPath:fileOrFolderPath error:nil] fileSize];
    }
    
    return size;
}

- (NSString *)fileOrFolderSizeAsHumanReadable:(NSString *)path {
    return [self fileSizeAsHumanReadableString:[self fileOrFolderSize:path]];
}

- (NSString *)fileSizeAsHumanReadableString:(UInt64)size {
    NSString *str;
    
    if (size < 1024ULL) {
        str = [NSString stringWithFormat:@"%u bytes", (unsigned int)size];
    } else if (size < 1048576ULL) {
        str = [NSString stringWithFormat:@"%llu KB", (UInt64)size / 1024];
    } else if (size < 1073741824ULL) {
        str = [NSString stringWithFormat:@"%.1f MB", size / 1048576.0];
    } else {
        str = [NSString stringWithFormat:@"%.1f GB", size / 1073741824.0];
    }
    return str;
}

#pragma mark - Temp file

- (NSString *)createTempFileNamed:(NSString *)fileName withContents:(NSString *)contentStr usingTextEncoding:(NSStringEncoding)textEncoding {
    // This could be done by just writing to /tmp, but this method is more secure
    // and will result in the script file being created at a path that looks something
    // like this:  /var/folders/yV/yV8nyB47G-WRvC76fZ3Be++++TI/-Tmp-/
    // Kind of ugly, but it's the Apple-sanctioned secure way of doing things with temp files
    // Thanks to Matt Gallagher for this technique:
    // http://cocoawithlove.com/2009/07/temporary-files-and-folders-in-cocoa.html
    
    NSString *tmpFileNameTemplate = fileName ? fileName : @"tmp_file_nsfilemgr_osx.XXXXXX";
    NSString *tmpDir = NSTemporaryDirectory();
    if (!tmpDir) {
        return nil;
    }
    
    NSString *tempFileTemplate = [tmpDir stringByAppendingPathComponent:tmpFileNameTemplate];
    const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
    char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
    strcpy(tempFileNameCString, tempFileTemplateCString);
    
    // use mkstemp to expand template
    int fileDescriptor = mkstemp(tempFileNameCString);
    if (fileDescriptor == -1) {
        free(tempFileNameCString);
        NSLog(@"%@", [NSString stringWithFormat:@"Error %d in mkstemp()", errno]);
        close(fileDescriptor);
        return nil;
    }
    close(fileDescriptor);
    
    // create nsstring from the c-string temp path
    NSString *tempScriptPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
    free(tempFileNameCString);
    
    // write script to the temporary path
    NSError *err;
    BOOL success = [contentStr writeToFile:tempScriptPath atomically:YES encoding:textEncoding error:&err];
    
    // make sure writing it was successful
    if (!success || [[NSFileManager defaultManager] fileExistsAtPath:tempScriptPath] == FALSE) {
        NSLog(@"Erroring creating temp file '%@': %@", tempScriptPath, [err localizedDescription]);
        return nil;
    }
    return tempScriptPath;
}

- (NSString *)createTempFileNamed:(NSString *)fileName withContents:(NSString *)contentStr {
    return [self createTempFileNamed:fileName withContents:contentStr usingTextEncoding:NSUTF8StringEncoding];
}

- (NSString *)createTempFileWithContents:(NSString *)contentStr {
    return [self createTempFileNamed:nil withContents:contentStr usingTextEncoding:NSUTF8StringEncoding];
}

- (NSString *)createTempFileWithContents:(NSString *)contentStr usingTextEncoding:(NSStringEncoding)textEncoding {
    return [self createTempFileNamed:nil withContents:contentStr usingTextEncoding:textEncoding];
}

#pragma mark - Notify Finder

- (void)notifyFinderFileChangedAtPath:(NSString *)path {
    [[NSWorkspace sharedWorkspace] noteFileSystemChanged:path];
    NSString *source = [NSString stringWithFormat:@"tell application \"Finder\" to update item (POSIX file \"%@\")", path];
    
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:source];
    if (appleScript != nil) {
        [appleScript executeAndReturnError:nil];
    }
#if !__has_feature(objc_arc)
    [appleScript release];
#endif
}

#pragma mark - Services

- (void)flushServices {
    // This call used to refresh Services without user having to log out/in
    // but may not do anything any more. Anyway, we'll keep invoking it for now
    NSUpdateDynamicServices();

    // This does the real deal
    [NSTask launchedTaskWithLaunchPath:@"/System/Library/CoreServices/pbs"
                             arguments:@[@"-flush"]];
}

#pragma mark - Misc

- (BOOL)openPathInDefaultBrowser:(NSString *)path {
    NSURL *url = [NSURL URLWithString:@"http://"];
    CFURLRef fromPathURL = NULL;
    OSStatus err = LSGetApplicationForURL((__bridge CFURLRef)url, kLSRolesAll, NULL, &fromPathURL);
    NSString *app = nil;
    
    if (fromPathURL) {
        if (err == noErr) {
            app = [(__bridge NSURL *)fromPathURL path];
        }
        CFRelease(fromPathURL);
    }
    
    if (!app || err) {
        NSLog(@"Unable to find default browser");
        return FALSE;
    }
    
    [[NSWorkspace sharedWorkspace] openFile:path withApplication:app];
    return TRUE;
}

- (BOOL)runCommandInTerminal:(NSString *)cmd {
    
    NSString *osaCmd = [NSString stringWithFormat:@"tell application \"Terminal\"\n\tdo script \"%@\"\nactivate\nend tell", cmd];
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:osaCmd];
    id ret = [script executeAndReturnError:nil];
#if !__has_feature(objc_arc)
    [script release];
#endif
    return (ret != nil);
}

@end
