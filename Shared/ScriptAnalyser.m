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

//
//  This is a class with convenience and analysis methods for the
//  script file types handled by Platypus.
//

#import "ScriptAnalyser.h"
#import "NSTask+Description.h"

@implementation ScriptAnalyser

+ (NSArray *)interpreters {
    return @[@"/bin/sh",
            @"/bin/bash",
            @"/bin/csh",
            @"/bin/tcsh",
            @"/bin/ksh",
            @"/bin/zsh",
            @"/usr/bin/env",
            @"/usr/bin/perl",
            @"/usr/bin/python",
            @"/usr/bin/ruby",
            @"/usr/bin/osascript",
            @"/usr/bin/tclsh",
            @"/usr/bin/expect",
            @"/usr/bin/php",
            @""];
}

+ (NSArray *)interpreterDisplayNames {
    return @[@"Shell",
            @"Bash",
            @"Csh",
            @"Tcsh",
            @"Ksh",
            @"Zsh",
            @"Env",
            @"Perl",
            @"Python",
            @"Ruby",
            @"AppleScript",
            @"Tcl",
            @"Expect",
            @"PHP",
            @"Other..."];
}

// a mapping between scripting languages and a simple hello world
// program implemented in said language

+ (NSDictionary *)interpreterHelloWorlds {
    return @{@"Shell": @"echo 'Hello, World'",
                                                @"Bash": @"echo 'Hello, World'",
                                                @"Csh": @"echo 'Hello, World'",
                                                @"Tcsh": @"echo 'Hello, World'",
                                                @"Ksh": @"echo 'Hello, World'",
                                                @"Zsh": @"echo 'Hello, World'",
                                                @"Env": @"",
                                                @"Perl": @"print \"Hello, World\\n\";",
                                                @"Python": @"print \"Hello, World\"",
                                                @"Ruby": @"puts \"Hello, World\";",
                                                @"AppleScript": @"",
                                                @"Tcl": @"puts \"Hello, World\";",
                                                @"Expect": @"send \"Hello, world\\n\"",
                                                @"PHP": @"<?php\necho \"Hello, World\";\n?>",
                                                @"Other...": @""};
}

+ (NSString *)helloWorldProgramForDisplayName:(NSString *)name {
    NSArray *displayNames = [ScriptAnalyser interpreterDisplayNames];
    int index = [displayNames indexOfObject:name];
    if (index == NSNotFound) {
        return @"";
    }
    NSDictionary *helloWorldDict = [ScriptAnalyser interpreterHelloWorlds];
    return helloWorldDict[name];
}

+ (NSString *)displayNameForInterpreter:(NSString *)theInterpreter {
    NSArray *interpreters = [ScriptAnalyser interpreters];
    NSArray *displayNames = [ScriptAnalyser interpreterDisplayNames];
    
    NSUInteger index = [interpreters indexOfObject:theInterpreter];
    if (index != NSNotFound) {
        return displayNames[index];
    }
    return @"Other...";
}

+ (NSString *)interpreterForDisplayName:(NSString *)name {
    NSArray *interpreterDisplayNames = [ScriptAnalyser interpreterDisplayNames];
    NSArray *interpreters = [ScriptAnalyser interpreters];

    NSUInteger index = [interpreterDisplayNames indexOfObject:name];
    if (index != NSNotFound) {
        return interpreters[index];
    }
    return @"";
}

#pragma mark -

+ (NSString *)interpreterForFileSuffix:(NSString *)fileName {
    NSArray *interpreters = [ScriptAnalyser interpreters];
    
    if ([fileName hasSuffix:@".sh"] || [fileName hasSuffix:@".command"]) {
        return interpreters[0];
    } else if ([fileName hasSuffix:@".bash"]) {
        return interpreters[1];
    } else if ([fileName hasSuffix:@".csh"]) {
        return interpreters[2];
    } else if ([fileName hasSuffix:@".tcsh"]) {
        return interpreters[3];
    } else if ([fileName hasSuffix:@".ksh"]) {
        return interpreters[4];
    } else if ([fileName hasSuffix:@".zsh"]) {
        return interpreters[5];
    } else if ([fileName hasSuffix:@".pl"] || [fileName hasSuffix:@".perl"] || [fileName hasSuffix:@".pm"]) {
        return interpreters[6];
    } else if ([fileName hasSuffix:@".py"] || [fileName hasSuffix:@".python"] || [fileName hasSuffix:@".objpy"]) {
        return interpreters[7];
    } else if ([fileName hasSuffix:@".rb"] || [fileName hasSuffix:@".rbx"] || [fileName hasSuffix:@".ruby"] | [fileName hasSuffix:@".rbw"]) {
        return interpreters[8];
    } else if ([fileName hasSuffix:@".scpt"] || [fileName hasSuffix:@".applescript"] || [fileName hasSuffix:@".osascript"]) {
        return interpreters[9];
    } else if ([fileName hasSuffix:@".tcl"] || [fileName hasSuffix:@".tcsh"]) {
        return interpreters[10];
    } else if ([fileName hasSuffix:@".exp"] || [fileName hasSuffix:@".expect"]) {
        return interpreters[11];
    } else if ([fileName hasSuffix:@".php"] || [fileName hasSuffix:@".php4"] || [fileName hasSuffix:@".php5"] ||
             [fileName hasSuffix:@".php3"] || [fileName hasSuffix:@".hp3"] || [fileName hasSuffix:@".ph4"] || [fileName hasSuffix:@".phtml"]) {
        return interpreters[12];
    }
    return nil;
}

