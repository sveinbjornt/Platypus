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

#import "ArgsController.h"
#import "Common.h"

// Table view extension notifies delegate when it becomes first responder
@interface NSResponderNotifyingTableView : NSTableView

@end

@implementation NSResponderNotifyingTableView

-(BOOL)becomeFirstResponder {
    BOOL become = [super becomeFirstResponder];
    if (become && [self delegate] && [[self delegate] respondsToSelector:@selector(tableViewDidBecomeFirstResponder:)]) {
        [self.delegate performSelector:@selector(tableViewDidBecomeFirstResponder:) withObject:self];
    }
    return become;
}

@end

#define DEFAULT_ARG_VALUE       @"-arg"

@interface ArgsController()
{
    IBOutlet NSWindow *argsWindow;
    IBOutlet NSTextField *commandTextField;
    IBOutlet NSTextField *interpreterTextField;
    
    IBOutlet NSButton *interpreterArgsAddButton;
    IBOutlet NSButton *interpreterArgsRemoveButton;
    IBOutlet NSResponderNotifyingTableView *interpreterArgsTableView;
    
    IBOutlet NSButton *scriptArgsAddButton;
    IBOutlet NSButton *scriptArgsRemoveButton;
    IBOutlet NSResponderNotifyingTableView *scriptArgsTableView;
    
    IBOutlet NSButton *isDroppableCheckbox;
    IBOutlet NSWindow *window;
    
    IBOutlet NSMenu *scriptArgsContextualMenu;
    IBOutlet NSMenu *interpreterArgsContextualMenu;
    
    NSMutableArray *interpreterArgs;
    NSMutableArray *scriptArgs;
}

- (IBAction)addInterpreterArg:(id)sender;
- (IBAction)clearInterpreterArgs:(id)sender;
- (IBAction)addScriptArg:(id)sender;
- (IBAction)clearScriptArgs:(id)sender;
- (IBAction)removeListItem:(id)sender;
- (IBAction)apply:(id)sender;
- (IBAction)show:(id)sender;
- (IBAction)showHelp:(id)sender;

@end

@implementation ArgsController

- (instancetype)init {
    if ((self = [super init])) {
        interpreterArgs = [[NSMutableArray alloc] init];
        scriptArgs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [interpreterArgs release];
    [scriptArgs release];
    [super dealloc];
}

#pragma mark - Getters/setters

- (void)setInterpreterArgs:(NSArray *)array {
    [interpreterArgs removeAllObjects];
    [interpreterArgs addObjectsFromArray:array];
    [interpreterArgsTableView reloadData];
    [self tableViewSelectionDidChange:nil];
}

- (void)setScriptArgs:(NSArray *)array {
    [scriptArgs removeAllObjects];
    [scriptArgs addObjectsFromArray:array];
    [scriptArgsTableView reloadData];
    [self tableViewSelectionDidChange:nil];
}

- (NSArray *)interpreterArgs {
    return interpreterArgs;
}

- (NSArray *)scriptArgs {
    return scriptArgs;
}

#pragma mark -

- (IBAction)apply:(id)sender {
    [window setTitle:PROGRAM_NAME];
    [NSApp stopModal];
}

- (IBAction)setToDefaults:(id)sender {
    [self clearScriptArgs:self];
    [self clearInterpreterArgs:self];
}

- (IBAction)showHelp:(id)sender {
    [WORKSPACE openURL:[NSURL URLWithString:PROGRAM_DOCUMENTATION_ARGS_SETTINGS_URL]];
}

- (IBAction)show:(id)sender {
    [window setTitle:[NSString stringWithFormat:@"%@ - Edit Arguments", PROGRAM_NAME]];
    
    [self constructCommandString];
    
    //open window
    [NSApp  beginSheet:argsWindow
        modalForWindow:window
         modalDelegate:nil
        didEndSelector:nil
           contextInfo:nil];
    
    [NSApp runModalForWindow:argsWindow];
    
    [NSApp endSheet:argsWindow];
    [argsWindow orderOut:self];
}

- (void)constructCommandString {
    
    // interpreter
    NSMutableAttributedString *cmdString = [[NSMutableAttributedString alloc] initWithString:[interpreterTextField stringValue]];
    NSMutableDictionary *defaultAttrs = [NSMutableDictionary dictionaryWithObject:[NSColor textColor]
                                                                           forKey:NSForegroundColorAttributeName];
    
    // interpreter args
    for (int i = 0; i < [interpreterArgs count]; i++)
    {
        NSString *a = [NSString stringWithFormat:@" %@", interpreterArgs[i]];
        NSMutableDictionary *attrs = [[defaultAttrs mutableCopy] autorelease];
        
        if ([interpreterArgsTableView selectedRow] == i && interpreterArgsTableView == [argsWindow firstResponder]) {
            attrs[NSBackgroundColorAttributeName] = [NSColor selectedControlColor];
        }
        
        NSMutableAttributedString *attrStr = [[[NSMutableAttributedString alloc] initWithString:a attributes:attrs] autorelease];
        if (interpreterArgsTableView == [argsWindow firstResponder]) {
            [attrStr beginEditing];
            [attrStr addAttribute:NSFontAttributeName
                            value:[NSFont boldSystemFontOfSize:11]
                            range:NSMakeRange(0, [attrStr length])];
            [attrStr endEditing];
        }
        [cmdString appendAttributedString:attrStr];
    }
    
    // yourScript
    NSAttributedString *scriptString = [[[NSAttributedString alloc] initWithString:@" yourScript " attributes:nil] autorelease];
    [cmdString appendAttributedString:scriptString];
    
    // script args
    for (int i = 0; i < [scriptArgs count]; i++)
    {
        NSString *a = [NSString stringWithFormat:@"%@ ", scriptArgs[i]];
        NSMutableDictionary *attrs = [[defaultAttrs mutableCopy] autorelease];
        
        if ([scriptArgsTableView selectedRow] == i && scriptArgsTableView == [argsWindow firstResponder]) {
            attrs[NSBackgroundColorAttributeName] = [NSColor selectedControlColor];
        }
        
        NSMutableAttributedString *attrStr = [[[NSMutableAttributedString alloc] initWithString:a attributes:attrs] autorelease];
        if (scriptArgsTableView == [argsWindow firstResponder]) {
            [attrStr beginEditing];
            [attrStr addAttribute:NSFontAttributeName
                            value:[NSFont boldSystemFontOfSize:11]
                            range:NSMakeRange(0, [attrStr length])];
            [attrStr endEditing];
        }
        [cmdString appendAttributedString:attrStr];
    }
    
    // file args
    if ([isDroppableCheckbox state] == NSOnState) {
        NSAttributedString *attrStr = [[[NSAttributedString alloc] initWithString:@" [files ...]" attributes:defaultAttrs] autorelease];
        [cmdString appendAttributedString:attrStr];
    }
    
    [commandTextField setAttributedStringValue:[cmdString autorelease]];
}

#pragma mark - Manipulating list contents

- (IBAction)addInterpreterArg:(id)sender {
    [interpreterArgs addObject:DEFAULT_ARG_VALUE];
    [interpreterArgsTableView reloadData];
    [interpreterArgsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[interpreterArgs count] - 1] byExtendingSelection:NO];
    [self tableViewSelectionDidChange:nil];
    [self constructCommandString];
    [argsWindow makeFirstResponder:interpreterArgsTableView];
}

