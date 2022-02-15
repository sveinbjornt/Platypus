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


// all the information required to create a Platypus application.

#import <Cocoa/Cocoa.h>
#import "MutableDictProxy.h"

// PlatypusAppSpec is a dictionary proxy class containing all data needed to create app.
// The class behaves like a dict since it inherits from MutableDictProxy object and
// can therefore be subscripted using modern Objective-C syntax, e.g. spec[@"key"]
@interface PlatypusAppSpec : MutableDictProxy

@property (nonatomic, readonly, strong) NSString *error;
@property (nonatomic) BOOL silentMode;

- (PlatypusAppSpec *)initWithDefaults;
- (PlatypusAppSpec *)initWithDefaultsForScript:(NSString *)scriptPath;
- (PlatypusAppSpec *)initWithDictionary:(NSDictionary *)dict;
- (PlatypusAppSpec *)initWithProfile:(NSString *)filePath;

+ (PlatypusAppSpec *)specWithDefaults;
+ (PlatypusAppSpec *)specWithDictionary:(NSDictionary *)dict;
+ (PlatypusAppSpec *)specWithProfile:(NSString *)filePath;
+ (PlatypusAppSpec *)specWithDefaultsFromScript:(NSString *)scriptPath;

- (BOOL)create;
- (BOOL)verify;
- (void)dump;
- (void)writeToFile:(NSString *)filePath;

- (NSString *)commandStringUsingShortOpts:(BOOL)shortOpts;

+ (NSString *)bundleIdentifierForAppName:(NSString *)name
                              authorName:(NSString *)authorName
                           usingDefaults:(BOOL)def;

@end
