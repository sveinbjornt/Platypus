//
//  Alerts.h
//  Platypus
//
//  Created by Sveinbjorn Thordarson on 28/10/15.
//  Copyright © 2015 Sveinbjorn Thordarson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface Alerts : NSObject

+ (void)alert:(NSString *)message subText:(NSString *)subtext style:(NSAlertStyle)style;
+ (void)alert:(NSString *)message subText:(NSString *)subtext;
+ (void)fatalAlert:(NSString *)message subText:(NSString *)subtext;
+ (void)sheetAlert:(NSString *)message subText:(NSString *)subtext forWindow:(NSWindow *)window;
+ (BOOL)proceedAlert:(NSString *)message subText:(NSString *)subtext withAction:(NSString *)action;

@end
