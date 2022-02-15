/*
    Copyright (c) 2003-2022, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

#define DEFAULT_ARG_VALUE @"-arg"

@interface ArgsController()
{
    // Main window outlets
    IBOutlet NSButton *argsButton;
    IBOutlet NSTextField *interpreterTextField;
    
    // Args window outlets
    IBOutlet NSTextField *commandTextField;
    
    IBOutlet NSButton *interpreterArgsRemoveButton;
    IBOutlet NSResponderNotifyingTableView *interpreterArgsTableView;
    
    IBOutlet NSButton *scriptArgsRemoveButton;
    IBOutlet NSResponderNotifyingTableView *scriptArgsTableView;
    
    IBOutlet NSButton *isDroppableCheckbox;
    
    IBOutlet NSMenu *scriptArgsContextualMenu;
    IBOutlet NSMenu *interpreterArgsContextualMenu;
    
    NSMutableArray <NSString *> *interpreterArgs;
    NSMutableArray <NSString *> *scriptArgs;
}
@end

@implementation ArgsController

- (instancetype)init {
    if (self = [super init]) {
        interpreterArgs = [[NSMutableArray alloc] init];
        scriptArgs = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - Getters/setters

- (void)setInterpreterArgs:(NSArray *)array {
    [interpreterArgs removeAllObjects];
    [interpreterArgs addObjectsFromArray:array];
    [interpreterArgsTableView reloadData];
    [self updateGUIStatus];
}

- (void)setScriptArgs:(NSArray *)array {
    [scriptArgs removeAllObjects];
    [scriptArgs addObjectsFromArray:array];
    [scriptArgsTableView reloadData];
    [self updateGUIStatus];
}

- (NSArray *)interpreterArgs {
    return interpreterArgs;
}

- (NSArray *)scriptArgs {
    return scriptArgs;
}

#pragma mark -

- (IBAction)apply:(id)sender {
    [[self window] makeFirstResponder:commandTextField];
    [NSApp stopModal];
}

- (IBAction)setToDefaults:(id)sender {
    [self clearScriptArgs:self];
    [self clearInterpreterArgs:self];
}

- (IBAction)show:(id)sender {
    NSWindow *parentWindow = [argsButton window];
    
    [self constructCommandString];
    [[self window] makeFirstResponder:interpreterArgsTableView];
    
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

- (void)constructCommandString {
    
    // Interpreter
    NSDictionary *defaultAttrs = @{ NSForegroundColorAttributeName: [NSColor blackColor],
                                    NSBackgroundColorAttributeName: [NSColor whiteColor] };
    NSMutableAttributedString *cmdString = [[NSMutableAttributedString alloc] initWithString:[interpreterTextField stringValue] attributes:defaultAttrs];
    
    // Interpreter args
    for (int i = 0; i < [interpreterArgs count]; i++)
    {
        NSString *a = [NSString stringWithFormat:@" %@", interpreterArgs[i]];
        NSMutableDictionary *attrs = [defaultAttrs mutableCopy];
        
        if ([interpreterArgsTableView selectedRow] == i && interpreterArgsTableView == [[self window] firstResponder]) {
            attrs[NSBackgroundColorAttributeName] = [NSColor lightGrayColor];
        }
        
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:a attributes:attrs];
        if (interpreterArgsTableView == [[self window] firstResponder]) {
            [attrStr beginEditing];
            [attrStr addAttribute:NSFontAttributeName
                            value:[NSFont boldSystemFontOfSize:11]
                            range:NSMakeRange(0, [attrStr length])];
            [attrStr endEditing];
        }
        [cmdString appendAttributedString:attrStr];
    }
    
    // yourScript
    NSAttributedString *scriptString = [[NSAttributedString alloc] initWithString:@" yourScript " attributes:defaultAttrs];
    [cmdString appendAttributedString:scriptString];
    
    // Script args
    for (int i = 0; i < [scriptArgs count]; i++)
    {
        NSString *a = [NSString stringWithFormat:@"%@ ", scriptArgs[i]];
        NSMutableDictionary *attrs = [defaultAttrs mutableCopy];
        
        if ([scriptArgsTableView selectedRow] == i && scriptArgsTableView == [[self window] firstResponder]) {
            attrs[NSBackgroundColorAttributeName] = [NSColor lightGrayColor];
        }
        
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:a attributes:attrs];
        if (scriptArgsTableView == [[self window] firstResponder]) {
            [attrStr beginEditing];
            [attrStr addAttribute:NSFontAttributeName
                            value:[NSFont boldSystemFontOfSize:11]
                            range:NSMakeRange(0, [attrStr length])];
            [attrStr endEditing];
        }
        [cmdString appendAttributedString:attrStr];
    }
    
    // File args
    if ([isDroppableCheckbox state] == NSOnState) {
        NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:@" [files ...]" attributes:defaultAttrs];
        [cmdString appendAttributedString:attrStr];
    }
    
    [commandTextField setAttributedStringValue:cmdString];
}

- (void)updateGUIStatus {
    [interpreterArgsRemoveButton setEnabled:
        ([interpreterArgsTableView selectedRow] != -1) &&
        [[self window] firstResponder] == interpreterArgsTableView
    ];
    [scriptArgsRemoveButton setEnabled:
        ([scriptArgsTableView selectedRow] != -1) &&
        [[self window] firstResponder] == scriptArgsTableView
     ];
    [self updateArgsButtonTitle];
    [self constructCommandString];
}

- (void)updateArgsButtonTitle {
    NSInteger numArgs = [interpreterArgs count] + [scriptArgs count];
    if (numArgs) {
        [argsButton setTitle:[NSString stringWithFormat:@"Args (%ld)", (long)numArgs]];
    } else {
        [argsButton setTitle:@"Args"];
    }
}

#pragma mark - Manipulating list contents

- (IBAction)addInterpreterArg:(id)sender {
    [interpreterArgs addObject:DEFAULT_ARG_VALUE];
    [interpreterArgsTableView reloadData];
    [interpreterArgsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[interpreterArgs count] - 1] byExtendingSelection:NO];
    [[self window] makeFirstResponder:interpreterArgsTableView];
    [self updateGUIStatus];
}

- (IBAction)addScriptArg:(id)sender {
    [scriptArgs addObject:DEFAULT_ARG_VALUE];
    [scriptArgsTableView reloadData];
    [scriptArgsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[scriptArgs count] - 1] byExtendingSelection:NO];
    [[self window] makeFirstResponder:scriptArgsTableView];
    [self updateGUIStatus];
}

- (IBAction)clearInterpreterArgs:(id)sender {
    [interpreterArgs removeAllObjects];
    [interpreterArgsTableView reloadData];
    [self updateGUIStatus];
}

- (IBAction)clearScriptArgs:(id)sender {
    [scriptArgs removeAllObjects];
    [scriptArgsTableView reloadData];
    [self updateGUIStatus];
}

- (IBAction)removeListItem:(id)sender {
    NSMutableArray <NSString *> *args;
    id firstResponder = [[self window] firstResponder];
    
    if (firstResponder == scriptArgsTableView) {
        args = scriptArgs;
    } else if (firstResponder == interpreterArgsTableView) {
        args = interpreterArgs;
    } else {
        return;
    }
    
    NSTableView *tableView = firstResponder;
    NSInteger selectedRow = [tableView selectedRow];
    
    if (selectedRow == -1 || [args count] == 0) {
        return;
    }
    
    [args removeObjectAtIndex:[tableView selectedRow]];
    
    if ([tableView numberOfRows] == 0) {
        return;
    }
    
    NSInteger rowToSelect = selectedRow - 1;
    
    [tableView reloadData];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowToSelect] byExtendingSelection:NO];
    [[self window] makeFirstResponder:tableView];
    [self updateGUIStatus];
}

#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    NSMutableArray *args = (aTableView == interpreterArgsTableView) ? interpreterArgs : scriptArgs;
    return [args count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    NSMutableArray *args = (aTableView == interpreterArgsTableView) ? interpreterArgs : scriptArgs;
    return args[rowIndex];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    NSMutableArray *args = (aTableView == interpreterArgsTableView) ? interpreterArgs : scriptArgs;
    args[rowIndex] = anObject;
    [self constructCommandString];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self updateGUIStatus];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 20;
}

- (void)tableViewDidBecomeFirstResponder:(id)sender {
    [self updateGUIStatus];
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
