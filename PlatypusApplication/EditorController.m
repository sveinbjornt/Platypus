/*
 Platypus - program for creating Mac OS X application wrappers around scripts
 Copyright (C) 2003-2013 Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 
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

#import "EditorController.h"

@implementation EditorController

- (id)init {
	return [super initWithWindowNibName:@"Editor"];
}

- (void)awakeFromNib {
	[textView setFont:[NSFont userFixedPitchFontOfSize:10.0]];
}

- (void)showEditorForFile:(NSString *)path window:(NSWindow *)theWindow {
	NSString *str = [NSString stringWithContentsOfFile:path encoding:[[DEFAULTS objectForKey:@"DefaultTextEncoding"] intValue] error:nil];
	if (str == nil) {
		[PlatypusUtility alert:@"Error reading document" subText:@"This document does not appear to be a text file and cannot be opened with a text editor."];
		return;
	}
    
	[self loadWindow];
	[scriptPathTextField setStringValue:path];
	[textView setString:str];
	mainWindow = theWindow;
    
	[NSApp  beginSheet:[self window]
	    modalForWindow:theWindow
	     modalDelegate:self
	    didEndSelector:nil
	       contextInfo:nil];
    
	[NSApp runModalForWindow:[self window]];
}

- (IBAction)save:(id)sender {
	if (![FILEMGR isWritableFileAtPath:[scriptPathTextField stringValue]])
		[PlatypusUtility alert:@"Unable to save changes" subText:@"You don't the neccesary privileges to save this text file."];
	else
		[[textView string] writeToFile:[scriptPathTextField stringValue] atomically:YES encoding:[[DEFAULTS objectForKey:@"DefaultTextEncoding"] intValue] error:nil];
    
	[NSApp endSheet:[self window]];
	[NSApp stopModal];
	[[self window] close];
}

- (IBAction)cancel:(id)sender {
	[NSApp endSheet:[self window]];
	[NSApp stopModal];
	[[self window] close];
}

- (IBAction)checkSyntax:(id)sender {
	SyntaxCheckerController *syntax = [[SyntaxCheckerController alloc] initWithWindowNibName:@"SyntaxChecker"];
	[syntax showSyntaxCheckerForFile:[scriptPathTextField stringValue]
	                 withInterpreter:nil
	                          window:mainWindow];
}

- (IBAction)revealInFinder:(id)sender {
	[[NSWorkspace sharedWorkspace] selectFile:[scriptPathTextField stringValue] inFileViewerRootedAtPath:nil];
}

- (void)windowWillClose:(NSNotification *)notification {
	[self release];
}

@end
