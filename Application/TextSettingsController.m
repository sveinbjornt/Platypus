/*
    Copyright (c) 2003-2023, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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
#import "NSColor+Inverted.h"

@interface TextSettingsController()
{
    IBOutlet NSColorWell *backgroundColorWell;
    IBOutlet NSColorWell *foregroundColorWell;
    IBOutlet NSTextField *fontFaceTextField;
    IBOutlet NSTextView *textPreviewTextView;
    IBOutlet NSButton *textSettingsButton;
    IBOutlet NSWindow *parentWindow;
    
    NSFont *currentFont;
}
@end

@implementation TextSettingsController

- (void)awakeFromNib {
    [self setCurrentFont:[NSFont fontWithName:DEFAULT_TEXT_FONT_NAME size:DEFAULT_TEXT_FONT_SIZE]];
    [self updateTextViewColor:self];
//    [NSDistributedNotificationCenter.defaultCenter addObserver:self
//                                                      selector:@selector(themeChanged:) name:@"AppleInterfaceThemeChangedNotification"
//                                                        object: nil];
}

//- (void)themeChanged:(NSNotification *)notification {
//    [self updateTextViewColor:notification];
//}

- (IBAction)show:(id)sender {
    [parentWindow setTitle:[NSString stringWithFormat:@"%@ - Text Settings", PROGRAM_NAME]];
    [self updateTextViewColor:self];
    [NSApp beginSheet:[self window]
       modalForWindow:parentWindow
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
    
    [NSApp runModalForWindow:[self window]];
}

- (IBAction)apply:(id)sender {
    if ([NSColorPanel sharedColorPanelExists]) {
        [[NSColorPanel sharedColorPanel] orderOut:self];
    }
    if ([NSFontPanel sharedFontPanelExists]) {
        [[[NSFontManager sharedFontManager] fontPanel:NO] orderOut:self];
    }
    [parentWindow setTitle:PROGRAM_NAME];
    [NSApp stopModal];
    [NSApp endSheet:[self window]];
    [[self window] orderOut:self];
}

- (IBAction)setToDefaults:(id)sender {
    [foregroundColorWell setColor:[NSColor blackColor]];
    [backgroundColorWell setColor:[NSColor whiteColor]];
    [self setCurrentFont:[NSFont fontWithName:DEFAULT_TEXT_FONT_NAME size:DEFAULT_TEXT_FONT_SIZE]];
    [self updateTextViewColor:self];
}

- (IBAction)updateTextViewColor:(id)sender {
    NSColor *bgColor = [backgroundColorWell color];
    NSColor *fgColor = [foregroundColorWell color];
    
    BOOL darkMode = NO;
    BOOL darkPossible = NO;
    if (@available(macOS 10.14, *)) {
        darkPossible = YES;
    }
    if (darkPossible) {
        darkMode = [[[NSAppearance currentAppearance] name] isEqualToString:NSAppearanceNameDarkAqua];
        if (darkMode) {
            bgColor = [bgColor inverted];
            fgColor = [fgColor inverted];
        }
    }
    
    [textPreviewTextView setBackgroundColor:bgColor];
    [textPreviewTextView setTextColor:fgColor];
}

#pragma mark - Font Manager

- (IBAction)chooseFont:(id)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    if (currentFont != nil) {
        [fontManager setSelectedFont:currentFont isMultiple:NO];
    }
    [fontManager orderFrontFontPanel:nil];
}

- (void)setCurrentFont:(NSFont *)font {
    currentFont = [font copy];
    [self updateFontField];
}

// Called by the shared NSFontManager when user chooses a new font or size in the Font Panel
- (void)changeFont:(id)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    if ([fontManager selectedFont] != nil) {
        [self setCurrentFont:[fontManager convertFont:[fontManager selectedFont]]];
    }
}

- (void)updateFontField {
    if (currentFont) {
        [fontFaceTextField setStringValue:[NSString stringWithFormat:@"%@ %.0f", [currentFont fontName], [currentFont pointSize]]];
        [textPreviewTextView setFont:currentFont];
    }
}

#pragma mark - Getters/Setters

- (NSFont *)textFont {
    return [textPreviewTextView font];
}

- (void)setTextFont:(NSFont *)font {
    [self setCurrentFont:font];
}

- (NSColor *)textForegroundColor {
    return [foregroundColorWell color];
}

- (void)setTextForegroundColor:(NSColor *)color {
    [foregroundColorWell setColor:color];
    [self updateTextViewColor:self];
}

- (NSColor *)textBackgroundColor {
    return [backgroundColorWell color];
}

- (void)setTextBackgroundColor:(NSColor *)color {
    [backgroundColorWell setColor:color];
    [self updateTextViewColor:self];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    return [textSettingsButton isEnabled];
}

@end
