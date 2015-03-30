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

#import "StatusItemSettingsController.h"
#import "Common.h"

@implementation StatusItemSettingsController

- (id)init {
    if ((self = [super init])) {
        pStatusItem = NULL;
    }
    return self;
}

- (IBAction)show:(id)sender {
    [window setTitle:[NSString stringWithFormat:@"%@ - Status Item Settings", PROGRAM_NAME]];
    
    //open window
    [NSApp  beginSheet:statusItemSettingsWindow
        modalForWindow:window
         modalDelegate:NULL
        didEndSelector:NULL
           contextInfo:NULL];
    
    [statusItemSettingsWindow makeFirstResponder:statusItemSettingsWindow];
    [NSApp runModalForWindow:statusItemSettingsWindow];
    
    [NSApp endSheet:statusItemSettingsWindow];
    [statusItemSettingsWindow orderOut:self];
}

- (IBAction)close:(id)sender {
    [window setTitle:PROGRAM_NAME];
    [NSApp stopModal];
    [NSApp endSheet:statusItemSettingsWindow];
    [statusItemSettingsWindow orderOut:self];
    [self killStatusItem];
}

- (IBAction)restoreDefaults:(id)sender {
    [titleTextField setStringValue:@"Title"];
    [self setDisplayType:@"Text"];
    [iconImageView setImage:[NSImage imageNamed:@"PlatypusStatusMenuIcon"]];
}

- (IBAction)statusItemDisplayTypeChanged:(id)sender {
    if ([sender indexOfSelectedItem] == 0) {
        [iconLabel setHidden:YES];
        [iconImageView setHidden:YES];
        [selectIconButton setHidden:YES];
        [titleLabel setHidden:NO];
        [titleTextField setHidden:NO];
    }
    else if ([sender indexOfSelectedItem] == 1) {
        [iconLabel setHidden:NO];
        [iconImageView setHidden:NO];
        [selectIconButton setHidden:NO];
        [titleLabel setHidden:YES];
        [titleTextField setHidden:YES];
    }
    else if ([sender indexOfSelectedItem] == 2) {
        [iconLabel setHidden:NO];
        [iconImageView setHidden:NO];
        [selectIconButton setHidden:NO];
        [titleLabel setHidden:NO];
        [titleTextField setHidden:NO];
    }
    
    if ([self showingStatusItem]) {
        [self previewStatusItem:self];
    }
}

- (void)setDisplayType:(NSString *)name {
    [displayTypePopup selectItemWithTitle:name];
    [self statusItemDisplayTypeChanged:displayTypePopup];
}

- (NSString *)displayType {
    return [displayTypePopup titleOfSelectedItem];
}

- (IBAction)selectStatusItemIcon:(id)sender {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setPrompt:@"Select"];
    [oPanel setTitle:[NSString stringWithFormat:@"%@ - Select Image", PROGRAM_NAME]];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setAllowedFileTypes:[PlatypusUtility imageFileSuffixes]];
    
    if ([oPanel runModal] == NSOKButton) {
        NSString *filePath = [[[oPanel URLs] objectAtIndex:0] path];
        NSImage *img = [[NSImage alloc] initWithContentsOfFile:filePath];
        if (img != NULL) {
            [self setIcon:img];
            [img release];
        }
        else {
            [PlatypusUtility alert:@"Corrupt Image File" subText:@"The image file you selected appears to be damaged or corrupt."];
        }
    }
}

- (IBAction)previewStatusItem:(id)sender {
    [self killStatusItem];
    
    int dType = [displayTypePopup indexOfSelectedItem];
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    
    // create status item
    pStatusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [pStatusItem setHighlightMode:YES];
    
    // set icon / title depending on settings
    if (dType == 0 || dType == 2)
        [pStatusItem setTitle:[titleTextField stringValue]];
    if (dType == 1 || dType == 2)
        [pStatusItem setImage:[iconImageView image]];
    
    //create placeholder menu
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"Your script output here" action:NULL keyEquivalent:@""] autorelease];
    [menu insertItem:menuItem atIndex:0];
    
    // get this thing rolling
    [pStatusItem setMenu:menu];
    [pStatusItem setEnabled:YES];
}

- (void)killStatusItem {
    if (pStatusItem != NULL) {
        [[NSStatusBar systemStatusBar] removeStatusItem:pStatusItem]; // remove cleanly from status bar
        [pStatusItem release];
        pStatusItem = NULL;
    }
}

- (BOOL)showingStatusItem {
    return (pStatusItem != NULL);
}

- (NSString *)title {
    return [titleTextField stringValue];
}

- (void)setTitle:(NSString *)title {
    [titleTextField setStringValue:title];
}

- (NSImage *)icon {
    return [iconImageView image];
}

- (void)setIcon:(NSImage *)img {
    NSSize originalSize = [img size];
    
    if (originalSize.width == 16 && originalSize.height == 16) {
        [iconImageView setImage:img];
    }
    // if the selected image isn't in dimensions 16x16, we scale it to that size
    else {
        // draw the image we're handed into a 16x16 bitmap
        NSImage *resizedImage = [[[NSImage alloc] initWithSize:NSMakeSize(16, 16)] autorelease];
        [resizedImage lockFocus];
        [img drawInRect:NSMakeRect(0, 0, 16, 16) fromRect:NSMakeRect(0, 0, originalSize.width, originalSize.height) operation:NSCompositeSourceOver fraction:1.0];
        [resizedImage unlockFocus];
        
        [iconImageView setImage:resizedImage];
    }
}

@end
