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
    IBOutlet NSWindow *window;
    IBOutlet NSWindow *statusItemSettingsWindow;
    IBOutlet NSPopUpButton *statusItemStylePopupButton;
    IBOutlet NSImageView *iconImageView;
    IBOutlet NSButton *selectIconButton;
    IBOutlet NSTextField *titleTextField;
    IBOutlet NSTextField *titleLabelTextField;
    IBOutlet NSTextField *iconLabelTextField;
    IBOutlet NSButton *useSystemFontCheckbox;
    IBOutlet NSButton *isTemplateCheckbox;
    IBOutlet PlatypusController *platypusController;
    
    NSStatusItem *previewStatusItem;
    NSMenu *previewStatusItemMenu;
}

- (IBAction)show:(id)sender;
- (IBAction)apply:(id)sender;
- (IBAction)statusItemDisplayTypeChanged:(id)sender;
- (IBAction)selectStatusItemIcon:(id)sender;
- (IBAction)previewStatusItem:(id)sender;
- (IBAction)useAsTemplateChanged:(id)sender;

@end

@implementation StatusItemSettingsController

- (IBAction)show:(id)sender {
    [window setTitle:[NSString stringWithFormat:@"%@ - Status Item Settings", PROGRAM_NAME]];
    
    [NSApp beginSheet:statusItemSettingsWindow
       modalForWindow:window
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
    
    [NSApp runModalForWindow:statusItemSettingsWindow];
}

- (IBAction)apply:(id)sender {
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
    [isTemplateCheckbox setIntValue:TRUE];
}

- (IBAction)statusItemDisplayTypeChanged:(id)sender {
    BOOL isTitleStyle = ([sender indexOfSelectedItem] == PLATYPUS_STATUS_ITEM_STYLE_TITLE);
    
    [iconLabelTextField setHidden:isTitleStyle];
    [iconImageView setHidden:isTitleStyle];
    [selectIconButton setHidden:isTitleStyle];
    [isTemplateCheckbox setHidden:isTitleStyle];
    
    [titleLabelTextField setHidden:!isTitleStyle];
    [titleTextField setHidden:!isTitleStyle];
    
    if (previewStatusItem != nil) {
        [self previewStatusItem:self];
    }
}

- (IBAction)selectStatusItemIcon:(id)sender {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setAllowedFileTypes:[NSImage imageTypes]];
    if ([oPanel runModal] != NSOKButton) {
        return;
    }
    
    NSString *filePath = [[oPanel URLs][0] path];
    NSImage *img = [[NSImage alloc] initWithContentsOfFile:filePath];
    if (img != nil) {
        [self setIcon:img];
        if (previewStatusItem != nil) {
            [self previewStatusItem:self];
        }
    } else {
        [Alerts alert:@"Corrupt Image File"
              subText:@"The image file you selected appears to be damaged or corrupt."];
        [self killStatusItem];
    }
}

- (IBAction)useAsTemplateChanged:(id)sender {
    if (previewStatusItem != nil) {
        [self previewStatusItem:self];
    }
}

#pragma mark - Preview Status Item

- (IBAction)previewStatusItem:(id)sender {
    [self killStatusItem];
    
    // create status item
    previewStatusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [previewStatusItem setHighlightMode:YES];
    [previewStatusItem setMenu:previewStatusItemMenu];
    
    // set icon / title depending on settings
    PlatypusStatusItemStyle displayStyle = [statusItemStylePopupButton indexOfSelectedItem];
    if (displayStyle == PLATYPUS_STATUS_ITEM_STYLE_TITLE) {
        [previewStatusItem setTitle:[titleTextField stringValue]];
    }
    else if (displayStyle == PLATYPUS_STATUS_ITEM_STYLE_ICON) {
        NSImage *img = [iconImageView image];
        NSSize imgSize = [img size];
        CGFloat rel = 18/imgSize.height;
        NSSize finalSize = NSMakeSize(imgSize.width * rel, imgSize.height * rel);
        [img setSize:finalSize];
        [previewStatusItem setImage:[img copy]];
    }
    else {
        PLog(@"Unknown status item style: %d", displayStyle);
    }
    
    [[previewStatusItem image] setTemplate:[isTemplateCheckbox intValue]];
    
    // create menu
    previewStatusItemMenu = [[NSMenu alloc] initWithTitle:@""];
    [previewStatusItemMenu setDelegate:self];
    [previewStatusItemMenu setAutoenablesItems:NO];
    [previewStatusItem setEnabled:YES];
    [previewStatusItem setMenu:previewStatusItemMenu];
}

- (void)killStatusItem {
    [[NSStatusBar systemStatusBar] removeStatusItem:previewStatusItem];
    previewStatusItem = nil;
}

- (BOOL)showingStatusItem {
    return (previewStatusItem != nil);
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    [self createMenuForScriptOutput];
}

- (void)createMenuForScriptOutput {
    [previewStatusItemMenu removeAllItems];
    
    NSTask *task = [platypusController taskForCurrentScript];
    if (task == nil) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Your script output here" action:nil keyEquivalent:@""];
        [previewStatusItemMenu insertItem:menuItem atIndex:0];
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
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
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
        [previewStatusItemMenu addItem:menuItem];
    }
    if ([previewStatusItemMenu numberOfItems] == 0) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"No output" action:nil keyEquivalent:@""];
        [menuItem setEnabled:NO];
        [previewStatusItemMenu addItem:menuItem];
    }
}

- (void)statusMenuItemSelected {
    
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    return YES;
}

#pragma mark - Setters/Getters

- (NSString *)title {
    return [titleTextField stringValue];
}

- (void)setTitle:(NSString *)title {
    [titleTextField setStringValue:title];
}

- (void)setDisplayType:(NSString *)name {
    [statusItemStylePopupButton selectItemWithTitle:name];
    [self statusItemDisplayTypeChanged:statusItemStylePopupButton];
}

- (NSString *)displayType {
    return [statusItemStylePopupButton titleOfSelectedItem];
}

- (NSImage *)icon {
    return [iconImageView image];
}

- (void)setIcon:(NSImage *)img {
    [iconImageView setImage:img];
}

- (void)setUsesSystemFont:(BOOL)useSysFont {
    [useSystemFontCheckbox setIntValue:useSysFont];
}

- (BOOL)usesSystemFont {
    return [useSystemFontCheckbox intValue];
}

- (void)setUsesTemplateIcon:(BOOL)useTemplate {
    [isTemplateCheckbox setIntValue:useTemplate];
}

- (BOOL)usesTemplateIcon {
    return [isTemplateCheckbox intValue];
}

@end
