/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C) 2003-2011 Sveinbjorn Thordarson <sveinbjornt@gmail.com>

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

#import "FileTypesController.h"
#import "Common.h"

@implementation FileTypesController

/*****************************************
 - init function
*****************************************/

- (id)init
{
	if (self = [super init]) 
	{
		typesList = [[TypesList alloc] init];
		suffixList = [[SuffixList alloc] init];
    }
    return self;
}

/*****************************************
 - dealloc for controller object
   release all the stuff we alloc in init
*****************************************/

-(void)dealloc
{
	[typesList release];
	[suffixList release];
	[super dealloc];
}

#pragma mark -

- (void)awakeFromNib
{
	[typesListDataBrowser registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
	[suffixListDataBrowser registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
}

/*****************************************
 - Display the Edit Types Window as a sheet
*****************************************/

- (IBAction) openTypesSheet: (id)sender
{
	[window setTitle: [NSString stringWithFormat: @"%@ - Drop settings", PROGRAM_NAME]];
	//clear text fields from last time
	[typeCodeTextField setStringValue: @""];
	[suffixTextField setStringValue: @""];
	
	// refresh these guys
	[typesListDataBrowser setDataSource: typesList];
	[typesListDataBrowser reloadData];
	[typesListDataBrowser setDelegate: self];
	[typesListDataBrowser setTarget: self];

	[suffixListDataBrowser setDataSource: suffixList];
	[suffixListDataBrowser reloadData];
	[suffixListDataBrowser setDelegate: self];
	
	// updated text fields reporting no. suffixes and no. file type codes
	if ([suffixList hasAllSuffixes])
		[numSuffixesTextField setStringValue: @"All suffixes"];
	else
		[numSuffixesTextField setStringValue: [NSString stringWithFormat:@"%d suffixes", [suffixList numSuffixes]]];

	if ([typesList hasAllTypes])
		[numTypesTextField setStringValue: @"All file types"];
	else
		[numTypesTextField setStringValue: [NSString stringWithFormat:@"%d file types", [typesList numTypes]]];
	if ([typesList hasFolderType])
		[numTypesTextField setStringValue: [[numTypesTextField stringValue] stringByAppendingString: @" and folders"]];
		
	//open window
	[NSApp beginSheet:	typesWindow
						modalForWindow: window 
						modalDelegate:nil
						didEndSelector:nil
						contextInfo:nil];

	 [NSApp runModalForWindow: typesWindow];
	 
	 [NSApp endSheet:typesWindow];
     [typesWindow orderOut:self];
}

- (IBAction)closeTypesSheet:(id)sender
{
	//make sure typeslist contains valid values
	if ([typesList numTypes] <= 0 && [suffixList numSuffixes] <= 0)
	{
		[typesErrorTextField setStringValue: @"One of the lists must contain at least one entry."];
	}
	else
	{
		[typesErrorTextField setStringValue: @""];
		[window setTitle: PROGRAM_NAME];
		[NSApp stopModal];
		[NSApp endSheet:typesWindow];
		[typesWindow orderOut:self];
	}
}

#pragma mark -

- (IBAction)acceptDroppedFilesClicked:(id)sender
{
	if ([acceptDroppedFilesCheckbox intValue])
	{
		
	}
	else
	{
		
	}
}


#pragma mark -

/*****************************************
 - called when [+] button is pressed in Types List
*****************************************/

- (IBAction) addSuffix:(id)sender;
{
	NSString	*theSuffix = [suffixTextField stringValue];
	
	if ([suffixList hasSuffix: theSuffix] || ([theSuffix length] < 0))
		return;
		
	//if the user put in a suffix beginning with a '.', we trim the string to start from index 1
	if ([theSuffix characterAtIndex: 0] == '.')
		theSuffix = [theSuffix substringFromIndex: 1];

	[suffixList addSuffix: theSuffix];
	[suffixTextField setStringValue: @""];
	[self controlTextDidChange: NULL];

	//update
	[suffixListDataBrowser setDataSource: suffixList];
	[suffixListDataBrowser reloadData];
	
	if ([suffixList hasAllSuffixes])
		[numSuffixesTextField setStringValue: @"All suffixes"];
	else
		[numSuffixesTextField setStringValue: [NSString stringWithFormat:@"%d suffixes", [suffixList numSuffixes]]];
}

/*****************************************
 - called when [+] button is pressed in Types List
*****************************************/

- (IBAction) addType:(id)sender;
{
	//make sure the type is 4 characters long
	if ([[typeCodeTextField stringValue] length] != 4)
	{
				[PlatypusUtility sheetAlert:@"Invalid File Type" subText: @"A File Type must consist of exactly 4 ASCII characters." forWindow: typesWindow];
		return;
	}

	if (![typesList hasType: [typeCodeTextField stringValue]] && ([[typeCodeTextField stringValue] length] > 0))
	{
		[typesList addType: [typeCodeTextField stringValue]];
		[typeCodeTextField setStringValue: @""];
		[self controlTextDidChange: NULL];
	}
	//update
	[typesListDataBrowser setDataSource: typesList];
	[typesListDataBrowser reloadData];
	
	if ([typesList hasAllTypes])
		[numTypesTextField setStringValue: @"All file types"];
	else
		[numTypesTextField setStringValue: [NSString stringWithFormat:@"%d file types", [typesList numTypes]]];
	if ([typesList hasFolderType])
		[numTypesTextField setStringValue: [[numTypesTextField stringValue] stringByAppendingString: @" and folders"]];
}

/*****************************************
 - called when [C] button is pressed in Types List
*****************************************/

- (IBAction) clearSuffixList:(id)sender
{
	[suffixList clearList];
	[suffixListDataBrowser reloadData];
	[numSuffixesTextField setStringValue: [NSString stringWithFormat:@"%d suffixes", [suffixList numSuffixes]]];
}

/*****************************************
 - called when [C] button is pressed in Types List
*****************************************/

- (IBAction) clearTypesList:(id)sender
{
	[typesList clearList];
	[typesListDataBrowser reloadData];
	[numTypesTextField setStringValue: [NSString stringWithFormat:@"%d file types", [typesList numTypes]]];
}

/*****************************************
 - called when [-] button is pressed in Types List
*****************************************/

- (IBAction) removeSuffix:(id)sender;
{
	int i;
	NSIndexSet *selectedItems = [suffixListDataBrowser selectedRowIndexes];
	
	for (i = [suffixList numSuffixes]; i >= 0; i--)
	{
		if ([selectedItems containsIndex: i])
		{
			[suffixList removeSuffix: i];
			[suffixListDataBrowser reloadData];
			break;
		}
	}
	
	if ([suffixList hasAllSuffixes])
		[numSuffixesTextField setStringValue: @"All suffixes"];
	else
		[numSuffixesTextField setStringValue: [NSString stringWithFormat:@"%d suffixes", [suffixList numSuffixes]]];
}

/*****************************************
 - called when [-] button is pressed in Types List
*****************************************/

- (IBAction) removeType:(id)sender;
{
	int i;
	NSIndexSet *selectedItems = [typesListDataBrowser selectedRowIndexes];
	
	for (i = [typesList numTypes]; i >= 0; i--)
	{
		if ([selectedItems containsIndex: i])
		{
			[typesList removeType: i];
			[typesListDataBrowser reloadData];
			break;
		}
	}
	
	if ([typesList hasAllTypes])
		[numTypesTextField setStringValue: @"All file types"];
	else
		[numTypesTextField setStringValue: [NSString stringWithFormat:@"%d file types", [typesList numTypes]]];
	if ([typesList hasFolderType])
		[numTypesTextField setStringValue: [[numTypesTextField stringValue] stringByAppendingString: @" and folders"]];
}

/*****************************************
 - called when "Default" button is pressed in Types List
*****************************************/

- (IBAction) setDefaultTypes:(id)sender
{
	//default File Types
	[typesList clearList];
	[typesList addType: @"****"];
	[typesList addType: @"fold"];
	[typesListDataBrowser reloadData];
	
		if ([typesList hasAllTypes])
		[numTypesTextField setStringValue: @"All file types"];
	else
		[numTypesTextField setStringValue: [NSString stringWithFormat:@"%d file types", [typesList numTypes]]];
	if ([typesList hasFolderType])
		[numTypesTextField setStringValue: [[numTypesTextField stringValue] stringByAppendingString: @" and folders"]];
		
	//default suffixes
	[suffixList clearList];
	[suffixList addSuffix: @"*"];
	[suffixListDataBrowser reloadData];
	
	if ([suffixList hasAllSuffixes])
		[numSuffixesTextField setStringValue: @"All suffixes"];
	else
		[numSuffixesTextField setStringValue: [NSString stringWithFormat:@"%d suffixes", [suffixList numSuffixes]]];
	
	//set app function to default
	[appFunctionRadioButtons selectCellWithTag: 0];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	int i;
	int selected = 0;
	NSIndexSet *selectedItems;
	
	if ([aNotification object] == suffixListDataBrowser || [aNotification object] == NULL)
	{
		selectedItems = [suffixListDataBrowser selectedRowIndexes];
		for (i = 0; i < [suffixList numSuffixes]; i++)
		{
			if ([selectedItems containsIndex: i])
				selected++;
		}
		
		//update button status
		if (selected == 0)
			[removeSuffixButton setEnabled: NO];
		else
			[removeSuffixButton setEnabled: YES];
	}
	if ([aNotification object] == typesListDataBrowser || [aNotification object] == NULL)
	{
		selectedItems = [typesListDataBrowser selectedRowIndexes];
		for (i = 0; i < [typesList numTypes]; i++)
		{
			if ([selectedItems containsIndex: i])
				selected++;
		}
		
		//update button status
		if (selected == 0)
			[removeTypeButton setEnabled: NO];
		else
			[removeTypeButton setEnabled: YES];
	}
}


- (void)controlTextDidChange:(NSNotification *)aNotification
{	
	//bundle signature or "type code" changed
	if ([aNotification object] == typeCodeTextField || [aNotification object] == NULL)
	{
		NSRange	 range = { 0, 4 };
		NSString *sig = [[aNotification object] stringValue];
		
		if ([sig length] > 4)
		{
			[[aNotification object] setStringValue: [sig substringWithRange: range]];
		}
		else if ([sig length] < 4)
			[[aNotification object] setTextColor: [NSColor redColor]];
		else if ([sig length] == 4)
			[[aNotification object] setTextColor: [NSColor blackColor]];
	}

	//enable/disable buttons for Edit Types window
	if ([[suffixTextField stringValue] length] > 0)
		[addSuffixButton setEnabled: YES];
	else
		[addSuffixButton setEnabled: NO];
			
	if ([[typeCodeTextField stringValue] length] == 4)
		[addTypeButton setEnabled: YES];
	else
		[addTypeButton setEnabled: NO];
}

- (BOOL)validateMenuItem:(NSMenuItem*)anItem
{
	if (![showTypesButton isEnabled])
		return NO;
	
	if ([[anItem title] isEqualToString: @"Remove File Type"] && [typesListDataBrowser selectedRow] == -1)
		return NO;
	
	if ([[anItem title] isEqualToString: @"Remove Suffix"] && [suffixListDataBrowser selectedRow] == -1)
		return NO;
	
	return YES;
}

#pragma mark -

- (TypesList *) types
{
	return typesList;
}

- (SuffixList *) suffixes
{
	return suffixList;
}

- (BOOL)acceptsText
{
    return [acceptDroppedTextCheckbox intValue];
}

- (NSString *)role
{
	return [[appFunctionRadioButtons selectedCell] title];
}

-(void) setRole: (NSString *)role
{
	if ([role isEqualToString: @"Viewer"])
		[appFunctionRadioButtons selectCellWithTag: 0];
	else
		[appFunctionRadioButtons selectCellWithTag: 1];
}
@end
