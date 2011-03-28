/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C) 2003-2010 Sveinbjorn Thordarson <sveinbjornt@simnet.is>

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

#import "PlatypusController.h"
#import "EnvController.h"

@implementation EnvController

- (id) init
{
		keys = [[NSMutableArray alloc] init];
		values = [[NSMutableArray alloc] init];
		environmentDictionary = NULL;
		return self;
}

-(void)dealloc
{
	if (keys != NULL)
		[keys release];
	if (values != NULL)
		[values release];
	if (environmentDictionary != NULL)
		[environmentDictionary release];
	[super dealloc];
}

- (IBAction)add:(id)sender
{
	[keys addObject: @"VARIABLE"];
	[values addObject: @"Value"];
	[envTableView reloadData];
	[envTableView selectRow: [keys count]-1 byExtendingSelection: NO];
	[self tableViewSelectionDidChange: NULL];
}

- (void)set: (NSDictionary *)dict;
{
	if (keys != NULL)
		[keys release];
	if (values != NULL)
		[values release];

	keys = [[NSMutableArray alloc] initWithArray: [dict allKeys]];
	values = [[NSMutableArray alloc] initWithArray: [dict allValues]];
		
	[self tableViewSelectionDidChange: NULL];
}

- (IBAction)apply:(id)sender
{
	[window setTitle: PROGRAM_NAME];
	[NSApp stopModal];
}

- (IBAction)clear:(id)sender
{
	[keys removeAllObjects];
	[values removeAllObjects];
	[envTableView reloadData];
	[self tableViewSelectionDidChange: NULL];
}

- (IBAction)help:(id)sender
{	
	NSURL *fileURL = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"env.html" ofType:nil]];
	[[NSWorkspace sharedWorkspace] openURL: fileURL];
}

- (IBAction)remove:(id)sender
{
	int selectedRow = [envTableView selectedRow];
	int rowToSelect;

	if (selectedRow == -1)
		return;
	
	[keys removeObjectAtIndex: selectedRow];
	[values removeObjectAtIndex: selectedRow];
	if (![envTableView numberOfRows]) { return; }

	rowToSelect = selectedRow-1;
		
	[envTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: rowToSelect] byExtendingSelection: NO];
	
	[envTableView reloadData];
	[self tableViewSelectionDidChange: NULL];
}

- (IBAction)resetDefaults:(id)sender
{
	[self clear: self];
	[envTableView reloadData];
	[self tableViewSelectionDidChange: NULL];
}

- (IBAction)show:(id)sender
{
	[window setTitle: [NSString stringWithFormat: @"%@ - Environmental Variables", PROGRAM_NAME]];
	[envTableView reloadData];
	[NSApp beginSheet:	envWindow
						modalForWindow: window 
						modalDelegate:nil
						didEndSelector:nil
						contextInfo:nil];
	[NSApp runModalForWindow: envWindow];
	[NSApp endSheet:envWindow];
    [envWindow orderOut:self];
}


- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return([keys count]);
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ([[aTableColumn identifier] caseInsensitiveCompare: @"2"] == NSOrderedSame)//value
	{
		return([values objectAtIndex: rowIndex]);
	}
	else if ([[aTableColumn identifier] caseInsensitiveCompare: @"1"] == NSOrderedSame)//name
	{
        return [keys objectAtIndex: rowIndex];
	}
	return(@"");
}

- (void)tableView:(NSTableView *)aTableView setObjectValue: anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if (rowIndex < 0 || rowIndex > [values count]-1)
		return;
	
	if ([[aTableColumn identifier] caseInsensitiveCompare: @"2"] == NSOrderedSame)//value
	{
		[values replaceObjectAtIndex: rowIndex withObject: anObject];
	}
	else if ([[aTableColumn identifier] caseInsensitiveCompare: @"1"] == NSOrderedSame)//keys
	{
        [keys replaceObjectAtIndex: rowIndex withObject: [anObject uppercaseString]];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	int selected = [envTableView selectedRow];

	if (selected != -1) //there is a selected item
		[removeButton setEnabled: YES];
	else
		[removeButton setEnabled: NO];

	if ([keys count] == 0)
		[clearButton setEnabled: NO];
	else
		[clearButton setEnabled: YES];
	
	if ([keys count] == PROGRAM_MAX_LIST_ITEMS)
		[addButton setEnabled: NO];
	else
		[addButton setEnabled: YES];
}

- (NSMutableDictionary *)environmentDictionary
{
	if (environmentDictionary != NULL)
		[environmentDictionary release];
	
	environmentDictionary = [[NSMutableDictionary alloc] initWithObjects: values forKeys: keys];
	return(environmentDictionary);
}

- (BOOL)validateMenuItem:(NSMenuItem*)anItem 
{
	if ([[anItem title] isEqualToString:@"Remove Entry"] && [envTableView selectedRow] == -1)
		return NO;
	return YES;
}

@end
