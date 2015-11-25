//
//  Alerts.m
//  Platypus
//
//  Created by Sveinbjorn Thordarson on 28/10/15.
//  Copyright © 2015 Sveinbjorn Thordarson. All rights reserved.
//

#import "Alerts.h"

@implementation Alerts

+ (void)alert:(NSString *)message subText:(NSString *)subtext style:(NSAlertStyle)style {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:message];
    [alert setInformativeText:subtext];
    [alert setAlertStyle:style];
    [[alert window] setPreventsApplicationTerminationWhenModal:YES];
    [alert runModal];
    [alert release];
}

+ (void)alert:(NSString *)message subTextFormat:(NSString *)formatString, ...
{
    va_list args;
    va_start(args, formatString);
    NSString *formattedString = [[[NSString alloc] initWithFormat:formatString arguments:args] autorelease];
    va_end(args);
    [self alert:message subText:formattedString];
}

+ (void)alert:(NSString *)message subText:(NSString *)subtext {
    [self alert:message subText:subtext style:NSWarningAlertStyle];
}

+ (void)fatalAlert:(NSString *)message subText:(NSString *)subtext {
    [self alert:message subText:subtext style:NSCriticalAlertStyle];
    [[NSApplication sharedApplication] terminate:self];
}

+ (void)fatalAlert:(NSString *)message subTextFormat:(NSString *)formatString, ... {
    va_list args;
    va_start(args, formatString);
    NSString *formattedString = [[[NSString alloc] initWithFormat:formatString arguments:args] autorelease];
    va_end(args);
    [self fatalAlert:message subText:formattedString];
}

#pragma mark -

+ (void)sheetAlert:(NSString *)message subText:(NSString *)subtext forWindow:(NSWindow *)window {
    [self sheetAlert:message subText:subtext style:NSCriticalAlertStyle forWindow:window];
}

+ (void)sheetAlert:(NSString *)message subText:(NSString *)subtext style:(NSAlertStyle)style forWindow:(NSWindow *)window {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:message];
    [alert setInformativeText:subtext];
    [alert setAlertStyle:style];
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:nil];
    [alert release];
}

#pragma mark -

+ (BOOL)proceedAlert:(NSString *)message subText:(NSString *)subtext withAction:(NSString *)action {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:action];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:message];
    [alert setInformativeText:subtext];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    BOOL ret = ([alert runModal] == NSAlertFirstButtonReturn);
    [alert release];
    return ret;
}

@end
