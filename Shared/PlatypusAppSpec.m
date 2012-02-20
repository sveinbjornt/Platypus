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

// PlatypusAppSpec is a data wrapper class around an NSDictionary containing
// all the information / specifications for creating a Platypus application.


#import "PlatypusAppSpec.h"

@implementation PlatypusAppSpec

#pragma mark - Creation
/*****************************************
 - init / dealloc functions
*****************************************/

-(PlatypusAppSpec *)init
{
	if (self = [super init]) 
	{
		properties = [[NSMutableDictionary alloc] initWithCapacity: MAX_APPSPEC_PROPERTIES];
    }
    return self;
}

-(PlatypusAppSpec *)initWithDefaults
{
	if (self = [self init]) 
	{
		[self setDefaults];
    }
	return self;
}

-(PlatypusAppSpec *)initWithDefaultsFromScript: (NSString *)scriptPath
{
    if (self = [self init]) 
	{
        [self setDefaultsForScript: scriptPath];
    }
	return self;
}

-(PlatypusAppSpec *)initWithDictionary: (NSDictionary *)dict
{
	if (self = [self init]) 
	{
        [self setDefaults];
		[properties addEntriesFromDictionary: dict];
    }
	return self;
}

-(PlatypusAppSpec *)initWithProfile: (NSString *)filePath
{
	return [self initWithDictionary: [NSMutableDictionary dictionaryWithContentsOfFile: filePath]];
}

+(PlatypusAppSpec *)specWithDefaults
{
	return [[[PlatypusAppSpec alloc] initWithDefaults] autorelease];
}

+(PlatypusAppSpec *)specWithDictionary: (NSDictionary *)dict
{
	return [[[PlatypusAppSpec alloc] initWithDictionary: dict] autorelease];
}

+(PlatypusAppSpec *)specFromProfile: (NSString *)filePath
{
	return [[[PlatypusAppSpec alloc] initWithProfile: filePath] autorelease];
}

+(PlatypusAppSpec *)specWithDefaultsFromScript: (NSString *)scriptPath
{
	return [[[PlatypusAppSpec alloc] initWithDefaultsFromScript: scriptPath] autorelease];
}

-(void)dealloc
{
	[properties release];
	[super dealloc];
}

#pragma mark - Instance methods

/**********************************
	init a spec with default values for everything
**********************************/

-(void)setDefaults
{
	// stamp the spec with the creator
	[properties setObject: PROGRAM_STAMP												forKey: @"Creator"];

	//prior properties
	[properties setObject: CMDLINE_EXEC_PATH											forKey: @"ExecutablePath"];
	[properties setObject: CMDLINE_NIB_PATH												forKey: @"NibPath"];
	[properties setObject: DEFAULT_DESTINATION_PATH                                     forKey: @"Destination"];
	
	[properties setValue: [NSNumber numberWithBool: NO]									forKey: @"DestinationOverride"];
	[properties setValue: [NSNumber numberWithBool: NO]									forKey: @"DevelopmentVersion"];
	[properties setValue: [NSNumber numberWithBool: YES]								forKey: @"OptimizeApplication"];
	[properties setValue: [NSNumber numberWithBool: YES]                                forKey: @"UseXMLPlistFormat"];
    
	// primary attributes	
	[properties setObject: DEFAULT_APP_NAME												forKey: @"Name"];
	[properties setObject: @""															forKey: @"ScriptPath"];
	[properties setObject: DEFAULT_OUTPUT_TYPE											forKey: @"Output"];
	[properties setObject: CMDLINE_ICON_PATH											forKey: @"IconPath"];
	
	// secondary attributes
	[properties setObject: DEFAULT_INTERPRETER											forKey: @"Interpreter"];
	[properties setObject: [NSMutableArray array]										forKey: @"InterpreterArgs"];
	[properties setObject: [NSMutableArray array]										forKey: @"ScriptArgs"];
    [properties setObject: DEFAULT_VERSION												forKey: @"Version"];
	[properties setObject: DEFAULT_BUNDLE_ID                                            forKey: @"Identifier"];
	[properties setObject: NSFullUserName()												forKey: @"Author"];
	
	[properties setValue: [NSNumber numberWithBool: NO]									forKey: @"Droppable"];
	[properties setValue: [NSNumber numberWithBool: NO]									forKey: @"Secure"];
	[properties setValue: [NSNumber numberWithBool: NO]									forKey: @"Authentication"];
	[properties setValue: [NSNumber numberWithBool: YES]								forKey: @"RemainRunning"];
	[properties setValue: [NSNumber numberWithBool: NO]									forKey: @"ShowInDock"];
		
	// bundled files
	[properties setObject: [NSMutableArray array]										forKey: @"BundledFiles"];
	
    // file/drag acceptance properties
	[properties setObject: [NSMutableArray arrayWithObject: @"*"]						forKey: @"Suffixes"];
	[properties setObject: [NSMutableArray arrayWithObjects: @"****", @"fold", nil]     forKey: @"FileTypes"];
	[properties setObject: DEFAULT_ROLE													forKey: @"Role"];
    [properties setObject: [NSNumber numberWithBool: NO]                                forKey: @"AcceptsText"];
    [properties setObject: [NSNumber numberWithBool: YES]                               forKey: @"AcceptsFiles"];
    [properties setObject: [NSNumber numberWithBool: NO]                                forKey: @"DeclareService"];
    [properties setObject: @""                                                          forKey: @"DocIcon"];
    
	// text output settings
	[properties setObject: [NSNumber numberWithInt: DEFAULT_OUTPUT_TXT_ENCODING]		forKey: @"TextEncoding"];
	[properties setObject: DEFAULT_OUTPUT_FONT											forKey: @"TextFont"];
	[properties setObject: [NSNumber numberWithFloat: DEFAULT_OUTPUT_FONTSIZE]			forKey: @"TextSize"];
	[properties setObject: DEFAULT_OUTPUT_FG_COLOR										forKey: @"TextForeground"];
	[properties setObject: DEFAULT_OUTPUT_BG_COLOR										forKey: @"TextBackground"];

	// status item settings
	[properties setObject: DEFAULT_STATUSITEM_DTYPE                                     forKey: @"StatusItemDisplayType"];
	[properties setObject: DEFAULT_APP_NAME												forKey: @"StatusItemTitle"];
	[properties setObject: [NSData data]												forKey: @"StatusItemIcon"];
}

