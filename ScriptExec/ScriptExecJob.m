//
//  ScriptExecJob.m
//  Platypus
//
//  Created by Sveinbjorn Thordarson on 06/11/15.
//  Copyright © 2015 Sveinbjorn Thordarson. All rights reserved.
//

#import "ScriptExecJob.h"

@interface ScriptExecJob()
@end

@implementation ScriptExecJob

- (instancetype)initWithArguments:(NSArray *)args andStandardInput:(NSString *)stdinStr {
    if ((self = [super init])) {
        self.arguments = args;
        self.standardInputString = stdinStr;
    }
    return self;
}

+ (instancetype)jobWithArguments:(NSArray *)args andStandardInput:(NSString *)stdinStr {
    id job = [[self alloc] initWithArguments:args andStandardInput:stdinStr];
#if !__has_feature(objc_arc)
    [job autorelease];
#endif
    return job;
}

@end
