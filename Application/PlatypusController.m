/*
 Copyright (c) 2003-2015, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 
 3. Neither the name of the copyright holder nor the names of its contributors may
 be used to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

// PlatypusController class is the controller class for the basic Platypus
// main window interface.  Also delegate for the application, and for menus.

#import "PlatypusController.h"

@implementation PlatypusController

#pragma mark - Application

/*****************************************
 - When application is launched by the user for the very first time
 we create a default set of preferences
 *****************************************/

+ (void)initialize {
    // create the user defaults here if none exists
    NSMutableDictionary *defaultPrefs = [NSMutableDictionary dictionary];
    
    // put default prefs in the dictionary
    
    // create default bundle identifier string from usename
    NSString *bundleId = [PlatypusAppSpec standardBundleIdForAppName:@"" usingDefaults:NO];
    
    [defaultPrefs setObject:bundleId forKey:@"DefaultBundleIdentifierPrefix"];
    [defaultPrefs setObject:DEFAULT_EDITOR forKey:@"DefaultEditor"];
    [defaultPrefs setObject:[NSArray array] forKey:@"Profiles"];
    [defaultPrefs setObject:[NSNumber numberWithBool:NO] forKey:@"RevealApplicationWhenCreated"];
    [defaultPrefs setObject:[NSNumber numberWithBool:NO] forKey:@"OpenApplicationWhenCreated"];
    [defaultPrefs setObject:[NSNumber numberWithBool:NO] forKey:@"CreateOnScriptChange"];
    [defaultPrefs setObject:[NSNumber numberWithInt:DEFAULT_OUTPUT_TXT_ENCODING] forKey:@"DefaultTextEncoding"];
    [defaultPrefs setObject:NSFullUserName() forKey:@"DefaultAuthor"];
    [defaultPrefs setObject:[NSNumber numberWithBool:NO] forKey:@"OnCreateDevVersion"];
    [defaultPrefs setObject:[NSNumber numberWithBool:YES] forKey:@"OnCreateOptimizeNib"];
    [defaultPrefs setObject:[NSNumber numberWithBool:NO] forKey:@"OnCreateUseXMLPlist"];
    
    // register the dictionary of defaults
    [DEFAULTS registerDefaults:defaultPrefs];
}

- (void)awakeFromNib {
    // make sure application support folder and subfolders exist
    BOOL isDir;
    
    // app support folder
    if (![FILEMGR fileExistsAtPath:APP_SUPPORT_FOLDER isDirectory:&isDir] && ![FILEMGR createDirectoryAtPath:APP_SUPPORT_FOLDER withIntermediateDirectories:NO attributes:nil error:nil]) {
            [PlatypusUtility alert:@"Error" subText:[NSString stringWithFormat:@"Could not create directory '%@'", [APP_SUPPORT_FOLDER stringByExpandingTildeInPath]]];
    }
    
    // profiles folder
    if (![FILEMGR fileExistsAtPath:PROFILES_FOLDER isDirectory:&isDir]) {
        if (![FILEMGR createDirectoryAtPath:PROFILES_FOLDER withIntermediateDirectories:NO attributes:nil error:nil]) {
            [PlatypusUtility alert:@"Error" subText:[NSString stringWithFormat:@"Could not create directory '%@'", PROFILES_FOLDER]];
        }
    }
    
    // we list ourself as an observer of changes to file system, for script
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(controlTextDidChange:) name:UKFileWatcherRenameNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(controlTextDidChange:) name:UKFileWatcherDeleteNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(scriptFileChanged:) name:UKFileWatcherWriteNotification object:nil];
    
    //populate script type menu
    [scriptTypePopupButton addItemsWithTitles:[ScriptAnalyser interpreterDisplayNames]];
    for (int i = 0; i < [[scriptTypePopupButton itemArray] count]; i++) {
        NSImage *icon = [NSImage imageNamed:[[scriptTypePopupButton itemAtIndex:i] title]];
        
        [[scriptTypePopupButton itemAtIndex:i] setImage:icon];
    }
    
    //populate output type menu
    [self updateOutputTypeMenu:NSMakeSize(16, 16)];
    
    [window registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, nil]];
    [window makeFirstResponder:appNameTextField];
    
    // if we haven't already loaded a profile via openfile delegate method
    // we set all fields to their defaults.  Any profile must contain a name
    // so we can be sure that one hasn't been loaded if the app name field is empty
    if ([[appNameTextField stringValue] isEqualToString:@""]) {
        [self clearAllFields:self];
    }
}

/*****************************************
 - Handler for when app is done launching
 *****************************************/

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //show window
    [window center];
    [window makeKeyAndOrderFront:self];
    [appNameTextField becomeFirstResponder];
}

/*****************************************
 - Handler for dragged files and/or files opened via the Finder
 We handle these as scripts, not bundled files
 *****************************************/

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    if ([filename hasSuffix:PROFILES_SUFFIX]) {
        [profilesController loadProfileFile:filename];
    } else {
        [self loadScript:filename];
    }
    return YES;
}

- (NSWindow *)window {
    return window;
}

#pragma mark - Script functions

/*****************************************
 - Create a new script and open in default editor
 *****************************************/

- (IBAction)newScript:(id)sender {
    NSString *newScriptPath = [self createNewScript:nil];
    [self loadScript:newScriptPath];
    [self editScript:self];
}

/*****************************************
 - Create a new script in app support directory
 with settings etc. from controls
 *****************************************/