/********************************************************
 inits with default values and then analyse script, 
 load default values based on analysed script properties
 ********************************************************/

-(void)setDefaultsForScript: (NSString *)scriptPath
{
    // start with a dict populated with defaults
    [self setDefaults];
    
    // set script path
    [self setProperty: scriptPath forKey: @"ScriptPath"];
    
    //determine app name based on script filename
	NSString *appName = [ScriptAnalyser appNameFromScriptFileName: scriptPath];
	[self setProperty: appName forKey: @"Name"];
        
	//find an interpreter for it
    NSString *interpreter = [ScriptAnalyser determineInterpreterForScriptFile: scriptPath];
	if ([interpreter isEqualToString: @""])
        interpreter = DEFAULT_INTERPRETER;
    else
	{
        // get parameters to interpreter
		NSMutableArray *shebangCmdComponents = [NSMutableArray arrayWithArray: [ScriptAnalyser getInterpreterFromShebang: scriptPath]];
		[shebangCmdComponents removeObjectAtIndex: 0];
        [self setProperty: shebangCmdComponents forKey: @"InterpreterArgs"];
	}
    [self setProperty: interpreter forKey: @"Interpreter"];
    
    // find parent folder wherefrom we create destination path of app bundle
    NSString *parentFolder = [scriptPath stringByDeletingLastPathComponent];
    NSString *destPath = [NSString stringWithFormat: @"%@/%@.app", parentFolder, appName];
    [self setProperty: destPath forKey: @"Destination"];
    [self setProperty: [PlatypusAppSpec standardBundleIdForAppName: appName usingDefaults: NO] forKey: @"Identifier"];
}

/****************************************
 This function creates the Platypus app
 based on the data contained in the spec.
****************************************/

