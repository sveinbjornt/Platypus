/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C) 2003-2012 Sveinbjorn Thordarson <sveinbjornt@gmail.com>

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

#import "ArgsController.h"
#import "Common.h"

@implementation ArgsController

#define DEFAULT_ARG_VALUE		@"-arg"

- (id) init
{
    interpreterArgs = [[NSMutableArray alloc] init];
    scriptArgs = [[NSMutableArray alloc] init];
    return self;
}

-(void)dealloc
{
	[interpreterArgs release];
    [scriptArgs release];
	[super dealloc];
}

- (void)setInterpreterArgs: (NSArray *)array
{	
	[interpreterArgs removeAllObjects];
	[interpreterArgs addObjectsFromArray: array];
	[interpreterArgsTableView reloadData];
	[self tableViewSelectionDidChange: NULL];
}

- (void)setScriptArgs: (NSArray *)array
{	
	[scriptArgs removeAllObjects];
	[scriptArgs addObjectsFromArray: array];
	[scriptArgsTableView reloadData];
	[self tableViewSelectionDidChange: NULL];
}

- (NSArray *)interpreterArgs
{
    return interpreterArgs;
}

- (NSArray *)scriptArgs
{
    return scriptArgs;
}

- (IBAction)apply:(id)sender 
{
	[window setTitle: PROGRAM_NAME];
	[NSApp stopModal];
}

- (IBAction)addInterpreterArg:(id)sender
{
	[interpreterArgs addObject: DEFAULT_ARG_VALUE];
	[interpreterArgsTableView reloadData];
    [window makeFirstResponder: interpreterArgsTableView];
	[interpreterArgsTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: [interpreterArgs count]-1] byExtendingSelection: NO];
	[self tableViewSelectionDidChange: NULL];
	[paramsCommandTextField setStringValue: [self constructCommandString]];
}

- (IBAction)addScriptArg:(id)sender
{
    [scriptArgs addObject: DEFAULT_ARG_VALUE];
	[scriptArgsTableView reloadData];
	[scriptArgsTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: [scriptArgs count]-1] byExtendingSelection: NO];
	[self tableViewSelectionDidChange: NULL];
	[paramsCommandTextField setStringValue: [self constructCommandString]];
}
- (IBAction)clearInterpreterArgs:(id)sender
{
	[interpreterArgs removeAllObjects];
	[interpreterArgsTableView reloadData];
	[self tableViewSelectionDidChange: NULL];
	[paramsCommandTextField setStringValue: [self constructCommandString]];   
}

- (IBAction)clearScriptArgs:(id)sender
{
    [scriptArgs removeAllObjects];
	[scriptArgsTableView reloadData];
	[self tableViewSelectionDidChange: NULL];
	[paramsCommandTextField setStringValue: [self constructCommandString]];   
}

- (IBAction)removeInterpreterArg:(id)sender
{
	int selectedRow = [interpreterArgsTableView selectedRow];
	int rowToSelect;

	if (selectedRow == -1 || ![interpreterArgs count])
		return;
	
	[interpreterArgs removeObjectAtIndex: [interpreterArgsTableView selectedRow]];
	
	if (![interpreterArgsTableView numberOfRows]) { return; }

	rowToSelect = selectedRow-1;
    
	[interpreterArgsTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: rowToSelect] byExtendingSelection: NO];
	
	[interpreterArgsTableView reloadData];
	[self tableViewSelectionDidChange: NULL];

	[paramsCommandTextField setStringValue: [self constructCommandString]];
}

- (IBAction)removeScriptArg:(id)sender
{
    int selectedRow = [scriptArgsTableView selectedRow];
	int rowToSelect;
    
	if (selectedRow == -1 || ![scriptArgs count])
		return;
	
	[scriptArgs removeObjectAtIndex: [scriptArgsTableView selectedRow]];
	
	if (![scriptArgsTableView numberOfRows]) { return; }
    
	rowToSelect = selectedRow-1;
    
	[scriptArgsTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: rowToSelect] byExtendingSelection: NO];
	
	[scriptArgsTableView reloadData];
	[self tableViewSelectionDidChange: NULL];

}