- (NSString *)createNewScript:(NSString *)scriptText {
    NSString *tempScript, *defaultScript;
    NSString *interpreter = [interpreterTextField stringValue];
    
    // get a random number to append to script name in temp dir
    do {
        int randnum =  random() / 1000000;
        tempScript = [NSString stringWithFormat:@"%@Script.%d", [TEMP_FOLDER stringByExpandingTildeInPath], randnum];
    } while ([FILEMGR fileExistsAtPath:tempScript]);
    
    //put shebang line in the new script text file
    NSString *contentString = [NSString stringWithFormat:@"#!%@\n\n", interpreter];
    
    if (scriptText != nil) {
        contentString = [contentString stringByAppendingString:scriptText];
    } else {
        defaultScript = [[ScriptAnalyser interpreterHelloWorlds] objectForKey:[scriptTypePopupButton titleOfSelectedItem]];
        if (defaultScript != nil) {
            contentString = [contentString stringByAppendingString:defaultScript];
        }
    }
    
    //write the default content to the new script
    [contentString writeToFile:tempScript atomically:YES encoding:[[DEFAULTS objectForKey:@"DefaultTextEncoding"] intValue] error:nil];
    
    return tempScript;
}

/*****************************************
 - Reveal script in Finder
 *****************************************/

- (IBAction)revealScript:(id)sender {
    [[NSWorkspace sharedWorkspace] selectFile:[scriptPathTextField stringValue] inFileViewerRootedAtPath:[scriptPathTextField stringValue]];
}

/*****************************************
 - Open script in external editor
 *****************************************/

- (IBAction)editScript:(id)sender {
    //see if file exists
    if (![FILEMGR fileExistsAtPath:[scriptPathTextField stringValue]]) {
        [PlatypusUtility alert:@"File does not exist" subText:@"No file exists at the specified path"];
        return;
    }
    
    // if the default editor is the built-in editor, we pop down the editor sheet
    if ([[DEFAULTS stringForKey:@"DefaultEditor"] isEqualToString:DEFAULT_EDITOR]) {
        [self openScriptInBuiltInEditor:[scriptPathTextField stringValue]];
    } else { // open it in the external application
        NSString *defaultEditor = [DEFAULTS stringForKey:@"DefaultEditor"];
        if ([[NSWorkspace sharedWorkspace] fullPathForApplication:defaultEditor] != nil) {
            [[NSWorkspace sharedWorkspace] openFile:[scriptPathTextField stringValue] withApplication:defaultEditor];
        } else {
            // Complain if editor is not found, set it to the built-in editor
            [PlatypusUtility alert:@"Application not found" subText:[NSString stringWithFormat:@"The application '%@' could not be found on your system.  Reverting to the built-in editor.", defaultEditor]];
            [DEFAULTS setObject:DEFAULT_EDITOR forKey:@"DefaultEditor"];
            [self openScriptInBuiltInEditor:[scriptPathTextField stringValue]];
        }
    }
}

/*****************************************
 - Run the script in Terminal.app via Apple Event
 *****************************************/

- (IBAction)runScriptInTerminal:(id)sender {
    NSString *osaCmd = [NSString stringWithFormat:@"tell application \"Terminal\"\n\tdo script \"%@ '%@'\"\nactivate\nend tell", [interpreterTextField stringValue], [scriptPathTextField stringValue]];
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:osaCmd];
    [script executeAndReturnError:nil];
    [script release];
}

/*****************************************
 - Report on syntax of script
 *****************************************/

- (IBAction)checkSyntaxOfScript:(id)sender {
    [window setTitle:[NSString stringWithFormat:@"%@ - Syntax Checker", PROGRAM_NAME]];
    
    [[[SyntaxCheckerController alloc] init]
     showSyntaxCheckerForFile:[scriptPathTextField stringValue]
     withInterpreter:[interpreterTextField stringValue]
     window:window];
    
    [window setTitle:PROGRAM_NAME];
}

/*****************************************
 - Built-In script editor
 *****************************************/

- (void)openScriptInBuiltInEditor:(NSString *)path {
    [window setTitle:[NSString stringWithFormat:@"%@ - Editing script", PROGRAM_NAME]];
    [[[EditorController alloc] init] showEditorForFile:[scriptPathTextField stringValue] window:window];
    [window setTitle:PROGRAM_NAME];
}

- (void)scriptFileChanged:(NSNotification *)aNotification {
    if (![DEFAULTS boolForKey:@"CreateOnScriptChange"]) {
        return;
    }
    
    NSString *appBundleName = [NSString stringWithFormat:@"%@.app", [appNameTextField stringValue]];
    NSString *destPath = [[[scriptPathTextField stringValue] stringByDeletingLastPathComponent] stringByAppendingPathComponent:appBundleName];
    [self createApplication:destPath];
}

#pragma mark - Create

/*********************************************************************
 - Create button was pressed: Verify that field values are valid
 - Then put up a sheet for designating location to create application
 **********************************************************************/