-(BOOL)create
{
	int      i;
	NSString *contentsPath, *macosPath, *resourcesPath, *tmpPath = NSTemporaryDirectory();
	NSString *execDestinationPath, *infoPlistPath, *iconPath, *docIconPath, *bundledFileDestPath, *nibDestPath;
	NSString *execPath, *nibPath, *bundledFilePath;
	NSString *appSettingsPlistPath;
	NSString *b_enc_script = @"";
	NSMutableDictionary	*appSettingsPlist;
	NSFileManager *fileManager = FILEMGR;
	
	/////// MAKE SURE CONDITIONS ARE ACCEPTABLE //////
	
	// make sure we can write to temp path
	if (![fileManager isWritableFileAtPath: tmpPath])
	{
		error = [NSString stringWithFormat: @"Could not write to the temp directory '%@'.", tmpPath]; 
		return 0;
	}

	//check if app already exists
	if ([fileManager fileExistsAtPath: [properties objectForKey: @"Destination"]])
	{
        if (![[properties objectForKey: @"DestinationOverride"] boolValue])
        {
            error = [NSString stringWithFormat: @"App already exists at path %@. Use -y flag to overwrite.", [properties objectForKey: @"Destination"]];
            return 0;
        }
        else
            [self report: [NSString stringWithFormat: @"Overwriting app at path %@", [properties objectForKey: @"Destination"]]];
	}
    
    // check if executable exists
    execPath = [properties objectForKey: @"ExecutablePath"];
    if (![fileManager fileExistsAtPath: execPath] || ![fileManager isReadableFileAtPath: execPath])
    {
        [self report: [NSString stringWithFormat: @"Executable %@ does not exist. Aborting.", execPath, nil]];
        return NO;
    }
    
    // check if source nib exists
    nibPath = [properties objectForKey: @"NibPath"];
    if (![fileManager fileExistsAtPath: nibPath] || ![fileManager isReadableFileAtPath: nibPath])
    {
        [self report: [NSString stringWithFormat: @"Nib file %@ does not exist. Aborting.", nibPath, nil]];
        return NO;
    }
    
	////////////////////////// CREATE THE FOLDER HIERARCHY //////////////////////////
	
	// we begin by creating the application bundle at temp path
	
    [self report: @"Creating app bundle hierarchy"];
    
	//Application.app bundle
	tmpPath = [tmpPath stringByAppendingString: [[properties objectForKey: @"Destination"] lastPathComponent]];
	[fileManager createDirectoryAtPath: tmpPath withIntermediateDirectories: NO attributes: nil error: nil];
	
	//.app/Contents
	contentsPath = [tmpPath stringByAppendingString:@"/Contents"];
	[fileManager createDirectoryAtPath: contentsPath withIntermediateDirectories: NO attributes: nil error: nil];
	
	//.app/Contents/MacOS
	macosPath = [contentsPath stringByAppendingString:@"/MacOS"];
	[fileManager createDirectoryAtPath: macosPath withIntermediateDirectories: NO attributes: nil error: nil];
	
	//.app/Contents/Resources
	resourcesPath = [contentsPath stringByAppendingString:@"/Resources"];
	[fileManager createDirectoryAtPath: resourcesPath withIntermediateDirectories: NO attributes: nil error: nil];
			
	////////////////////////// COPY FILES TO THE APP BUNDLE //////////////////////////////////
	
    [self report: @"Copying executable to bundle"];
    
	//copy exec file
	//.app/Contents/Resources/MacOS/ScriptExec
    execDestinationPath = [macosPath stringByAppendingString:@"/"];
	execDestinationPath = [execDestinationPath stringByAppendingString: [properties objectForKey: @"Name"]]; 
	[fileManager copyItemAtPath: execPath toPath: execDestinationPath error: nil];
    [PlatypusUtility setPermissions: S_IRWXU | S_IRWXG | S_IROTH forFile: execDestinationPath];
	
	//copy nib file to app bundle
	//.app/Contents/Resources/MainMenu.nib
    [self report: @"Copying nib file to bundle"];
	nibDestPath = [resourcesPath stringByAppendingString:@"/MainMenu.nib"];
	[fileManager copyItemAtPath: nibPath toPath: nibDestPath error: nil];
		
	// if optimize application is set, we see if we can compile the nib file
	if ([[properties objectForKey: @"OptimizeApplication"] boolValue] == YES && [fileManager fileExistsAtPath: IBTOOL_PATH])
	{
        [self report: @"Optimizing nib file"];
        
		NSTask *ibToolTask = [[NSTask alloc] init];
		[ibToolTask setLaunchPath: IBTOOL_PATH];
		[ibToolTask setArguments: [NSArray arrayWithObjects: @"--strip", nibDestPath, nibDestPath, nil]];
		[ibToolTask launch];
		[ibToolTask waitUntilExit];
		[ibToolTask release];
	}
	
	// create script file in app bundle
	//.app/Contents/Resources/script
    [self report: @"Copying script"];
    
	if ([[properties objectForKey: @"Secure"] boolValue])
		b_enc_script = [NSData dataWithContentsOfFile: [properties objectForKey: @"ScriptPath"]];
	else
	{
		NSString *scriptFilePath = [resourcesPath stringByAppendingString:@"/script"];
		// make a symbolic link instead of copying script if this is a dev version
		if ([[properties objectForKey: @"DevelopmentVersion"] boolValue] == YES)
			[fileManager createSymbolicLinkAtPath: scriptFilePath withDestinationPath: [properties objectForKey: @"ScriptPath"] error: nil];
		else // copy script over
			[fileManager copyItemAtPath: [properties objectForKey: @"ScriptPath"] toPath: scriptFilePath error: nil];
        
        [PlatypusUtility setPermissions: S_IRWXU | S_IRWXG | S_IROTH forFile: scriptFilePath];
	}
		
	//create AppSettings.plist file
	//.app/Contents/Resources/AppSettings.plist
    [self report: @"Creating property lists"];
	appSettingsPlist = [NSMutableDictionary dictionaryWithCapacity: PROGRAM_MAX_LIST_ITEMS];
	[appSettingsPlist setObject: [properties objectForKey: @"Authentication"] forKey: @"RequiresAdminPrivileges"];
	[appSettingsPlist setObject: [properties objectForKey: @"Droppable"] forKey: @"Droppable"];
	[appSettingsPlist setObject: [properties objectForKey: @"RemainRunning"] forKey: @"RemainRunningAfterCompletion"];
	[appSettingsPlist setObject: [properties objectForKey: @"Secure"] forKey: @"Secure"];
	[appSettingsPlist setObject: [properties objectForKey: @"Output"] forKey: @"OutputType"];
	[appSettingsPlist setObject: [properties objectForKey: @"Interpreter"] forKey: @"ScriptInterpreter"];
	[appSettingsPlist setObject: PROGRAM_STAMP forKey: @"Creator"];
	[appSettingsPlist setObject: [properties objectForKey: @"InterpreterArgs"] forKey: @"InterpreterArgs"];
	[appSettingsPlist setObject: [properties objectForKey: @"ScriptArgs"] forKey: @"ScriptArgs"];
    
	// we need only set text settings for the output types that use this information
	if ([[properties objectForKey: @"Output"] isEqualToString: @"Progress Bar"] ||
		[[properties objectForKey: @"Output"] isEqualToString: @"Text Window"] ||
		[[properties objectForKey: @"Output"] isEqualToString: @"Status Menu"])
	{
		[appSettingsPlist setObject: [properties objectForKey: @"TextFont"] forKey: @"TextFont"];
		[appSettingsPlist setObject: [properties objectForKey: @"TextSize"] forKey: @"TextSize"];
		[appSettingsPlist setObject: [properties objectForKey: @"TextForeground"] forKey: @"TextForeground"];
		[appSettingsPlist setObject: [properties objectForKey: @"TextBackground"] forKey: @"TextBackground"];
		[appSettingsPlist setObject: [properties objectForKey: @"TextEncoding"] forKey: @"TextEncoding"];
	}
	
	// likewise, status menu settings are only written if that is the output type
	if ([[properties objectForKey: @"Output"] isEqualToString: @"Status Menu"] == YES)
	{
		[appSettingsPlist setObject: [properties objectForKey: @"StatusItemDisplayType"] forKey: @"StatusItemDisplayType"];
		[appSettingsPlist setObject: [properties objectForKey: @"StatusItemTitle"] forKey: @"StatusItemTitle"];
		[appSettingsPlist setObject: [properties objectForKey: @"StatusItemIcon"] forKey: @"StatusItemIcon"];
	}
	
	// we  set the suffixes/file types in the AppSettings.plist if app is droppable
	if ([[properties objectForKey: @"Droppable"] boolValue] == YES)
	{		
		[appSettingsPlist setObject: [properties objectForKey: @"Suffixes"] forKey: @"DropSuffixes"];
		[appSettingsPlist setObject: [properties objectForKey: @"FileTypes"] forKey: @"DropTypes"];
	}
    [appSettingsPlist setObject: [properties objectForKey: @"AcceptsFiles"] forKey: @"AcceptsFiles"];
    [appSettingsPlist setObject: [properties objectForKey: @"AcceptsText"] forKey: @"AcceptsText"];

	// if script is "secured" we encoded it into AppSettings property list
	if ([[properties objectForKey: @"Secure"] boolValue])
		[appSettingsPlist setObject: [NSKeyedArchiver archivedDataWithRootObject: b_enc_script] forKey: @"TextSettings"];
	
	appSettingsPlistPath = [resourcesPath stringByAppendingString:@"/AppSettings.plist"];
    
    // write the app settings plist
    if (![[properties objectForKey: @"UseXMLPlistFormat"] boolValue])
    {
        NSData *binPlistData = [NSPropertyListSerialization dataFromPropertyList: appSettingsPlist
                                                                          format: NSPropertyListBinaryFormat_v1_0
                                                                errorDescription: nil];
        [binPlistData writeToFile: appSettingsPlistPath atomically: YES];
    }
    else
        [appSettingsPlist writeToFile: appSettingsPlistPath atomically: YES];
	
	//create icon
	//.app/Contents/Resources/appIcon.icns
    if ([properties objectForKey: @"IconPath"] && ![[properties objectForKey: @"IconPath"] isEqualToString: @""])
    {
        [self report: @"Writing application icon"];
        iconPath = [resourcesPath stringByAppendingString:@"/appIcon.icns"];
        [fileManager copyItemAtPath: [properties objectForKey: @"IconPath"] toPath: iconPath error: nil];
    }
    
    if ([properties objectForKey: @"DocIcon"] && ![[properties objectForKey: @"DocIcon"] isEqualToString: @""])
    {
        [self report: @"Writing document icon"];
        docIconPath = [resourcesPath stringByAppendingString:@"/docIcon.icns"];
        [fileManager copyItemAtPath: [properties objectForKey: @"DocIcon"] toPath: docIconPath error: nil];
    }
          
	//create Info.plist file
	//.app/Contents/Info.plist
    [self report: @"Creating Info.plist"];
	infoPlistPath = [contentsPath stringByAppendingString:@"/Info.plist"];
	// create the Info.plist dictionary
	NSMutableDictionary *infoPlist = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
							@"English", @"CFBundleDevelopmentRegion",
							[properties objectForKey: @"Name"], @"CFBundleExecutable", 
							[properties objectForKey: @"Name"], @"CFBundleName",
							[properties objectForKey: @"Name"], @"CFBundleDisplayName",
							[NSString stringWithFormat: @"© %d %@", [[NSCalendarDate calendarDate] yearOfCommonEra], [properties objectForKey: @"Author"] ], @"NSHumanReadableCopyright", 
							[properties objectForKey: @"Version"], @"CFBundleShortVersionString", 
							[properties objectForKey: @"Identifier"], @"CFBundleIdentifier",  
							[properties objectForKey: @"ShowInDock"], @"LSUIElement",
							@"6.0", @"CFBundleInfoDictionaryVersion",
							@"APPL", @"CFBundlePackageType",
							@"MainMenu", @"NSMainNibFile",
							PROGRAM_MIN_SYS_VERSION, @"LSMinimumSystemVersion",
							@"NSApplication", @"NSPrincipalClass",  nil];
    if (![[properties objectForKey: @"IconPath"] isEqualToString: @""])
        [infoPlist setObject: @"appIcon.icns" forKey: @"CFBundleIconFile"]; 
	
	// if droppable, we declare the accepted file types
	if ([[properties objectForKey: @"Droppable"] boolValue] == YES)
	{
		NSMutableDictionary	*typesAndSuffixesDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
						[properties objectForKey: @"Suffixes"], @"CFBundleTypeExtensions",//extensions
						[properties objectForKey: @"FileTypes"], @"CFBundleTypeOSTypes",//os types
						[properties objectForKey: @"Role"], @"CFBundleTypeRole", nil];//viewer or editor?
        
        // document icon
        if (docIconPath && [fileManager fileExistsAtPath: docIconPath])
            [typesAndSuffixesDict setObject: @"docIcon.icns" forKey: @"CFBundleTypeIconFile"];
        
        [infoPlist setObject: [NSArray arrayWithObject: typesAndSuffixesDict] forKey: @"CFBundleDocumentTypes"];
        
        // add service settings to Info.plist
        if ([[properties objectForKey: @"DeclareService"] boolValue])
        {
            // service data type handling
            NSMutableArray      *sendTypes = [NSMutableArray arrayWithCapacity: 2];
            if ([[properties objectForKey: @"AcceptsFiles"] boolValue])
                [sendTypes addObject: @"NSFilenamesPboardType"];
            if ([[properties objectForKey: @"AcceptsText"] boolValue])
                [sendTypes addObject: @"NSStringPboardType"];
            
            NSString            *appName = [properties objectForKey: @"Name"];
            NSMutableDictionary *serviceDict = [NSMutableDictionary dictionaryWithCapacity: 10];
            NSDictionary        *menuItemDict = [NSDictionary dictionaryWithObject: [NSString stringWithFormat: @"Process with %@", appName] forKey: @"default"];
            
            [serviceDict setObject: menuItemDict  forKey: @"NSMenuItem"];
            [serviceDict setObject: @"dropService"  forKey: @"NSMessage"];
            [serviceDict setObject: appName         forKey: @"NSPortName"];
            [serviceDict setObject: sendTypes       forKey: @"NSSendTypes"];
            [infoPlist setObject: [NSArray arrayWithObject: serviceDict] forKey: @"NSServices"];
        }
	}
    		
	// finally, write the Info.plist file
    [self report: @"Writing Info.plist"];
    if (![[properties objectForKey: @"UseXMLPlistFormat"] boolValue]) // if binary
    {
        NSData *binPlistData = [NSPropertyListSerialization dataFromPropertyList: infoPlist
                                                                          format: NSPropertyListBinaryFormat_v1_0
                                                                errorDescription: nil];
        [binPlistData writeToFile: infoPlistPath atomically: YES];
    }
    else
        [infoPlist writeToFile: infoPlistPath atomically: YES]; // if xml
			
	//copy files in file list to the Resources folder
	//.app/Contents/Resources/*
    [self report: @"Copying bundled files"];
    
	for (i = 0; i < [[properties objectForKey: @"BundledFiles"] count]; i++)
	{
		bundledFilePath = [[properties objectForKey: @"BundledFiles"] objectAtIndex: i];
		bundledFileDestPath = [resourcesPath stringByAppendingString:@"/"];
		bundledFileDestPath = [bundledFileDestPath stringByAppendingString: [bundledFilePath lastPathComponent]];
		
        NSString *srcFileName = [bundledFilePath lastPathComponent];
        [self report: [NSString stringWithFormat: @"Copying %@ to bundle", srcFileName]];
        
		// if it's a development version, we just symlink it
		if ([[properties objectForKey: @"DevelopmentVersion"] boolValue] == YES)
			[fileManager createSymbolicLinkAtPath: bundledFileDestPath withDestinationPath: bundledFilePath error: nil];
		else // else we copy it 
			[fileManager copyItemAtPath: bundledFilePath toPath: bundledFileDestPath error: nil];
	}

	////////////////////////////////// COPY APP OVER TO FINAL DESTINATION /////////////////////////////////
	
	// we've created the application bundle in the temporary directory
	// now it's time to move it to the destination specified by the user
    [self report: @"Moving app to destination"];
	
	// first, let's see if there's anything there.  If we have override set on, we just delete that stuff.
	if ([fileManager fileExistsAtPath: [properties objectForKey: @"Destination"]] && [[properties objectForKey: @"DestinationOverride"] boolValue])
		[fileManager removeItemAtPath: [properties objectForKey: @"Destination"] error: nil];

	//if delete wasn't a success and there's still something there
	if ([fileManager fileExistsAtPath: [properties objectForKey: @"Destination"]]) 
	{
		[fileManager removeItemAtPath: tmpPath error: nil];
		error = @"Could not remove pre-existing item at destination path";
		return 0;
	}
	
	// now, move the newly created app to the destination
	[fileManager moveItemAtPath: tmpPath toPath: [properties objectForKey: @"Destination"] error: nil];//move
	if (![fileManager fileExistsAtPath: [properties objectForKey: @"Destination"]]) //if move wasn't a success
	{
		[fileManager removeItemAtPath: tmpPath error: nil];
		error = @"Failed to create application at the specified destination";
		return 0;
	}
    if ([[properties objectForKey: @"DeclareService"] boolValue])
    {
        [self report: @"Updating Dynamic Services"];
        NSUpdateDynamicServices();
    }
    
    [self report: @"Done"];

	// notify workspace that the file changed
	[[NSWorkspace sharedWorkspace] noteFileSystemChanged:  [properties objectForKey: @"Destination"]];
	
	return 1;
}

