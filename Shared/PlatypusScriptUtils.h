/*
    Copyright (c) 2003-2022, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface PlatypusScriptUtils : NSObject

+ (NSArray <NSDictionary *> *)interpreters;
+ (NSArray <NSString *> *)interpreterDisplayNames;
+ (NSArray <NSString *> *)interpreterPaths;

+ (NSString *)helloWorldProgramForDisplayName:(NSString *)displayName;

+ (NSString *)displayNameForInterpreterPath:(NSString *)interpreterPath;
+ (NSString *)interpreterPathForDisplayName:(NSString *)displayName;

+ (NSArray <NSString *> *)interpreterArgsForInterpreterPath:(NSString *)path;
+ (NSArray <NSString *> *)scriptArgsForInterpreterPath:(NSString *)path;

+ (NSString *)interpreterPathForFilenameSuffix:(NSString *)fileName;
+ (NSString *)standardFilenameSuffixForInterpreterPath:(NSString *)interpreter;

+ (BOOL)isPotentiallyScriptAtPath:(NSString *)path;
+ (BOOL)hasShebangLineAtPath:(NSString *)path;

+ (NSArray <NSString *> *)parseInterpreterInScriptFile:(NSString *)scriptPath;
+ (NSString *)appNameFromScriptFile:(NSString *)scriptPath;

+ (NSString *)determineInterpreterPathForScriptFile:(NSString *)scriptPath;
+ (NSString *)checkSyntaxOfFile:(NSString *)scriptPath
         usingInterpreterAtPath:(NSString *)suggestedInterpreter;

@end