- (IBAction)createButtonPressed:(id)sender {
    
    //are there invalid values in the fields?
    if (![self verifyFieldContents]) {
        return;
    }
    
    [window setTitle:[NSString stringWithFormat:@"%@ - Select place to create app", PROGRAM_NAME]];
    
    // get default app bundle name
    NSString *defaultAppBundleName = [appNameTextField stringValue];
    if (![defaultAppBundleName hasSuffix:@"app"]) {
        defaultAppBundleName = [NSString stringWithFormat:@"%@.app", defaultAppBundleName];
    }
    
    // Create save panel and add our custom accessory view
    NSSavePanel *sPanel = [NSSavePanel savePanel];
    [sPanel setPrompt:@"Create"];
    [sPanel setAccessoryView:debugSaveOptionView];
    [sPanel setNameFieldStringValue:defaultAppBundleName];
    
    // Configure the controls in the accessory view
    
    // development version checkbox: always disable this option if secure bundled script is checked
    [developmentVersionCheckbox setIntValue:[[DEFAULTS objectForKey:@"OnCreateDevVersion"] boolValue]];
    [developmentVersionCheckbox setEnabled:![encryptCheckbox intValue]];
    if ([encryptCheckbox intValue]) {
        [developmentVersionCheckbox setIntValue:0];
    }
    
    // optimize nib is enabled and on by default if ibtool is present
    [optimizeApplicationCheckbox setIntValue:[[DEFAULTS objectForKey:@"OnCreateOptimizeNib"] boolValue]];
    BOOL ibtoolInstalled = [FILEMGR fileExistsAtPath:[PlatypusUtility ibtoolPath]];
    [optimizeApplicationCheckbox setEnabled:ibtoolInstalled];
    if (!ibtoolInstalled) {
        [optimizeApplicationCheckbox setIntValue:0];
    }
    
    [xmlPlistFormatCheckbox setIntValue:[[DEFAULTS objectForKey:@"OnCreateUseXMLPlist"] boolValue]];
    
    //run save panel
    [sPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            [self createConfirmed:sPanel returnCode:result];
        }
    }];
    
}

- (void)createConfirmed:(NSSavePanel *)sPanel returnCode:(int)result {
    // restore window title
    [window setTitle:PROGRAM_NAME];
    
    [NSApp endSheet:window];
    [NSApp stopModal];
    
    // save accessory debug prefs into defaults
    [DEFAULTS setBool:[developmentVersionCheckbox state] forKey:@"OnCreateDevVersion"];
    [DEFAULTS setBool:[optimizeApplicationCheckbox state] forKey:@"OnCreateOptimizeNib"];
    [DEFAULTS setBool:[xmlPlistFormatCheckbox state] forKey:@"OnCreateUseXMLPlist"];
    
    // if user pressed cancel, we do nothing
    if (result != NSOKButton) {
        return;
    }
    
    // else, we go ahead with creating the application
    [NSTimer scheduledTimerWithTimeInterval:0.0001
                                     target:self
                                   selector:@selector(createApplicationFromTimer:)
                                   userInfo:[[sPanel URL] path]
                                    repeats:NO];
}

- (void)creationStatusUpdated:(NSNotification *)aNotification {
    [progressDialogStatusLabel setStringValue:[aNotification object]];
    [[progressDialogStatusLabel window] display];
}

- (BOOL)createApplicationFromTimer:(NSTimer *)theTimer {
    return [self createApplication:[theTimer userInfo]];
}

- (BOOL)createApplication:(NSString *)destination {
    // observe create notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(creationStatusUpdated:)
                                                 name:@"PlatypusAppSpecCreationNotification"
                                               object:nil];
    
    // we begin by making sure destination path ends in .app
    NSString *appPath = destination;
    if (![appPath hasSuffix:@".app"]) {
        appPath = [appPath stringByAppendingString:@".app"];
    }
    
    // create spec from controls and verify
    PlatypusAppSpec *spec = [self appSpecFromControls];
    
    // we set this specifically -- extra profile data
    [spec setProperty:appPath forKey:@"Destination"];
    [spec setProperty:[[NSBundle mainBundle] pathForResource:@"ScriptExec" ofType:nil] forKey:@"ExecutablePath"];
    [spec setProperty:[[NSBundle mainBundle] pathForResource:@"MainMenu.nib" ofType:nil] forKey:@"NibPath"];
    [spec setProperty:[NSNumber numberWithBool:[developmentVersionCheckbox intValue]] forKey:@"DevelopmentVersion"];
    [spec setProperty:[NSNumber numberWithBool:[optimizeApplicationCheckbox intValue]] forKey:@"OptimizeApplication"];
    [spec setProperty:[NSNumber numberWithBool:[xmlPlistFormatCheckbox intValue]] forKey:@"UseXMLPlistFormat"];
    [spec setProperty:[NSNumber numberWithBool:YES] forKey:@"DestinationOverride"];
    
    // verify that the values in the spec are OK
    if (![spec verify]) {
        [PlatypusUtility alert:@"Spec verification failed" subText:[spec error]];
        return NO;
    }
    
    // ok, now we try to create the app
    
    // first, show progress dialog
    [progressDialogMessageLabel setStringValue:[NSString stringWithFormat:@"Creating application %@", [spec propertyForKey:@"Name"]]];
    
    [progressBar setUsesThreadedAnimation:YES];
    [progressBar startAnimation:self];
    
    [NSApp  beginSheet:progressDialogWindow
        modalForWindow:window
         modalDelegate:nil
        didEndSelector:nil
           contextInfo:nil];
    
    // create the app from spec
    if (![spec create]) {
        // Dialog ends here.
        [NSApp endSheet:progressDialogWindow];
        [progressDialogWindow orderOut:self];
        
        [PlatypusUtility alert:@"Creating from spec failed" subText:[spec error]];
        return NO;
    }
    
    // reveal newly create app in Finder, if prefs say so
    if ([DEFAULTS boolForKey:@"RevealApplicationWhenCreated"]) {
        [[NSWorkspace sharedWorkspace] selectFile:appPath inFileViewerRootedAtPath:appPath];
    }
    
    // open newly create app, if prefs say so
    if ([DEFAULTS boolForKey:@"OpenApplicationWhenCreated"]) {
        [[NSWorkspace sharedWorkspace] launchApplication:appPath];
    }
    
    [developmentVersionCheckbox setIntValue:0];
    [optimizeApplicationCheckbox setIntValue:0];
    
    // Dialog ends here.
    [NSApp endSheet:progressDialogWindow];
    [progressDialogWindow orderOut:self];
    
    // Stop observing the filehandle for data since task is done
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PlatypusAppSpecCreationNotification" object:nil];
    
    return YES;
}

