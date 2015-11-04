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

#import "NSFileManager+Additions.h"

@implementation NSFileManager (TempFile)

#pragma mark - File/folder size

- (UInt64)fileOrFolderSize:(NSString *)path {
    UInt64 size = 0;
    BOOL isDir;
    
    if (path == nil || ![self fileExistsAtPath:path isDirectory:&isDir]) {
        return size;
    }
    
    if (isDir) {
        NSDirectoryEnumerator *dirEnumerator = [self enumeratorAtPath:path];
        while ([dirEnumerator nextObject]) {
            if ([NSFileTypeRegular isEqualToString:[[dirEnumerator fileAttributes] fileType]]) {
                size += [[dirEnumerator fileAttributes] fileSize];
            }
        }
    } else {
        size = [[FILEMGR attributesOfItemAtPath:path error:nil] fileSize];
    }
    
    return size;
}

- (NSString *)fileOrFolderSizeAsHumanReadable:(NSString *)path {
    return [self sizeAsHumanReadable:[self fileOrFolderSize:path]];
}

- (NSString *)sizeAsHumanReadable:(UInt64)size {
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

#pragma mark -

- (BOOL)openPathInDefaultBrowser:(NSString *)path {
    NSURL *url = [NSURL URLWithString:@"http://"];
    CFURLRef fromPathURL = NULL;
    OSStatus err = LSGetApplicationForURL((CFURLRef)url, kLSRolesAll, NULL, &fromPathURL);
    NSString *app = nil;
    
    if (fromPathURL) {
        if (err == noErr) {
            app = [(NSURL *)fromPathURL path];
        }
        CFRelease(fromPathURL);
    }
    
    if (!app || err) {
        NSLog(@"Unable to find default browser");
        return FALSE;
    }
    
    [WORKSPACE openFile:path withApplication:app];
    return TRUE;
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
    [contentStr writeToFile:tempScriptPath atomically:YES encoding:textEncoding error:&err];
    
    // make sure writing it was successful
    if (err != nil || [[NSFileManager defaultManager] fileExistsAtPath:tempScriptPath] == FALSE) {
        NSLog(@"Could not create the temp file '%@'", tempScriptPath);
        return nil;
    }
    return tempScriptPath;
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
}






@end
