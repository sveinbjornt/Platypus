//
//  NSTask+Description.m
//  Platypus
//
//  Created by Sveinbjorn Thordarson on 10/10/15.
//  Copyright © 2015 Sveinbjorn Thordarson. All rights reserved.
//

#import "NSTask+Description.h"

@implementation NSTask (Description)

-(NSString *)humanDescription
{
    NSString *string = [self launchPath];
    NSArray *args = [self arguments];
    for (NSString *argument in args) {
        string = [string stringByAppendingFormat:@" %@", argument];
    }
    return string;
}

@end
