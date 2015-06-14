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