/*************************************************
 - Make sure that all fields contain valid values
 **************************************************/

- (BOOL)verifyFieldContents {
    BOOL isDir;
    
    //file manager
    NSFileManager *fileManager = FILEMGR;
    
    //script path
    if ([[appNameTextField stringValue] length] == 0) { //make sure a name has been assigned
        [PlatypusUtility sheetAlert:@"Invalid Application Name" subText:@"You must specify a name for your application" forWindow:window];
        return NO;
    }
    
    //script path
    if (([fileManager fileExistsAtPath:[scriptPathTextField stringValue] isDirectory:&isDir] == NO) || isDir) { //make sure script exists and isn't a folder
        [PlatypusUtility sheetAlert:@"Invalid Script Path" subText:@"No file exists at the script path you have specified" forWindow:window];
        return NO;
    }
    
    //make sure we have an icon
    if (([iconController hasIcns] && ![[iconController icnsFilePath] isEqualToString:@""] && ![fileManager fileExistsAtPath:[iconController icnsFilePath]])
        ||  (![(IconController *)iconController hasIcns] && [(IconController *)iconController imageData] == nil)) {
        [PlatypusUtility sheetAlert:@"Missing Icon" subText:@"You must set an icon for your application." forWindow:window];
        return NO;
    }
    
    // let's be certain that the bundled files list doesn't contain entries that have been moved
    if (![bundledFilesController allPathsAreValid]) {
        [PlatypusUtility sheetAlert:@"Moved or missing files" subText:@"One or more of the files that are to be bundled with the application have been moved.  Please rectify this and try again." forWindow:window];
        return NO;
    }
    
    //interpreter
    if ([fileManager fileExistsAtPath:[interpreterTextField stringValue]] == NO) {
        if ([PlatypusUtility proceedWarning:@"Invalid Interpreter" subText:@"The specified interpreter does not exist on this system.  Do you wish to proceed anyway?" withAction:@"Proceed"] == NO) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Generate/Read AppSpec

/*************************************************
 - Create app spec and fill it w. data from controls
 **************************************************/

- (id)appSpecFromControls {
    PlatypusAppSpec *spec = [[[PlatypusAppSpec alloc] initWithDefaults] autorelease];
    
    [spec setProperty:[appNameTextField stringValue] forKey:@"Name"];
    [spec setProperty:[scriptPathTextField stringValue] forKey:@"ScriptPath"];
    
    // set output type to the name of the output type, minus spaces
    [spec setProperty:[outputTypePopupMenu titleOfSelectedItem]
               forKey:@"Output"];
    
    // icon
    if ([iconController hasIcns]) {
        [spec setProperty:[iconController icnsFilePath] forKey:@"IconPath"];
    } else {
        [iconController writeIconToPath:[NSString stringWithFormat:@"%@%@.icns", APP_SUPPORT_FOLDER, [appNameTextField stringValue]]];
        [spec setProperty:TEMP_ICON_PATH forKey:@"IconPath"];
    }
    
    // advanced attributes
    [spec setProperty:[interpreterTextField stringValue] forKey:@"Interpreter"];
    [spec setProperty:[argsController interpreterArgs] forKey:@"InterpreterArgs"];
    [spec setProperty:[argsController scriptArgs] forKey:@"ScriptArgs"];
    [spec setProperty:[versionTextField stringValue] forKey:@"Version"];
    [spec setProperty:[bundleIdentifierTextField stringValue] forKey:@"Identifier"];
    [spec setProperty:[authorTextField stringValue] forKey:@"Author"];
    
    // checkbox attributes
    [spec setProperty:[NSNumber numberWithBool:[isDroppableCheckbox state]] forKey:@"Droppable"];
    [spec setProperty:[NSNumber numberWithBool:[encryptCheckbox state]] forKey:@"Secure"];
    [spec setProperty:[NSNumber numberWithBool:[rootPrivilegesCheckbox state]] forKey:@"Authentication"];
    [spec setProperty:[NSNumber numberWithBool:[remainRunningCheckbox state]] forKey:@"RemainRunning"];
    [spec setProperty:[NSNumber numberWithBool:[showInDockCheckbox state]] forKey:@"ShowInDock"];
    
    // bundled files
    [spec setProperty:[bundledFilesController getFilesArray] forKey:@"BundledFiles"];
    
    // file types
    [spec setProperty:(NSMutableArray *)[(SuffixListController *)[dropSettingsController suffixListController] getItemsArray] forKey:@"Suffixes"];
    [spec setProperty:(NSMutableArray *)[(UniformTypeListController *)[dropSettingsController uniformTypesListController] getItemsArray] forKey:@"UniformTypes"];
    [spec setProperty:[dropSettingsController docIconPath] forKey:@"DocIcon"];
    [spec setProperty:[NSNumber numberWithBool:[dropSettingsController acceptsText]] forKey:@"AcceptsText"];
    [spec setProperty:[NSNumber numberWithBool:[dropSettingsController acceptsFiles]] forKey:@"AcceptsFiles"];
    [spec setProperty:[NSNumber numberWithBool:[dropSettingsController declareService]] forKey:@"DeclareService"];
    [spec setProperty:[NSNumber numberWithBool:[dropSettingsController promptsForFileOnLaunch]] forKey:@"PromptForFileOnLaunch"];
    
    //  text output text settings
    [spec setProperty:[NSNumber numberWithInt:(int)[textSettingsController getTextEncoding]] forKey:@"TextEncoding"];
    [spec setProperty:[[textSettingsController getTextFont] fontName] forKey:@"TextFont"];
    [spec setProperty:[NSNumber numberWithFloat:[[textSettingsController getTextFont] pointSize]] forKey:@"TextSize"];
    [spec setProperty:[[textSettingsController getTextForeground] hexString] forKey:@"TextForeground"];
    [spec setProperty:[[textSettingsController getTextBackground] hexString] forKey:@"TextBackground"];
    
    // status menu settings
    if ([[outputTypePopupMenu titleOfSelectedItem] isEqualToString:@"Status Menu"]) {
        [spec setProperty:[statusItemSettingsController displayType] forKey:@"StatusItemDisplayType"];
        [spec setProperty:[statusItemSettingsController title] forKey:@"StatusItemTitle"];
        [spec setProperty:[[statusItemSettingsController icon] TIFFRepresentation] forKey:@"StatusItemIcon"];
    }
    
    return spec;
}

- (void)controlsFromAppSpec:(id)spec {
    [appNameTextField setStringValue:[spec propertyForKey:@"Name"]];
    [scriptPathTextField setStringValue:[spec propertyForKey:@"ScriptPath"]];
    
    [versionTextField setStringValue:[spec propertyForKey:@"Version"]];
    [authorTextField setStringValue:[spec propertyForKey:@"Author"]];
    
    [outputTypePopupMenu selectItemWithTitle:[spec propertyForKey:@"Output"]];
    [self outputTypeWasChanged:nil];
    [interpreterTextField setStringValue:[spec propertyForKey:@"Interpreter"]];
    
    //icon
    if ([spec propertyForKey:@"IconPath"] && ![[spec propertyForKey:@"IconPath"] isEqualToString:@""]) {
        [iconController loadIcnsFile:[spec propertyForKey:@"IconPath"]];
    }
    
    //checkboxes
    [rootPrivilegesCheckbox setState:[[spec propertyForKey:@"Authentication"] boolValue]];
    [isDroppableCheckbox setState:[[spec propertyForKey:@"Droppable"] boolValue]];
    [self isDroppableWasClicked:isDroppableCheckbox];
    [encryptCheckbox setState:[[spec propertyForKey:@"Secure"] boolValue]];
    [showInDockCheckbox setState:[[spec propertyForKey:@"ShowInDock"] boolValue]];
    [remainRunningCheckbox setState:[[spec propertyForKey:@"RemainRunning"] boolValue]];
    
    //file list
    [bundledFilesController clearList];
    [bundledFilesController addFiles:[spec propertyForKey:@"BundledFiles"]];
    
    //update button status
    [bundledFilesController performSelector:@selector(tableViewSelectionDidChange:) withObject:nil];
    
    //drop settings
    [(SuffixListController *)[dropSettingsController suffixListController] removeAllItems];
    [(SuffixListController *)[dropSettingsController suffixListController] addItems:[spec propertyForKey:@"Suffixes"]];
    [(UniformTypeListController *)[dropSettingsController uniformTypesListController] removeAllItems];
    [(UniformTypeListController *)[dropSettingsController uniformTypesListController] addItems:[spec propertyForKey:@"UniformTypes"]];

    [dropSettingsController performSelector:@selector(tableViewSelectionDidChange:) withObject:nil];
    
    if ([spec propertyForKey:@"DocIcon"] != nil) {
        [dropSettingsController setDocIconPath:[spec propertyForKey:@"DocIcon"]];
    }
    if ([spec propertyForKey:@"AcceptsText"] != nil) {
        [dropSettingsController setAcceptsText:[[spec propertyForKey:@"AcceptsText"] boolValue]];
    }
    if ([spec propertyForKey:@"AcceptsFiles"] != nil) {
        [dropSettingsController setAcceptsFiles:[[spec propertyForKey:@"AcceptsFiles"] boolValue]];
    }
    if ([spec propertyForKey:@"DeclareService"] != nil) {
        [dropSettingsController setDeclareService:[[spec propertyForKey:@"DeclareService"] boolValue]];
    }
    if ([spec propertyForKey:@"PromptForFileOnLaunch"] != nil) {
        [dropSettingsController setPromptsForFileOnLaunch:[[spec propertyForKey:@"PromptForFileOnLaunch"] boolValue]];
    }
    
    // args
    [argsController setInterpreterArgs:[spec propertyForKey:@"InterpreterArgs"]];
    [argsController setScriptArgs:[spec propertyForKey:@"ScriptArgs"]];
    
    // text output settings
    [textSettingsController setTextEncoding:[[spec propertyForKey:@"TextEncoding"] intValue]];
    [textSettingsController setTextFont:[NSFont fontWithName:[spec propertyForKey:@"TextFont"] size:[[spec propertyForKey:@"TextSize"] intValue]]];
    [textSettingsController setTextForeground:[NSColor colorFromHex:[spec propertyForKey:@"TextForeground"]]];
    [textSettingsController setTextBackground:[NSColor colorFromHex:[spec propertyForKey:@"TextBackground"]]];
    
    // status menu settings
    if ([[spec propertyForKey:@"Output"] isEqualToString:@"Status Menu"]) {
        if (![[spec propertyForKey:@"StatusItemDisplayType"] isEqualToString:@"Text"]) {
            NSImage *icon = [[[NSImage alloc] initWithData:[spec propertyForKey:@"StatusItemIcon"]] autorelease];
            if (icon != nil) {
                [statusItemSettingsController setIcon:icon];
            }
        }
        [statusItemSettingsController setTitle:[spec propertyForKey:@"StatusItemTitle"]];
        [statusItemSettingsController setDisplayType:[spec propertyForKey:@"StatusItemDisplayType"]];
    }
    
    //update buttons
    [self performSelector:@selector(controlTextDidChange:) withObject:nil];
    
    [self updateEstimatedAppSize];
    
    [bundleIdentifierTextField setStringValue:[spec propertyForKey:@"Identifier"]];
}

#pragma mark - Load/Select script

/*****************************************
 - Open sheet to select script to load
 *****************************************/

- (IBAction)selectScript:(id)sender {
    [window setTitle:[NSString stringWithFormat:@"%@ - Select script", PROGRAM_NAME]];
    
    //create open panel
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setPrompt:@"Select"];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    
    //run open panel sheet
    [oPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            NSString *filePath = [[[oPanel URLs] objectAtIndex:0] path];
            [self loadScript:filePath];
        }
        [window setTitle:PROGRAM_NAME];
    }];
}

