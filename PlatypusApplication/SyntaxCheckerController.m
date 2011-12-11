/*
 Platypus - program for creating Mac OS X application wrappers around scripts
 Copyright (C) 2003-2011 Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 
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

#import "SyntaxCheckerController.h"


@implementation SyntaxCheckerController

-(id) init
{
	return [super initWithWindowNibName: @"SyntaxChecker"];
}

- (void)awakeFromNib
{
	[textView setFont:[NSFont userFixedPitchFontOfSize: 10.0]];
}

- (void)showSyntaxCheckerForFile: (NSString *)path withInterpreter: (NSString *)interpreter window: (NSWindow *)theWindow
{	
	[self loadWindow];
	[scriptPathTextField setStringValue: path];
	NSString *reportText = [ScriptAnalyser checkSyntaxOfFile: path withInterpreter: interpreter];
	[textView setString: reportText];
	
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
