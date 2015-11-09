//
//  ScriptExecJob.m
//  Platypus
//
//  Created by Sveinbjorn Thordarson on 06/11/15.
//  Copyright © 2015 Sveinbjorn Thordarson. All rights reserved.
//

#import "ScriptExecJob.h"

@implementation ScriptExecJob

- (instancetype)initWithArguments:(NSArray *)args andStandardInput:(NSString *)stdinStr {
    if ((self = [super init])) {
        arguments = [args retain];
        standardInputString = [stdinStr retain];
    }
    return self;
}

+ (instancetype)jobWithArguments:(NSArray *)args andStandardInput:(NSString *)stdinStr {
    return [[[self alloc] initWithArguments:args andStandardInput:stdinStr] autorelease];
}

- (void)dealloc {
    if (arguments) {
        [arguments release];
    }
    if (standardInputString) {
        [standardInputString release];
    }
    [super dealloc];
}

#pragma mark -

- (NSArray *)arguments {
    return arguments;
}

- (NSString *)standardInputString {
    return standardInputString;
}

@end