/*****************************************
 - Called when script type is changed
 *****************************************/

- (IBAction)scriptTypeSelected:(id)sender {
    [self setScriptType:[[sender selectedItem] title]];
}

- (void)selectScriptTypeBasedOnInterpreter {
    NSString *type = [ScriptAnalyser displayNameForInterpreter:[interpreterTextField stringValue]];
    [scriptTypePopupButton selectItemWithTitle:type];
}

/*****************************************
 - Updates data in interpreter, icon and output type popup button
 *****************************************/

- (void)setScriptType:(NSString *)type {
    // set the script type based on the number which identifies each type
    NSString *interpreter = [ScriptAnalyser interpreterForDisplayName:type];
    [interpreterTextField setStringValue:interpreter];
    [scriptTypePopupButton selectItemWithTitle:type];
    [self performSelector:@selector(controlTextDidChange:) withObject:nil];
}

/*****************************************
 - Loads script data into platypus window
 *****************************************/

- (void)loadScript:(NSString *)filename {
    //make sure file we're loading actually exists
    BOOL isDir;
    if (![FILEMGR fileExistsAtPath:filename isDirectory:&isDir] || isDir) {
        return;
    }
    
    PlatypusAppSpec *spec = [[PlatypusAppSpec alloc] initWithDefaultsFromScript:filename];
    [self controlsFromAppSpec:spec];
    [spec release];
    
    [iconController setDefaultIcon];
    
    // add to recent items menu
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:filename]];
    
    [self updateEstimatedAppSize];
}

