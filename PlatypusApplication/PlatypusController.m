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

// PlatypusController class is the controller class for the basic Platypus 
// main window interface.  Also delegate for the application, and for menus.

#import "PlatypusController.h"

@implementation PlatypusController

#pragma mark Application functions

/*****************************************
 - When application is launched by the user for the very first time
   we create a default set of preferences
*****************************************/

+ (void)initialize 
{ 
	// create the user defaults here if none exists
    NSMutableDictionary *defaultPrefs = [NSMutableDictionary dictionary];
    
	// put default prefs in the dictionary

	// create default bundle identifier string from usename
	NSString *bundleId = [NSString stringWithFormat: @"org.%@.", NSUserName()];
	bundleId = [[bundleId componentsSeparatedByString: @" "] componentsJoinedByString: @""];//no spaces
	
	[defaultPrefs setObject: bundleId						forKey: @"DefaultBundleIdentifierPrefix"];
	[defaultPrefs setObject: DEFAULT_EDITOR					forKey: @"DefaultEditor"];
	[defaultPrefs setObject: [NSArray array]				forKey: @"Profiles"];
	[defaultPrefs setObject: [NSNumber numberWithBool:NO]	forKey: @"RevealApplicationWhenCreated"];
	[defaultPrefs setObject: [NSNumber numberWithInt: DEFAULT_OUTPUT_TXT_ENCODING]
															forKey: @"DefaultTextEncoding"];
	[defaultPrefs setObject: NSFullUserName()				forKey: @"DefaultAuthor"];
	
    // register the dictionary of defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultPrefs];
}

- (void)awakeFromNib
{	
	// make sure application support folder and subfolders exist
	BOOL isDir;
	
	// app support folder
	if (! [[NSFileManager defaultManager] fileExistsAtPath: [APP_SUPPORT_FOLDER stringByExpandingTildeInPath] isDirectory: &isDir])
		if ( ! [[NSFileManager defaultManager] createDirectoryAtPath: [APP_SUPPORT_FOLDER stringByExpandingTildeInPath] attributes: NULL] )
			[STUtil alert: @"Error" subText: [NSString stringWithFormat: @"Could not create directory '%@'", [APP_SUPPORT_FOLDER stringByExpandingTildeInPath]]]; 
	
	// profiles folder
	if (! [[NSFileManager defaultManager] fileExistsAtPath: [PROFILES_FOLDER stringByExpandingTildeInPath] isDirectory: &isDir])
		if ( ! [[NSFileManager defaultManager] createDirectoryAtPath: [PROFILES_FOLDER stringByExpandingTildeInPath] attributes: NULL] )
			[STUtil alert: @"Error" subText: [NSString stringWithFormat: @"Could not create directory '%@'", [PROFILES_FOLDER stringByExpandingTildeInPath]]]; 
	
	
	// we list ourself as an observer of changes to file system, for script
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(controlTextDidChange:) name: UKFileWatcherRenameNotification object: NULL];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(controlTextDidChange:) name: UKFileWatcherDeleteNotification object: NULL];
			
	//populate script type menu
	[scriptTypePopupMenu addItemsWithTitles: [ScriptAnalyser interpreterDisplayNames]];
	
	[window registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, NSStringPboardType, nil]];
	[window makeFirstResponder: appNameTextField];

	// if we haven't already loaded a profile via openfile delegate method
	// we set all fields to their defaults.  Any profile must contain a name
	// so we can be sure that one hasn't been loaded if the app name field is empty
	if ([[appNameTextField stringValue] isEqualToString: @""])
		[self clearAllFields: self];
}

/*****************************************
 - Handler for when app is done launching
 - Set up the window and stuff like that
*****************************************/

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{		
    // register for sudden termination for >= Mac OS X 10.6
    if ([STUtil runningSnowLeopardOrLater]) 
    {
        //[[NSProcessInfo processInfo] enableSuddenTermination];
    }
    
	//show window
	[window center];
	[window makeKeyAndOrderFront: self];
}

/*****************************************
 - Handler for dragged files and/or files opened via the Finder
   We handle these as scripts, not bundled files
*****************************************/

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{		
	if ([filename hasSuffix: PROFILES_SUFFIX]) //load as profile
		[profilesControl loadProfileFile: filename];
	else //load as script
		[self loadScript: filename];
		
	return YES;
}

#pragma mark Script functions

/*****************************************
 - Create a new script and open in default editor
*****************************************/

- (IBAction)newScript:(id)sender
{
	NSString *newScriptPath = [self createNewScript: NULL];
	
	//load and edit the script
	[self loadScript: newScriptPath];
	[self editScript: self];
}

/*****************************************
 - Create a new script in app support directory
 with settings etc. from controls
 *****************************************/

