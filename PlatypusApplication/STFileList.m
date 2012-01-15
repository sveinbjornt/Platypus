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

// STFileList is a controller class around the Bundled Files list in the Platypus
// window.  It is the data source and delegate of the tableview with the files.
//
// NOTE: It's also a complete mess and needs to be rewritten, it was one of the very first
// pieces of code I ever wrote in Objective C, way back in the days...

#import "STFileList.h"
#import "PlatypusController.h"
#import "PlatypusUtility.h"

#import "UKKQueue.h"

@implementation STFileList

- (id) init
{
	files = [[NSMutableArray alloc] init];
	return self;
}

-(void)dealloc
{
	[files release];
	[super dealloc];
}

- (void)awakeFromNib
{
	totalSize = 0;
	[tableView registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
	[tableView setTarget: self];
	[tableView setDoubleAction:@selector(itemDoubleClicked:)];
	[tableView setDraggingSourceOperationMask: NSDragOperationCopy | NSDragOperationMove forLocal: NO];
	
	// we list ourself as an observer of changes to file system
	[[[NSWorkspace sharedWorkspace] notificationCenter]
		addObserver: self selector: @selector(trackedFileDidChange) name: UKFileWatcherRenameNotification object: NULL];
	[[[NSWorkspace sharedWorkspace] notificationCenter]
		addObserver: self selector: @selector(trackedFileDidChange) name: UKFileWatcherDeleteNotification object: NULL];
}

#pragma mark -

- (void)itemDoubleClicked: (id)sender
{
	if ([tableView clickedRow] == -1)
		return;
	
	if(GetCurrentKeyModifiers() & cmdKey)
		[self revealInFinder: [tableView clickedRow]];
	else
		[self openInFinder: [tableView clickedRow]];
}

- (void)trackedFileDidChange
{
	[tableView reloadData];
}

- (NSString *)getFileAtIndex:(int)index
{
	return [[files objectAtIndex: index] objectForKey: @"Path"];
}

- (void) addFile: (NSString *)fileName
{
	[self addFiles: [NSArray arrayWithObject: fileName]];
}

- (void) addFiles: (NSArray *)fileNames
{
	int i;
	
	for (i = 0; i < [fileNames count]; i++)
	{
		NSString *filePath = [fileNames objectAtIndex: i];

		if (![self hasFile: filePath])
		{
			NSMutableDictionary *fileInfoDict = [NSMutableDictionary dictionaryWithCapacity: 10];
			[fileInfoDict setObject: filePath forKey: @"Path"];
			
			NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile: filePath];
			[icon setSize: NSMakeSize(16,16)];
		
			[fileInfoDict setObject: icon forKey: @"Icon"];
			[files addObject: fileInfoDict];
		}
	}
	[tableView reloadData];
	[self tableViewSelectionDidChange: NULL];
	[self updateQueueWatch];
	[self updateFileSizeField];
}

-(void)updateQueueWatch
{
	int i;
	for (i = 0; i < [files count]; i++)
		[[UKKQueue sharedFileWatcher] addPathToQueue:  [[files objectAtIndex: i] objectForKey: @"Path"]];
		
}

- (BOOL) hasFile: (NSString *)fileName
{
	int i;
	
	for (i = 0; i < [files count]; i++)
	{
		if ([[[files objectAtIndex: i] objectForKey: @"Path"] isEqualToString: fileName])
			return YES;
	}
	return NO;
}

- (void) clearList
{
	[files removeAllObjects];
	[self updateQueueWatch];
	[tableView reloadData];
}

- (void) removeFile: (int)index
{
	[files removeObjectAtIndex: index];
	[self updateQueueWatch];
	[tableView reloadData];
}

- (int)numFiles
{
	return([files count]);
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [self numFiles];
}

- (NSArray *)getFilesArray
{
	NSMutableArray	*fileNames = [NSMutableArray arrayWithCapacity: PROGRAM_MAX_LIST_ITEMS];
	int				i;
	
	for (i = 0; i < [files count]; i++)
		[fileNames addObject: [[files objectAtIndex: i] objectForKey: @"Path"]];

	return fileNames;
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{	
	if ([[aTableColumn identifier] caseInsensitiveCompare: @"2"] == NSOrderedSame)//path
	{
		// check if bundled file still exists at path
		NSString *filePath = [[files objectAtIndex: rowIndex] objectForKey: @"Path"];
		if ([FILEMGR fileExistsAtPath: filePath])
			return([[files objectAtIndex: rowIndex] objectForKey: @"Path"]);
		else // if not, we hilight red
		{
			NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor redColor], NSForegroundColorAttributeName, nil];
			return([[[NSAttributedString alloc] initWithString: filePath attributes: attr] autorelease]);
		}
	}
	else if ([[aTableColumn identifier] caseInsensitiveCompare: @"1"] == NSOrderedSame)//icon
	{
        return [[files objectAtIndex: rowIndex] objectForKey: @"Icon"];
	}
	
	return(@"");
}