#pragma mark - Window interface actions

/*****************************************
 - Delegate for when text changes in any of
 the text fields
 *****************************************/

- (void)controlTextDidChange:(NSNotification *)aNotification {
    BOOL isDir, exists = NO, validName = NO;
    
    //app name or script path was changed
    if (aNotification == nil || [aNotification object] == nil || [aNotification object] == appNameTextField || [aNotification object] == scriptPathTextField) {
        if ([[appNameTextField stringValue] length] > 0) {
            validName = YES;
        }
        
        if ([scriptPathTextField hasValidPath]) {
            // add watcher that tracks whether it exists or is edited
            [[UKKQueue sharedFileWatcher] removeAllPathsFromQueue];
            [[UKKQueue sharedFileWatcher] addPathToQueue:[scriptPathTextField stringValue]];
            exists = YES;
        }
        
        [scriptPathTextField updateTextColoring];
        
        [editScriptButton setEnabled:exists];
        [revealScriptButton setEnabled:exists];
        
        //enable/disable create app button
        [createAppButton setEnabled:validName && exists];
    }
    if (aNotification != nil && [aNotification object] == appNameTextField) {
        //update identifier
        [bundleIdentifierTextField setStringValue:[PlatypusAppSpec standardBundleIdForAppName:[appNameTextField stringValue] usingDefaults:YES]];
    }
    
    //interpreter changed -- we try to select type based on the value in the field, also color red if path doesn't exist
    if (aNotification == nil || [aNotification object] == interpreterTextField || [aNotification object] == nil) {
        [self selectScriptTypeBasedOnInterpreter];
        NSColor *textColor = ([FILEMGR fileExistsAtPath:[interpreterTextField stringValue] isDirectory:&isDir] && !isDir) ? [NSColor blackColor] : [NSColor redColor];
        [interpreterTextField setTextColor:textColor];
    }
}

/*****************************************
 - called when Droppable checkbox is clicked
 *****************************************/

- (IBAction)isDroppableWasClicked:(id)sender {
    [dropSettingsButton setHidden:![isDroppableCheckbox state]];
    [dropSettingsButton setEnabled:[isDroppableCheckbox state]];
}

/*****************************************
 - called when Output Type is changed
 *****************************************/

