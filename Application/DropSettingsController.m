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

#import "DropSettingsController.h"
#import "Common.h"

@implementation DropSettingsController

- (id)init {
    if ((self = [super init])) {
        suffixListController = [[SuffixListController alloc] init];
        uniformTypeListController = [[UniformTypeListController alloc] init];
    }
    return self;
}

- (void)dealloc {
    [suffixListController release];
    [uniformTypeListController release];
    [super dealloc];
}

#pragma mark -

- (void)awakeFromNib {
    [suffixListTableView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [uniformTypeListTableView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

/*****************************************
 - Display the Drop Settings Window as a sheet
 *****************************************/

- (IBAction)openDropSettingsSheet:(id)sender {
    [window setTitle:[NSString stringWithFormat:@"%@ - Drop settings", PROGRAM_NAME]];
    
    //do setup
    [suffixTextField setStringValue:@""];
    [suffixListTableView setDataSource:suffixListController];
    [suffixListTableView reloadData];
    [suffixListTableView setDelegate:self];
    [suffixListTableView setTarget:self];
    
    [uniformTypeTextField setStringValue:@""];
    [uniformTypeListTableView setDataSource:uniformTypeListController];
    [uniformTypeListTableView reloadData];
    [uniformTypeListTableView setDelegate:self];
    [uniformTypeListTableView setTarget:self];
    
    [typesErrorTextField setStringValue:@""];
    
    //open window
    [NSApp  beginSheet:dropSettingsWindow
        modalForWindow:window
         modalDelegate:nil
        didEndSelector:nil
           contextInfo:nil];
    
    [NSApp runModalForWindow:dropSettingsWindow];
    
    [NSApp endSheet:dropSettingsWindow];
    [dropSettingsWindow orderOut:self];
}

- (IBAction)closeDropSettingsSheet:(id)sender {
    //make sure suffix list contains valid values
    if (![suffixListController numItems] && [self acceptsFiles]) {
        [typesErrorTextField setStringValue:@"The suffix list must contain at least one entry."];
        return;
    }
    
    // end drop settings sheet
    [window setTitle:PROGRAM_NAME];
    [NSApp stopModal];
    [NSApp endSheet:dropSettingsWindow];
    [dropSettingsWindow orderOut:self];
}

#pragma mark -

- (IBAction)selectDocIcon:(id)sender {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setPrompt:@"Select"];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setTitle:@"Select an icns file"];
    [oPanel setAllowedFileTypes:[NSArray arrayWithObject:@"icns"]];
    
    if ([oPanel runModal] == NSOKButton) {
        NSString *filename = [[[oPanel URLs] objectAtIndex:0] path];
        [self setDocIconPath:filename];
    }
}

#pragma mark -

- (IBAction)addSuffix:(id)sender {
    
    NSString *theSuffix = [suffixTextField stringValue];
    if ([suffixListController hasItem:theSuffix] || [theSuffix length] == 0) {
        [suffixTextField setStringValue:@""];
        return;
    }
    
    //if the user put in a suffix beginning with a '.', we trim the string to start from index 1
    if ([theSuffix characterAtIndex:0] == '.') {
        theSuffix = [theSuffix substringFromIndex:1];
    }
    
    [suffixListController addItem:theSuffix];
    [suffixTextField setStringValue:@""];
    [self controlTextDidChange];
    [suffixListTableView reloadData];
}

- (IBAction)removeSuffix:(id)sender
{
    NSIndexSet *selectedItems = [suffixListTableView selectedRowIndexes];
    for (int i = [suffixListController numItems]; i >= 0; i--) {
        if ([selectedItems containsIndex:i]) {
            [suffixListController removeItem:i];
            [suffixListTableView reloadData];
            break;
        }
    }
}

- (IBAction)addUTI:(id)sender {
    
    NSString *theUTI = [uniformTypeTextField stringValue];
    
    if ([uniformTypeListController hasItem:theUTI] || [theUTI length] == 0) {
        [uniformTypeTextField setStringValue:@""];
        return;
    }
    
    [uniformTypeListController addItem:theUTI];
    [uniformTypeTextField setStringValue:@""];
    [self controlTextDidChange];
    [uniformTypeListTableView reloadData];
}

- (IBAction)removeUTI:(id)sender {
    
    NSIndexSet *selectedItems = [uniformTypeListTableView selectedRowIndexes];
    for (int i = [uniformTypeListController numItems]; i >= 0; i--) {
        if ([selectedItems containsIndex:i]) {
            [uniformTypeListController removeItem:i];
            [uniformTypeListTableView reloadData];
            break;
        }
    }
}

#pragma mark -

/*****************************************
 - called when "Default" button is pressed in Types List
 *****************************************/

- (IBAction)setToDefaults:(id)sender {
    [suffixListController removeAllItems];
    [suffixListController addItem:@"*"];
    [suffixListTableView reloadData];
    
    [uniformTypeListController removeAllItems];
    [uniformTypeListTableView reloadData];
    
    [self setDocIconPath:@""];
    [self setAcceptsText:NO];
    [self setAcceptsFiles:YES];
    [self setDeclareService:NO];
    [self setPromptsForFileOnLaunch:NO];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    
    if (aNotification == nil || [aNotification object] == suffixListTableView || [aNotification object] == nil) {
        
        int selected = 0;
        NSIndexSet *selectedItems = [suffixListTableView selectedRowIndexes];
        
        for (int i = 0; i < [suffixListController numItems]; i++) {
            if ([selectedItems containsIndex:i]) {
                selected++;
            }
        }
        [removeSuffixButton setEnabled:(selected != 0)];
    }
    
    if (aNotification == nil || [aNotification object] == uniformTypeListTableView || [aNotification object] == nil) {
        
        int selected = 0;
        NSIndexSet *selectedItems = [uniformTypeListTableView selectedRowIndexes];
        
        for (int i = 0; i < [uniformTypeListController numItems]; i++) {
            if ([selectedItems containsIndex:i]) {
                selected++;
            }
        }
        [removeUTIButton setEnabled:(selected != 0)];
    }
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
    [self controlTextDidChange];
}

- (void)controlTextDidChange {
    //enable/disable buttons for Edit Types window
    [addSuffixButton setEnabled:([[suffixTextField stringValue] length] > 0)];
    [addUTIButton setEnabled:([[uniformTypeTextField stringValue] length] > 0)];

}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    
    if ([[item title] isEqualToString:@"Remove Suffix"] && [suffixListTableView selectedRow] == -1) {
        return NO;
    }
    
    if ([[item title] isEqualToString:@"Remove Uniform Type"] && [uniformTypeListTableView selectedRow] == -1) {
        return NO;
    }
    
    if ([[item title] isEqualToString:@"Edit Drop Settings..."]) {
        return [droppableEnabledCheckbox intValue];
    }
    
    return YES;
}

