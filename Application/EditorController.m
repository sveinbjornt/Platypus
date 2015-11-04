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

#import "EditorController.h"
#import "Common.h"
#import "Alerts.h"
#import "SyntaxCheckerController.h"
#import "NSTextView+JSDExtensions.h"

@implementation EditorController

- (id)init {
    return [super initWithWindowNibName:@"Editor"];
}

- (void)awakeFromNib {
    
    NSNumber *userFontSizeNum = [DEFAULTS objectForKey:@"EditorFontSize"];
    CGFloat fontSize = userFontSizeNum ? [userFontSizeNum floatValue] : DEFAULT_OUTPUT_FONTSIZE;
    NSFont *font = [NSFont fontWithName:DEFAULT_OUTPUT_FONT size:fontSize];
    [textView setFont:font];
    
    [textView setAutomaticQuoteSubstitutionEnabled:NO];
    [textView setAutomaticLinkDetectionEnabled:NO];
}

- (void)showEditorForFile:(NSString *)path window:(NSWindow *)theWindow {
    NSError *err;
    NSString *str = [NSString stringWithContentsOfFile:path encoding:[[DEFAULTS objectForKey:@"DefaultTextEncoding"] intValue] error:&err];
    if (str == nil) {
        [Alerts alert:@"Error reading document" subText:@"This document could not be opened with the text editor."];
        return;
    }
    
    [self loadWindow];
    [scriptPathTextField setStringValue:path];
    NSImage *icon = [WORKSPACE iconForFile:path];
    [icon setSize:NSMakeSize(16, 16)];
    [scriptIconImageView setImage:icon];
    
    
    [textView setShowsLineNumbers:YES];
    
    [wordWrapCheckbox setIntValue:[DEFAULTS boolForKey:@"EditorWordWrap"]];
    [textView setWordwrapsText:[DEFAULTS boolForKey:@"EditorWordWrap"]];
    
    [textView setString:str];
    
    mainWindow = theWindow;
    
    [NSApp  beginSheet:[self window]
        modalForWindow:theWindow
         modalDelegate:self
        didEndSelector:nil
           contextInfo:nil];
    
    [NSApp runModalForWindow:[self window]];
}

#pragma mark -

- (IBAction)save:(id)sender {
    NSError *err;
    if ([[textView string] writeToFile:[scriptPathTextField stringValue] atomically:YES encoding:[[DEFAULTS objectForKey:@"DefaultTextEncoding"] intValue] error:&err] == FALSE) {
        [Alerts alert:@"Error saving document" subText:[err localizedDescription]];
    }
    
    [NSApp endSheet:[self window]];
    [NSApp stopModal];
    [[self window] close];
}

- (IBAction)cancel:(id)sender {
    [NSApp endSheet:[self window]];
    [NSApp stopModal];
    [[self window] close];
}

#pragma mark -

- (IBAction)checkSyntax:(id)sender {
    SyntaxCheckerController *syntaxController = [[SyntaxCheckerController alloc] initWithWindowNibName:@"SyntaxChecker"];
    [syntaxController showSyntaxCheckerForFile:[scriptPathTextField stringValue]
                               withInterpreter:nil
                                        window:mainWindow];
}

- (IBAction)revealInFinder:(id)sender {
    [WORKSPACE selectFile:[scriptPathTextField stringValue] inFileViewerRootedAtPath:[scriptPathTextField stringValue]];
}

- (IBAction)wordWrapCheckboxClicked:(id)sender {
    [textView setWordwrapsText:[sender intValue]];
    [DEFAULTS setBool:[sender intValue] forKey:@"EditorWordWrap"];
}

#pragma mark - Font size

- (void)changeFontSize:(CGFloat)delta {
    NSFont *font = [textView font];
    CGFloat newFontSize = [font pointSize] + delta;
    font = [[NSFontManager sharedFontManager] convertFont:font toSize:newFontSize];
    [textView setFont:font];
    [DEFAULTS setObject:[NSNumber numberWithFloat:newFontSize] forKey:@"EditorFontSize"];
    [textView didChangeText];
}


- (IBAction)makeTextBigger:(id)sender {
    [self changeFontSize:1];
}

- (IBAction)makeTextSmaller:(id)sender {
    [self changeFontSize:-1];
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
    [self release];
}

@end
