/*
    Copyright (c) 2003-2021, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

#import "NSFileManager+TempFiles.h"

@implementation NSFileManager (TempFiles)

- (NSString *)createTempFileNamed:(NSString *)fileName withContents:(NSString *)contentStr usingTextEncoding:(NSStringEncoding)textEncoding {
    // This could be done by just writing to /tmp, but this method is more secure
    // and will result in the script file being created at a path that looks something
    // like this:  /var/folders/yV/yV8nyB47G-WRvC76fZ3Be++++TI/-Tmp-/
    // Kind of ugly, but it's the Apple-sanctioned secure way of doing things with temp files
    // Thanks to Matt Gallagher for this technique:
    // http://cocoawithlove.com/2009/07/temporary-files-and-folders-in-cocoa.html
    
    NSString *tmpFileNameTemplate = fileName ? fileName : @"tmp_file_platypus_macos.XXXXXX";
    NSString *tmpDir = NSTemporaryDirectory();
    if (!tmpDir) {
        NSLog(@"NSTemporaryDirectory() returned nil");
        return nil;
    }
    
    NSString *tempFileTemplate = [tmpDir stringByAppendingPathComponent:tmpFileNameTemplate];
    const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
    char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
    strcpy(tempFileNameCString, tempFileTemplateCString);
    
    // Use mkstemp to expand template
    int fileDescriptor = mkstemp(tempFileNameCString);
    if (fileDescriptor == -1) {
        free(tempFileNameCString);
        NSLog(@"Error %d in mkstemp()", errno);
        close(fileDescriptor);
        return nil;
    }
    close(fileDescriptor);
    
    // Create nsstring from the c-string temp path
    NSString *tempScriptPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
    free(tempFileNameCString);
    
    // Write script to the temporary path
    NSError *err;
    BOOL success = [contentStr writeToFile:tempScriptPath atomically:YES encoding:textEncoding error:&err];
    
    // Make sure writing it was successful
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

@end