#pragma mark -

- (void)setAcceptsFilesControlsEnabled:(BOOL)enabled {
    [[droppedFilesSettingsBox contentView] setAlphaValue:0.5 + (enabled * 0.5)];
    
    [addSuffixButton setEnabled:enabled];
    [removeSuffixButton setEnabled:enabled];
    [suffixListTableView setEnabled:enabled];
    [suffixTextField setEnabled:enabled];
    
    [addUTIButton setEnabled:enabled];
    [removeUTIButton setEnabled:enabled];
    [uniformTypeListTableView setEnabled:enabled];
    [uniformTypeTextField setEnabled:enabled];
    
    [promptForFileOnLaunchCheckbox setEnabled:enabled];
    [selectDocumentIconButton setEnabled:enabled];
}

- (void)setAcceptsTextControlsEnabled:(BOOL)enabled {
    [declareServiceCheckbox setEnabled:enabled];
}

- (IBAction)acceptsFilesChanged:(id)sender {
    [self setAcceptsFilesControlsEnabled:[sender intValue]];
}

- (IBAction)acceptsTextChanged:(id)sender {
    [self setAcceptsTextControlsEnabled:[sender intValue]];
}

#pragma mark -

- (SuffixListController *)suffixListController {
    return suffixListController;
}

- (UniformTypeListController *)uniformTypesListController {
    return uniformTypeListController;
}

#pragma mark -

- (UInt64)docIconSize;
{
    if ([FILEMGR fileExistsAtPath:docIconPath]) {
        return [PlatypusUtility fileOrFolderSize:docIconPath];
    }
    return 0;
}

#pragma mark -

- (BOOL)acceptsText {
    return [acceptDroppedTextCheckbox intValue];
}

- (void)setAcceptsText:(BOOL)b {
    [self setAcceptsTextControlsEnabled:b];
    [acceptDroppedTextCheckbox setIntValue:b];
}

- (BOOL)acceptsFiles {
    return [acceptDroppedFilesCheckbox intValue];
}

- (void)setAcceptsFiles:(BOOL)b {
    [self setAcceptsFilesControlsEnabled:b];
    [acceptDroppedFilesCheckbox setIntValue:b];
}

- (BOOL)declareService {
    return [declareServiceCheckbox intValue];
}

- (void)setDeclareService:(BOOL)b {
    [declareServiceCheckbox setIntValue:b];
}

- (BOOL)promptsForFileOnLaunch {
    return [promptForFileOnLaunchCheckbox intValue];
}

- (void)setPromptsForFileOnLaunch:(BOOL)b {
    [promptForFileOnLaunchCheckbox setIntValue:b];
}

- (NSString *)docIconPath {
    return docIconPath;
}

- (void)setDocIconPath:(NSString *)path {
    if (docIconPath) {
        [docIconPath release];
    }
    docIconPath = [path retain];
    
    NSImage *icon;
    if (path == nil || [path isEqualToString:@""]) {
        icon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericDocumentIcon)];
    } else {
        icon = [[[NSImage alloc] initWithContentsOfFile:docIconPath] autorelease];
    }
    
    [docIconImageView setImage:icon];
}

#pragma mark -

// Open Documentation.html file within app bundle
- (IBAction)showHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:PROGRAM_DOCUMENTATION_DROP_SETTINGS_URL]];
}

@end