- (NSString *)createNewScript: (NSString *)scriptText
{
	NSString	*tempScript;
	
	// get a random number to append to script name in /tmp/
	do
	{
		int randnum =  random() / 1000000;
		tempScript = [NSString stringWithFormat: @"%@Script.%d", [TEMP_FOLDER stringByExpandingTildeInPath], randnum];
	}
	while ([[NSFileManager defaultManager] fileExistsAtPath: tempScript]);
	
	//put shebang line in the new script text file
	NSString	*contentString = [NSString stringWithFormat: @"#!%@\n\n", [interpreterTextField stringValue]];
	
	//if this is a perl or shell script, we add a commented list of paths to the bundled files 
	if (([[interpreterTextField stringValue] isEqualToString: @"/usr/bin/perl"] || [[interpreterTextField stringValue] isEqualToString: @"/bin/sh"]) && [fileList numFiles] > 0)
	{
		contentString = [contentString stringByAppendingString: @"# The following files are bundled:\n#\n"];

		int	i;
		for (i = 0; i < [fileList numFiles]; i++)
		{
            contentString = [contentString stringByAppendingString: [NSString stringWithFormat:@"# '%@'\n", [[fileList getFileAtIndex: i] lastPathComponent]]];
		}
		
		contentString = [contentString stringByAppendingString: @"#\n#\n\n"];
	}
	
	if (scriptText != NULL && [scriptText length])
		contentString = [contentString stringByAppendingString: scriptText];

		//write the default content to the new script
	[contentString writeToFile: tempScript atomically: YES encoding: [[[NSUserDefaults standardUserDefaults] objectForKey: @"DefaultTextEncoding"] intValue] error: NULL];

	return tempScript;
}

/*****************************************
 - Reveal script in Finder
*****************************************/

- (IBAction)revealScript:(id)sender
{
	[[NSWorkspace sharedWorkspace] selectFile:[scriptPathTextField stringValue] inFileViewerRootedAtPath:nil];
}

/*****************************************
 - Open script in external editor
*****************************************/

- (IBAction)editScript:(id)sender
{		
	//see if file exists
	if (![[NSFileManager defaultManager] fileExistsAtPath: [scriptPathTextField stringValue]])
	{
		[STUtil alert:@"File does not exist" subText: @"No file exists at the specified path"];
		return;
	}

	// if the default editor is the built-in editor, we pop down the editor sheet
	if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultEditor"] isEqualToString: DEFAULT_EDITOR])
	{
		[self openScriptInBuiltInEditor: [scriptPathTextField stringValue]];
	}
	else // open it in the external application
	{
		NSString *defaultEditor = [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultEditor"];
		if ([[NSWorkspace sharedWorkspace] fullPathForApplication: defaultEditor] != NULL)
			[[NSWorkspace sharedWorkspace] openFile: [scriptPathTextField stringValue] withApplication: defaultEditor];
		else
		{
			// Complain if editor is not found, set it to the built-in editor
			[STUtil alert: @"Application not found" subText: [NSString stringWithFormat: @"The application '%@' could not be found on your system.  Reverting to the built-in editor.", defaultEditor]];
			[[NSUserDefaults standardUserDefaults] setObject: DEFAULT_EDITOR  forKey:@"DefaultEditor"];
			[self openScriptInBuiltInEditor: [scriptPathTextField stringValue]];
		}
	}		
}

/*****************************************
 - Run the script in Terminal.app via Apple Event
*****************************************/

- (IBAction)runScript:(id)sender
{
	NSString *osaCmd = [NSString stringWithFormat: @"tell application \"Terminal\"\n\tdo script \"%@ '%@'\"\nend tell", [interpreterTextField stringValue], [scriptPathTextField stringValue]];
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource: osaCmd];
	[script executeAndReturnError: nil];
	[script release];
}

/*****************************************
 - Report on syntax of script
*****************************************/

- (IBAction)checkSyntaxOfScript: (id)sender
{
	[window setTitle: [NSString stringWithFormat: @"%@ - Syntax Checker", PROGRAM_NAME]];
	
	[[[SyntaxCheckerController alloc] init] 
			showSyntaxCheckerForFile: [scriptPathTextField stringValue] 
					 withInterpreter: [interpreterTextField stringValue]
							  window: window];

	[window setTitle: PROGRAM_NAME];
}

/*****************************************
 - Built-In script editor
 *****************************************/

- (void)openScriptInBuiltInEditor: (NSString *)path
{
	[window setTitle: [NSString stringWithFormat: @"%@ - Editing script", PROGRAM_NAME]];
	[[[EditorController alloc] init] showEditorForFile: [scriptPathTextField stringValue] window: window];
	[window setTitle: PROGRAM_NAME];
}

#pragma mark Create

/*********************************************************************
 - Create button was pressed: Verify that field values are valid
 - Then put up a sheet for designating location to create application
**********************************************************************/

