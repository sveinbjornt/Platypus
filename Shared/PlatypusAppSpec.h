/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C) 2003-2013 Sveinbjorn Thordarson <sveinbjornt@gmail.com>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

*/

// PlatypusAppSpec is a wrapper class around an NSDictionary containing
// all the information / specifications for creating a Platypus application.

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "ScriptAnalyser.h"
#import "PlatypusUtility.h"

#define MAX_APPSPEC_PROPERTIES    255 // whatever...

@interface PlatypusAppSpec : NSObject 
{
    NSMutableDictionary     *properties;
    NSString                *error;
}
-(PlatypusAppSpec *)initWithDefaults;
-(PlatypusAppSpec *)initWithDefaultsFromScript: (NSString *)scriptPath;
-(PlatypusAppSpec *)initWithDictionary: (NSDictionary *)dict;
-(PlatypusAppSpec *)initWithProfile: (NSString *)filePath;
+(PlatypusAppSpec *)specWithDefaults;
+(PlatypusAppSpec *)specWithDictionary: (NSDictionary *)dict;
+(PlatypusAppSpec *)specFromProfile: (NSString *)filePath;
+(PlatypusAppSpec *)specWithDefaultsFromScript: (NSString *)scriptPath;
-(void)setDefaults;
-(void)setDefaultsForScript: (NSString *)scriptPath;
-(BOOL)create;
-(NSDictionary *)infoPlist;
-(BOOL)verify;
-(void)report: (NSString *)str;
-(void)dumpToFile: (NSString *)filePath;
-(void)dump;
-(NSString *)commandString;
-(void)setProperty: (id)property forKey: (NSString *)theKey;
-(id)propertyForKey: (NSString *)theKey;
-(NSDictionary *)properties;
-(void)addProperties: (NSDictionary *)dict;
-(NSString *)error;
+(NSString *)standardBundleIdForAppName: (NSString *)name  usingDefaults: (BOOL)def;
@end
