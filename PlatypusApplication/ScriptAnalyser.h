//
//  ScriptAnalyser.h
//  Platypus
//
//  Created by Sveinbjorn Thordarson on 8/30/10.
//  Copyright 2010 Sveinbjorn Thordarson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface ScriptAnalyser : NSObject 
{

}
+ (NSArray *)interpreters;
+ (NSArray *)interpreterDisplayNames;
+ (NSString *)displayNameForInterpreter: (NSString *)theInterpreter;
+ (NSString *)interpreterForDisplayName: (NSString *)name;
+ (NSString *)interpreterFromSuffix: (NSString *)fileName;
+ (NSArray *)getInterpreterFromShebang: (NSString *)path;
+ (NSString *)determineInterpreterForScriptFile: (NSString *)path;
+ (NSString *)checkSyntaxOfFile: (NSString *)scriptPath withInterpreter: (NSString *)suggestedInterpreter;
@end