-(void)report: (NSString *)str
{
    fprintf(stderr, "%s\n", [str UTF8String]);
    [[NSNotificationCenter defaultCenter] postNotificationName: @"PlatypusAppSpecCreationNotification" object: str];
}

/********************************************
	Make sure the data in the spec is sane
*********************************************/

-(BOOL)verify
{
	BOOL isDir;
	
	if (![[properties objectForKey: @"Destination"] hasSuffix: @"app"])
	{
		error = @"Destination must end with .app";
		return 0;
	}

	if ([[properties objectForKey: @"Name"] isEqualToString: @""])
	{
		error = @"Empty app name";
		return 0;
	}
	
	if (![FILEMGR fileExistsAtPath: [properties objectForKey: @"ScriptPath"] isDirectory: &isDir] || isDir)
	{
		error = [NSString stringWithFormat: @"Script not found at path '%@'", [properties objectForKey: @"ScriptPath"], nil];
		return 0;
	}
	
	if (![FILEMGR fileExistsAtPath: [properties objectForKey: @"NibPath"] isDirectory: &isDir])
	{
		error = [NSString stringWithFormat: @"Nib not found at path '%@'", [properties objectForKey: @"NibPath"], nil];
		return 0;
	}
	
	if (![FILEMGR fileExistsAtPath: [properties objectForKey: @"ExecutablePath"] isDirectory: &isDir] || isDir)
	{
		error = [NSString stringWithFormat: @"Executable not found at path '%@'", [properties objectForKey: @"ExecutablePath"], nil];
		return 0;
	}
	
	//make sure destination directory exists
	if (![FILEMGR fileExistsAtPath: [[properties objectForKey: @"Destination"] stringByDeletingLastPathComponent] isDirectory: &isDir] || !isDir)
	{
		error = [NSString stringWithFormat: @"Destination directory '%@' does not exist.", [[properties objectForKey: @"Destination"] stringByDeletingLastPathComponent], nil];
		return 0;
	}
	
	//make sure we have write privileges for the destination directory
	if (![FILEMGR isWritableFileAtPath: [[properties objectForKey: @"Destination"] stringByDeletingLastPathComponent]])
	{
		error = [NSString stringWithFormat: @"Don't have permission to write to the destination directory '%@'", [properties objectForKey: @"Destination"]] ;
		return 0;
	}
	
	return 1;
}