+ (NSArray *)parseInterpreterFromShebang:(NSString *)path {
    
    // get the first line of the script
    NSString *script = [NSString stringWithContentsOfFile:path encoding:DEFAULT_OUTPUT_TXT_ENCODING error:nil];
    NSArray *lines = [script componentsSeparatedByString:@"\n"];
    if ([lines count] == 0) {
        // empty file
        return @[@""];
    }
    NSString *firstLine = lines[0];

    // if shorter than 2 chars, it can't possibly be a shebang line
    if ([firstLine length] <= 2) {
        return @[@""];
    }
    
    // get first two characters of first line
    NSString *shebang = [firstLine substringToIndex:2];  // first two characters should be #!
    if (![shebang isEqualToString:@"#!"]) {
        return @[@""];
    }
    
    // get everything that follows after the #!
    // seperate it by whitespaces, in order not to get also the params to the interpreter
    NSString *interpreterCmd = [firstLine substringFromIndex:2];
    NSArray *words = [interpreterCmd componentsSeparatedByString:@" "];
    return ([[words retain] autorelease]); // return array w. interpreter + arguments for it
}

+ (NSString *)appNameFromScriptFilePath:(NSString *)path {
    NSString *name = [[path lastPathComponent] stringByDeletingPathExtension];
    
    // replace these common filename word separators w. spaces
    name = [name stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    name = [name stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    
    // iterate over each word, capitalize and append to app name
    NSArray *words = [name componentsSeparatedByString:@" "];
    NSString *appName = @"";
    for (int i = 0; i < [words count]; i++) {
        if (i != 0) {
            appName = [appName stringByAppendingString:@" "];
        }
        NSString *word = words[i];
        NSString *firstCharacter = [word substringWithRange:NSMakeRange(0,1)];
        if ([firstCharacter isEqualToString:[firstCharacter uppercaseString]] == FALSE) {
            word = [word capitalizedString];
        }
        appName = [appName stringByAppendingString:word];
    }
    
    return appName;
}

+ (NSString *)determineInterpreterForScriptFile:(NSString *)path {
    NSString *interpreter = [ScriptAnalyser parseInterpreterFromShebang:path][0];
    if (interpreter != nil && ![interpreter isEqualToString:@""]) {
        return interpreter;
    }
    return [ScriptAnalyser interpreterForFileSuffix:path];
}

+ (NSString *)checkSyntaxOfFile:(NSString *)scriptPath withInterpreter:(NSString *)suggestedInterpreter {
    NSTask *task;
    NSString *interpreter = suggestedInterpreter;
    NSPipe *outputPipe = [NSPipe pipe];
    NSFileHandle *readHandle;
    
    if (![FILEMGR fileExistsAtPath:scriptPath]) { //make sure it exists
        return @"File does not exist";
    }
    
    if (interpreter == nil || [interpreter isEqualToString:@""]) {
        interpreter = [ScriptAnalyser determineInterpreterForScriptFile:scriptPath];
    }
    
    if (interpreter == nil || [interpreter isEqualToString:@""]) {
        return @"Unable to determine script interpreter";
    }
    
    //let's see if the script type is supported for syntax checking
    //if so, we set up the task's launch path as the script interpreter and set the relevant flags and arguments
    NSArray *args = nil;
    
    if ([interpreter isEqualToString:@"/bin/sh"]) {
        args = @[@"-n", scriptPath];
    } else if ([interpreter isEqualToString:@"/bin/bash"]) {
        args = @[@"-n", scriptPath];
    } else if ([interpreter isEqualToString:@"/usr/bin/perl"]) {
        args = @[@"-c", scriptPath];
    } else if ([interpreter isEqualToString:@"/usr/bin/ruby"]) {
        args = @[@"-c", scriptPath];
    } else if ([interpreter isEqualToString:@"/usr/bin/php"]) {
        args = @[@"-l", scriptPath];
    } else if ([interpreter isEqualToString:@"/usr/bin/python"]) {
        args = @[@"-m", @"py_compile", scriptPath];
    } else {
        return [NSString stringWithFormat:@"Syntax Checking is not supported by interpreter %@", interpreter];
    }
    
    task = [[NSTask alloc] init];
    [task setLaunchPath:interpreter];
    [task setArguments:args];
    [task setStandardOutput:outputPipe];
    [task setStandardError:outputPipe];
    readHandle = [outputPipe fileHandleForReading];
    
    //launch task
    [task launch];
    [task waitUntilExit];
    
    //get output in string
    NSString *outputStr = [[[NSString alloc] initWithData:[readHandle readDataToEndOfFile] encoding:DEFAULT_OUTPUT_TXT_ENCODING] autorelease];
    
    //if the syntax report string is empty --> no complaints, so we report syntax as OK
    outputStr = [outputStr length] ? outputStr : @"Syntax OK";
    outputStr = [NSString stringWithFormat:@"%@\n\n%@", [task humanDescription], outputStr];
    
    [task release];

    return outputStr;
}

@end
