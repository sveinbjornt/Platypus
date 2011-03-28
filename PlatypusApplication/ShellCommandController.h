//
//  ShellCommandController.h
//  Platypus
//
//  Created by Sveinbjorn Thordarson on 9/1/10.
//  Copyright 2010 Sveinbjorn Thordarson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PlatypusAppSpec.h"

@interface ShellCommandController : NSWindowController 
{
	IBOutlet id textView;
}
- (void)showShellCommandForSpec: (PlatypusAppSpec *)spec window: (NSWindow *)theWindow;
- (IBAction)close: (id)sender;

@end
