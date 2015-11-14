//
//  ScriptExecJob.h
//  Platypus
//
//  Created by Sveinbjorn Thordarson on 06/11/15.
//  Copyright © 2015 Sveinbjorn Thordarson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScriptExecJob : NSObject

- (instancetype)initWithArguments:(NSArray *)args andStandardInput:(NSString *)stdinStr;
+ (instancetype)jobWithArguments:(NSArray *)args andStandardInput:(NSString *)stdinStr;
- (NSArray *)arguments;
- (NSString *)standardInputString;

@end