- (IBAction)addScriptArg:(id)sender {
    [scriptArgs addObject:DEFAULT_ARG_VALUE];
    [scriptArgsTableView reloadData];
    [scriptArgsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[scriptArgs count] - 1] byExtendingSelection:NO];
    [self tableViewSelectionDidChange:nil];
    [self constructCommandString];
    [argsWindow makeFirstResponder:scriptArgsTableView];
}

- (IBAction)clearInterpreterArgs:(id)sender {
    [interpreterArgs removeAllObjects];
    [interpreterArgsTableView reloadData];
    [self tableViewSelectionDidChange:nil];
    [self constructCommandString];
}

- (IBAction)clearScriptArgs:(id)sender {
    [scriptArgs removeAllObjects];
    [scriptArgsTableView reloadData];
    [self tableViewSelectionDidChange:nil];
    [self constructCommandString];
}

- (IBAction)removeListItem:(id)sender
{
    NSMutableArray *args;
    sender = [argsWindow firstResponder];
    
    if (sender == scriptArgsTableView) {
        args = scriptArgs;
    } else if (sender == interpreterArgsTableView) {
        args = interpreterArgs;
    } else {
        return;
    }
    
    NSTableView *tableView = sender;

    int selectedRow = [tableView selectedRow];
    int rowToSelect;
    
    if (selectedRow == -1 || ![args count]) {
        return;
    }
    
    [args removeObjectAtIndex:[tableView selectedRow]];
    
    if ([tableView numberOfRows] == 0) {
        return;
    }
    
    rowToSelect = selectedRow - 1;
    
    [tableView reloadData];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowToSelect] byExtendingSelection:NO];
    [self tableViewSelectionDidChange:nil];
    [argsWindow makeFirstResponder:tableView];
}

#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    NSMutableArray *args = (aTableView == interpreterArgsTableView) ? interpreterArgs : scriptArgs;
    return([args count]);
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    NSMutableArray *args = (aTableView == interpreterArgsTableView) ? interpreterArgs : scriptArgs;
    
    if ([[aTableColumn identifier] caseInsensitiveCompare:@"1"] == NSOrderedSame) {
        return args[rowIndex];
    }
    return(@"");
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSMutableArray *args = (aTableView == interpreterArgsTableView) ? interpreterArgs : scriptArgs;
    
    if ([[aTableColumn identifier] caseInsensitiveCompare:@"1"] == NSOrderedSame) {
        args[rowIndex] = anObject;
        [self constructCommandString];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [interpreterArgsRemoveButton setEnabled:([interpreterArgsTableView selectedRow] != -1)];
    [interpreterArgsAddButton setEnabled:YES];
    
    [scriptArgsRemoveButton setEnabled:([scriptArgsTableView selectedRow] != -1)];
    [scriptArgsAddButton setEnabled:YES];
    
    [self constructCommandString];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 20;
}

- (void)tableViewDidBecomeFirstResponder:(id)sender {
    [self constructCommandString];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    if ([anItem menu] == scriptArgsContextualMenu && [[anItem title] isEqualToString:@"Remove Entry"] && [scriptArgsTableView selectedRow] == -1) {
        return NO;
    }
    if ([anItem menu] == interpreterArgsContextualMenu && [[anItem title] isEqualToString:@"Remove Entry"] && [interpreterArgsTableView selectedRow] == -1) {
        return NO;
    }
    
    return YES;
}

@end
