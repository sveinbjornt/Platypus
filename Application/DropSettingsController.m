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
        suffixList = [[SuffixList alloc] init];
    }
    return self;
}

- (void)dealloc {
    [suffixList release];
    [super dealloc];
}

#pragma mark -

- (void)awakeFromNib {
    [suffixListDataBrowser registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

/*****************************************
 - Display the Drop Settings Window as a sheet
 *****************************************/

- (IBAction)openDropSettingsSheet:(id)sender {
    [window setTitle:[NSString stringWithFormat:@"%@ - Drop settings", PROGRAM_NAME]];
    //clear text fields from last time
    [suffixTextField setStringValue:@""];
    
    [suffixListDataBrowser setDataSource:suffixList];
    [suffixListDataBrowser reloadData];
    [suffixListDataBrowser setDelegate:self];
    [suffixListDataBrowser setTarget:self];
    
    // updated text fields reporting no. suffixes and no. file type codes
    if ([suffixList hasAllSuffixes])
        [numSuffixesTextField setStringValue:@"All suffixes"];
    else
        [numSuffixesTextField setStringValue:[NSString stringWithFormat:@"%d suffixes", [suffixList numSuffixes]]];
    
    // clear any error message
    [typesErrorTextField setStringValue:@""];
    
    //open window
    [NSApp  beginSheet:typesWindow
        modalForWindow:window
         modalDelegate:nil
        didEndSelector:nil
           contextInfo:nil];
    
    [NSApp runModalForWindow:typesWindow];
    
    [NSApp endSheet:typesWindow];
    [typesWindow orderOut:self];
}

- (IBAction)closeDropSettingsSheet:(id)sender {
    //make sure suffix list contains valid values
    if (![suffixList numSuffixes] && [self acceptsFiles]) {
        [typesErrorTextField setStringValue:@"The suffix list must contain at least one entry."];
        return;
    }
    
    // end drop settings sheet
    [window setTitle:PROGRAM_NAME];
    [NSApp stopModal];
    [NSApp endSheet:typesWindow];
    [typesWindow orderOut:self];
}

#pragma mark -

//create open panel


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

/*****************************************
 - called when [+] button is pressed in Types List
 *****************************************/

- (IBAction)addSuffix:(id)sender;
{
    NSString *theSuffix = [suffixTextField stringValue];
    
    if ([suffixList hasSuffix:theSuffix] || ([theSuffix length] == 0))
        return;
    
    //if the user put in a suffix beginning with a '.', we trim the string to start from index 1
    if ([theSuffix characterAtIndex:0] == '.')
        theSuffix = [theSuffix substringFromIndex:1];
    
    [suffixList addSuffix:theSuffix];
    [suffixTextField setStringValue:@""];
    [self controlTextDidChange:NULL];
    
    //update
    [suffixListDataBrowser reloadData];
    
    if ([suffixList hasAllSuffixes])
        [numSuffixesTextField setStringValue:@"All suffixes"];
    else
        [numSuffixesTextField setStringValue:[NSString stringWithFormat:@"%d suffixes", [suffixList numSuffixes]]];
}


/*****************************************
 - called when [C] button is pressed in Types List
 *****************************************/

- (IBAction)clearSuffixList:(id)sender {
    [suffixList clearList];
    [suffixListDataBrowser reloadData];
    [numSuffixesTextField setStringValue:[NSString stringWithFormat:@"%d suffixes", [suffixList numSuffixes]]];
}

/*****************************************
 - called when [-] button is pressed in Types List
 *****************************************/

- (IBAction)removeSuffix:(id)sender;
{
    int i;
    NSIndexSet *selectedItems = [suffixListDataBrowser selectedRowIndexes];
    
    for (i = [suffixList numSuffixes]; i >= 0; i--) {
        if ([selectedItems containsIndex:i]) {
            [suffixList removeSuffix:i];
            [suffixListDataBrowser reloadData];
            break;
        }
    }
    
    if ([suffixList hasAllSuffixes])
        [numSuffixesTextField setStringValue:@"All suffixes"];
    else
        [numSuffixesTextField setStringValue:[NSString stringWithFormat:@"%d suffixes", [suffixList numSuffixes]]];
}

/*****************************************
 - called when "Default" button is pressed in Types List
 *****************************************/

- (IBAction)setToDefaults:(id)sender {
    //default suffixes
    [suffixList clearList];
    [suffixList addSuffix:@"*"];
    [suffixListDataBrowser reloadData];
    
    if ([suffixList hasAllSuffixes])
        [numSuffixesTextField setStringValue:@"All suffixes"];
    else
        [numSuffixesTextField setStringValue:[NSString stringWithFormat:@"%d suffixes", [suffixList numSuffixes]]];
    
    //set app function to default
    [appFunctionRadioButtons selectCellWithTag:0];
    
    [self setDocIconPath:@""];
    [self setAcceptsText:NO];
    [self setAcceptsFiles:YES];
    [self setDeclareService:NO];
    [self setPromptsForFileOnLaunch:NO];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    int i;
    int selected = 0;
    NSIndexSet *selectedItems;
    
    if ([aNotification object] == suffixListDataBrowser || [aNotification object] == NULL) {
        selectedItems = [suffixListDataBrowser selectedRowIndexes];
        for (i = 0; i < [suffixList numSuffixes]; i++)
            if ([selectedItems containsIndex:i])
                selected++;
        
        [removeSuffixButton setEnabled:(selected != 0)];
    }
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
    //enable/disable buttons for Edit Types window
    [addSuffixButton setEnabled:([[suffixTextField stringValue] length] > 0)];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    if ([[anItem title] isEqualToString:@"Remove Suffix"] && [suffixListDataBrowser selectedRow] == -1)
        return NO;
    
    if ([[anItem title] isEqualToString:@"Edit Drop Settings..."])
        return YES;
    
    return YES;
}

#pragma mark -

- (void)setAcceptsFilesControlsEnabled:(BOOL)enabled {
    [[droppedFilesSettingsBox contentView] setAlphaValue:0.5 + (enabled * 0.5)];
    [appFunctionRadioButtons setEnabled:enabled];
    [addSuffixButton setEnabled:enabled];
    [numSuffixesTextField setEnabled:enabled];
    [removeSuffixButton setEnabled:enabled];
    [suffixListDataBrowser setEnabled:enabled];
    [suffixTextField setEnabled:enabled];
    [promptForFileOnLaunchCheckbox setEnabled:enabled];
    [selectDocumentIconButton setEnabled:enabled];
}

- (void)setAcceptsTextControlsEnabled:(BOOL)enabled {
    [declareServiceCheckbox setEnabled:enabled];
}

- (IBAction)acceptsFilesChanged:(id)sender {
    [self setAcceptsFilesControlsEnabled:[sender boolValue]];
}

- (IBAction)acceptsTextChanged:(id)sender {
    [self setAcceptsTextControlsEnabled:[sender boolValue]];
}

#pragma mark -

- (SuffixList *)suffixes {
    return suffixList;
}

- (UInt64)docIconSize;
{
    if ([FILEMGR fileExistsAtPath:docIconPath])
        return [PlatypusUtility fileOrFolderSize:docIconPath];
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

- (NSString *)role {
    return [[appFunctionRadioButtons selectedCell] title];
}

- (void)setRole:(NSString *)role {
    if ([role isEqualToString:@"Viewer"])
        [appFunctionRadioButtons selectCellWithTag:0];
    else
        [appFunctionRadioButtons selectCellWithTag:1];
}

- (NSString *)docIconPath {
    return docIconPath;
}

- (void)setDocIconPath:(NSString *)path {
    [docIconPath release];
    docIconPath = [path retain];
    
    //set document icon to default
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericDocumentIcon)];
    
    if (![path isEqualToString:@""])  // load it from file if it's a path
        icon = [[[NSImage alloc] initWithContentsOfFile:docIconPath] autorelease];
    
    if (icon != nil)
        [docIconImageView setImage:icon];
}

@end