- (IBAction)createButtonPressed: (id)sender
{
	if (![self verifyFieldContents])//are there invalid values in the fields?
		return;

	NSSavePanel *sPanel = [NSSavePanel savePanel];
	[sPanel setPrompt:@"Create"];
	[window setTitle: [NSString stringWithFormat: @"%@ - Select place to create app", PROGRAM_NAME]];
	[sPanel setAccessoryView: debugSaveOptionView];
	
	// development version checkbox, disable this option if secure bundled script is checked
	[developmentVersionCheckbox setIntValue: 0];
	[developmentVersionCheckbox setEnabled: ![encryptCheckbox intValue]];	
	
	// optimize application is enabled and on by default if ibtool is present
	BOOL ibtoolInstalled = [[NSFileManager defaultManager] fileExistsAtPath: IBTOOL_PATH];
	[optimizeApplicationCheckbox setEnabled: ibtoolInstalled];
	[optimizeApplicationCheckbox setIntValue: ibtoolInstalled];
	
	//run save panel
    [sPanel beginSheetForDirectory: nil file: [appNameTextField stringValue] modalForWindow: window modalDelegate: self didEndSelector: @selector(createConfirmed:returnCode:contextInfo:) contextInfo: nil];
	[NSApp runModalForWindow: window];
}

- (void)createConfirmed:(NSSavePanel *)sPanel returnCode:(int)result contextInfo:(void *)contextInfo
{
	//restore window title
	[window setTitle: PROGRAM_NAME];
	
	[NSApp endSheet: window];
	[NSApp stopModal];
	
	//if user pressed cancel, we do nothing
	if (result != NSOKButton) 
		return;
	
	//else, we go ahead with creating the application
	[NSTimer scheduledTimerWithTimeInterval: 0.0001 target: self selector:@selector(createApplication:) userInfo: [sPanel filename] repeats: NO];
}

- (void)creationStatusUpdated: (NSNotification *)aNotification
{
    [progressDialogStatusLabel setStringValue:[aNotification object]];
    [[progressDialogStatusLabel window] display];
}

- (BOOL)createApplication: (NSTimer *)theTimer
{
	BOOL overwrite = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(creationStatusUpdated:)
												 name: @"PlatypusAppSpecCreationNotification"
											   object: NULL];
	
	// we begin by making sure destination path ends in .app
	NSString *appPath = [theTimer userInfo];
	if (![appPath hasSuffix:@".app"])
		appPath = [appPath stringByAppendingString:@".app"];
	
	//check if app already exists, and if so, prompt if to replace
	if ([[NSFileManager defaultManager] fileExistsAtPath: appPath])
	{
		overwrite = [STUtil proceedWarning: @"Application already exists" subText: @"An application with this name already exists in the location you specified.  Do you want to overwrite it?" withAction: @"Overwrite"];
		if (!overwrite)
			return NO;
	}
	
	// create spec from controls and verify
	PlatypusAppSpec	*spec = [self appSpecFromControls];
	
	// we set this specifically -- extra profile data
	[spec setProperty: appPath forKey: @"Destination"];
	[spec setProperty: [[NSBundle mainBundle] pathForResource: @"ScriptExec" ofType: NULL] forKey: @"ExecutablePath"];
	[spec setProperty: [[NSBundle mainBundle] pathForResource: @"MainMenu.nib" ofType: NULL] forKey: @"NibPath"];
	[spec setProperty: [NSNumber numberWithBool: [developmentVersionCheckbox intValue]] forKey: @"DevelopmentVersion"];
	[spec setProperty: [NSNumber numberWithBool: [optimizeApplicationCheckbox intValue]] forKey: @"OptimizeApplication"];	
	if (overwrite) 
		[spec setProperty: [NSNumber numberWithBool: YES] forKey: @"DestinationOverride"];
	
	// verify that the values in the spec are OK
	if (![spec verify])
	{
		[STUtil alert: @"Spec verification failed" subText: [spec error]];
		return NO;
	}
	
	// ok, now we try to create the app
	
	// first, show progress dialog
	[progressDialogMessageLabel setStringValue: [NSString stringWithFormat: @"Creating application %@", [spec propertyForKey: @"Name"]]];
	
	[progressBar setUsesThreadedAnimation: YES];
	[progressBar startAnimation: self];
												 
	[NSApp beginSheet: progressDialogWindow
		modalForWindow: window
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];

	// create the app from spec
	if (![spec create])
	{
		// Dialog ends here.
		[NSApp endSheet: progressDialogWindow];
		[progressDialogWindow orderOut: self];
		
		[STUtil alert: @"Creating from spec failed" subText: [spec error]];
		return NO;
	}
	
	// reveal newly create app in Finder, if prefs say so
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"RevealApplicationWhenCreated"])
		[[NSWorkspace sharedWorkspace] selectFile: appPath inFileViewerRootedAtPath:nil];
	
	[developmentVersionCheckbox setIntValue: 0];
	[optimizeApplicationCheckbox setIntValue: 0];
	
	// Dialog ends here.
    [NSApp endSheet: progressDialogWindow];
    [progressDialogWindow orderOut: self];
	
    // Stop observing the filehandle for data since task is done
	[[NSNotificationCenter defaultCenter] removeObserver: self name: @"PlatypusAppSpecCreationNotification" object: nil];
    
	return YES;
}

