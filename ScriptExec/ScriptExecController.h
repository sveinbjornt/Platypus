/*
 Copyright (c) 2003-2015, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 
 3. Neither the name of the copyright holder nor the names of its contributors may
 be used to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

/* This is the source code to the main window controller for
 the binary bundled into Platypus-generated applications */

#import <Cocoa/Cocoa.h>
#import <Security/Authorization.h>
#import <WebKit/WebKit.h>

#import <sys/syslimits.h>
#import <unistd.h>
#import <sys/types.h>
#import <sys/stat.h>

#import "NSColor+HexTools.h"
#import "Common.h"
#import "STPrivilegedTask.h"
#import "STDragWebView.h"
#import "NSFileManager+TempFile.h"

@interface ScriptExecController : NSObject <NSMenuDelegate>
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
    NSStatusItem *statusItem;
    NSMenu *statusItemMenu;
    
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
    
    NSTextView *outputTextView;
    
    IBOutlet id windowMenu;
    
    // tasks
    NSTask *task;
    STPrivilegedTask *privilegedTask;
    
    NSTimer *checkStatusTimer;
    
    NSPipe *outputPipe;
    NSFileHandle *readHandle;
    
    NSMutableArray *arguments;
    NSMutableArray *commandLineArguments;
    NSMutableArray *fileArgs;
    NSArray *interpreterArgs;
    NSArray *scriptArgs;
    
    
    NSString *interpreter;
    NSString *scriptPath;
    NSString *appName;
    
    NSFont *textFont;
    NSColor *textForeground;
    NSColor *textBackground;
    int textEncoding;
    
    NSInteger execStyle;
    NSInteger outputType;
    BOOL isDroppable;
    BOOL remainRunning;
    BOOL secureScript;
    BOOL acceptsFiles;
    BOOL acceptsText;
    BOOL promptForFileOnLaunch;
    
    NSArray *droppableSuffixes;
    BOOL acceptAnyDroppedItem;
    BOOL acceptDroppedFolders;
    
    NSString *statusItemTitle;
    NSImage *statusItemIcon;
    
    BOOL isTaskRunning;
    BOOL outputEmpty;
    
    NSString *script;
    NSString *remnants;
    
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

- (void)getOutputData:(NSNotification *)aNotification;
- (void)appendOutput:(NSData *)data;

- (BOOL)isAcceptableFileType:(NSString *)file;
- (BOOL)addDroppedFilesJob:(NSArray *)files;
- (BOOL)addDroppedTextJob:(NSString *)text;

- (IBAction)openFiles:(id)sender;
- (IBAction)saveToFile:(id)sender;
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

- (void)loadAppSettings;
- (IBAction)cancel:(id)sender;
- (IBAction)toggleDetails:(id)sender;
- (IBAction)showDetails;
- (IBAction)hideDetails;

- (IBAction)makeTextBigger:(id)sender;
- (IBAction)makeTextSmaller:(id)sender;

- (void)fatalAlert:(NSString *)message subText:(NSString *)subtext;
@end
