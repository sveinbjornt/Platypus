/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C) 2003-2010 Sveinbjorn Thordarson <sveinbjornt@simnet.is>

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

#import "TextSettingsController.h"
#import "CommonDefs.h"

@implementation TextSettingsController

- (void)awakeFromNib
{
	[[NSFontManager sharedFontManager] setDelegate: self];
	[self setCurrentFont: [[NSFont fontWithName:DEFAULT_OUTPUT_FONT size: DEFAULT_OUTPUT_FONTSIZE] retain]];
}

-(void)dealloc
{
	if (currentFont != NULL) { [currentFont release]; }
	[super dealloc];
}

- (IBAction)show:(id)sender
{
	[window setTitle: [NSString stringWithFormat: @"%@ - Edit Text Field Settings", PROGRAM_NAME]];

	

	//open window
	[NSApp beginSheet:	textSettingsWindow
						modalForWindow: window 
						modalDelegate:nil
						didEndSelector:nil
						contextInfo:nil];
	
	[textSettingsWindow makeFirstResponder: textSettingsWindow];
	 [NSApp runModalForWindow: textSettingsWindow];
	 
	 [NSApp endSheet: textSettingsWindow];
     [textSettingsWindow orderOut:self];
}

- (IBAction)apply:(id)sender
{
	[[[NSFontManager sharedFontManager] fontPanel: NO] orderOut: self];
	[[NSColorPanel sharedColorPanel] orderOut: self];
	[window setTitle: PROGRAM_NAME];
	[NSApp stopModal];
}

- (IBAction)resetDefaults:(id)sender
{
	[foregroundColorWell setColor: [NSColor blackColor]];
	[backgroundColorWell setColor: [NSColor whiteColor]];
	[self setCurrentFont: [NSFont fontWithName: DEFAULT_OUTPUT_FONT size: DEFAULT_OUTPUT_FONTSIZE]];
	[textEncodingPopupButton selectItemWithTag: [[[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultTextEncoding"] intValue]];
	[self changeColor: self];
}

- (void)changeColor:(id)sender
{
	[textPreviewTextView setBackgroundColor: [backgroundColorWell color]];
	[textPreviewTextView setTextColor: [foregroundColorWell color]];
}

#pragma mark -

////////////////////////////////////////////////////////////////////////
//
//  Functions to handle the font selection manager
//
////////////////////////////////////////////////////////////////////////

- (IBAction)chooseFont:(id)sender
{
	//[textSettingsWindow makeFirstResponder: textEncodingPopupButton];
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
    [fontManager setSelectedFont:currentFont isMultiple:NO];
    [fontManager orderFrontFontPanel:nil];
}

- (void)setCurrentFont:(NSFont *)font
{
    NSFont *newFont = [font retain];
    [currentFont release];
    currentFont = newFont;
	[self updateFontField];
}

// called by the shared NSFontManager when user chooses a new font or size in the Font Panel
- (void)changeFont:(id)sender
{
	//[textSettingsWindow makeFirstResponder: textEncodingPopupButton];
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    [self setCurrentFont:[fontManager convertFont:[fontManager selectedFont]]];
}

- (void)updateFontField
{
    [fontFaceTextField setStringValue: [NSString stringWithFormat:@"%@ %.0f", [currentFont fontName], [currentFont pointSize]]];
	[textPreviewTextView setFont: currentFont];
}

#pragma mark -
//////////////////////////////////

- (int)getTextEncoding
{
	return [[textEncodingPopupButton selectedItem] tag];
}

- (NSFont *)getTextFont
{
	return [textPreviewTextView font];
}

- (NSColor *)getTextForeground
{
	return [foregroundColorWell color];
}

- (NSColor *)getTextBackground
{
	return [backgroundColorWell color];
}

//////////////////////////////////

- (void)setTextEncoding: (int)encoding
{
	[textEncodingPopupButton selectItemWithTag: encoding];
}

- (void)setTextFont: (NSFont *)font
{
	[self setCurrentFont: font];
}

- (void )setTextForeground: (NSColor *)color
{
	[foregroundColorWell setColor: color];
	[self changeColor: self];
}

- (void )setTextBackground: (NSColor *)color
{
	[backgroundColorWell setColor: color];
	[self changeColor: self];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem*)anItem
{
	return [textSettingsButton isEnabled];
}

@end