/*************************************************
 - Make sure that all fields contain valid values
 **************************************************/

- (BOOL)verifyFieldContents
{
	BOOL			isDir;
	
	//file manager
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	//script path
	if ([[appNameTextField stringValue] length] == 0)//make sure a name has been assigned
	{
		[STUtil sheetAlert:@"Invalid Application Name" subText: @"You must specify a name for your application" forWindow: window];
		return NO;
	}
	
	//script path
	if (([fileManager fileExistsAtPath: [scriptPathTextField stringValue] isDirectory: &isDir] == NO) || isDir)//make sure script exists and isn't a folder
	{
		[STUtil sheetAlert:@"Invalid Script Path" subText: @"No file exists at the script path you have specified" forWindow: window];
		return NO;
	}
	
	//make sure we have an icon
	if (	([iconControl hasIcns] && ![[iconControl icnsFilePath] isEqualToString: @""] && ![fileManager fileExistsAtPath: [iconControl icnsFilePath]])
		||	(![(IconController *)iconControl hasIcns] && [(IconController *)iconControl imageData] == nil))
	{
		[STUtil sheetAlert:@"Missing Icon" subText: @"You must set an icon for your application." forWindow: window];
		return NO;
	}
	
	// let's be certain that the bundled files list doesn't contain entries that have been moved
	if(![fileList allPathsAreValid])
	{
		[STUtil sheetAlert: @"Moved or missing files" subText:@"One or more of the files that are to be bundled with the application have been moved.  Please rectify this and try again." forWindow: window];
		return NO;
	}
	
	//interpreter
	if ([fileManager fileExistsAtPath: [interpreterTextField stringValue]] == NO)//make sure interpreter exists
	{
		if (NO == [STUtil proceedWarning: @"Invalid Interpreter" subText: @"The specified interpreter does not exist on this system.  Do you wish to proceed anyway?" withAction: @"Proceed"])
			return NO;
	}
	
	return YES;
}

#pragma mark Generate/Read AppSpec

/*************************************************
 - Create app spec and fill it w. data from controls
**************************************************/

-(id)appSpecFromControls
{
	PlatypusAppSpec *spec = [[[PlatypusAppSpec alloc] initWithDefaults] autorelease];
	
	[spec setProperty: [appNameTextField stringValue]		forKey: @"Name"];
	[spec setProperty: [scriptPathTextField stringValue]	forKey: @"ScriptPath"];
	
	// set output type to the name of the output type, minus spaces
	[spec setProperty: [outputTypePopupMenu titleOfSelectedItem]
															forKey: @"Output"];
	
	// icon
	[spec setProperty: [iconControl icnsFilePath]		forKey: @"IconPath"];
	
	// advanced attributes
	[spec setProperty: [interpreterTextField stringValue]	forKey: @"Interpreter"];
	[spec setProperty: [paramsControl paramsArray]			forKey: @"Parameters"];
	[spec setProperty: [versionTextField stringValue]		forKey: @"Version"];
	[spec setProperty: [bundleIdentifierTextField stringValue]
															forKey: @"Identifier"];
	[spec setProperty: [authorTextField stringValue]		forKey: @"Author"];
	
	// checkbox attributes
	[spec setProperty: [NSNumber numberWithBool: [paramsControl passAppPathAsFirstArg]] 
															forKey: @"AppPathAsFirstArg"];
	
	[spec setProperty: [NSNumber numberWithBool:[isDroppableCheckbox state]]					
															forKey: @"Droppable"];
	[spec setProperty: [NSNumber numberWithBool:[encryptCheckbox state]]
															forKey: @"Secure"];
	[spec setProperty: [NSNumber numberWithBool:[rootPrivilegesCheckbox state]]		
															forKey: @"Authentication"];
	[spec setProperty: [NSNumber numberWithBool:[remainRunningCheckbox state]]
															forKey: @"RemainRunning"];
	[spec setProperty: [NSNumber numberWithBool:[showInDockCheckbox state]]
															forKey: @"ShowInDock"];

	// bundled files
	[spec setProperty: [fileList getFilesArray]	forKey: @"BundledFiles"];
	
	// file types
	[spec setProperty: (NSMutableArray *)[(SuffixList *)[typesControl suffixes] getSuffixArray]				forKey: @"Suffixes"];
	[spec setProperty: (NSMutableArray *)[(TypesList *)[typesControl types] getTypesArray]					forKey: @"FileTypes"];
	[spec setProperty: [typesControl role]																	forKey: @"Role"];

	//  text output text settings
	[spec setProperty: [NSNumber numberWithInt: (int)[textSettingsControl getTextEncoding]]							forKey: @"TextEncoding"];
	[spec setProperty: [[textSettingsControl getTextFont] fontName]													forKey: @"TextFont"];
	[spec setProperty: [NSNumber numberWithFloat: [[textSettingsControl getTextFont] pointSize]]					forKey: @"TextSize"];
	[spec setProperty: [[textSettingsControl getTextForeground] hexString]											forKey: @"TextForeground"];
	[spec setProperty: [[textSettingsControl getTextBackground] hexString]											forKey: @"TextBackground"];
	
	// status menu settings
	if ([[outputTypePopupMenu titleOfSelectedItem] isEqualToString: @"Status Menu"])
	{
		[spec setProperty: [statusItemSettingsControl displayType] forKey: @"StatusItemDisplayType"];
		[spec setProperty: [statusItemSettingsControl title] forKey: @"StatusItemTitle"];
		[spec setProperty: [[statusItemSettingsControl icon] TIFFRepresentation] forKey: @"StatusItemIcon"];		
	}
	
	return spec;
}

