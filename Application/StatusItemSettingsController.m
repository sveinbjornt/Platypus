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

#import "StatusItemSettingsController.h"
#import "Common.h"
#import "PlatypusController.h"
#import "Alerts.h"

@interface StatusItemSettingsController()
{
    IBOutlet id window;
    IBOutlet id statusItemSettingsWindow;
    IBOutlet id displayTypePopup;
    IBOutlet id iconImageView;
    IBOutlet id selectIconButton;
    IBOutlet id titleTextField;
    IBOutlet id titleLabel;
    IBOutlet id iconLabel;
    IBOutlet NSButton *useSystemFontCheckbox;
    
    IBOutlet PlatypusController *platypusController;
    
    NSStatusItem *pStatusItem;
    NSMenu *pStatusItemMenu;
}

- (IBAction)show:(id)sender;
- (IBAction)close:(id)sender;
- (IBAction)statusItemDisplayTypeChanged:(id)sender;
- (IBAction)selectStatusItemIcon:(id)sender;
- (IBAction)previewStatusItem:(id)sender;

@end

@implementation StatusItemSettingsController

- (void)dealloc {
    if (pStatusItemMenu) {
        [pStatusItemMenu release];
    }
    [super dealloc];
}

- (IBAction)show:(id)sender {
    [window setTitle:[NSString stringWithFormat:@"%@ - Status Item Settings", PROGRAM_NAME]];
    
    //open window
    [NSApp beginSheet:statusItemSettingsWindow
       modalForWindow:window
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
    
    [statusItemSettingsWindow makeFirstResponder:statusItemSettingsWindow];
    [NSApp runModalForWindow:statusItemSettingsWindow];
    
    [NSApp endSheet:statusItemSettingsWindow];
    [statusItemSettingsWindow orderOut:self];
}

- (IBAction)close:(id)sender {
    [self killStatusItem];
    [window setTitle:PROGRAM_NAME];
    [NSApp stopModal];
    [NSApp endSheet:statusItemSettingsWindow];
    [statusItemSettingsWindow orderOut:self];
}

#pragma mark -

- (IBAction)setToDefaults:(id)sender {
    [titleTextField setStringValue:@"Title"];
    [self setDisplayType:@"Text"];
    [iconImageView setImage:[NSImage imageNamed:@"DefaultStatusMenuIcon"]];
    [useSystemFontCheckbox setIntValue:TRUE];
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
    
    if (pStatusItem != nil) {
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
    [oPanel setAllowedFileTypes:[NSImage imageTypes]];
    
    if ([oPanel runModal] == NSOKButton) {
        NSString *filePath = [[oPanel URLs][0] path];
        NSImage *img = [[NSImage alloc] initWithContentsOfFile:filePath];
        if (img != nil) {
            [self setIcon:img];
            [img release];
        } else {
            [Alerts alert:@"Corrupt Image File" subText:@"The image file you selected appears to be damaged or corrupt."];
        }
    }
}

#pragma mark - Preview Status Item

- (IBAction)previewStatusItem:(id)sender {
    [self killStatusItem];
    
    // create status item
    pStatusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [pStatusItem setHighlightMode:YES];
    [pStatusItem setMenu:pStatusItemMenu];
    
    // set icon / title depending on settings
    int dType = [displayTypePopup indexOfSelectedItem];
    if (dType == 0 || dType == 2) {
        [pStatusItem setTitle:[titleTextField stringValue]];
    }
    if (dType == 1 || dType == 2) {
        NSImage *img = [iconImageView image];
        [img setSize:NSMakeSize(18, 18)];
        [pStatusItem setImage:img];
    }
    
    // create menu
    pStatusItemMenu = [[NSMenu alloc] initWithTitle:@""];
    [pStatusItemMenu setDelegate:self];
    [pStatusItemMenu setAutoenablesItems:NO];
    
    // get this thing rolling
    [pStatusItem setEnabled:YES];
    [pStatusItem setMenu:pStatusItemMenu];
}

- (void)killStatusItem {
    if (pStatusItem != nil) {
        [[NSStatusBar systemStatusBar] removeStatusItem:pStatusItem]; // remove cleanly from status bar
        [pStatusItem release];
        pStatusItem = nil;
    }
}

- (BOOL)showingStatusItem {
    return (pStatusItem != nil);
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    [self createMenuForScriptOutput];
}

- (void)createMenuForScriptOutput {
    
    [pStatusItemMenu removeAllItems];
    
    NSTask *task = [platypusController taskForCurrentScript];
    if (task == nil) {
        NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"Your script output here" action:nil keyEquivalent:@""] autorelease];
        [pStatusItemMenu insertItem:menuItem atIndex:0];
        return;
    }
    
    // direct output to file handle and start monitoring it if script provides feedback
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    [task setStandardError:outputPipe];
    NSFileHandle *readHandle = [outputPipe fileHandleForReading];
    
    // set it off
    [task launch];
    [task waitUntilExit];
    
    // get output as string
    NSData *outputData = [readHandle readDataToEndOfFile];
    NSString *outputString = [[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];
    
    // create one menu item per line of output
    NSArray *lines = [outputString componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        // ignore empty lines of output
        if ([line isEqualToString:@""]) {
            continue;
        }
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:line action:@selector(statusMenuItemSelected) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setEnabled:YES];
        [pStatusItemMenu addItem:menuItem];
        [menuItem release];
    }
    if ([pStatusItemMenu numberOfItems] == 0) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"No output" action:nil keyEquivalent:@""];
        [menuItem setEnabled:NO];
        [pStatusItemMenu addItem:menuItem];
        [menuItem release];
    }
}

- (void)statusMenuItemSelected {
    
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    return YES;
}

#pragma mark -

- (NSString *)title {
    return [titleTextField stringValue];
}

- (void)setTitle:(NSString *)title {
    [titleTextField setStringValue:title];
}

#pragma mark -

- (NSImage *)icon {
    return [iconImageView image];
}

- (void)setIcon:(NSImage *)img {
    NSSize originalSize = [img size];
    
    // http://alastairs-place.net/blog/2013/07/23/nsstatusitem-what-size-should-your-icon-be/
    
    if ((originalSize.width == 18 && originalSize.height == 18) || (originalSize.width == 36 && originalSize.height == 36)) {
        [iconImageView setImage:img];
    } else {
        
        // if the selected image isn't in dimensions 18x18, we scale it to that size
        // and draw the image we're handed into a 18x18 bitmap
        NSImage *resizedImage = [[[NSImage alloc] initWithSize:NSMakeSize(36, 36)] autorelease];
        [resizedImage lockFocus];
        [img drawInRect:NSMakeRect(0, 0, 36, 36) fromRect:NSMakeRect(0, 0, originalSize.width, originalSize.height) operation:NSCompositeSourceOver fraction:1.0];
        [resizedImage unlockFocus];
        
        [iconImageView setImage:resizedImage];
    }
}

#pragma mark -

- (void)setUsesSystemFont:(BOOL)useSysFont {
    [useSystemFontCheckbox setIntValue:useSysFont];
}

- (BOOL)usesSystemFont {
    return [useSystemFontCheckbox intValue];
}

@end