- (IBAction)resetDefaults:(id)sender
{
	[self clearInterpreterArgs: self];
    [self clearScriptArgs: self];
}

- (IBAction)show:(id)sender 
{
	[window setTitle: [NSString stringWithFormat: @"%@ - Edit Arguments", PROGRAM_NAME]];
	
	[paramsCommandTextField setStringValue: [self constructCommandString]];
	
	//open window
	[NSApp beginSheet:	argsWindow
						modalForWindow: window 
						modalDelegate:nil
						didEndSelector:nil
						contextInfo:nil];

	 [NSApp runModalForWindow: argsWindow];
	 
	 [NSApp endSheet:argsWindow];
     [argsWindow orderOut:self];
}

- (NSString *)constructCommandString
{
	int i;
    
    // interpreter
	NSString *cmdString = [NSString stringWithString: [interpreterTextField stringValue]];
	
    // interpreter args
	for (i = 0; i < [interpreterArgs count]; i++)
	{
		cmdString = [cmdString stringByAppendingString: [NSString stringWithFormat: @" %@", [interpreterArgs objectAtIndex: i]]];
	}
	
	cmdString = [cmdString stringByAppendingString: @" yourScript"];
    
    // script args
	for (i = 0; i < [scriptArgs count]; i++)
	{
		cmdString = [cmdString stringByAppendingString: [NSString stringWithFormat: @" %@", [scriptArgs objectAtIndex: i]]];
	}
    
    // file args
	if ([isDroppableCheckbox state] == NSOnState)
		cmdString = [cmdString stringByAppendingString: @" [files ...]"];
	
	return cmdString;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    NSMutableArray *args = (aTableView == interpreterArgsTableView) ? interpreterArgs : scriptArgs;
	return([args count]);
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSMutableArray *args = (aTableView == interpreterArgsTableView) ? interpreterArgs : scriptArgs;
    
	if ([[aTableColumn identifier] caseInsensitiveCompare: @"1"] == NSOrderedSame)
	{
        return [args objectAtIndex: rowIndex];
	}
	return(@"");
}

- (void)tableView:(NSTableView *)aTableView setObjectValue: anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if (rowIndex < 0)
		return;
    
    NSMutableArray *args = (aTableView == interpreterArgsTableView) ? interpreterArgs : scriptArgs;
	
	if ([[aTableColumn identifier] caseInsensitiveCompare: @"1"] == NSOrderedSame)
	{
        [args replaceObjectAtIndex: rowIndex withObject: anObject];
		[paramsCommandTextField setStringValue: [self constructCommandString]];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{	
    [interpreterArgsRemoveButton setEnabled: ([interpreterArgsTableView selectedRow] != -1)];	
    [interpreterArgsClearButton setEnabled: ([interpreterArgs count] != 0)];
    [interpreterArgsAddButton setEnabled: ([interpreterArgs count] != PROGRAM_MAX_LIST_ITEMS)];
    
    [scriptArgsRemoveButton setEnabled: ([scriptArgsTableView selectedRow] != -1)];	
    [scriptArgsClearButton setEnabled: ([scriptArgs count] != 0)];
    [scriptArgsAddButton setEnabled: ([scriptArgs count] != PROGRAM_MAX_LIST_ITEMS)];
}

- (BOOL)validateMenuItem:(NSMenuItem*)anItem 
{
    if ([anItem menu] == scriptArgsContextualMenu && [[anItem title] isEqualToString:@"Remove Entry"] && [scriptArgsTableView selectedRow] == -1)
		return NO;
    if ([anItem menu] == interpreterArgsContextualMenu && [[anItem title] isEqualToString:@"Remove Entry"] && [interpreterArgsTableView selectedRow] == -1)
		return NO;

	return YES;
}

- (IBAction)appPathCheckboxClicked:(id)sender
{	
	[paramsCommandTextField setStringValue: [self constructCommandString]];
}


@end