- (void) controlsFromAppSpec: (id)spec
{
	[appNameTextField setStringValue: [spec propertyForKey: @"Name"]];
	[scriptPathTextField setStringValue: [spec propertyForKey: @"ScriptPath"]];

	[versionTextField setStringValue: [spec propertyForKey: @"Version"]];
	[authorTextField setStringValue: [spec propertyForKey: @"Author"]];
	
	[outputTypePopupMenu selectItemWithTitle: [spec propertyForKey: @"Output"]];
	[self outputTypeWasChanged: NULL];
	[interpreterTextField setStringValue: [spec propertyForKey: @"Interpreter"]];
	
	//icon
	[iconControl loadIcnsFile: [spec propertyForKey: @"IconPath"]];
	
	//checkboxes
	[rootPrivilegesCheckbox setState: [[spec propertyForKey: @"Authentication"] boolValue]];
	[isDroppableCheckbox setState: [[spec propertyForKey: @"Droppable"] boolValue]];
		[self isDroppableWasClicked: isDroppableCheckbox];
	[encryptCheckbox setState: [[spec propertyForKey: @"Secure"] boolValue]];
	[showInDockCheckbox setState: [[spec propertyForKey: @"ShowInDock"] boolValue]];
	[remainRunningCheckbox setState: [[spec propertyForKey: @"RemainRunning"] boolValue]];
	
	//file list
		[fileList clearList];
		[fileList addFiles: [spec propertyForKey: @"BundledFiles"]];

		//update button status
		[fileList tableViewSelectionDidChange: NULL];
	
	//suffix list
		[(SuffixList *)[typesControl suffixes] clearList];
		[(SuffixList *)[typesControl suffixes] addSuffixes: [spec propertyForKey: @"Suffixes"]];
	
	//types list
		[(TypesList *)[typesControl types] clearList];
		[(TypesList *)[typesControl types] addTypes: [spec propertyForKey: @"FileTypes"]];
		
		[typesControl tableViewSelectionDidChange: NULL];
		[typesControl setRole: [spec propertyForKey: @"Role"]];
		
	// parameters
		[paramsControl set: [spec propertyForKey: @"Parameters"]];
		[paramsControl setAppPathAsFirstArg: [[spec propertyForKey: @"AppPathAsFirstArg"] boolValue]];
		 
	// text output settings
	[textSettingsControl setTextEncoding: [[spec propertyForKey: @"TextEncoding"] intValue]];
	[textSettingsControl setTextFont: [NSFont fontWithName: [spec propertyForKey: @"TextFont"] size: [[spec propertyForKey: @"TextSize"] intValue]]];
	[textSettingsControl setTextForeground: [NSColor colorFromHex: [spec propertyForKey: @"TextForeground"]]];
	[textSettingsControl setTextBackground: [NSColor colorFromHex: [spec propertyForKey: @"TextBackground"]]];

	// status menu settings
	if ([[spec propertyForKey: @"Output"] isEqualToString: @"Status Menu"])
	{
		if (![[spec propertyForKey: @"StatusItemDisplayType"] isEqualToString: @"Text"])
		{
			NSImage *icon = [[[NSImage alloc] initWithData: [spec propertyForKey: @"StatusItemIcon"]] autorelease];
			if (icon != NULL)
				[statusItemSettingsControl setIcon: icon];
		}
		[statusItemSettingsControl setTitle: [spec propertyForKey: @"StatusItemTitle"]];
		[statusItemSettingsControl setDisplayType: [spec propertyForKey: @"StatusItemDisplayType"]];
	}
	
	//update buttons
	[self controlTextDidChange: NULL];
	
	[self updateEstimatedAppSize];
	
	[bundleIdentifierTextField setStringValue: [spec propertyForKey: @"Identifier"]];
}

#pragma mark Load/Select script

/*****************************************
 - Open sheet to select script to load
 *****************************************/

- (IBAction)selectScript:(id)sender
{
	//create open panel
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	[oPanel setPrompt:@"Select"];
    [oPanel setAllowsMultipleSelection:NO];
	[oPanel setCanChooseDirectories: NO];
	
	[window setTitle: [NSString stringWithFormat: @"%@ - Select script", PROGRAM_NAME]];
	
	//run open panel
    [oPanel beginSheetForDirectory:nil file:nil types:nil modalForWindow: window modalDelegate: self didEndSelector: @selector(selectScriptPanelDidEnd:returnCode:contextInfo:) contextInfo: nil];
}

