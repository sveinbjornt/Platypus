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
#import "SuffixTypeListController.h"
#import "NSWorkspace+Additions.h"
#import "UniformTypeListController.h"

@interface DropSettingsController()
{
    IBOutlet NSWindow *dropSettingsWindow;
    IBOutlet NSWindow *window;
    
    IBOutlet NSButton *acceptDroppedFilesCheckbox;
    IBOutlet NSBox *droppedFilesSettingsBox;

    IBOutlet NSBox *suffixListBox;
    IBOutlet NSButton *addSuffixButton;
    IBOutlet NSButton *removeSuffixButton;
    IBOutlet NSTableView *suffixListTableView;
    IBOutlet NSTextField *suffixTextField;
    
    IBOutlet NSBox *utiListBox;
    IBOutlet NSButton *addUTIButton;
    IBOutlet NSButton *removeUTIButton;
    IBOutlet NSTableView *uniformTypeListTableView;
    IBOutlet NSTextField *uniformTypeTextField;
    
    IBOutlet NSButton *promptForFileOnLaunchCheckbox;
    
    IBOutlet NSImageView *docIconImageView;
    IBOutlet NSButton *selectDocumentIconButton;

    IBOutlet NSButton *acceptDroppedTextCheckbox;
    IBOutlet NSButton *declareServiceCheckbox;
    
    IBOutlet NSTextField *errorTextField;
    
    IBOutlet NSButton *droppableEnabledCheckbox;

    NSString *docIconPath;
    
    SuffixTypeListController *suffixListController;
    UniformTypeListController *uniformTypeListController;
}

- (IBAction)addSuffix:(id)sender;
- (IBAction)addUTI:(id)sender;
- (IBAction)removeListItem:(id)sender;
- (IBAction)openDropSettingsSheet:(id)sender;
- (IBAction)closeDropSettingsSheet:(id)sender;
- (IBAction)selectDocIcon:(id)sender;
- (IBAction)acceptsFilesChanged:(id)sender;
- (IBAction)acceptsTextChanged:(id)sender;
- (IBAction)showHelp:(id)sender;

@end

@implementation DropSettingsController

- (instancetype)init {
    if ((self = [super init])) {
        suffixListController = [[SuffixTypeListController alloc] init];
        uniformTypeListController = [[UniformTypeListController alloc] init];
    }
    return self;
}

#pragma mark -

- (void)awakeFromNib {
    [suffixListTableView registerForDraggedTypes:@[NSFilenamesPboardType]];
    [uniformTypeListTableView registerForDraggedTypes:@[NSFilenamesPboardType]];
}

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
    
    [errorTextField setStringValue:@""];
    [self textInInputTextFieldDidChange];
    [self updateButtonStatus];
    
    [self setSuffixListEnabled:([uniformTypeListController itemCount] == 0)];
    
    //open window
    [NSApp beginSheet:dropSettingsWindow
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
    if ([suffixListController itemCount] == 0 && [uniformTypeListController itemCount] == 0 && [self acceptsFiles]) {
        [errorTextField setStringValue:@"Either suffix or UTI list must contain at least one entry."];
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
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setAllowedFileTypes:@[(NSString *)kUTTypeAppleICNS]];
        
    if ([oPanel runModal] == NSOKButton) {
        NSString *filename = [[oPanel URLs][0] path];
        [self setDocIconPath:filename];
    }
}

#pragma mark -

- (IBAction)addSuffix:(id)sender {
    NSString *theSuffix = [suffixTextField stringValue];
    [suffixTextField setStringValue:@""];
    
    if ([theSuffix length] == 0) {
        return;
    }
    
    //if the user put in a suffix beginning with a '.', we trim the string to start from index 1
    if ([theSuffix characterAtIndex:0] == '.') {
        theSuffix = [theSuffix substringFromIndex:1];
    }
    
    [suffixListController addItem:theSuffix];
    [self textInInputTextFieldDidChange];
    [suffixListTableView reloadData];
}

- (IBAction)addUTI:(id)sender {
    NSString *theUTI = [uniformTypeTextField stringValue];
    [uniformTypeTextField setStringValue:@""];

    if ([theUTI length] == 0) {
        return;
    }
    
    [uniformTypeListController addItem:theUTI];
    [self textInInputTextFieldDidChange];
    [uniformTypeListTableView reloadData];
    [self setSuffixListEnabled:NO];
}

- (IBAction)removeListItem:(id)sender
{
    NSTableView *tableView;
    TypeListController *typeListController;
    
    sender = [dropSettingsWindow firstResponder];

    if (sender == suffixListTableView) {
        tableView = suffixListTableView;
        typeListController = suffixListController;
    } else if (sender == uniformTypeListTableView) {
        tableView = uniformTypeListTableView;
        typeListController = uniformTypeListController;
    } else {
        return;
    }
    
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    for (int i = [typeListController itemCount]; i >= 0; i--) {
        if ([selectedItems containsIndex:i]) {
            [typeListController removeItemAtIndex:i];
            break;
        }
    }
    
    [tableView reloadData];
    [self setSuffixListEnabled:([uniformTypeListController itemCount] == 0)];
}

#pragma mark -

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
    [self setSuffixListEnabled:([uniformTypeListController itemCount] == 0)];
}

- (void)setSuffixListEnabled:(BOOL)enabled {
    [suffixListTableView setEnabled:enabled];
    [addSuffixButton setEnabled:enabled];
    [removeSuffixButton setEnabled:enabled];
    [suffixTextField setEnabled:enabled];
    [suffixListBox setAlphaValue:0.5 + (enabled * 0.5)];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self updateButtonStatus];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 20;
}

- (void)updateButtonStatus {
    [removeSuffixButton setEnabled:[[suffixListTableView selectedRowIndexes] count]];
    [removeUTIButton setEnabled:[[uniformTypeListTableView selectedRowIndexes] count]];
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
    [self textInInputTextFieldDidChange];
}

- (void)textInInputTextFieldDidChange {
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

- (NSArray *)suffixList {
    return [suffixListController itemsArray];
}

- (void)setSuffixList:(NSArray *)suffixList {
    [suffixListController removeAllItems];
    [suffixListController addItems:suffixList];
}

- (NSArray *)uniformTypesList {
    return [uniformTypeListController itemsArray];
}

- (void)setUniformTypesList:(NSArray *)uniformTypesList {
    [uniformTypeListController removeAllItems];
    [uniformTypeListController addItems:uniformTypesList];
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
    docIconPath = [path copy];
    
    NSImage *icon;
    if (path == nil || [path isEqualToString:@""]) {
        icon = [WORKSPACE iconForFileType:NSFileTypeForHFSTypeCode(kGenericDocumentIcon)];
    } else {
        icon = [[NSImage alloc] initWithContentsOfFile:docIconPath];
    }
    
    [docIconImageView setImage:icon];
}

#pragma mark -

// Open Documentation.html file within app bundle
- (IBAction)showHelp:(id)sender {
    [WORKSPACE openURL:[NSURL URLWithString:PROGRAM_DOCUMENTATION_DROP_SETTINGS_URL]];
}

@end