/********************************
 Dump properties array to a file
********************************/

-(void)dumpToFile: (NSString *)filePath
{
	[properties writeToFile: filePath atomically: YES];
}

-(void)dump
{
    fprintf(stdout, "%s\n", [[properties description] UTF8String]);
}

// generates the command that would create this spec using flags to the platypus command line tool

-(NSString *)commandString
{
	int i;
	NSString *checkboxParamStr = @"";
	NSString *iconParamStr = @"", *versionString = @"", *authorString = @"";
	NSString *suffixesString = @"", *filetypesString = @"", *parametersString = @"";
	NSString *textEncodingString = @"", *textOutputString = @"", *statusMenuOptionsString = @""; 
	
	// checkbox parameters
	if ([[properties objectForKey: @"Authentication"] boolValue])
		checkboxParamStr = [checkboxParamStr stringByAppendingString: @"A"];
	if ([[properties objectForKey: @"Secure"] boolValue])
		checkboxParamStr = [checkboxParamStr stringByAppendingString: @"S"];
	if ([[properties objectForKey: @"Droppable"] boolValue] && [[properties objectForKey: @"AcceptsFiles"] boolValue])
		checkboxParamStr = [checkboxParamStr stringByAppendingString: @"D"];
    if ([[properties objectForKey: @"Droppable"] boolValue] && [[properties objectForKey: @"AcceptsText"] boolValue])
		checkboxParamStr = [checkboxParamStr stringByAppendingString: @"F"];
    if ([[properties objectForKey: @"Droppable"] boolValue] && [[properties objectForKey: @"DeclareService"] boolValue])
		checkboxParamStr = [checkboxParamStr stringByAppendingString: @"N"];
	if ([[properties objectForKey: @"ShowInDock"] boolValue])
		checkboxParamStr = [checkboxParamStr stringByAppendingString: @"B"];
	if (![[properties objectForKey: @"RemainRunning"] boolValue])
		checkboxParamStr = [checkboxParamStr stringByAppendingString: @"R"];
	
	if ([checkboxParamStr length] != 0)
		checkboxParamStr = [NSString stringWithFormat: @"-%@ ", checkboxParamStr];
	
	if (![[properties objectForKey: @"Version"] isEqualToString: @"1.0"])
		versionString = [NSString stringWithFormat:@" -V '%@' ", [properties objectForKey: @"Version"]];
	
	if (![[properties objectForKey: @"Author"] isEqualToString: NSFullUserName()])
		authorString = [NSString stringWithFormat: @" -u '%@' ", [properties objectForKey: @"Author"]];
	
	// if it's droppable, we need the Types and Suffixes
	if ([[properties objectForKey: @"Droppable"] boolValue])
	{
		//create suffixes param
		suffixesString = [[properties objectForKey: @"Suffixes"] componentsJoinedByString:@"|"];
		suffixesString = [NSString stringWithFormat: @"-X '%@' ", suffixesString];
		
		//create filetype codes param
		filetypesString = [[properties objectForKey: @"FileTypes"] componentsJoinedByString:@"|"];
		filetypesString = [NSString stringWithFormat: @"-T '%@' ", filetypesString];
	}
	
	//create bundled files string
	NSString *bundledFilesCmdString = @"";
	NSArray *bundledFiles = (NSArray *)[properties objectForKey: @"BundledFiles"];
	for (i = 0; i < [bundledFiles count]; i++)
	{
		bundledFilesCmdString = [bundledFilesCmdString stringByAppendingString: [NSString stringWithFormat: @"-f '%@' ", [bundledFiles objectAtIndex: i]]];
	}
	
	// create interpreter and script args flags
	if ([(NSArray *)[properties objectForKey: @"InterpreterArgs"] count])
	{
		NSString *arg = [[properties objectForKey: @"InterpreterArgs"] componentsJoinedByString:@"|"];
		parametersString = [parametersString stringByAppendingString: [NSString stringWithFormat: @"-G '%@' ", arg]];
	}
    if ([(NSArray *)[properties objectForKey: @"ScriptArgs"] count])
	{
		NSString *arg = [[properties objectForKey: @"ScriptArgs"] componentsJoinedByString:@"|"];
		parametersString = [parametersString stringByAppendingString: [NSString stringWithFormat: @"-C '%@' ", arg]];
	}
	
	//  create args for text settings if progress bar/text window or status menu
	if (([[properties objectForKey: @"Output"] isEqualToString: @"Text Window"] || 
		 [[properties objectForKey: @"Output"] isEqualToString: @"Progress Bar"] ||
		 [[properties objectForKey: @"Output"] isEqualToString: @"Status Menu"]))
	{
		NSString *textFgString = @"", *textBgString = @"", *textFontString = @""; 
		if (![[properties objectForKey: @"TextForeground"] isEqualToString: DEFAULT_OUTPUT_FG_COLOR])
			textFgString = [NSString stringWithFormat: @" -g '%@' ", [properties objectForKey: @"TextForeground"]];
		
		if (![[properties objectForKey: @"TextBackground"] isEqualToString: DEFAULT_OUTPUT_BG_COLOR])
			textBgString = [NSString stringWithFormat: @" -b '%@' ", [properties objectForKey: @"TextForeground"]];
		
		if ([[properties objectForKey: @"TextSize"] floatValue] != DEFAULT_OUTPUT_FONTSIZE ||
			![[properties objectForKey: @"TextFont"] isEqualToString: DEFAULT_OUTPUT_FONT])
			textFontString = [NSString stringWithFormat: @" -n '%@ %2.f' ", [properties objectForKey: @"TextFont"], [[properties objectForKey: @"TextSize"] floatValue]];
	
		textOutputString = [NSString stringWithFormat: @"%@%@%@", textFgString, textBgString, textFontString];
	}
	
	//	text encoding	
	if ([[properties objectForKey: @"TextEncoding"] intValue] != DEFAULT_OUTPUT_TXT_ENCODING)
		textEncodingString = [NSString stringWithFormat: @" -E %d ", [[properties objectForKey: @"TextEncoding"] intValue]];
	
	//create custom icon string
	if (![[properties objectForKey: @"IconPath"] isEqualToString: CMDLINE_ICON_PATH] && ![[properties objectForKey: @"IconPath"] isEqualToString: @""])
		iconParamStr = [NSString stringWithFormat: @" -i '%@' ", [properties objectForKey: @"IconPath"]];
    //create custom icon string
	if ([properties objectForKey: @"DocIcon"] && ![[properties objectForKey: @"DocIcon"] isEqualToString: @""])
		iconParamStr = [iconParamStr stringByAppendingFormat: @" -Q '%@' ", [properties objectForKey: @"DocIcon"]];
    
	//status menu settings, if output mode is status menu
	if ([[properties objectForKey: @"Output"] isEqualToString: @"Status Menu"])
	{
		// -K kind
		statusMenuOptionsString = [statusMenuOptionsString stringByAppendingString: [NSString stringWithFormat: @"-K '%@' ", [properties objectForKey: @"StatusItemDisplayType"]]];
		
		// -L /path/to/image
		if (![[properties objectForKey: @"StatusItemDisplayType"] isEqualToString: @"Text"])
			statusMenuOptionsString = [statusMenuOptionsString stringByAppendingString: @"-L '/path/to/image' "];
		
		// -Y 'Title'
		if (![[properties objectForKey: @"StatusItemDisplayType"] isEqualToString: @"Icon"])
			statusMenuOptionsString = [statusMenuOptionsString stringByAppendingString: [NSString stringWithFormat: @"-Y '%@' ", [properties objectForKey: @"StatusItemTitle"]]];
	}
    
    // only set app name arg if we have a proper value
    NSString *appNameArg = [[properties objectForKey: @"Name"] isEqualToString: @""] ? @"" : [NSString stringWithFormat: @" -a '%@'", [properties objectForKey: @"Name"]];
    
    // only add identifier argument if it varies from default
    NSString *identifArg = [NSString stringWithFormat: @" -I %@", [properties objectForKey: @"Identifier"]];
    if ([[properties objectForKey: @"Identifier"] isEqualToString: [PlatypusAppSpec standardBundleIdForAppName: [properties objectForKey: @"Name"] usingDefaults: NO]])
        identifArg = @"";
	
	// finally, generate the command
	NSString *commandStr = [NSString stringWithFormat: 
							@"%@ %@%@%@ -o '%@' -p '%@'%@ %@%@%@%@%@%@%@%@%@ '%@'",
							CMDLINE_TOOL_PATH,
							checkboxParamStr,
							iconParamStr,
                            appNameArg,
							[properties objectForKey: @"Output"],
							[properties objectForKey: @"Interpreter"],
							authorString,
							versionString,
							identifArg,
							suffixesString,
							filetypesString,
							bundledFilesCmdString,
							parametersString,
							textEncodingString,
							textOutputString,
							statusMenuOptionsString,
							[properties objectForKey: @"ScriptPath"],
							nil];
	
	return commandStr;
}

