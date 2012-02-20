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

#import "ProfilesController.h"

@implementation ProfilesController

/*****************************************
 - Select dialog for .platypus profile
*****************************************/

- (IBAction)loadProfile:(id)sender
{
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	[oPanel setPrompt: @"Open"];
	[oPanel setTitle: [NSString stringWithFormat: @"Select %@ Profile", PROGRAM_NAME]];
    [oPanel setAllowsMultipleSelection:NO];
	[oPanel setCanChooseDirectories: NO];
	
	if (NSOKButton == [oPanel runModalForDirectory: [PROFILES_FOLDER stringByExpandingTildeInPath] file: NULL types: [NSArray arrayWithObjects: @"platypus", NULL]])
		[self loadProfileFile: [oPanel filename]];
}

/*****************************************
 - Deal with dropped .platypus profile files
*****************************************/

- (void)loadProfileFile: (NSString *)file
{	
	PlatypusAppSpec *spec = [[PlatypusAppSpec alloc] initWithProfile: file];
    
	// make sure we got a spec from the file
	if (spec == NULL)
	{
		[PlatypusUtility alert: @"Error" subText: @"Unable to create Platypus spec from profile"];
		return;
	}
    
    // check if it's an example
    if ([spec propertyForKey: @"Example"] != nil)
    {
        // make sure of the example profile's integrity
        NSString *scriptStr = [spec propertyForKey: @"Script"];
        NSString *scriptName = [spec propertyForKey: @"ScriptName"];
        if (scriptStr == nil || scriptName == nil)
        {
            [PlatypusUtility alert: @"Error loading example" subText: @"Nil script value(s) in this example's profile dictionary."];
            [spec release];
            return;
        }
        // write script contained in the example profile dictionary to file
        NSString *scriptPath = [[NSString stringWithFormat: @"%@%@", TEMP_FOLDER, scriptName] stringByExpandingTildeInPath];
        [scriptStr writeToFile: scriptPath atomically: YES encoding: DEFAULT_OUTPUT_TXT_ENCODING error: nil];
        
        // set this path as the source script path
        [spec setProperty: scriptPath forKey: @"ScriptPath"];
    }
	
	// warn if created with a different version of Platypus
//	if (![[spec propertyForKey: @"Creator"] isEqualToString: PROGRAM_STAMP])
//		[PlatypusUtility alert:@"Version clash" subText: @"The profile you selected was created with a different version of Platypus and may not load correctly."];
	
	[platypusControl controlsFromAppSpec: spec];
	[platypusControl controlTextDidChange: NULL];
    [spec release];
}

/*****************************************
 - Save a profile with values from fields in default location
*****************************************/

- (IBAction)saveProfile:(id)sender;
{
	if (![platypusControl verifyFieldContents])
		return;

	// get profile from platypus controls
	NSDictionary *profileDict = [[platypusControl appSpecFromControls] properties];
	
	// create path for profile file and write to it
	NSString *profileDestPath = [NSString stringWithFormat: @"%@/%@.%@", 
                                 [PROFILES_FOLDER stringByExpandingTildeInPath], 
                                 [profileDict objectForKey: @"Name"], 
                                 PROFILES_SUFFIX];
	[self writeProfile: profileDict toFile: profileDestPath];
}

/*****************************************
 - Save a profile with in user-specified location
*****************************************/

- (IBAction)saveProfileToLocation:(id)sender;
{
	if (![platypusControl verifyFieldContents])
		return;

	// get profile from platypus controls
	NSDictionary *profileDict = [[platypusControl appSpecFromControls] properties];
	NSString *defaultName = [NSString stringWithFormat: @"%@.%@", [profileDict objectForKey: @"Name"], PROFILES_SUFFIX];
	
	NSSavePanel *sPanel = [NSSavePanel savePanel];
	[sPanel setTitle: [NSString stringWithFormat: @"Save %@ Profile", PROGRAM_NAME]];
	[sPanel setPrompt:@"Save"];
	
	if ([sPanel runModalForDirectory:  [PROFILES_FOLDER stringByExpandingTildeInPath] file: defaultName] == NSFileHandlingPanelOKButton)
	{
		NSString *fileName = [sPanel filename];
		
		if (! [fileName hasSuffix: PROFILES_SUFFIX])
			fileName = [NSString stringWithFormat: @"%@.%@", fileName, PROFILES_SUFFIX];
		
		[self writeProfile: profileDict toFile: fileName];
	}
}


/*****************************************
 - Write profile dictionary to path
*****************************************/

- (void)writeProfile: (NSDictionary *)dict toFile: (NSString *)profileDestPath;
{
	// if there's a file already, make sure we can overwrite
	if ([FILEMGR fileExistsAtPath: profileDestPath] && ![FILEMGR isDeletableFileAtPath: profileDestPath])
	{
		[PlatypusUtility alert: @"Error" subText: [NSString stringWithFormat: @"Cannot overwrite file '%@'.", profileDestPath]];
		return;
	}
	[dict writeToFile: profileDestPath atomically: YES];
	[self constructMenus: self];
}


/*****************************************
 - Fill Platypus fields in with data from profile when it's selected in the menu
*****************************************/

-(void)profileMenuItemSelected: (id)sender
{
    BOOL isExample = ([sender tag]  == EXAMPLES_TAG);
	NSString *folder = PROFILES_FOLDER;
	if (isExample)
		folder = [NSString stringWithFormat: @"%@/Examples/", [[NSBundle mainBundle] resourcePath]];
    
	NSString *profilePath = [NSString stringWithFormat: @"%@/%@", [folder stringByExpandingTildeInPath], [sender title]];

	// if command key is down, we reveal in finder
	if(GetCurrentKeyModifiers() & cmdKey)
		[[NSWorkspace sharedWorkspace] selectFile: profilePath inFileViewerRootedAtPath:nil];
	else
		[self loadProfileFile: profilePath];
}

