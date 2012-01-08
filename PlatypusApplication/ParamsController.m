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

#import "ParamsController.h"
#import "Common.h"

@implementation ParamsController

#define DEFAULT_ARG_VALUE		@"-arg"

- (id) init
{
		values = [[NSMutableArray alloc] init];
		return self;
}

-(void)dealloc
{
	[values release];
	[super dealloc];
}

- (IBAction)add:(id)sender
{
	[values addObject: DEFAULT_ARG_VALUE];
	[interpreterArgsTableView reloadData];
	[interpreterArgsTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: [values count]-1] byExtendingSelection: NO];
	[self tableViewSelectionDidChange: NULL];
	[paramsCommandTextField setStringValue: [self constructCommandString]];
}

- (void)set: (NSArray *)array
{	
	[values removeAllObjects];
	[values addObjectsFromArray: array];
	[interpreterArgsTableView reloadData];
	[self tableViewSelectionDidChange: NULL];
}

- (IBAction)apply:(id)sender 
{
	[window setTitle: PROGRAM_NAME];
	[NSApp stopModal];
}

- (IBAction)clear:(id)sender
{
	[values removeAllObjects];
	[interpreterArgsTableView reloadData];
	[self tableViewSelectionDidChange: NULL];
	[paramsCommandTextField setStringValue: [self constructCommandString]];   
}

- (IBAction)remove:(id)sender
{
	int selectedRow = [interpreterArgsTableView selectedRow];
	int rowToSelect;

	if (selectedRow == -1)
		return;
	
	[values removeObjectAtIndex: [interpreterArgsTableView selectedRow]];
	
	if (![interpreterArgsTableView numberOfRows]) { return; }

	rowToSelect = selectedRow-1;
    
	[interpreterArgsTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: rowToSelect] byExtendingSelection: NO];
	
	[interpreterArgsTableView reloadData];
	[self tableViewSelectionDidChange: NULL];

	[paramsCommandTextField setStringValue: [self constructCommandString]];
}

- (IBAction)resetDefaults:(id)sender
{
	[setFirstArgAppPathCheckbox setState: NSOffState];
	[self clear: self];
}

- (IBAction)show:(id)sender 
{
	[window setTitle: [NSString stringWithFormat: @"%@ - Edit Arguments", PROGRAM_NAME]];
	
	[paramsCommandTextField setStringValue: [self constructCommandString]];
	
	//open window
	[NSApp beginSheet:	paramsWindow
						modalForWindow: window 
						modalDelegate:nil
						didEndSelector:nil
						contextInfo:nil];

	 [NSApp runModalForWindow: paramsWindow];
	 
	 [NSApp endSheet:paramsWindow];
     [paramsWindow orderOut:self];
}

- (NSString *)constructCommandString
{
	int i;
	NSString *cmdString = [NSString stringWithFormat: @"%@", [interpreterTextField stringValue]];
	
	for (i = 0; i < [values count]; i++)
	{
		cmdString = [cmdString stringByAppendingString: [NSString stringWithFormat: @" %@", [values objectAtIndex: i]]];
	}
	
	cmdString = [cmdString stringByAppendingString: @" yourScript"];
	
	if ([setFirstArgAppPathCheckbox state] == NSOnState)
		cmdString = [cmdString stringByAppendingString: @" /path/to/MyApp.app"];
	
	if ([isDroppableCheckbox state] == NSOnState)
		cmdString = [cmdString stringByAppendingString: @" [files ...]"];
	
	return cmdString;
}

- (NSArray *)paramsArray
{
	return values;
}

- (BOOL)passAppPathAsFirstArg
{
	return [setFirstArgAppPathCheckbox state];
}
- (void)setAppPathAsFirstArg: (BOOL)state
{	
	[setFirstArgAppPathCheckbox setState: state];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return([values count]);
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ([[aTableColumn identifier] caseInsensitiveCompare: @"1"] == NSOrderedSame)
	{
        return [values objectAtIndex: rowIndex];
	}
	return(@"");
}

- (void)tableView:(NSTableView *)aTableView setObjectValue: anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if (rowIndex < 0 || rowIndex > [values count]-1)
		return;
	
	if ([[aTableColumn identifier] caseInsensitiveCompare: @"1"] == NSOrderedSame)
	{
        [values replaceObjectAtIndex: rowIndex withObject: anObject];
		[paramsCommandTextField setStringValue: [self constructCommandString]];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{	
    [interpreterArgsRemoveButton setEnabled: ([interpreterArgsTableView selectedRow] != -1)];	
    [interpreterArgsClearButton setEnabled: ([values count] != 0)];
    [interpreterArgsAddButton setEnabled: ([values count] != PROGRAM_MAX_LIST_ITEMS)];
    
    [scriptArgsRemoveButton setEnabled: ([scriptArgsTableView selectedRow] != -1)];	
    [scriptArgsClearButton setEnabled: ([values count] != 0)];
    [scriptArgsAddButton setEnabled: ([values count] != PROGRAM_MAX_LIST_ITEMS)];
}

- (BOOL)validateMenuItem:(NSMenuItem*)anItem 
{
	if ([[anItem title] isEqualToString:@"Remove Entry"] && [interpreterArgsTableView selectedRow] == -1)
		return NO;
	return YES;
}

- (IBAction)appPathCheckboxClicked:(id)sender
{	
	[paramsCommandTextField setStringValue: [self constructCommandString]];
}


@end
