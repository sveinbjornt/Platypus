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


#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface PlatypusUtility : NSObject
+ (NSString *)removeWhitespaceInString:(NSString *)str;
+ (BOOL)isTextFile:(NSString *)path;
+ (NSString *)ibtoolPath;
//+ (BOOL)runningSnowLeopardOrLater;
+ (BOOL)setPermissions:(short)pp forFile:(NSString *)path;
+ (void)alert:(NSString *)message subText:(NSString *)subtext;
+ (void)fatalAlert:(NSString *)message subText:(NSString *)subtext;
+ (BOOL)proceedWarning:(NSString *)message subText:(NSString *)subtext withAction:(NSString *)action;
+ (void)sheetAlert:(NSString *)message subText:(NSString *)subtext forWindow:(NSWindow *)window;
+ (UInt64)fileOrFolderSize:(NSString *)path;
+ (NSString *)sizeAsHumanReadable:(UInt64)size;
+ (NSString *)fileOrFolderSizeAsHumanReadable:(NSString *)path;
+ (BOOL)openInDefaultBrowser:(NSString *)path;
+ (NSString *)loadBundledTemplate:(NSString *)templateFileName usingDictionary:(NSDictionary *)dict;
+ (NSArray *)imageFileSuffixes;
@end
