/*
 Platypus - program for creating Mac OS X application wrappers around scripts
 Copyright (C) 2003-2015 Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 
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

@interface TextSettingsController : NSObject
{
    IBOutlet id window;
    IBOutlet id textSettingsWindow;
    
    IBOutlet id backgroundColorWell;
    IBOutlet id foregroundColorWell;
    
    IBOutlet id fontFaceTextField;
    IBOutlet id textEncodingPopupButton;
    
    IBOutlet id textPreviewTextView;
    IBOutlet id textSettingsButton;
    
    NSFont *currentFont;
}
- (IBAction)apply:(id)sender;
- (IBAction)resetDefaults:(id)sender;
- (IBAction)show:(id)sender;
- (void)changeColor:(id)sender;
- (IBAction)chooseFont:(id)sender;
- (void)changeFont:(id)sender;
- (void)setCurrentFont:(NSFont *)font;
- (void)updateFontField;

- (int)getTextEncoding;
- (NSFont *)getTextFont;
- (NSColor *)getTextForeground;
- (NSColor *)getTextBackground;

- (void)setTextEncoding:(int)encoding;
- (void)setTextFont:(NSFont *)font;
- (void)setTextForeground:(NSColor *)color;
- (void)setTextBackground:(NSColor *)color;


@end
