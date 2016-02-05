/*
 Copyright (c) 2003-2016, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
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

#import "TextSettingsController.h"
#import "Common.h"

@interface TextSettingsController()
{
    IBOutlet NSColorWell *backgroundColorWell;
    IBOutlet NSColorWell *foregroundColorWell;
    IBOutlet NSTextField *fontFaceTextField;
    IBOutlet NSPopUpButton *textEncodingPopupButton;
    IBOutlet NSTextView *textPreviewTextView;
    IBOutlet NSButton *textSettingsButton;
    
    NSFont *currentFont;
}

- (IBAction)apply:(id)sender;
- (IBAction)show:(id)sender;
- (IBAction)chooseFont:(id)sender;
- (IBAction)updateTextViewColor:(id)sender;

@end

@implementation TextSettingsController

- (void)awakeFromNib {
    [[NSFontManager sharedFontManager] setDelegate:self];
    [self setCurrentFont:[NSFont fontWithName:DEFAULT_TEXT_FONT_NAME size:DEFAULT_TEXT_FONT_SIZE]];
}

- (IBAction)show:(id)sender {
    NSWindow *parentWindow = [[[NSApplication sharedApplication] delegate] window];
    [parentWindow setTitle:[NSString stringWithFormat:@"%@ - Text Settings", PROGRAM_NAME]];
    
    [NSApp beginSheet:[self window]
       modalForWindow:parentWindow
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
    
    [NSApp runModalForWindow:[self window]];
}

- (IBAction)apply:(id)sender {
    [[[NSFontManager sharedFontManager] fontPanel:NO] orderOut:self];
    [[NSColorPanel sharedColorPanel] orderOut:self];
    NSWindow *window = [[[NSApplication sharedApplication] delegate] window];
    [window setTitle:PROGRAM_NAME];
    [NSApp stopModal];
    [NSApp endSheet:[self window]];
    [[self window] orderOut:self];
}

- (IBAction)setToDefaults:(id)sender {
    [foregroundColorWell setColor:[NSColor blackColor]];
    [backgroundColorWell setColor:[NSColor whiteColor]];
    [self setCurrentFont:[NSFont fontWithName:DEFAULT_TEXT_FONT_NAME size:DEFAULT_TEXT_FONT_SIZE]];
    [textEncodingPopupButton selectItemWithTag:[[DEFAULTS objectForKey:DefaultsKey_DefaultTextEncoding] intValue]];
    [self updateTextViewColor:self];
}

- (IBAction)updateTextViewColor:(id)sender {
    [textPreviewTextView setBackgroundColor:[backgroundColorWell color]];
    [textPreviewTextView setTextColor:[foregroundColorWell color]];
}

#pragma mark - Font Manager

- (IBAction)chooseFont:(id)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    [fontManager setSelectedFont:currentFont isMultiple:NO];
    [fontManager orderFrontFontPanel:nil];
}

- (void)setCurrentFont:(NSFont *)font {
    currentFont = [font copy];
    [self updateFontField];
}

// called by the shared NSFontManager when user chooses a new font or size in the Font Panel
- (void)changeFont:(id)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    [self setCurrentFont:[fontManager convertFont:[fontManager selectedFont]]];
}

- (void)updateFontField {
    [fontFaceTextField setStringValue:[NSString stringWithFormat:@"%@ %.0f", [currentFont fontName], [currentFont pointSize]]];
    [textPreviewTextView setFont:currentFont];
}

#pragma mark - Getters/Setters

- (NSStringEncoding)textEncoding {
    return (NSStringEncoding)[[textEncodingPopupButton selectedItem] tag];
}

- (void)setTextEncoding:(NSStringEncoding)encoding {
    [textEncodingPopupButton selectItemWithTag:encoding];
}

- (NSFont *)textFont {
    return [textPreviewTextView font];
}

- (void)setTextFont:(NSFont *)font {
    [self setCurrentFont:font];
}

- (NSColor *)textForegroundColor {
    return [foregroundColorWell color];
}

- (void)setTextForeground:(NSColor *)color {
    [foregroundColorWell setColor:color];
    [self updateTextViewColor:self];
}

- (NSColor *)textBackgroundColor {
    return [backgroundColorWell color];
}

- (void)setTextBackground:(NSColor *)color {
    [backgroundColorWell setColor:color];
    [self updateTextViewColor:self];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    return [textSettingsButton isEnabled];
}

@end
