/*
    ScriptExec - binary bundled into Platypus-created applications
    Copyright (C) 2003-2012 Sveinbjorn Thordarson <sveinbjornt@gmail.com>

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

#import <Cocoa/Cocoa.h>
#import <Security/Authorization.h>
#import <WebKit/WebKit.h>
#import <sys/syslimits.h>

#import "NSColor+HexTools.h"
#import "Common.h"
#import "STPrivilegedTask.h"
#import "STDragWebView.h"

@interface ScriptExecController : NSObject
{
	// progress bar
    IBOutlet id progressBarCancelButton;
    IBOutlet id progressBarMessageTextField;
    IBOutlet id progressBarIndicator;
	IBOutlet id progressBarWindow;
	IBOutlet id progressBarTextView;
	IBOutlet id progressBarDetailsTriangle;
	IBOutlet id progressBarDetailsLabel;
	
	// text window
	IBOutlet id textOutputWindow;
	IBOutlet id textOutputCancelButton;
	IBOutlet id textOutputTextView;
	IBOutlet id textOutputProgressIndicator;
	IBOutlet id textOutputMessageTextField;
	
	// web view
	IBOutlet id webOutputWindow;
	IBOutlet id webOutputCancelButton;
	IBOutlet id webOutputWebView;
	IBOutlet id webOutputProgressIndicator;
	IBOutlet id webOutputMessageTextField;
	
	// status item menu
	NSStatusItem	*statusItem;
	NSMenu			*statusItemMenu;
	
	// droplet
	IBOutlet id dropletWindow;
	IBOutlet id dropletBox;
	IBOutlet id dropletProgressIndicator;
	IBOutlet id dropletMessageTextField;
	IBOutlet id dropletDropFilesLabel;
	IBOutlet id dropletShader;
	
	//menu items
	IBOutlet id hideMenuItem;
	IBOutlet id quitMenuItem;
	IBOutlet id aboutMenuItem;
	
	NSTextView	*outputTextView;
		
	IBOutlet id windowMenu;
	
	// tasks
	NSTask				*task;
	STPrivilegedTask	*privilegedTask;
	
	NSTimer			*checkStatusTimer;

	NSPipe			*outputPipe;
	NSFileHandle	*readHandle;

	NSMutableArray  *arguments;
	NSMutableArray  *fileArgs;
	NSArray			*interpreterArgs;
    NSArray         *scriptArgs;
    

	NSString		*interpreter;
	NSString		*scriptPath;
	NSString		*appName;
	
	NSFont			*textFont;
	NSColor			*textForeground;
	NSColor			*textBackground;
	int				 textEncoding;
	
	int			appPathAsFirstArg;
	int			execStyle;
	int			outputType;
	int			isDroppable;
	int			remainRunning;
	int			secureScript;
	
	NSArray		*droppableSuffixes;
	NSArray		*droppableFileTypes;
	BOOL		acceptAnyDroppedItem;
    BOOL        acceptDroppedFolders;
	
	NSString	*statusItemTitle;
	NSImage		*statusItemIcon;

	BOOL		isTaskRunning;
	BOOL		outputEmpty;
	
	NSString	*script;

	NSString	*remnants;
	
	NSMutableArray *jobQueue;
}

- (void)initialiseInterface;
- (void)prepareInterfaceForExecution;
- (void)cleanupInterface;

- (void)prepareForExecution;
- (void)executeScript;

- (void)executeScriptWithoutPrivileges;
- (void)executeScriptWithPrivileges;

- (void)cleanup;
- (void)taskFinished:(NSNotification *)aNotification;

- (void)getOutputData: (NSNotification *)aNotification;
- (void)appendOutput: (NSData *)data;

- (BOOL)acceptableFileType: (NSString *)file;
- (BOOL)addDroppedFilesJob: (NSArray *)files;
- (BOOL)addDroppedTextJob: (NSString *)text;

- (IBAction)openFiles:(id)sender;
- (IBAction)saveToFile: (id)sender;
- (BOOL)validateMenuItem:(NSMenuItem*)anItem;

- (void)loadSettings;
- (IBAction)cancel: (id)sender;
- (IBAction)toggleDetails: (id)sender;

- (void)fatalAlert: (NSString *)message subText: (NSString *)subtext;
@end
