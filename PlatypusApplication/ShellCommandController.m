//
//  ShellCommandController.m
//  Platypus
//
//  Created by Sveinbjorn Thordarson on 9/1/10.
//  Copyright 2010 Sveinbjorn Thordarson. All rights reserved.
//

#import "ShellCommandController.h"


@implementation ShellCommandController

- (id)init 
{
    return [super initWithWindowNibName: @"ShellCommandWindow"];
}

- (void)awakeFromNib
{
	[textView setFont:[NSFont userFixedPitchFontOfSize: 10.0]];
}

- (void)showShellCommandForSpec: (PlatypusAppSpec *)spec window: (NSWindow *)theWindow
{	
	[self loadWindow];
		
	[textView setString: [spec commandString]];
	
	[NSApp beginSheet: [self window]
	   modalForWindow: theWindow 
		modalDelegate: self
	   didEndSelector:nil
		  contextInfo:nil];
	
	[NSApp runModalForWindow: [self window]];
}

- (IBAction)close: (id)sender
{
	[NSApp endSheet: [self window]];
	[NSApp stopModal];
	[[self window] close];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[self release];
}

@end