/*****************************************
 - Clear the profiles list
*****************************************/

- (IBAction) clearAllProfiles:(id)sender
{
	if ([PlatypusUtility proceedWarning: @"Delete all profiles?" subText: @"This will permanently delete all profiles in your Profiles folder." withAction: @"Delete"] == 0)
		return;

	//delete all .platypus files in PROFILES_FOLDER
	
	NSFileManager			*manager = FILEMGR;
	NSDirectoryEnumerator	*dirEnumerator = [manager enumeratorAtPath: [PROFILES_FOLDER stringByExpandingTildeInPath]];
	NSString *filename;
	
	while ((filename = [dirEnumerator nextObject]) != NULL)
	{
		if ([filename hasSuffix: PROFILES_SUFFIX])
		{
			NSString *path = [NSString stringWithFormat: @"%@/%@",[PROFILES_FOLDER stringByExpandingTildeInPath],filename];
			if (![manager isDeletableFileAtPath: path])
				[PlatypusUtility alert: @"Error" subText: [NSString stringWithFormat: @"Cannot delete file %@.", path]];
			[manager removeItemAtPath: path error: nil];
		}
	}
	
	//regenerate the menu
	[self constructMenus: self];
}

/*****************************************
 - Generate the Profiles menu according to the save profiles
*****************************************/

- (IBAction)constructMenus: (id)sender
{
	int i;
	NSArray *profiles = [self getProfilesList];
	NSArray *examples = [self getExamplesList];
	
	// Create icon
	NSImage *icon = [NSImage imageNamed: @"PlatypusProfile"];
	[icon setSize: NSMakeSize(16,16)];
	
	// Create Examples menu
	NSMenu *em = [[[NSMenu alloc] init] autorelease];
	for (i = 0; i < [examples count]; i++)
	{
		NSMenuItem *menuItem = [em addItemWithTitle: [examples objectAtIndex: i] action: @selector(profileMenuItemSelected:) keyEquivalent:@""];
		[menuItem setTarget: self];
		[menuItem setEnabled: YES];
		[menuItem setImage: icon];
		[menuItem setTag: EXAMPLES_TAG];
	}
	
	[(NSMenuItem *)examplesMenuItem setSubmenu: em];
	
	//clear out all menu items
	while ([profilesMenu numberOfItems] > 6)
		[profilesMenu removeItemAtIndex: 6];

	if ([profiles count] > 0)
	{	
		//populate with contents of array
		for (i = 0; i < [profiles count]; i++)
		{
			NSMenuItem *menuItem = [profilesMenu addItemWithTitle: [profiles objectAtIndex: i] action: @selector(profileMenuItemSelected:) keyEquivalent:@""];
			[menuItem setTarget: self];
			[menuItem setEnabled: YES];
			[menuItem setImage: icon ];
		}
		
		[profilesMenu addItem: [NSMenuItem separatorItem]];
		
		NSMenuItem *menuItem = [profilesMenu addItemWithTitle: @"Open Profiles Folder" action: @selector(openProfilesFolder) keyEquivalent:@""];
		[menuItem setTarget: self];
		[menuItem setEnabled: YES];
	}
	else
		[profilesMenu addItemWithTitle: @"Empty" action: NULL keyEquivalent:@""];
}

-(void)openProfilesFolder
{
	[[NSWorkspace sharedWorkspace] selectFile: NULL inFileViewerRootedAtPath: [PROFILES_FOLDER stringByExpandingTildeInPath]];
}

/*****************************************
 - Get list of .platypus files in Profiles folder
*****************************************/

- (NSArray *)getProfilesList
{
	NSMutableArray			*profilesArray = [NSMutableArray arrayWithCapacity: PROGRAM_MAX_LIST_ITEMS];
	NSFileManager			*manager = FILEMGR;
	NSDirectoryEnumerator	*dirEnumerator = [manager enumeratorAtPath: [PROFILES_FOLDER stringByExpandingTildeInPath]];
	NSString *filename;
	while ((filename = [dirEnumerator nextObject]) != NULL)
	{
		if ([filename hasSuffix: PROFILES_SUFFIX])
			[profilesArray addObject: filename];
	}
	return profilesArray;
}

- (NSArray *)getExamplesList
{
	NSMutableArray			*examplesArray = [NSMutableArray arrayWithCapacity: PROGRAM_MAX_LIST_ITEMS];
	NSFileManager			*manager = FILEMGR;
	NSDirectoryEnumerator	*dirEnumerator = [manager enumeratorAtPath: [NSString stringWithFormat: @"%@/Examples/", [[NSBundle mainBundle] resourcePath]]];
	NSString *filename;
	while ((filename = [dirEnumerator nextObject]) != NULL)
	{
		if ([filename hasSuffix: PROFILES_SUFFIX])
			[examplesArray addObject: filename];
	}
	return examplesArray;
}

/*****************************************
 - Profile menu item validation
*****************************************/

- (BOOL)validateMenuItem:(NSMenuItem*)anItem 
{
	if ([[anItem title] isEqualToString:@"Clear All Profiles"] && [[self getProfilesList] count] < 1)
		return NO;
	
	return YES;
}

- (void)menuWillOpen:(NSMenu *)menu
{
	// we do this lazily
	[self constructMenus: self];
}

@end