/****************************
 Accessor functions
*****************************/

-(void)setProperty: (id)property forKey: (NSString *)theKey
{
	[properties setObject: property forKey: theKey];
}

-(id)propertyForKey: (NSString *)theKey
{
	return [properties objectForKey: theKey];
}

-(void)addProperties: (NSDictionary *)dict
{
	[properties addEntriesFromDictionary: dict];
}

-(NSDictionary *)properties
{
	return [properties retain];
}

-(NSString *)error
{
	return error;
}

-(NSString *)description
{
    return [properties description];
}

#pragma mark - Class Methods

/*****************************************
 - //return the bundle identifier for the application to be generated
 -  based on username etc. e.g. org.username.AppName
 *****************************************/

+ (NSString *)standardBundleIdForAppName: (NSString *)name  usingDefaults: (BOOL)def;
{
    NSString *defaults = def ? [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultBundleIdentifierPrefix"] : @"";    
    
    NSString *pre = (!def || [defaults isEqualToString: @""]) ? [NSString stringWithFormat: @"org.%@.", NSUserName()] : defaults;
    
	NSString *bundleId = [NSString stringWithFormat: @"%@%@", pre , name];
	bundleId = [PlatypusUtility removeWhitespaceInString: bundleId];//no spaces
	
    return bundleId;
}

@end
