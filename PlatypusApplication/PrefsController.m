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

#import "PrefsController.h"


@implementation PrefsController

- (id)init 
{
    return [super initWithWindowNibName: @"Preferences"];
}

/*****************************************
 - Set controls according to data in NSUserDefaults
*****************************************/

- (IBAction)showWindow:(id)sender
{	
	[super loadWindow];
	
	// set controls according to NSUserDefaults
	[defaultEditorMenu setTitle: [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultEditor"]];
	[defaultArchitecturePopupButton selectItemWithTitle: [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultArchitecture"]];
	[defaultTextEncodingPopupButton selectItemWithTag: [[[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultTextEncoding"] intValue]];
	[defaultBundleIdentifierTextField setStringValue: [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultBundleIdentifierPrefix"]];
	[defaultAuthorTextField setStringValue: [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultAuthor"]];
	[revealAppCheckbox setState: [[NSUserDefaults standardUserDefaults] boolForKey:@"RevealApplicationWhenCreated"]];
		
	//set icons for editor menu
	[self setIconsForEditorMenu];
	[self updateCLTStatus: CLTStatusTextField];	
	
	[super showWindow: sender];
}

/*****************************************
 - Set the icons for the menu items in the Editors list
*****************************************/

- (void)setIconsForEditorMenu
{
	int i;
	NSSize	smallIconSize = { 16, 16 };

	for (i = 0; i < [defaultEditorMenu numberOfItems]; i++)
	{
		if ([[[defaultEditorMenu itemAtIndex: i] title] isEqualToString: DEFAULT_EDITOR] == YES)
		{
			NSImage *icon = [NSImage imageNamed: @"Platypus"];
			[icon setSize: smallIconSize];
			[[defaultEditorMenu itemAtIndex: i] setImage: icon];
		}
		else if ([[[defaultEditorMenu itemAtIndex: i] title] isEqualToString: @"Select..."] == NO && [[[defaultEditorMenu itemAtIndex: i] title] length] > 0)
		{
			NSImage *icon = [NSImage imageNamed: @"NSDefaultApplicationIcon"];
			NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication: [[defaultEditorMenu itemAtIndex: i] title]];
			if (appPath != NULL) // app found
				icon = [[NSWorkspace sharedWorkspace] iconForFile: appPath];
			[icon setSize: smallIconSize];
			[[defaultEditorMenu itemAtIndex: i] setImage: icon];
		}
	}
}

/*****************************************
 - Set NSUserDefaults according to control settings
*****************************************/

- (IBAction)applyPrefs:(id)sender
{
	// editor
	[[NSUserDefaults standardUserDefaults] setObject: [defaultEditorMenu titleOfSelectedItem]  forKey:@"DefaultEditor"];
	
	// text encoding
	[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: [[defaultTextEncodingPopupButton selectedItem] tag]]  forKey:@"DefaultTextEncoding"];
	
	// architecture
	[[NSUserDefaults standardUserDefaults] setObject: [defaultArchitecturePopupButton titleOfSelectedItem]  forKey:@"DefaultArchitecture"];
	
	//bundle identifier
	//make sure bundle identifier ends with a '.'
	if ([[defaultBundleIdentifierTextField stringValue] characterAtIndex: [[defaultBundleIdentifierTextField stringValue]length]-1] != '.')
		[[NSUserDefaults standardUserDefaults] setObject: [[defaultBundleIdentifierTextField stringValue] stringByAppendingString: @"."]  forKey:@"DefaultBundleIdentifierPrefix"];
	else
		[[NSUserDefaults standardUserDefaults] setObject: [defaultBundleIdentifierTextField stringValue]  forKey:@"DefaultBundleIdentifierPrefix"];
	//author
	[[NSUserDefaults standardUserDefaults] setObject: [defaultAuthorTextField stringValue]  forKey:@"DefaultAuthor"];

	// reveal
	[[NSUserDefaults standardUserDefaults] setBool: [revealAppCheckbox state]  forKey:@"RevealApplicationWhenCreated"];

	[[self window] close];
}

- (IBAction)cancel:(id)sender
{
	[[self window] close];
}

/*****************************************
 - Restore prefs to their default value
*****************************************/

- (IBAction)restoreDefaultPrefs:(id)sender
{
	[revealAppCheckbox setState: NO];
	[defaultEditorMenu setTitle: DEFAULT_EDITOR];
	[defaultArchitecturePopupButton selectItemWithTitle: DEFAULT_ARCHITECTURE];
	[defaultTextEncodingPopupButton selectItemWithTag: DEFAULT_OUTPUT_TXT_ENCODING];
	[defaultAuthorTextField setStringValue: NSFullUserName()];
	
	// create default bundle identifier prefix string
	NSString *bundleId = [NSString stringWithFormat: @"org.%@.", NSUserName()];
	bundleId = [[bundleId componentsSeparatedByString:@" "] componentsJoinedByString:@""];//remove all spaces
	[defaultBundleIdentifierTextField setStringValue: bundleId];
}


/*****************************************
 - For selecting any application as the external editor for script
*****************************************/

- (IBAction) selectScriptEditor:(id)sender
{
	int			result;
	NSString	*editorName;
	
	//create open panel
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	[oPanel setTitle: @"Select Editor"];
    [oPanel setAllowsMultipleSelection:NO];
	[oPanel setCanChooseDirectories: NO];
	
	//run open panel
    result = [oPanel runModalForDirectory:nil file:nil types: [NSArray arrayWithObject:@"app"]];
    if (result == NSOKButton) 
	{
		//set app name minus .app suffix
		editorName = [[[oPanel filename] lastPathComponent] stringByDeletingPathExtension];
		[defaultEditorMenu setTitle: editorName];
		[self setIconsForEditorMenu];
	}
	else
		[defaultEditorMenu setTitle: [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultEditor"]];
}

/*****************************************
 - Update report on command line tool install status
    -- both text field and button
*****************************************/

- (void)updateCLTStatus: (NSTextField *)textField
{
	//set status of clt install button and text field
	if ([self isCommandLineToolInstalled])
	{
		NSString *versionString = [NSString stringWithContentsOfFile: CMDLINE_VERSION_PATH encoding: NSUTF8StringEncoding error: NULL];
		
		if ([versionString isEqualToString: PROGRAM_VERSION]) // it's installed and current
		{
			[textField setTextColor: [NSColor colorWithCalibratedRed: 0.0 green: 0.6 blue: 0.0 alpha: 1.0]];
			[textField setStringValue: @"Command line tool is installed"];
		}
		else // installed but not this version
		{
			[textField setTextColor: [NSColor orangeColor]];

			if ([versionString floatValue] < [PROGRAM_VERSION floatValue])
				[textField setStringValue: @"Old version of command line"]; //older
			else
				[textField setStringValue: @"Newer version of command line"]; //newer
		}
		[installCLTButton setTitle: @"Uninstall"];
	}
	else  // it's not installed at all
	{
		[textField setStringValue: @"Command line tool is not installed"];
		[textField setTextColor: [NSColor redColor]];
		[installCLTButton setTitle: @"Install"];
	}
}

/*****************************************
 - Install/uninstall CLT based on install status
*****************************************/

- (IBAction)installCLT:(id)sender;
{
	if ([self isCommandLineToolInstalled] == NO)
		[self installCommandLineTool];
	else
		[self uninstallCommandLineTool];
}

/*****************************************
 - Run install script for CLT stuff
*****************************************/

-(void)installCommandLineTool
{
	[self runCLTScript: @"InstallCommandLineTool.sh"];
}

/*****************************************
 - Run UNinstall script for CLT stuff
*****************************************/

-(void)uninstallCommandLineTool
{
	[self runCLTScript: @"UninstallCommandLineTool.sh"];
}

/*****************************************
 - Run a script with privileges from the Resources folder
 *****************************************/

-(void)runCLTScript: (NSString *)scriptName
{
	[installCLTProgressIndicator setUsesThreadedAnimation: YES];
	[installCLTProgressIndicator startAnimation: self];
	[self executeScriptWithPrivileges: [[NSBundle mainBundle] pathForResource: scriptName ofType: NULL]];
	[self updateCLTStatus: CLTStatusTextField];
	[installCLTProgressIndicator stopAnimation: self];
}

/*****************************************
 - Determine whether command line tool is installed
*****************************************/

-(BOOL)isCommandLineToolInstalled
{
	return	   ([[NSFileManager defaultManager] fileExistsAtPath: CMDLINE_VERSION_PATH] &&
				[[NSFileManager defaultManager] fileExistsAtPath: CMDLINE_TOOL_PATH] &&
				[[NSFileManager defaultManager] fileExistsAtPath: CMDLINE_MANPAGE_PATH] &&
				[[NSFileManager defaultManager] fileExistsAtPath: CMDLINE_EXEC_PATH] &&
				[[NSFileManager defaultManager] fileExistsAtPath: CMDLINE_ICON_PATH]);
}

/*****************************************
 - Run script with privileges using Authentication Manager
*****************************************/
- (void)executeScriptWithPrivileges: (NSString *)pathToScript
{
	// execute path, pass Resources directory and version as arguments 1 and 2
	[STPrivilegedTask launchedPrivilegedTaskWithLaunchPath: pathToScript arguments: [NSArray arrayWithObjects: [[NSBundle mainBundle] resourcePath], PROGRAM_VERSION, nil]];
}

@end
