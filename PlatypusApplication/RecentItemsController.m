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

#import "RecentItemsController.h"

@implementation RecentItemsController

/*****************************************
 - Load the script of item selected in Open Recent Menu
 *****************************************/

-(void) openRecentMenuItemSelected: (id)sender
{
	BOOL			isDir = NO;
	NSString		*filePath = [sender title];
	
	// reveal if Cmd key is down
	if(GetCurrentKeyModifiers() & cmdKey)
	{
		[[NSWorkspace sharedWorkspace] selectFile: filePath inFileViewerRootedAtPath:nil];
		return;
	}
	
	// otherwise load item
	if ([[NSFileManager defaultManager] fileExistsAtPath: filePath isDirectory: &isDir] && isDir == NO)
		[platypusController loadScript: filePath];
	else
		[STUtil alert:@"Invalid item" subText: @"The file you selected no longer exists at the specified path."];
}

/*****************************************
 - Generate the Open Recent Menu
 *****************************************/

- (void)menuWillOpen:(NSMenu *)menu
{
	[self constructOpenRecentMenu: self];
}

-(IBAction) constructOpenRecentMenu: (id)sender
{	
	int i;
	NSArray *recentItems = [[NSUserDefaults standardUserDefaults] objectForKey:@"RecentItems"];
	
	//clear out all menu items
	while ([openRecentMenu numberOfItems])
		[openRecentMenu removeItemAtIndex: 0];
	
	if ([recentItems count] == 0)
	{
		[openRecentMenu addItemWithTitle: @"Empty" action: nil keyEquivalent:@""];
		[[openRecentMenu itemAtIndex: 0] setEnabled: NO];
		return;
	}
	
	//populate with contents of array
	for (i = [recentItems count]-1; i >= 0 ; i--)
	{
		NSString *filePath = [recentItems objectAtIndex: i];
		NSMenuItem *menuItem = [openRecentMenu addItemWithTitle: filePath action: @selector(openRecentMenuItemSelected:) keyEquivalent:@""];
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile: filePath];
		[icon setSize: NSMakeSize(16,16)];
		[menuItem setImage: icon];
		[menuItem setTarget: self];
		
		// if file no longer exists at path, color it red
		if (![[NSFileManager defaultManager] fileExistsAtPath: filePath])
		{
			NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor redColor], NSForegroundColorAttributeName, [NSFont menuFontOfSize: 14.0] , NSFontAttributeName, NULL];
			NSAttributedString *attStr = [[[NSAttributedString alloc] initWithString: filePath attributes: attr] autorelease];
			[menuItem setAttributedTitle: attStr];
		}
	}
	
	//add seperator and clear menu
	[openRecentMenu addItem: [NSMenuItem separatorItem]];
	[[openRecentMenu addItemWithTitle: @"Clear Menu" action: @selector(clearRecentItems) keyEquivalent:@""] setTarget: self];
}

/*****************************************
 - Clear the Recent Items menu
 *****************************************/

-(void) clearRecentItems
{
	[[NSUserDefaults standardUserDefaults] setObject: [NSArray array] forKey: @"RecentItems"];
}

@end