- (void)selectScriptPanelDidEnd:(NSOpenPanel *)oPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton)
		[self loadScript: [oPanel filename]];
	[window setTitle: PROGRAM_NAME];
}

/*****************************************
 - Called when script type is changed
 *****************************************/

- (IBAction)scriptTypeSelected:(id)sender
{
	[self setScriptType: [[sender selectedItem] title]];
}

- (void)selectScriptTypeBasedOnInterpreter
{
	NSString *type = [ScriptAnalyser displayNameForInterpreter: [interpreterTextField stringValue]];
	[scriptTypePopupMenu selectItemWithTitle: type];
}

/*****************************************
 - Updates data in interpreter, icon and output type popup button
*****************************************/

- (void)setScriptType: (NSString *)type
{	
	// set the script type based on the number which identifies each type
	NSString *interpreter = [ScriptAnalyser interpreterBasedOnDisplayName: type];
	[interpreterTextField setStringValue: interpreter];
	[scriptTypePopupMenu selectItemWithTitle: type];
	[self controlTextDidChange: NULL];
}

/*****************************************
 - Loads script data into platypus window
*****************************************/

- (void)loadScript:(NSString *)filename
{
	//make sure file we're loading actually exists
	BOOL	isDir;
	if (![[NSFileManager defaultManager] fileExistsAtPath: filename isDirectory: &isDir] || isDir)
		return;

	//set script path
	[scriptPathTextField setStringValue: filename];

	//set app name
	NSString *appName = [[filename lastPathComponent] stringByDeletingPathExtension];
	[appNameTextField setStringValue: appName];
	
	//determine script type
	NSString *interpreter = [ScriptAnalyser determineInterpreterForScriptFile: filename];
	
	//ok, we've successfully found an interpreter for it
	if (![interpreter isEqualToString: @""])
	{
		NSString *scriptType = [ScriptAnalyser displayNameForInterpreter: interpreter];
		[self setScriptType: scriptType];
		if ([scriptType isEqualToString: @"Other..."])
			[interpreterTextField setStringValue: interpreter];
		
		NSMutableArray *shebangCmdComponents = [NSMutableArray arrayWithArray: [ScriptAnalyser getInterpreterFromShebang: filename]];
		[shebangCmdComponents removeObjectAtIndex: 0];
		[paramsControl set: [NSArray arrayWithArray: shebangCmdComponents]];
	}
	
	// add to recent items menu
	[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL: [NSURL fileURLWithPath: filename]];
	
	[self controlTextDidChange: NULL];
	[self updateEstimatedAppSize];
}

#pragma mark Window interface actions