- (void)revealInFinder: (int)index
{
	BOOL		isDir;
	NSString	*path = [[files objectAtIndex: index] objectForKey: @"Path"];
	
	if ([FILEMGR fileExistsAtPath:path isDirectory:&isDir]) 
	{
        if (isDir)
            [[NSWorkspace sharedWorkspace] selectFile:nil inFileViewerRootedAtPath:path];
        else
            [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
	}
}

- (void)openInFinder: (int)index
{	
	[[NSWorkspace sharedWorkspace] openFile: [[files objectAtIndex: index] objectForKey: @"Path"]];
}

- (void)openInEditor: (int)index
{
	// if the default editor is the built-in editor, we pop down the editor sheet
	if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultEditor"] isEqualToString: DEFAULT_EDITOR])
	{
		[window setTitle: [NSString stringWithFormat: @"%@ - Editing script", PROGRAM_NAME]];
        EditorController *editor = [[EditorController alloc] init];
		[editor showEditorForFile: [[files objectAtIndex: index] objectForKey: @"Path"] window: window];
		[window setTitle: PROGRAM_NAME];
	}
	else // open it in the external application
	{
		NSString *defaultEditor = [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultEditor"];
		if ([[NSWorkspace sharedWorkspace] fullPathForApplication: defaultEditor] != NULL)
			[[NSWorkspace sharedWorkspace] openFile: [[files objectAtIndex: index] objectForKey: @"Path"] withApplication: defaultEditor];
		else
		{
			// Complain if editor is not found, set it to the built-in editor
			[PlatypusUtility alert: @"Application not found" subText: [NSString stringWithFormat: @"The application '%@' could not be found on your system.  Reverting to the built-in editor.", defaultEditor]];
			[[NSUserDefaults standardUserDefaults] setObject: DEFAULT_EDITOR  forKey:@"DefaultEditor"];
			[window setTitle: [NSString stringWithFormat: @"%@ - Editing script", PROGRAM_NAME]];
            [[[EditorController alloc] init] showEditorForFile: [[files objectAtIndex: index] objectForKey: @"Path"] window: window];
            [window setTitle: PROGRAM_NAME];
		}
	}	
}

/*****************************************
 - called when a [+] button is pressed
*****************************************/

- (IBAction)addFileToFileList:(id)sender
{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	[oPanel setPrompt:@"Add"];
	[oPanel setCanChooseDirectories:YES];
    [oPanel setAllowsMultipleSelection:YES];
	
	[window setTitle: [NSString stringWithFormat: @"%@ - Select files or folders to add", PROGRAM_NAME]];
	
	//run open panel
    [oPanel beginSheetForDirectory:nil file:nil types:nil modalForWindow: window modalDelegate: self didEndSelector: @selector(addFilesPanelDidEnd:returnCode:contextInfo:) contextInfo: nil];
}

- (void)addFilesPanelDidEnd:(NSOpenPanel *)oPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton)
	{
        [self addFiles: [oPanel filenames]];
	}
	
	[window setTitle: PROGRAM_NAME];
}

/*****************************************
 - called when [C] button is pressed
*****************************************/

- (IBAction)clearFileList:(id)sender
{
	[self clearList];
	[self updateQueueWatch];
	[tableView reloadData];
	//update button status
	[self tableViewSelectionDidChange: NULL];
	[self updateFileSizeField];
}


/*****************************************
 - called when [R] button is pressed
*****************************************/
- (IBAction)revealFileInFileList:(id)sender
{	
	int i;
	NSIndexSet *selectedItems = [tableView selectedRowIndexes];
	
	for (i = 0; i < [self numFiles]; i++)
	{
		if ([selectedItems containsIndex: i])
			[self revealInFinder: i];
	}
}

/*****************************************

 *****************************************/
- (IBAction)openFileInFileList:(id)sender
{	
	int i;
	NSIndexSet *selectedItems = [tableView selectedRowIndexes];
	
	for (i = 0; i < [self numFiles]; i++)
	{
		if ([selectedItems containsIndex: i])
			[self openInFinder: i];
	}
}

- (IBAction)editFileInFileList:(id)sender
{
	int i;
	NSIndexSet *selectedItems = [tableView selectedRowIndexes];
	
	for (i = 0; i < [self numFiles]; i++)
	{
		if ([selectedItems containsIndex: i])
			[self openInEditor: i];
	}
}

/*****************************************
 - called when [-] button is pressed
*****************************************/