- (IBAction)outputTypeWasChanged:(id)sender {
    // we don't show text output settings for output modes None and Web View
    if (![[outputTypePopupMenu titleOfSelectedItem] isEqualToString:@"None"] &&
        ![[outputTypePopupMenu titleOfSelectedItem] isEqualToString:@"Web View"] &&
        ![[outputTypePopupMenu titleOfSelectedItem] isEqualToString:@"Droplet"]) {
        [textOutputSettingsButton setHidden:NO];
        [textOutputSettingsButton setEnabled:YES];
    } else {
        [textOutputSettingsButton setHidden:YES];
        [textOutputSettingsButton setEnabled:NO];
    }
    
    // disable options that don't make sense for status menu output mode
    if ([[outputTypePopupMenu titleOfSelectedItem] isEqualToString:@"Status Menu"]) {
        // disable droppable & admin privileges
        [isDroppableCheckbox setIntValue:0];
        [isDroppableCheckbox setEnabled:NO];
        [self isDroppableWasClicked:self];
        [rootPrivilegesCheckbox setIntValue:0];
        [rootPrivilegesCheckbox setEnabled:NO];
        
        // force-enable "Remain running"
        [remainRunningCheckbox setIntValue:1];
        [remainRunningCheckbox setEnabled:NO];
        
        // check Runs in Background as default for Status Menu output
        [showInDockCheckbox setIntValue:1];
        
        // show button for special status item settings
        [statusItemSettingsButton setEnabled:YES];
        [statusItemSettingsButton setHidden:NO];
    } else {
        if ([[outputTypePopupMenu titleOfSelectedItem] isEqualToString:@"Droplet"]) {
            [isDroppableCheckbox setIntValue:1];
            [self isDroppableWasClicked:self];
        }
        
        // re-enable droppable
        [isDroppableCheckbox setEnabled:YES];
        [rootPrivilegesCheckbox setEnabled:YES];
        
        // re-enable remain running
        [remainRunningCheckbox setEnabled:YES];
        
        [showInDockCheckbox setIntValue:0];
        
        // hide special status item settings
        [statusItemSettingsButton setEnabled:NO];
        [statusItemSettingsButton setHidden:YES];
    }
}

/*****************************************
 - called when (Clear) button is pressed
 -- restores fields to startup values
 *****************************************/

- (IBAction)clearAllFields:(id)sender {
    //clear all text field to start value
    [appNameTextField setStringValue:@""];
    [scriptPathTextField setStringValue:@""];
    [versionTextField setStringValue:@"1.0"];
    
    [bundleIdentifierTextField setStringValue:[PlatypusAppSpec standardBundleIdForAppName:[appNameTextField stringValue] usingDefaults:YES]];
    [authorTextField setStringValue:[DEFAULTS objectForKey:@"DefaultAuthor"]];
    
    //uncheck all options
    [isDroppableCheckbox setIntValue:0];
    [self isDroppableWasClicked:isDroppableCheckbox];
    [encryptCheckbox setIntValue:0];
    [rootPrivilegesCheckbox setIntValue:0];
    [remainRunningCheckbox setIntValue:1];
    [showInDockCheckbox setIntValue:0];
    
    //clear file list
    [bundledFilesController clearFileList:self];
    
    //clear suffix and types lists to default values
    [dropSettingsController setToDefaults:self];
    
    //set parameters to default
    [argsController resetDefaults:self];
    
    //set text ouput settings to default
    [textSettingsController resetDefaults:self];
    
    //set status item settings to default
    [statusItemSettingsController restoreDefaults:self];
    
    //set script type
    [self setScriptType:@"Shell"];
    
    //set output type
    [outputTypePopupMenu selectItemWithTitle:DEFAULT_OUTPUT_TYPE];
    [self outputTypeWasChanged:outputTypePopupMenu];
    
    //update button status
    [self performSelector:@selector(controlTextDidChange:) withObject:nil];
    
    [appSizeTextField setStringValue:@""];
    
    [iconController setDefaultIcon];
}

/*****************************************
 - Show shell command window
 *****************************************/

- (IBAction)showCommandLineString:(id)sender {
    if (![FILEMGR fileExistsAtPath:[scriptPathTextField stringValue]]) {
        [PlatypusUtility alert:@"Missing script" subText:[NSString stringWithFormat:@"No file exists at path '%@'", [scriptPathTextField stringValue]]];
        return;
    }
    
    [window setTitle:[NSString stringWithFormat:@"%@ - Shell Command String", PROGRAM_NAME]];
    ShellCommandController *controller = [[ShellCommandController alloc] init];
    [controller setPrefsController:prefsController];
    [controller showShellCommandForSpec:[self appSpecFromControls] window:window];
    
    [window setTitle:PROGRAM_NAME];
}

#pragma mark - App Size estimation

/*****************************************
 - // set app size textfield to formatted str with app size
 *****************************************/

- (void)updateEstimatedAppSize {
    [appSizeTextField setStringValue:[NSString stringWithFormat:@"Estimated final app size: ~%@", [self estimatedAppSize]]];
}

/*****************************************
 - // Make a decent guess concerning final app size
 *****************************************/

