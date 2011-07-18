/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C) 2003-2010 Sveinbjorn Thordarson <sveinbjornt@gmail.com>

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

// SuffixList is a controller class around the Suffix list in the Platypus
// Edit Types window.  It is the data source and delegate of this tableview.

#import "SuffixList.h"
#import "CommonDefs.h"

@implementation SuffixList

- (id) init
{
		items = [[NSMutableArray alloc] init];
		return self;
}

-(void)dealloc
{
	[items release];
	[super dealloc];
}

- (NSString *)getSuffixAtIndex:(int)index
{
	return ([[items objectAtIndex: index] objectAtIndex: 0]);
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return ([items count]);
}



- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	//return ([items objectAtIndex: rowIndex]);
	
	if ([[aTableColumn identifier] caseInsensitiveCompare: @"2"] == NSOrderedSame)
	{
		return([[items objectAtIndex: rowIndex] objectAtIndex: 0]);
	}
	else if ([[aTableColumn identifier] caseInsensitiveCompare: @"1"] == NSOrderedSame)
	{
		if (rowIndex == 0)
		{
			NSImageCell* iconCell;
			iconCell = [[[NSImageCell alloc] init] autorelease];
			[aTableColumn setDataCell:iconCell];
		}
        
        return [[items objectAtIndex: rowIndex] objectAtIndex: 1];
	}
	return(@"");
}

- (void) addSuffix: (NSString *)suffix
{
	if ([self hasSuffix: suffix])
		return;
	NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType: suffix];
	[items addObject: [NSArray arrayWithObjects: suffix, icon, nil]];
}

- (void) addSuffixes: (NSArray *)suffixes
{
	int i;
	
	for (i = 0; i < [suffixes count]; i++)
	{
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType: [suffixes objectAtIndex: i]];
		[items addObject: [NSArray arrayWithObjects: [suffixes objectAtIndex: i], icon, nil]];
		
	}
}

- (BOOL) hasSuffix: (NSString *)suffix
{
	int i;
	for (i = 0; i < [items count]; i++)
	{
		if ([[[items objectAtIndex: i] objectAtIndex: 0] isEqualToString: suffix])
			return YES;
	}
	return NO;
}

- (BOOL) hasAllSuffixes
{
	int i;
	for (i = 0; i < [items count]; i++)
	{
		if ([[[items objectAtIndex: i] objectAtIndex: 0] isEqualToString: @"*"])
			return YES;
	}
	return NO;
}

- (void) clearList
{
	[items removeAllObjects];
}

- (int) numSuffixes
{
		return ([items count]);
}

- (void) removeSuffix: (int)index
{
	if ([items count] > 0)
		[items removeObjectAtIndex: index];
}

- (NSArray *) getSuffixArray
{
	short i;
	NSMutableArray	*suffices = [NSMutableArray arrayWithCapacity: PROGRAM_MAX_LIST_ITEMS];
	
	for (i = 0; i < [items count]; i++)
	{
		[suffices addObject: [[items objectAtIndex: i] objectAtIndex: 0]];
	}

	return suffices;
}

-(BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	int i;
	NSPasteboard *pboard = [info draggingPasteboard];	
	NSArray *draggedFiles = [pboard propertyListForType:NSFilenamesPboardType];
	
	for (i = 0; i < [draggedFiles count]; i++)
	{
		if (![[[draggedFiles objectAtIndex: i] pathExtension] isEqualToString: @""])
			[[tv dataSource] addSuffix: [[draggedFiles objectAtIndex: i] pathExtension]];
	}
	[tv reloadData];
	return YES;
}

-(NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	return NSDragOperationCopy;
}

@end