/*****************************************
 - Delegate for when text changes in any of 
   the text fields
 *****************************************/

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	BOOL	isDir, exists = NO, validName = NO;
	
	//app name or script path was changed
	if ([aNotification object] == NULL || [aNotification object] == appNameTextField || [aNotification object] == scriptPathTextField)
	{
		if ([[appNameTextField stringValue] length] > 0)
			validName = YES;
		
		if ([scriptPathTextField hasValidPath])
		{
			// add watcher that tracks whether it exists
			[[UKKQueue sharedFileWatcher] addPathToQueue:  [scriptPathTextField stringValue]];
			exists = YES;
		}
		
		[scriptPathTextField updateTextColoring];
		
		[editScriptButton setEnabled: exists];
		[revealScriptButton setEnabled: exists];
		
		//enable/disable create app button
		[createAppButton setEnabled: validName && exists];
		
		//update identifier
		if (validName)
			[bundleIdentifierTextField setStringValue: [self generateBundleIdentifier]];
		else
			[bundleIdentifierTextField setStringValue: [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultBundleIdentifierPrefix"]];
	}
	
	//interpreter changed -- we try to select type based on the value in the field, also color red if path doesn't exist
	if ([aNotification object] == interpreterTextField || [aNotification object] == NULL)
	{
		[self selectScriptTypeBasedOnInterpreter];
		if ([[NSFileManager defaultManager] fileExistsAtPath: [interpreterTextField stringValue] isDirectory: &isDir] && !isDir)
			[interpreterTextField setTextColor: [NSColor blackColor]];
		else
			[interpreterTextField setTextColor: [NSColor redColor]];
	}
}

/*****************************************
 - called when Droppable checkbox is clicked
*****************************************/

- (IBAction)isDroppableWasClicked:(id)sender
{
	[editTypesButton setHidden: ![isDroppableCheckbox state]];
	[editTypesButton setEnabled: [isDroppableCheckbox state]];
}

/*****************************************
 - called when [X] Is Droppable is pressed
*****************************************/

- (IBAction)outputTypeWasChanged:(id)sender
{
	// we don't show text output settings for output modes None and Web View
	if (![[outputTypePopupMenu titleOfSelectedItem] isEqualToString: @"None"] &&
		![[outputTypePopupMenu titleOfSelectedItem] isEqualToString: @"Web View"] && 
		![[outputTypePopupMenu titleOfSelectedItem] isEqualToString: @"Droplet"])
	{
		[textOutputSettingsButton setHidden: NO];
		[textOutputSettingsButton setEnabled: YES];
	}
	else
	{
		[textOutputSettingsButton setHidden: YES];
		[textOutputSettingsButton setEnabled: NO];
	}
	
	// disable options that don't make sense for status menu output mode
	if ([[outputTypePopupMenu titleOfSelectedItem] isEqualToString: @"Status Menu"])
	{
		// disable droppable & admin privileges
		[isDroppableCheckbox setIntValue: 0];
		[isDroppableCheckbox setEnabled: NO];
		[self isDroppableWasClicked: self];
		[rootPrivilegesCheckbox setIntValue: 0];
		[rootPrivilegesCheckbox setEnabled: NO];
		
		// force-enable "Remain running"
		[remainRunningCheckbox setIntValue: 1];
		[remainRunningCheckbox setEnabled: NO];
		
		// check Runs in Background as default for Status Menu output
		[showInDockCheckbox setIntValue: 1];
		
		// show button for special status item settings
		[statusItemSettingsButton setEnabled: YES];
		[statusItemSettingsButton setHidden: NO];
	}
	else
	{
		if ([[outputTypePopupMenu titleOfSelectedItem] isEqualToString: @"Droplet"])
		{
			[isDroppableCheckbox setIntValue: 1];
			[self isDroppableWasClicked: self];
		}
		
		// re-enable droppable
		[isDroppableCheckbox setEnabled: YES];
		[rootPrivilegesCheckbox setEnabled: YES];
		
		// re-enable remain running
		[remainRunningCheckbox setEnabled: YES];

		[showInDockCheckbox setIntValue: 0];
		
		// hide special status item settings
		[statusItemSettingsButton setEnabled: NO];
		[statusItemSettingsButton setHidden: YES];
	}
}

/*****************************************
 - called when (Clear) button is pressed 
 -- restores fields to startup values
*****************************************/

- (IBAction)clearAllFields:(id)sender
{
	//clear all text field to start value
	[appNameTextField setStringValue: @""];
	[scriptPathTextField setStringValue: @""];
	[versionTextField setStringValue: @"1.0"];
	
	[bundleIdentifierTextField setStringValue: [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultBundleIdentifierPrefix"]];
	[authorTextField setStringValue: [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultAuthor"]];
	
	//uncheck all options
	[isDroppableCheckbox setIntValue: 0];
	[self isDroppableWasClicked: isDroppableCheckbox];
	[encryptCheckbox setIntValue: 0];
	[rootPrivilegesCheckbox setIntValue: 0];
	[remainRunningCheckbox setIntValue: 1];
	[showInDockCheckbox setIntValue: 0];
	
	//clear file list
	[fileList clearFileList: self];
	
	//clear suffix and types lists to default values
	[typesControl setDefaultTypes: self];
	
	//set parameters to default
	[paramsControl resetDefaults: self];
	
	//set text ouput settings to default
	[textSettingsControl resetDefaults: self];
	
	//set status item settings to default
	[statusItemSettingsControl restoreDefaults: self];
	
	//set script type
	[self setScriptType: @"Shell"];
	
	//set output type
	[outputTypePopupMenu selectItemWithTitle: DEFAULT_OUTPUT_TYPE];
	[self outputTypeWasChanged: outputTypePopupMenu];
	
	//update button status
	[self controlTextDidChange: NULL];
	
	[appSizeTextField setStringValue: @""];
	
	[iconControl setDefaultIcon];
}

/*****************************************
 - Show shell command window
*****************************************/

- (IBAction)showCommandLineString: (id)sender
{
	[window setTitle: [NSString stringWithFormat: @"%@ - Shell Command String", PROGRAM_NAME]];
	[[[ShellCommandController alloc] init] showShellCommandForSpec: [self appSpecFromControls] window: window];
	[window setTitle: PROGRAM_NAME];	
}

/*****************************************
 - //return the bundle identifier for the application to be generated
 -  based on username etc.
*****************************************/

- (NSString *)generateBundleIdentifier
{
	NSString	*bundleId;
	//The format is "org.username.appname"
	bundleId = [NSString stringWithFormat: @"%@%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultBundleIdentifierPrefix"], [appNameTextField stringValue]];
	bundleId = [[bundleId componentsSeparatedByString:@" "] componentsJoinedByString:@""];//no spaces
	return(bundleId);
}

#pragma mark App Size estimation

/*****************************************
 - // set app size textfield to formatted str with app size
*****************************************/

- (void)updateEstimatedAppSize
{
	[appSizeTextField setStringValue: [NSString stringWithFormat: @"Estimated final app size: ~%@", [self estimatedAppSize]]];
}

/*****************************************
 - // Make a decent guess concerning final app size
*****************************************/

- (NSString *)estimatedAppSize
{
	UInt64 estimatedAppSize = 0;
	
	estimatedAppSize += 4096; // Info.plist
	estimatedAppSize += 4096; // AppSettings.plist
	
	// if we want to know the size of the icon, let's assume default icon
	estimatedAppSize += [iconControl iconSize];
	estimatedAppSize += [STUtil fileOrFolderSize: [scriptPathTextField stringValue]];
	estimatedAppSize += [STUtil fileOrFolderSize: [[NSBundle mainBundle] pathForResource: @"ScriptExec" ofType: NULL]];  // executable
		
	// nib size is much smaller if compiled with ibtool
	UInt64 nibSize = [STUtil fileOrFolderSize: [[NSBundle mainBundle] pathForResource: @"MainMenu.nib" ofType: NULL]];  // bundled nib
	if ([[NSFileManager defaultManager] fileExistsAtPath: IBTOOL_PATH])
		nibSize = 0.2 * nibSize; // compiled nib is approximtely 20% of the size of original
    estimatedAppSize += nibSize;
	
    // bundled files altogether
    estimatedAppSize += [fileList getTotalSize];
		
	return [STUtil sizeAsHumanReadable: estimatedAppSize];
}

#pragma mark Drag and drop

/*****************************************
 - Dragging and dropping for Platypus window
*****************************************/

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pboard = [sender draggingPasteboard];
	NSString		*filename;
	BOOL			isDir = FALSE;

    if ( [[pboard types] containsObject: NSFilenamesPboardType] ) 
	{
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		filename = [files objectAtIndex: 0];//we only load the first dragged item
		if ([[NSFileManager defaultManager] fileExistsAtPath: filename isDirectory: &isDir] && !isDir)
		{
			if ([filename hasSuffix: PROFILES_SUFFIX])
				[profilesControl loadProfileFile: filename];
			else
				[self loadScript: filename];
	
			return YES;
		}
	}
	else if ( [[pboard types] containsObject: NSStringPboardType] )
	{
		// create a new script file with the dropped string, load it
		NSString *draggedString = [pboard stringForType: NSStringPboardType];
		NSString *newScriptPath = [self createNewScript: draggedString];
		[self loadScript: newScriptPath];
		//[self editScript: self];
		return YES;
	}
	
	return NO;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender 
{
	// we accept dragged files
    if ([[[sender draggingPasteboard] types] containsObject: NSFilenamesPboardType])
	{
		NSString *file = [[[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType] objectAtIndex: 0];
		
		if (![file hasSuffix: @".icns"])
			return NSDragOperationLink;
	}
	else if ([[[sender draggingPasteboard] types] containsObject: NSStringPboardType])
		return NSDragOperationCopy;
    
	return NSDragOperationNone;
}

// if we just created a file with a dragged string, we open it in default editor
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	if ([[[sender draggingPasteboard] types] containsObject: NSStringPboardType])
		[self editScript: self];
}

#pragma mark Menu items

/*****************************************
 - Delegate function for enabling and disabling menu items
*****************************************/

- (BOOL)validateMenuItem:(NSMenuItem*)anItem 
{
	BOOL isDir;

	//create app menu
	if ([[anItem title] isEqualToString:@"Create App"] && ![createAppButton isEnabled])
		return NO;
	
	BOOL validScriptFile = !(![[NSFileManager defaultManager] fileExistsAtPath: [scriptPathTextField stringValue] isDirectory: &isDir] || isDir);

	//edit script
	if (	(	[anItem action] == @selector(editScript:)	||
				[anItem action] == @selector(revealScript:) ||
				[anItem action] == @selector(runScript:)	||
				[anItem action] == @selector(checkSyntaxOfScript:) )
			&& !validScriptFile)
		return NO;

	return YES;
}

#pragma mark Help/Documentation

/*****************************************
 - Open Platypus Help HTML file within app bundle
*****************************************/

- (IBAction) showHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:
	 [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: PROGRAM_DOCUMENTATION ofType: nil]]
	];
}

/*****************************************
 - Open 'platypus' command line tool man page in PDF
*****************************************/

- (IBAction) showManPage:(id)sender
{	
	[[NSWorkspace sharedWorkspace] openFile: [[NSBundle mainBundle] pathForResource: PROGRAM_MANPAGE ofType: nil]];
}

/*****************************************
 - Open Readme file
*****************************************/

- (IBAction) showReadme:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL: 
	[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: PROGRAM_README_FILE ofType: nil]]
	];
}

/*****************************************
 - Open Platypus website in default browser
*****************************************/

- (IBAction) openWebsite: (id)sender
{
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: PROGRAM_WEBSITE]];
}

/*****************************************
 - Open License.txt file
 *****************************************/

- (IBAction) openLicense: (id)sender
{
	[[NSWorkspace sharedWorkspace] openURL: 
	 [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: PROGRAM_LICENSE_FILE ofType: nil]]
	 ];
}

/*****************************************
- Open donations website
*****************************************/

- (IBAction) openDonations: (id)sender
{
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: PROGRAM_DONATIONS]];
}


@end
