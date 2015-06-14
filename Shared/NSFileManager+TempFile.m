//
//  NSFileManager+TempFile.m
//  Platypus
//
//  Created by Sveinbjorn Thordarson on 14/06/15.
//  Copyright (c) 2015 Sveinbjorn Thordarson. All rights reserved.
//

#import "NSFileManager+TempFile.h"

@implementation NSFileManager (TempFile)

- (NSString *)createTempFileWithContents:(NSString *)contentStr usingTextEncoding:(NSStringEncoding)textEncoding {
    
    // This could be done by just writing to /tmp, but this method is more secure
    // and will result in the script file being created at a path that looks something
    // like this:  /var/folders/yV/yV8nyB47G-WRvC76fZ3Be++++TI/-Tmp-/
    // Kind of ugly, but it's the Apple-sanctioned secure way of doing things with temp files
    // Thanks to Matt Gallagher for this technique:
    // http://cocoawithlove.com/2009/07/temporary-files-and-folders-in-cocoa.html
    
    NSString *tmpScriptTemplate = @"tmp_file_nsfilemgr_osx.XXXXXX";
    
    NSString *tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:tmpScriptTemplate];
    const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
    char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
    strcpy(tempFileNameCString, tempFileTemplateCString);
    
    // use mkstemp to expand template
    int fileDescriptor = mkstemp(tempFileNameCString);
    if (fileDescriptor == -1) {
        NSLog(@"%@", [NSString stringWithFormat:@"Error %d in mkstemp()", errno]);
        close(fileDescriptor);
        return nil;
    }
    close(fileDescriptor);
    
    // create nsstring from the c-string temp path
    NSString *tempScriptPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
    free(tempFileNameCString);
    
    // write script to the temporary path
    [contentStr writeToFile:tempScriptPath atomically:YES encoding:textEncoding error:NULL];
    
    // make sure writing it was successful
    if (![[NSFileManager defaultManager] fileExistsAtPath:tempScriptPath]) {
        NSLog(@"%@", [NSString stringWithFormat:@"Could not create the temp file '%@'", tempScriptPath]);
        return nil;
    }
    return tempScriptPath;
}



@end
