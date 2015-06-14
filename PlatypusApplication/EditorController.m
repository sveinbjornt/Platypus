/*
Copyright (c) 2003-2015, Sveinbjorn Thordarson <sveinbjornt@gmail.com
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of the FreeBSD Project.
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
