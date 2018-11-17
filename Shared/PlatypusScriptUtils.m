/*
 Copyright (c) 2003-2018, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

//  This is a class with convenience and analysis methods
//  for the script file types handled by Platypus.

#import "PlatypusScriptUtils.h"
//#import "NSTask+Description.h"

@implementation PlatypusScriptUtils

+ (NSArray <NSDictionary *> *)interpreters {
    return @[
             @{ @"Name":        @"Shell",
                @"Path":        @"/bin/sh",
                @"Hello":       @"echo 'Hello, World'",
                @"Suffixes":    @[@".sh", @".command"],
                @"SyntaxCheck": @[@"-n"] },
             
             @{ @"Name":        @"bash",
                @"Path":        @"/bin/bash",
                @"Hello":       @"echo 'Hello, World'",
                @"Suffixes":    @[@".bash"],
                @"SyntaxCheck": @[@"-n"] },

             @{ @"Name":        @"csh",
                @"Path":        @"/bin/csh",
                @"Hello":       @"echo 'Hello, World'",
                @"Suffixes":    @[@".csh"],
                @"SyntaxCheck": @[@"-n"] },

             @{ @"Name":        @"tcsh",
                @"Path":        @"/bin/tcsh",
                @"Hello":       @"echo 'Hello, World'",
                @"Suffixes":    @[@".tcsh"],
                @"SyntaxCheck": @[@"-n"] },

             @{ @"Name":        @"ksh",
                @"Path":        @"/bin/ksh",
                @"Hello":       @"echo 'Hello, World'",
                @"Suffixes":    @[@".ksh"],
                @"SyntaxCheck": @[@"-n"] },

             @{ @"Name":        @"zsh",
                @"Path":        @"/bin/zsh",
                @"Hello":       @"echo 'Hello, World'",
                @"Suffixes":    @[@".zsh"],
                @"SyntaxCheck": @[@"-n"] },

             @{ @"Name":        @"env",
                @"Path":        @"/usr/bin/env",
                @"Hello":       @"",
                @"Suffixes":    @[] },

             @{ @"Name":        @"Perl",
                @"Path":        @"/usr/bin/perl",
                @"Hello":       @"print \"Hello, World\\n\";",
                @"Suffixes":    @[@".pl", @".pm"],
                @"SyntaxCheck": @[@"-c"] },
             
             @{ @"Name":        @"Python",
                @"Path":        @"/usr/bin/python",
                @"Hello":       @"print \"Hello, World\"",
                @"Suffixes":    @[@".py", @".python", @".objpy"],
                @"SyntaxCheck": @[@"-m", @"py_compile"] },
             
             @{ @"Name":        @"Ruby",
                @"Path":        @"/usr/bin/ruby",
                @"Hello":       @"puts \"Hello, World\";",
                @"Suffixes":    @[@".rb", @".rbx", @".ruby", @".rbw"],
                @"SyntaxCheck": @[@"-c"] },
             
             @{ @"Name":        @"AppleScript",
                @"Path":        @"/usr/bin/osascript",
                @"Hello":       @"display dialog \"Hello, World\" buttons {\"OK\"}",
                @"Suffixes":    @[@".scpt", @".applescript", @".osascript"] },
             
             @{ @"Name":        @"Tcl",
                @"Path":        @"/usr/bin/tclsh",
                @"Hello":       @"puts \"Hello, World\";",
                @"Suffixes":    @[@".tcl"] },
             
             @{ @"Name":        @"Expect",
                @"Path":        @"/usr/bin/expect",
                @"Hello":       @"send \"Hello, World\\n\"",
                @"Suffixes":    @[@".exp", @".expect"] },
             
             @{ @"Name":        @"PHP",
                @"Path":        @"/usr/bin/php",
                @"Hello":       @"<?php\necho \"Hello, World\";\n?>",
                @"Suffixes":    @[@".php", @".php3", @".php4", @".php5", @".php6", @".phtml"],
                @"SyntaxCheck": @[@"-l"] },
             
             @{ @"Name":        @"Swift",
                @"Path":        @"/usr/bin/swift",
                @"Hello":       @"print(\"Hello, World\")",
                @"Suffixes":    @[@".swift"],
                @"SyntaxCheck": @[@"-parse"],
                @"SyntaxCheckBinary": @"/usr/bin/swiftc" },
             
             @{ @"Name":        @"AWK",
                @"Path":        @"/usr/bin/awk",
                @"Hello":       @"BEGIN { print \"Hello, World\" }",
                @"Suffixes":    @[@".awk"],
                @"Args":        @[@"-f"] },
             
             @{ @"Name":        @"JavaScript",
                @"Path":        @"/System/Library/Frameworks/JavaScriptCore.framework/Resources/jsc",
                @"Hello":       @"print(\"Hello, World\");",
                @"Suffixes":    @[@".js"],
                @"ScriptArgs":  @[@"--"] },
             
             @{ @"Name":        @"Other...",
                @"Path":        @"",
                @"Hello":       @"",
                @"Suffixes":    @[@""] }
    ];
}

#pragma mark -

+ (NSArray <NSString *> *)arrayOfInterpreterValuesForKey:(NSString *)key {
    NSArray *interpreters = [self interpreters];
    NSMutableArray *arr = [NSMutableArray array];
    for (NSDictionary *dict in interpreters) {
        [arr addObject:dict[key]];
    }
    return [arr copy];
}

+ (NSArray <NSString *> *)interpreterDisplayNames {
    return [self arrayOfInterpreterValuesForKey:@"Name"];
}

+ (NSArray <NSString *> *)interpreterPaths {
    return [self arrayOfInterpreterValuesForKey:@"Path"];
}

#pragma mark - Mapping

+ (NSString *)interpreterPathForDisplayName:(NSString *)displayName {
    NSArray <NSDictionary *> *interpreters = [self interpreters];
    for (NSDictionary *infoDict in interpreters) {
        if ([infoDict[@"Name"] isEqualToString:displayName]) {
            return infoDict[@"Path"];
        }
    }
    return @"";
}

+ (NSArray <NSString *> *)interpreterArgsForInterpreterPath:(NSString *)path {
    NSArray <NSDictionary *> *interpreters = [self interpreters];
    for (NSDictionary *infoDict in interpreters) {
        if ([infoDict[@"Path"] isEqualToString:path]) {
            return infoDict[@"Args"];
        }
    }
    return nil;
}

+ (NSArray <NSString *> *)scriptArgsForInterpreterPath:(NSString *)path {
    NSArray <NSDictionary *> *interpreters = [self interpreters];
    for (NSDictionary *infoDict in interpreters) {
        if ([infoDict[@"Path"] isEqualToString:path]) {
            return infoDict[@"ScriptArgs"];
        }
    }
    return nil;
}

+ (NSString *)displayNameForInterpreterPath:(NSString *)interpreterPath {
    NSArray <NSDictionary *> *interpreters = [self interpreters];
    for (NSDictionary *infoDict in interpreters) {
        if ([infoDict[@"Path"] isEqualToString:interpreterPath]) {
            return infoDict[@"Name"];
        }
    }
    return @"Other...";
}

+ (NSString *)helloWorldProgramForDisplayName:(NSString *)displayName {
    NSArray <NSDictionary *> *interpreters = [self interpreters];
    for (NSDictionary *infoDict in interpreters) {
        if ([infoDict[@"Name"] isEqualToString:displayName]) {
            return infoDict[@"Hello"];
        }
    }
    return @"";
}

#pragma mark - File suffixes

+ (NSString *)interpreterPathForFilenameSuffix:(NSString *)fileName {
    NSArray <NSDictionary *> *interpreters = [self interpreters];
    for (NSDictionary *infoDict in interpreters) {
        NSArray *suffixes = infoDict[@"Suffixes"];
        for (NSString *suffix in suffixes) {
            if ([fileName hasSuffix:suffix]) {
                return infoDict[@"Path"];
            }
        }
    }
    return @"";
}

+ (NSString *)standardFilenameSuffixForInterpreterPath:(NSString *)interpreterPath {
    NSArray <NSDictionary *> *interpreters = [self interpreters];
    for (NSDictionary *infoDict in interpreters) {
        if ([infoDict[@"Path"] isEqualToString:interpreterPath]) {
            return [infoDict[@"Suffixes"] firstObject];
        }
    }
    return @"";
}

#pragma mark - Script file convenience methods

+ (BOOL)isPotentiallyScriptAtPath:(NSString *)path {
    if ([FILEMGR isExecutableFileAtPath:path]) {
        return YES;
    }
    if ([WORKSPACE type:[WORKSPACE typeOfFile:path error:nil] conformsToType:(NSString *)kUTTypePlainText]) {
        return YES;
    }
    if ([PlatypusScriptUtils hasShebangLineAtPath:path]) {
        return YES;
    }
    return NO;
}

+ (BOOL)hasShebangLineAtPath:(NSString *)path {
    if (![FILEMGR isReadableFileAtPath:path]) {
        NSLog(@"Unable to read file %@", path);
        return NO;
    }
    
    FILE *file;
    unsigned char buf[2];
    file = fopen([path fileSystemRepresentation], "r");
    fread(buf, 1, 2, file);
    fclose(file);
    
    return (buf[0] == '#' && buf[1] == '!');
}

+ (NSArray <NSString *> *)parseInterpreterInScriptFile:(NSString *)path {
    
    // Get the first line of the script
    NSString *script = [NSString stringWithContentsOfFile:path encoding:DEFAULT_TEXT_ENCODING error:nil];
    NSArray *lines = [script componentsSeparatedByString:@"\n"];
    if ([lines count] == 0) {
        // Empty file
        return @[@""];
    }
    NSString *firstLine = lines[0];

    // If shorter than 2 chars, it can't possibly be a shebang line
    if ([firstLine length] <= 2 || ([[firstLine substringToIndex:2] isEqualToString:@"#!"] == NO)) {
        return @[@""];
    }
    
    NSString *interpreterCmd = [firstLine substringFromIndex:2];
    
    // Get everything that follows after the #!
    // Separate it by whitespaces, in order not to get also the params to the interpreter
    NSMutableArray *interpreterAndArgs = [[interpreterCmd componentsSeparatedByString:@" "] mutableCopy];
    
    // If shebang interpreter is not an absolute path or doestn't exist,
    // check if the binary name is the same as one of our preset interpreters
    NSString *parsedPath = interpreterAndArgs[0];
    if ([parsedPath hasPrefix:@"/"] == NO || [FILEMGR fileExistsAtPath:parsedPath] == NO) {
        NSArray *paths = [self interpreterPaths];
        for (NSString *p in paths) {
            if ([[p lastPathComponent] isEqualToString:[parsedPath lastPathComponent]]) {
                interpreterAndArgs[0] = p;
            }
        }
    }
    
    // Remove all empty strings in array
    for (NSInteger i = [interpreterAndArgs count]-1; i > 0; i--) {
        NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
        NSString *trimmedStr = [interpreterAndArgs[i] stringByTrimmingCharactersInSet:set];
        
        if ([trimmedStr isEqualToString:@""]) {
            [interpreterAndArgs removeObjectAtIndex:i];
        } else {
            interpreterAndArgs[i] = trimmedStr;
        }
    }
    // Array w. interpreter path + arguments
    return interpreterAndArgs;
}

+ (NSString *)appNameFromScriptFile:(NSString *)path {
    NSString *name = [[path lastPathComponent] stringByDeletingPathExtension];
    
    // Replace these common filename word separators w. spaces
    name = [name stringByReplacingOccurrencesOfString:@"-" withString:@" "]; // hyphen
    name = [name stringByReplacingOccurrencesOfString:@"_" withString:@" "]; // underscore
    
    // Remove leading and trailing whitespace/newlines
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // Iterate over each word, capitalize and append to app name
    NSArray *words = [name componentsSeparatedByString:@" "];
    NSMutableString *appName = [[NSMutableString alloc] initWithString:@""];
    
    for (NSString *word in words) {
        if ([word length] == 0) {
            continue;
        }
        NSString *capitalizedWord = [word stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                                  withString:[[word substringToIndex:1] capitalizedString]];
        if (word != words[0]) {
            [appName appendString:@" "];
        }
        [appName appendString:capitalizedWord];
    }
    
    return [NSString stringWithString:appName];
}

+ (NSString *)determineInterpreterPathForScriptFile:(NSString *)filePath {
    NSString *interpreterPath = [self parseInterpreterInScriptFile:filePath][0];
    if (interpreterPath != nil && [interpreterPath isEqualToString:@""] == NO) {
        return interpreterPath;
    }
    return [self interpreterPathForFilenameSuffix:filePath];
}

#pragma mark - Syntax checking

+ (NSString *)checkSyntaxOfFile:(NSString *)scriptPath usingInterpreterAtPath:(NSString *)suggestedInterpreter {
    if ([FILEMGR fileExistsAtPath:scriptPath] == NO) {
        return [NSString stringWithFormat:@"File does not exist"];
    }
    
    NSString *interpreterPath = suggestedInterpreter;
    
    if (interpreterPath == nil || [interpreterPath isEqualToString:@""]) {
        interpreterPath = [self determineInterpreterPathForScriptFile:scriptPath];
        
        if (interpreterPath == nil || [interpreterPath isEqualToString:@""]) {
            return @"Unable to determine script interpreter";
        }
    }
    
    //let's see if the script type is supported for syntax checking
    //if so, we set up the task's launch path as the script interpreter and set the relevant flags and arguments
    NSMutableArray *args = nil;
    NSArray *interpreters = [self interpreters];
    for (NSDictionary *dict in interpreters) {
        if ([dict[@"Path"] isEqualToString:interpreterPath] && dict[@"SyntaxCheck"]) {
            args = [NSMutableArray arrayWithArray:dict[@"SyntaxCheck"]];
            interpreterPath = dict[@"SyntaxCheckBinary"] ? dict[@"SyntaxCheckBinary"] : interpreterPath;
        }
    }
    if (args == nil) {
        return [NSString stringWithFormat:@"Syntax Checking is not supported for interpreter %@", interpreterPath];
    }
    [args addObject:scriptPath];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:interpreterPath];
    [task setArguments:args];
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    [task setStandardError:outputPipe];
    NSFileHandle *readHandle = [outputPipe fileHandleForReading];
    
    //launch task
    [task launch];
    [task waitUntilExit];
    
    //get output in string
    NSString *outputStr = [[NSString alloc] initWithData:[readHandle readDataToEndOfFile] encoding:DEFAULT_TEXT_ENCODING];

    //if the syntax report string is empty --> no complaints, so we report syntax as OK
    outputStr = [outputStr length] ? outputStr : @"Syntax OK";
    outputStr = [NSString stringWithFormat:@"%@", /*[task humanDescription],*/ outputStr];

    return outputStr;
}

@end