- (NSString *)estimatedAppSize {
    
    // estimate the combined size of all the
    // files that will go into application bundle
    UInt64 estimatedAppSize = 0;
    estimatedAppSize += 4096; // Info.plist
    estimatedAppSize += 4096; // AppSettings.plist
    estimatedAppSize += [iconController iconSize];
    estimatedAppSize += [dropSettingsController docIconSize];
    estimatedAppSize += [PlatypusUtility fileOrFolderSize:[scriptPathTextField stringValue]];
    estimatedAppSize += [PlatypusUtility fileOrFolderSize:[[NSBundle mainBundle] pathForResource:@"ScriptExec" ofType:nil]];
    
    // nib size is much smaller if compiled with ibtool
    UInt64 nibSize = [PlatypusUtility fileOrFolderSize:[[NSBundle mainBundle] pathForResource:@"MainMenu.nib" ofType:nil]];
    if ([FILEMGR fileExistsAtPath:IBTOOL_PATH] || [FILEMGR fileExistsAtPath:IBTOOL_PATH_2]) {
        nibSize = 0.60 * nibSize; // compiled nib is approximtely 65% of original
    }
    estimatedAppSize += nibSize;
    
    // bundled files altogether
    estimatedAppSize += [bundledFilesController getTotalSize];
    
    return [PlatypusUtility sizeAsHumanReadable:estimatedAppSize];
}

// Creates an NSTask from settings
- (NSTask *)taskForCurrentScript {
    if (![FILEMGR fileExistsAtPath:[scriptPathTextField stringValue]]) {
        return nil;
    }
    
    //create task
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:[interpreterTextField stringValue]];
    [task setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    
    // add arguments
    NSMutableArray *args = [NSMutableArray array];
    [args addObjectsFromArray:[argsController interpreterArgs]];
    [args addObject:[scriptPathTextField stringValue]];
    [args addObjectsFromArray:[argsController scriptArgs]];
    [task setArguments:args];

    return [task autorelease];
}

#pragma mark - Drag and drop

/*****************************************
 - Dragging and dropping for Platypus window
 *****************************************/

- (BOOL)performDragOperation:(id <NSDraggingInfo> )sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSString *filename;
    BOOL isDir = FALSE;
    
    // File
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        filename = [files objectAtIndex:0]; //we only load the first dragged item
        if ([FILEMGR fileExistsAtPath:filename isDirectory:&isDir] && !isDir) {
            if ([filename hasSuffix:PROFILES_SUFFIX]) {
                [profilesController loadProfileFile:filename];
            } else {
                [self loadScript:filename];
            }
            return YES;
        }
    }
    // String
    else if ([[pboard types] containsObject:NSStringPboardType]) {
        // create a new script file with the dropped string, load it
        NSString *draggedString = [pboard stringForType:NSStringPboardType];
        NSString *newScriptPath = [self createNewScript:draggedString];
        [self loadScript:newScriptPath];
        //[self editScript: self];
        return YES;
    }
    
    return NO;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo> )sender {
    // we accept dragged files
    if ([[[sender draggingPasteboard] types] containsObject:NSFilenamesPboardType]) {
        NSString *file = [[[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType] objectAtIndex:0];
        if (![file hasSuffix:@".icns"]) {
            return NSDragOperationLink;
        }
    } else if ([[[sender draggingPasteboard] types] containsObject:NSStringPboardType]) {
        return NSDragOperationCopy;
    }
    
    return NSDragOperationNone;
}

// if we just created a file with a dragged string, we open it in default editor
- (void)concludeDragOperation:(id <NSDraggingInfo> )sender {
    if ([[[sender draggingPasteboard] types] containsObject:NSStringPboardType]) {
        [self editScript:self];
    }
}

#pragma mark - Menu items

/*****************************************
 - Delegate function for enabling and disabling menu items
 *****************************************/

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    
    //create app menu item
    if ([[anItem title] isEqualToString:@"Create App"] && ![createAppButton isEnabled]) {
        return NO;
    }
    
    //actions on script file
    BOOL isDir;
    BOOL badScriptFile = (![FILEMGR fileExistsAtPath:[scriptPathTextField stringValue] isDirectory:&isDir] || isDir);
    if (([anItem action] == @selector(editScript:) ||
         [anItem action] == @selector(revealScript:) ||
         [anItem action] == @selector(runScriptInTerminal:) ||
         [anItem action] == @selector(checkSyntaxOfScript:))
        && badScriptFile) {
        return NO;
    }

    // show shell command only works if we have a script
    if ([anItem action] == @selector(showCommandLineString:) && badScriptFile) {
        return NO;
    }
    
    return YES;
}

- (void)updateOutputTypeMenu:(NSSize)iconSize {
    NSArray *items = [outputTypePopupMenu itemArray];
    for (NSMenuItem *menuItem in items) {
        NSString *imageName = [[menuItem title] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
        NSImage *img = [NSImage imageNamed:imageName];
        img.size = iconSize;
        [menuItem setImage:nil];
        [menuItem setImage:img];
    }
}

- (void)menuWillOpen:(NSMenu *)menu {
    [self updateOutputTypeMenu:NSMakeSize(32, 32)];
}

- (void)menuDidClose:(NSMenu *)menu {
    [self updateOutputTypeMenu:NSMakeSize(16, 16)];
}

#pragma mark - Help/Documentation

// Open Documentation.html file within app bundle
- (IBAction)showHelp:(id)sender {
    [PlatypusUtility openInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_DOCUMENTATION ofType:nil]];
}

// Open html version of 'platypus' command line tool's man page
- (IBAction)showManPage:(id)sender {
    [PlatypusUtility openInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_MANPAGE ofType:nil]];
}

// Open Readme.html
- (IBAction)showReadme:(id)sender {
    [PlatypusUtility openInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_README_FILE ofType:nil]];
}

// Open program website
- (IBAction)openWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:PROGRAM_WEBSITE]];
}

// Open License html file
- (IBAction)openLicense:(id)sender {
    [PlatypusUtility openInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_LICENSE_FILE ofType:nil]];
}

// Open donations website
- (IBAction)openDonations:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:PROGRAM_DONATIONS]];
}

@end