- (IBAction)removeFileFromFileList:(id)sender
{
	int i, rowToSelect;
	NSIndexSet *selectedItems = [tableView selectedRowIndexes];
	int selectedRow = [selectedItems firstIndex];
	
	for (i = [self numFiles]; i >= 0; i--)
	{
		if ([selectedItems containsIndex: i])
		{
			[self removeFile: i];
		}
	}
	if ([tableView numberOfRows]) 
	{
		rowToSelect = selectedRow-1;
		[tableView selectRowIndexes: [NSIndexSet indexSetWithIndex: rowToSelect] byExtendingSelection: NO];
	}
	
	[tableView reloadData];
	[self tableViewSelectionDidChange: NULL];
	[self updateFileSizeField];
}

/*****************************************
 - Updates text field listing total size of bundled files
*****************************************/
- (void)updateFileSizeField
{
	int			i;
	
	totalSize = 0;
	NSString	*totalSizeString;
	

	//if there are no items, we just list it as 0 items
	if ([self numFiles] <= 0)
	{
		[bundleSizeTextField setStringValue: [NSString stringWithFormat: @"%d items", [self numFiles]]];
		[platypusControl updateEstimatedAppSize];
		return;
	}
	
	//otherwise, loop through all files, calculate size
	for (i = 0; i < [self numFiles]; i++)
	{		
		totalSize += [PlatypusUtility fileOrFolderSize: [self getFileAtIndex: i]];
	}
	
	totalSizeString = [PlatypusUtility sizeAsHumanReadable: totalSize];
	if ([self numFiles] > 1)
		[bundleSizeTextField setStringValue: [NSString stringWithFormat: @"%d items, %@", [self numFiles], totalSizeString]];
	else
		[bundleSizeTextField setStringValue: [NSString stringWithFormat: @"%d item, %@", [self numFiles], totalSizeString]];

	[platypusControl updateEstimatedAppSize];
}

#pragma mark -

/*****************************************
 - Delegate managing selection in the Bundled Files list
*****************************************/

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	int i;
	int selected = 0;
	NSIndexSet *selectedItems;
	
	//selection changed in File List
	if ([aNotification object] == tableView || [aNotification object] == NULL)
	{
		selectedItems = [tableView selectedRowIndexes];
		for (i = 0; i < [self numFiles]; i++)
		{
			if ([selectedItems containsIndex: i])
			{
				selected++;
			}
		}
		
		//update button status
		if (selected == 0)
		{
			[removeFileButton setEnabled: NO];
			[revealFileButton setEnabled: NO];
            [editFileButton setEnabled: NO];
		}
		else
		{
			[removeFileButton setEnabled: YES];
			[revealFileButton setEnabled: YES];
            [editFileButton setEnabled: YES];
		}
		
		if ([self numFiles] == 0)
			[clearFileListButton setEnabled: NO];
		else
			[clearFileListButton setEnabled: YES];
	}
}

- (int)currentSelectedRow
{
	return [tableView selectedRow];
}


/*****************************************
 - Drag and drop handling
*****************************************/
-(BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard *pboard = [info draggingPasteboard];	
	NSArray *draggedFiles = [pboard propertyListForType:NSFilenamesPboardType];
	[self addFiles: draggedFiles];
	return YES;
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard 
{
	NSMutableArray *filenames = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
	NSInteger index = [rowIndexes firstIndex];
	
	while (NSNotFound != index) 
	{
		[filenames addObject: [[files objectAtIndex: index] objectForKey: @"Path"]];
		index = [rowIndexes indexGreaterThanIndex: index];
	}
	
	[pboard declareTypes: [NSArray arrayWithObject: NSFilenamesPboardType] owner: NULL];
	[pboard setPropertyList: filenames forType: NSFilenamesPboardType];
	
	return YES;
	
}

-(NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	return NSDragOperationLink;
}

#pragma mark -

/*****************************************
 - Delegate for enabling and disabling contextual menu items
*****************************************/
- (BOOL)validateMenuItem:(NSMenuItem*)anItem 
{
	int selectedRow = [tableView selectedRow];

	if ([[anItem title] isEqualToString: @"Add New File"] || [[anItem title] isEqualToString: @"Add File To Bundle"])
		return YES;
	
	if ([[anItem title] isEqualToString: @"Clear File List"] && [self numFiles] >= 1)
		return YES;

	if (selectedRow == -1)
		return NO;

	return YES;
}

#pragma mark -

/*****************************************
 - Tells us whether there are missing/moved files on the list
*****************************************/
- (BOOL)allPathsAreValid
{
	int i;
	
	for (i = 0; i < [self numFiles]; i++)
	{
		if (![FILEMGR fileExistsAtPath: [[files objectAtIndex: i] objectForKey: @"Path"]])
			return NO;
	}
	return YES;
}

/*****************************************
 - Returns the total size of all bundled files at the moment
*****************************************/

-(UInt64)getTotalSize
{
	return totalSize;
}

@end
