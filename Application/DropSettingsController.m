/*
 Copyright (c) 2003-2018, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
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
#import "UriSchemesListController.h"

@interface DropSettingsController()
{
    IBOutlet NSButton *acceptDroppedFilesCheckbox;
    IBOutlet NSBox *droppedFilesSettingsBox;

    IBOutlet NSBox *suffixListBox;
    IBOutlet NSButton *addSuffixButton;
    IBOutlet NSButton *removeSuffixButton;
    IBOutlet NSResponderNotifyingTableView *suffixListTableView;
    
    IBOutlet NSBox *utiListBox;
    IBOutlet NSButton *addUTIButton;
    IBOutlet NSButton *removeUTIButton;
    IBOutlet NSResponderNotifyingTableView *uniformTypeListTableView;
    
    IBOutlet NSButton *promptForFileOnLaunchCheckbox;
    
    IBOutlet NSImageView *docIconImageView;
    IBOutlet NSButton *selectDocumentIconButton;

    IBOutlet NSButton *acceptDroppedTextCheckbox;
    IBOutlet NSButton *declareServiceCheckbox;
    
    IBOutlet NSButton *uriSchemesListCheckbox;
    
    IBOutlet NSBox *uriSchemesListBox;
    IBOutlet NSButton *addUriSchemesButton;
    IBOutlet NSButton *removeUriSchemesButton;
    IBOutlet NSResponderNotifyingTableView *uriSchemesListTableView;
    
    IBOutlet NSTextField *errorTextField;
    
    IBOutlet NSButton *droppableEnabledCheckbox;

    NSString *docIconPath;
    
    SuffixTypeListController *suffixListController;
    UniformTypeListController *uniformTypeListController;
    
    UriSchemesListController *uriSchemesListController;
}

- (IBAction)addSuffix:(id)sender;
- (IBAction)addUTI:(id)sender;
- (IBAction)addURIProtocol:(id)sender;
- (IBAction)removeListItem:(id)sender;
- (IBAction)registerAsURIHandlerClicked:(id)sender;
- (IBAction)openDropSettingsSheet:(id)sender;
- (IBAction)closeDropSettingsSheet:(id)sender;
- (IBAction)selectDocIcon:(id)sender;
- (IBAction)acceptsFilesChanged:(id)sender;
- (IBAction)acceptsTextChanged:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)showHelpForUTIs:(id)sender;

@end

@implementation DropSettingsController

- (instancetype)init {
    if (self = [super init]) {
        suffixListController = [[SuffixTypeListController alloc] init];
        uniformTypeListController = [[UniformTypeListController alloc] init];
        uriSchemesListController = [[UriSchemesListController alloc] init];
    }
    return self;
}

#pragma mark -

- (void)awakeFromNib {
    [suffixListTableView registerForDraggedTypes:@[NSFilenamesPboardType]];
    [uniformTypeListTableView registerForDraggedTypes:@[NSFilenamesPboardType]];
}

- (IBAction)openDropSettingsSheet:(id)sender {
    NSWindow *parentWindow = [droppableEnabledCheckbox window];
    [parentWindow setTitle:[NSString stringWithFormat:@"%@ - Drop Settings", PROGRAM_NAME]];
    
    //do setup
    [suffixListTableView setDataSource:suffixListController];
    [suffixListTableView reloadData];
    [suffixListTableView setDelegate:self];
    [suffixListTableView setTarget:self];
    
    [uniformTypeListTableView setDataSource:uniformTypeListController];
    [uniformTypeListTableView reloadData];
    [uniformTypeListTableView setDelegate:self];
    [uniformTypeListTableView setTarget:self];
    
    [uriSchemesListTableView setDataSource:uriSchemesListController];
    [uriSchemesListTableView reloadData];
    [uriSchemesListTableView setDelegate:self];
    [uriSchemesListTableView setTarget:self];
    
    [errorTextField setStringValue:@""];
    [self updateButtonStatus];
    
    [self setSuffixListEnabled:([uniformTypeListController itemCount] == 0)];
    
    //open window
    [NSApp beginSheet:[self window]
       modalForWindow:parentWindow
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
    
    [NSApp runModalForWindow:[self window]];
    
    [NSApp endSheet:[self window]];
    [[self window] orderOut:self];
}

- (IBAction)closeDropSettingsSheet:(id)sender {
    //make sure suffix list contains valid values
    if ([suffixListController itemCount] == 0 && [uniformTypeListController itemCount] == 0 && [self acceptsFiles]) {
        [errorTextField setStringValue:@"Either suffix or UTI list must contain at least one entry."];
        return;
    }
    
    // end drop settings sheet
    [[droppableEnabledCheckbox window] setTitle:PROGRAM_NAME];
    [NSApp stopModal];
    [NSApp endSheet:[self window]];
    [[self window] orderOut:self];
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
    [[self window] makeFirstResponder:suffixListTableView];
    [suffixListController addNewItem];
    [suffixListTableView reloadData];
    [suffixListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[suffixListController itemCount] - 1] byExtendingSelection:NO];
}

- (IBAction)addUTI:(id)sender {
    [[self window] makeFirstResponder:uniformTypeListTableView];
    [uniformTypeListController addNewItem];
    [uniformTypeListTableView reloadData];
    [uniformTypeListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[uniformTypeListController itemCount] - 1] byExtendingSelection:NO];
    [self setSuffixListEnabled:NO];
}

- (IBAction)addURIProtocol:(id)sender {
    [[self window] makeFirstResponder:uriSchemesListTableView];
    [uriSchemesListController addNewItem];
    [uriSchemesListTableView reloadData];
    [uriSchemesListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[uriSchemesListController itemCount] - 1] byExtendingSelection:NO];
}

- (IBAction)removeListItem:(id)sender {
    NSTableView *tableView;
    TypeListController *typeListController;
    
    id firstResponder = [[self window] firstResponder];

    if (firstResponder == suffixListTableView) {
        tableView = suffixListTableView;
        typeListController = suffixListController;
    } else if (firstResponder == uniformTypeListTableView) {
        tableView = uniformTypeListTableView;
        typeListController = uniformTypeListController;
    } else if (firstResponder == uriSchemesListTableView) {
        tableView = uriSchemesListTableView;
        typeListController = uriSchemesListController;
    } else {
        return;
    }
    
    NSInteger selectedIndex = [tableView selectedRow];
    if (selectedIndex >= 0) {
        [typeListController removeItemAtIndex:selectedIndex];

        NSInteger rowToSelect = selectedIndex - 1;
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowToSelect] byExtendingSelection:NO];
        
        [tableView reloadData];
        [self setSuffixListEnabled:([uniformTypeListController itemCount] == 0)];
    }
}

#pragma mark -

- (IBAction)setToDefaults:(id)sender {
    [suffixListController removeAllItems];
    [suffixListController addItems:DEFAULT_SUFFIXES];
    [suffixListTableView reloadData];
    
    [uniformTypeListController removeAllItems];
    [uniformTypeListController addItems:DEFAULT_UTIS];
    [uniformTypeListTableView reloadData];
    
    [uriSchemesListCheckbox setState:0];
    
    [uriSchemesListController removeAllItems];
    [uriSchemesListController addItems:DEFAULT_URI_PROTOCOLS];
    [uriSchemesListTableView reloadData];
    
    [self setDocIconPath:@""];
    [self setAcceptsText:NO];
    [self setAcceptsFiles:NO];
    [self setDeclareService:NO];
    [self setPromptsForFileOnLaunch:NO];
    [self setSuffixListEnabled:([uniformTypeListController itemCount] == 0)];
}

- (void)setSuffixListEnabled:(BOOL)enabled {
    [suffixListTableView setEnabled:enabled];
    [addSuffixButton setEnabled:enabled];
    [suffixListBox setAlphaValue:0.5 + (enabled * 0.5)];
    [self updateButtonStatus];
    if (enabled == NO) {
        [suffixListTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self updateButtonStatus];
}

- (void)tableViewDidBecomeFirstResponder:(id)sender {
    [self updateButtonStatus];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 20;
}

- (void)updateButtonStatus {
    [removeSuffixButton setEnabled:
        ([[suffixListTableView selectedRowIndexes] count] && [suffixListTableView selectedRow] >= 0) &&
        [[self window] firstResponder] == suffixListTableView
     ];
    [removeUTIButton setEnabled:
        ([[uniformTypeListTableView selectedRowIndexes] count] && [uniformTypeListTableView selectedRow] >= 0) &&
        [[self window] firstResponder] == uniformTypeListTableView
     ];
    
    [removeUriSchemesButton setEnabled:
     ([[uriSchemesListTableView selectedRowIndexes] count] && [uriSchemesListTableView selectedRow] >= 0) &&
     [[self window] firstResponder] == uriSchemesListTableView
     ];
    
    [addSuffixButton setEnabled:[uniformTypeListController itemCount] == 0];
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
    [suffixListTableView setEnabled:enabled]; // INCRIMINATING LINE
//
    [addUTIButton setEnabled:enabled];
    [removeUTIButton setEnabled:enabled];
    [uniformTypeListTableView setEnabled:enabled];
    
    [self updateButtonStatus];
    [self setSuffixListEnabled:([uniformTypeListController itemCount] == 0)];
    
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

- (IBAction)registerAsURIHandlerClicked:(id)sender {
    if ([sender intValue] == 0) {
        [uriSchemesListController removeAllItems];
        [uriSchemesListTableView reloadData];
    }
    [uriSchemesListTableView setEnabled:[sender intValue]];
    [addUriSchemesButton setEnabled:[sender intValue]];
}

#pragma mark -

- (NSArray OF_NSSTRING *)suffixList {
    return [suffixListController itemsArray];
}

- (void)setSuffixList:(NSArray OF_NSSTRING *)suffixList {
    [suffixListController removeAllItems]; // BLAME!
    [suffixListController addItems:suffixList];
}

- (NSArray OF_NSSTRING *)uniformTypesList {
    return [uniformTypeListController itemsArray];
}

- (void)setUniformTypesList:(NSArray OF_NSSTRING *)uniformTypesList {
    [uniformTypeListController removeAllItems];
    [uniformTypeListController addItems:uniformTypesList];
}

- (NSArray OF_NSSTRING *)uriSchemesList {
    return [uriSchemesListController itemsArray];
}

- (void)setUriSchemesList:(NSArray OF_NSSTRING *)items {
    [uriSchemesListController removeAllItems];
    [uriSchemesListController addItems:items];
    [uriSchemesListCheckbox setState:([items count] > 0)];
    [self registerAsURIHandlerClicked:uriSchemesListCheckbox];
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

- (IBAction)showHelpForUTIs:(id)sender {
    [WORKSPACE openURL:[NSURL URLWithString:PROGRAM_UTI_INFORMATION_URL]];
}

@end
