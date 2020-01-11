/*
    Copyright (c) 2003-2020, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

#import "PlatypusWindowController.h"
#import "Common.h"
#import "PlatypusAppSpec.h"
#import "PlatypusScriptUtils.h"
#import "IconController.h"
#import "ArgsController.h"
#import "ProfilesController.h"
#import "TextSettingsController.h"
#import "StatusItemSettingsController.h"
#import "EditorController.h"
#import "ShellCommandController.h"
#import "STPathTextField.h"
#import "STReverseDNSTextField.h"
#import "DropSettingsController.h"
#import "SyntaxCheckerController.h"
#import "BundledFilesController.h"
#import "PreferencesController.h"
#import "NSWorkspace+Additions.h"
#import "Alerts.h"
#import "NSColor+HexTools.h"
#import "VDKQueue.h"

@interface PlatypusWindowController()
{
    // Basic controls
    IBOutlet NSTextField *appNameTextField;
    IBOutlet NSPopUpButton *scriptTypePopupButton;
    IBOutlet STPathTextField *scriptPathTextField;
    IBOutlet NSButton *editScriptButton;
    IBOutlet NSButton *revealScriptButton;
    IBOutlet NSPopUpButton *interfaceTypePopupButton;
    IBOutlet NSButton *textSettingsButton;
    IBOutlet NSButton *statusItemSettingsButton;
    IBOutlet NSButton *createAppButton;
    IBOutlet NSTextField *appSizeTextField;

    // Advanced options controls
    IBOutlet NSTextField *interpreterPathTextField;
    IBOutlet NSTextField *versionTextField;
    IBOutlet STReverseDNSTextField *bundleIdentifierTextField;
    IBOutlet NSTextField *authorTextField;
    IBOutlet NSButton *acceptsDroppedItemsCheckbox;
    IBOutlet NSButton *dropSettingsButton;
    IBOutlet NSButton *rootPrivilegesCheckbox;
    IBOutlet NSButton *secureBundledScriptCheckbox;
    IBOutlet NSButton *runInBackgroundCheckbox;
    IBOutlet NSButton *remainRunningCheckbox;
    
    // Create app dialog view
    IBOutlet NSView *debugSaveOptionView;
    IBOutlet NSButton *createSymlinksCheckbox;
    IBOutlet NSButton *stripNibFileCheckbox;
    
    // Progress sheet when creating
    IBOutlet NSWindow *progressDialogWindow;
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSTextField *progressDialogMessageLabel;
    IBOutlet NSTextField *progressDialogStatusLabel;
    
    // Interface controllers
    IBOutlet IconController *iconController;
    IBOutlet DropSettingsController *dropSettingsController;
    IBOutlet ArgsController *argsController;
    IBOutlet ProfilesController *profilesController;
    IBOutlet TextSettingsController *textSettingsController;
    IBOutlet StatusItemSettingsController *statusItemSettingsController;
    IBOutlet PreferencesController *prefsController;
    IBOutlet BundledFilesController *bundledFilesController;
    
    VDKQueue *fileWatcherQueue;
}
@end

@implementation PlatypusWindowController

#pragma mark - Application

- (instancetype)init {
    if (self = [super init]) {
        fileWatcherQueue = [[VDKQueue alloc] init];
    }
    return self;
}

+ (void)initialize {
    // Register the dictionary of defaults
    [DEFAULTS registerDefaults:[PreferencesController defaultsDictionary]];
}

- (void)awakeFromNib {
    // Put application icon in window title bar
    [[self window] setRepresentedURL:[NSURL URLWithString:PROGRAM_WEBSITE]];
    NSButton *button = [[self window] standardWindowButton:NSWindowDocumentIconButton];
    [button setImage:[NSApp applicationIconImage]];
    
    // Make sure application support folder and subfolders exist
    BOOL isDir;
    // Application Support folder
    NSError *err;
    if (![FILEMGR fileExistsAtPath:PROGRAM_APP_SUPPORT_PATH isDirectory:&isDir] &&
        ![FILEMGR createDirectoryAtPath:PROGRAM_APP_SUPPORT_PATH withIntermediateDirectories:NO attributes:nil error:&err]) {
            [Alerts alert:@"Error" subTextFormat:@"Could not create directory '%@', %@",
             PROGRAM_APP_SUPPORT_PATH, [err localizedDescription]];
    }
    
    // Profiles subfolder
    if (![FILEMGR fileExistsAtPath:PROGRAM_PROFILES_PATH isDirectory:&isDir]) {
        if (![FILEMGR createDirectoryAtPath:PROGRAM_PROFILES_PATH withIntermediateDirectories:NO attributes:nil error:&err]) {
            [Alerts alert:@"Error" subTextFormat:@"Could not create directory '%@', %@",
             PROGRAM_PROFILES_PATH, [err localizedDescription]];
        }
    }
    
    // We list ourself as an observer of changes to file system for script path being watched
    [[WORKSPACE notificationCenter] addObserver:self
                                       selector:@selector(scriptFileSystemChange)
                                           name:VDKQueueRenameNotification
                                         object:nil];
    
    // Listen for app size change notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateEstimatedAppSize)
                                                 name:PLATYPUS_APP_SIZE_CHANGED_NOTIFICATION
                                               object:nil];

    
    // Populate script type menu
    [scriptTypePopupButton addItemsWithTitles:[PlatypusScriptUtils interpreterDisplayNames]];
    NSArray *menuItems = [scriptTypePopupButton itemArray];
    for (NSMenuItem *item in menuItems) {
        NSImage *icon = [NSImage imageNamed:[NSString stringWithFormat:@"Interpreter_%@", [item title]]];
        [icon setSize:NSMakeSize(16, 16)];
        [item setImage:icon];
    }
    
    // Populate interface type menu
    [interfaceTypePopupButton removeAllItems];
    [interfaceTypePopupButton addItemsWithTitles:PLATYPUS_INTERFACE_TYPE_NAMES];
    [self updateInterfaceTypeMenu:NSMakeSize(16, 16)];
    
    // Main window accepts dragged text and dragged files
    [[self window] registerForDraggedTypes:@[NSFilenamesPboardType, NSStringPboardType]];
    
    // If we haven't already loaded a profile via openfile delegate method
    // we set all fields to their defaults. Any profile must contain a name
    // so we can be sure that one hasn't been loaded if the app name field is empty
    if ([[appNameTextField stringValue] isEqualToString:@""]) {
        [self clearAllFields:self];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    if ([DEFAULTS boolForKey:DefaultsKey_Launched] == NO) {
        [[self window] center];
        [DEFAULTS setBool:YES forKey:DefaultsKey_Launched];
    }
    [[self window] makeKeyAndOrderFront:self];
    [appNameTextField becomeFirstResponder];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    NSString *fileType = [WORKSPACE typeOfFile:filename error:nil];
    if ([filename hasSuffix:PROGRAM_PROFILE_SUFFIX] || [WORKSPACE type:fileType conformsToType:PROGRAM_PROFILE_UTI]) {
        return [profilesController loadProfileAtPath:filename];
    } else {
        [self loadScript:filename];
    }
    return YES;
}

- (BOOL)window:(NSWindow *)window shouldPopUpDocumentPathMenu:(NSMenu *)menu {
    // Prevent popup menu when window icon/title is cmd-clicked
    return NO;
}

- (BOOL)window:(NSWindow *)window shouldDragDocumentWithEvent:(NSEvent *)e from:(NSPoint)loc withPasteboard:(NSPasteboard *)p {
    // Prevent dragging of title bar icon
    return NO;
}

#pragma mark - Script functions

- (IBAction)newScript:(id)sender {
    NSString *newScriptPath = [self createNewScript:nil];
    [self loadScript:newScriptPath];
    [self editScript:self];
}

- (NSString *)createNewScript:(NSString *)scriptText {
    NSString *interpreterPath = [interpreterPathTextField stringValue];
    NSString *suffix = [PlatypusScriptUtils standardFilenameSuffixForInterpreterPath:interpreterPath];
    
    NSString *appName = [appNameTextField stringValue];
    if ([appName isEqualToString:@""]) {
        appName = NEW_SCRIPT_FILENAME;
    }

    NSString *tmpScriptPath = [NSString stringWithFormat:@"%@%@%@", PROGRAM_TEMPDIR_PATH, appName, suffix];
    
    // Increment digit appended to script name until no script with that name exists at path
    int incr = 1;
    while ([FILEMGR fileExistsAtPath:tmpScriptPath]) {
        tmpScriptPath = [NSString stringWithFormat:@"%@%@-%d%@", PROGRAM_TEMPDIR_PATH, appName, incr, suffix];
        incr++;
    }
    
    // Put shebang line in the new script text file
    NSString *contentString = [NSString stringWithFormat:@"#!%@\n\n", interpreterPath];
    
    if (scriptText) {
        contentString = [contentString stringByAppendingString:scriptText];
    } else {
        NSString *defaultScriptText = [PlatypusScriptUtils helloWorldProgramForDisplayName:[scriptTypePopupButton titleOfSelectedItem]];
        if (defaultScriptText) {
            contentString = [contentString stringByAppendingString:defaultScriptText];
        }
    }
    
    // Write the default content to the new script
    NSError *err;
    BOOL success = [contentString writeToFile:tmpScriptPath
                                   atomically:YES
                                     encoding:DEFAULT_TEXT_ENCODING
                                        error:&err];
    if (!success) {
        [Alerts alert:@"Error creating file" subText:[err localizedDescription]];
        return nil;
    }
    
    return tmpScriptPath;
}

- (IBAction)revealScript:(id)sender {
    if ([FILEMGR fileExistsAtPath:[scriptPathTextField stringValue]] == NO) {
        [Alerts alert:@"File not found" subText:@"No file exists at the specified path"];
    }
    [WORKSPACE selectFile:[scriptPathTextField stringValue] inFileViewerRootedAtPath:[scriptPathTextField stringValue]];
}

- (IBAction)editScript:(id)sender {
    [self openScriptInEditor:[scriptPathTextField stringValue]];
}

- (void)openScriptInEditor:(NSString *)scriptPath {
    // See if file exists
    if (![FILEMGR fileExistsAtPath:scriptPath]) {
        [Alerts alert:@"File does not exist" subText:@"No file exists at the specified path"];
        return;
    }
    
    // If the default editor is the built-in editor, we pop down the editor sheet
    NSString *defEd = [DEFAULTS stringForKey:DefaultsKey_DefaultEditor];
    if ([defEd isEqualToString:DEFAULT_EDITOR] || [defEd isEqualToString:PROGRAM_NAME]) {
        [self openScriptInBuiltInEditor:scriptPath];
    } else {
        // Open it in the external application
        NSString *defaultEditor = [DEFAULTS stringForKey:DefaultsKey_DefaultEditor];
        if ([WORKSPACE fullPathForApplication:defaultEditor] != nil) {
            [WORKSPACE openFile:scriptPath withApplication:defaultEditor];
        } else {
            // Complain if editor is not found, set it to the built-in editor
            [Alerts alert:@"Application not found"
            subTextFormat:@"The editor '%@' could not be found on your system. Using built-in editor.", defaultEditor];
            [DEFAULTS setObject:DEFAULT_EDITOR forKey:DefaultsKey_DefaultEditor];
            [self openScriptInBuiltInEditor:scriptPath];
        }
    }
}

- (void)openScriptInBuiltInEditor:(NSString *)scriptPath {
    [[self window] setTitle:[NSString stringWithFormat:@"%@ - Script Editor", PROGRAM_NAME]];
    EditorController *controller = [[EditorController alloc] init];
    [controller showModalEditorSheetForFile:scriptPath window:[self window]];
    [[self window] setTitle:PROGRAM_NAME];
}

- (IBAction)checkSyntaxOfScript:(id)sender {
    [[self window] setTitle:[NSString stringWithFormat:@"%@ - Syntax Checker", PROGRAM_NAME]];
    SyntaxCheckerController *controller = [[SyntaxCheckerController alloc] init];
    [controller showModalSyntaxCheckerSheetForFile:[scriptPathTextField stringValue]
                                        scriptName:[[scriptPathTextField stringValue] lastPathComponent]
                            usingInterpreterAtPath:[interpreterPathTextField stringValue]
                                            window:[self window]];
    [[self window] setTitle:PROGRAM_NAME];
}

- (void)scriptFileSystemChange {
    [scriptPathTextField updateTextColoring];
}

#pragma mark - Create

- (IBAction)createButtonPressed:(id)sender {
    
    // Are there invalid values in the fields?
    if (![self verifyFieldContents]) {
        return;
    }
    
    [[self window] setTitle:[NSString stringWithFormat:@"%@ - Select destination", PROGRAM_NAME]];
    
    // Get default app bundle name
    NSString *defaultAppBundleName = [appNameTextField stringValue];
    if (![defaultAppBundleName hasSuffix:@"app"]) {
        defaultAppBundleName = [NSString stringWithFormat:@"%@.app", defaultAppBundleName];
    }
    
    // Create save panel and add our custom accessory view
    NSSavePanel *sPanel = [NSSavePanel savePanel];
    [sPanel setPrompt:@"Create"];
    [sPanel setAccessoryView:debugSaveOptionView];
    [sPanel setNameFieldStringValue:defaultAppBundleName];
    
    // Configure controls in the accessory view
    
    // Development version checkbox: always disable this option if secure script is checked
    [createSymlinksCheckbox setEnabled:![secureBundledScriptCheckbox intValue]];
    if ([secureBundledScriptCheckbox intValue]) {
        [DEFAULTS setBool:NO forKey:DefaultsKey_SymlinkFiles];
    }
    
    // Optimize nib is on by default if ibtool is present
    BOOL ibtoolInstalled = [FILEMGR fileExistsAtPath:IBTOOL_PATH];
    if ([[DEFAULTS objectForKey:DefaultsKey_StripNib] boolValue] == YES && ibtoolInstalled == NO) {
        [DEFAULTS setBool:NO forKey:DefaultsKey_StripNib];
    }
    [stripNibFileCheckbox setEnabled:ibtoolInstalled];
    
    // Run save panel
    [sPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        [[self window] setTitle:PROGRAM_NAME];
        if (result == NSOKButton) {
            [self createConfirmed:sPanel returnCode:result];
        }
    }];
}

- (void)createConfirmed:(NSSavePanel *)sPanel returnCode:(NSInteger)result {
    // Restore window title
    [[self window] setTitle:PROGRAM_NAME];
    
    [NSApp endSheet:[self window]];
    [NSApp stopModal];
        
    if (result != NSOKButton) {
        return;
    }
    
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
    // Start observing spec creation notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(creationStatusUpdated:)
                                                 name:PLATYPUS_APP_SPEC_CREATION_NOTIFICATION
                                               object:nil];
    
    // Begin by making sure destination path ends in .app
    NSString *appPath = destination;
    if (![appPath hasSuffix:APPBUNDLE_SUFFIX]) {
        appPath = [appPath stringByAppendingString:APPBUNDLE_SUFFIX];
    }
    
    // Create spec from controls
    PlatypusAppSpec *spec = [self appSpecFromControls];
    
    // We set this specifically
    spec[AppSpecKey_DestinationPath] = appPath;
    spec[AppSpecKey_ExecutablePath] = [[NSBundle mainBundle] pathForResource:CMDLINE_SCRIPTEXEC_GZIP_NAME ofType:nil];
    spec[AppSpecKey_NibPath] = [[NSBundle mainBundle] pathForResource:@"MainMenu.nib" ofType:nil];
    spec[AppSpecKey_SymlinkFiles] = @((BOOL)[createSymlinksCheckbox intValue]);
    spec[AppSpecKey_StripNib] = @((BOOL)[stripNibFileCheckbox intValue]);
    spec[AppSpecKey_Overwrite] = @YES;
    if (![[DEFAULTS stringForKey:DefaultsKey_SigningIdentity] isEqualToString:@"None"]) {
        spec[AppSpecKey_SigningIdentity] = [DEFAULTS stringForKey:@"SigningIdentity"];
    }
    
    // Verify that the values in the spec are OK
    if (![spec verify]) {
        [Alerts alert:@"Application spec verification failed" subText:[spec error]];
        return NO;
    }
    
    // Show progress dialog
    NSString *progressStr = [NSString stringWithFormat:@"Creating application %@", spec[AppSpecKey_Name]];
    [progressDialogMessageLabel setStringValue:progressStr];
    [progressBar setUsesThreadedAnimation:YES];
    [progressBar startAnimation:self];

    [NSApp beginSheet:progressDialogWindow
       modalForWindow:[self window]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
    
    // Create app from spec
    if (![spec create]) {
        [NSApp endSheet:progressDialogWindow];
        [progressDialogWindow orderOut:self];
        [Alerts alert:@"Creating from spec failed" subText:[spec error]];
        return NO;
    }

    // Reveal newly created app in Finder
    if ([DEFAULTS boolForKey:DefaultsKey_RevealApplicationWhenCreated]) {
        [WORKSPACE selectFile:appPath inFileViewerRootedAtPath:appPath];
    }
    
    // Open newly created app
    if ([DEFAULTS boolForKey:DefaultsKey_OpenApplicationWhenCreated]) {
        [WORKSPACE launchApplication:appPath];
    }
    
    // Dialog ends here
    [NSApp endSheet:progressDialogWindow];
    [progressDialogWindow orderOut:self];
    
    return YES;
}

- (BOOL)verifyFieldContents {
    
    // Make sure a name has been assigned
    if ([[appNameTextField stringValue] length] == 0) {
        [Alerts sheetAlert:@"Missing Application Name"
                   subText:@"You must provide a name for your application."
                 forWindow:[self window]];
        return NO;
    }
    
    // Verify that script exists at path and isn't a directory
    BOOL isDir;
    if ([FILEMGR fileExistsAtPath:[scriptPathTextField stringValue] isDirectory:&isDir] == NO || isDir) {
        [Alerts sheetAlert:@"Invalid Script Path"
                   subText:@"Script file does not exist at the path you specified"
                 forWindow:[self window]];
        return NO;
    }
    
    // Validate bundle identifier
    if ([bundleIdentifierTextField isValid] == NO) {
        [Alerts sheetAlert:@"Invalid Bundle Identifier"
                 forWindow:[self window]
             subTextFormat:@"The string '%@' is not a valid application bundle identifier.", [bundleIdentifierTextField stringValue]];
        return NO;
    }
    
    // Warn if interpreter doesn't exist
    if ([FILEMGR fileExistsAtPath:[interpreterPathTextField stringValue]] == NO) {
        NSString *promptString = [NSString stringWithFormat:@"The interpreter '%@' does not exist on this system.  Do you wish to proceed anyway?", [interpreterPathTextField stringValue]];
        if ([Alerts proceedAlert:@"Interpreter does not exist"
                         subText:promptString
                 withActionNamed:@"Proceed"] == NO) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Generate/read AppSpec

- (PlatypusAppSpec *)appSpecFromControls {
    PlatypusAppSpec *spec = [[PlatypusAppSpec alloc] initWithDefaults];
    
    spec[AppSpecKey_Name] = [appNameTextField stringValue];
    spec[AppSpecKey_ScriptPath] = [scriptPathTextField stringValue];
    spec[AppSpecKey_InterfaceType] = [interfaceTypePopupButton titleOfSelectedItem];
    spec[AppSpecKey_IconPath] = [iconController icnsFilePath];
    
    spec[AppSpecKey_InterpreterPath] = [interpreterPathTextField stringValue];
    spec[AppSpecKey_InterpreterArgs] = [argsController interpreterArgs];
    spec[AppSpecKey_ScriptArgs] = [argsController scriptArgs];
    spec[AppSpecKey_Version] = [versionTextField stringValue];
    spec[AppSpecKey_Identifier] = [bundleIdentifierTextField stringValue];
    spec[AppSpecKey_Author] = [authorTextField stringValue];
    
    spec[AppSpecKey_Droppable] = @((BOOL)[acceptsDroppedItemsCheckbox state]);
    spec[AppSpecKey_Authenticate] = @((BOOL)[rootPrivilegesCheckbox state]);
    spec[AppSpecKey_RemainRunning] = @((BOOL)[remainRunningCheckbox state]);
    spec[AppSpecKey_RunInBackground] = @((BOOL)[runInBackgroundCheckbox state]);
    
    spec[AppSpecKey_BundledFiles] = [bundledFilesController filePaths];
    
    spec[AppSpecKey_Suffixes] = [dropSettingsController suffixList];
    spec[AppSpecKey_Utis] = [dropSettingsController uniformTypesList];
    spec[AppSpecKey_URISchemes] = [dropSettingsController uriSchemesList];
    spec[AppSpecKey_DocIconPath] = [dropSettingsController docIconPath];
    spec[AppSpecKey_AcceptText] = @((BOOL)[dropSettingsController acceptsText]);
    spec[AppSpecKey_AcceptFiles] = @((BOOL)[dropSettingsController acceptsFiles]);
    spec[AppSpecKey_Service] = @((BOOL)[dropSettingsController declareService]);
    spec[AppSpecKey_PromptForFile] = @((BOOL)[dropSettingsController promptsForFileOnLaunch]);
    
    spec[AppSpecKey_TextFont] = [[textSettingsController textFont] fontName];
    spec[AppSpecKey_TextSize] = @((float)[[textSettingsController textFont] pointSize]);
    spec[AppSpecKey_TextColor] = [[textSettingsController textForegroundColor] hexString];
    spec[AppSpecKey_TextBackgroundColor] = [[textSettingsController textBackgroundColor] hexString];
    
    spec[AppSpecKey_StatusItemDisplayType] = [statusItemSettingsController displayType];
    spec[AppSpecKey_StatusItemTitle] = [statusItemSettingsController title];
    spec[AppSpecKey_StatusItemIcon] = [[statusItemSettingsController icon] TIFFRepresentation];
    spec[AppSpecKey_StatusItemUseSysfont] = @((BOOL)[statusItemSettingsController usesSystemFont]);
    spec[AppSpecKey_StatusItemIconIsTemplate] = @((BOOL)[statusItemSettingsController usesTemplateIcon]);
    
    return spec;
}

- (void)controlsFromAppSpec:(PlatypusAppSpec *)spec {
    [appNameTextField setStringValue:spec[AppSpecKey_Name]];
    [scriptPathTextField setStringValue:spec[AppSpecKey_ScriptPath]];
    
    [versionTextField setStringValue:spec[AppSpecKey_Version]];
    [authorTextField setStringValue:spec[AppSpecKey_Author]];
    [bundleIdentifierTextField setStringValue:spec[AppSpecKey_Identifier]];

    if (IsValidInterfaceTypeString(spec[AppSpecKey_InterfaceType])) {
        PlatypusInterfaceType index = InterfaceTypeForString(spec[AppSpecKey_InterfaceType]);
        [interfaceTypePopupButton selectItemAtIndex:index];
        [self interfaceTypeDidChange:nil];
    } else {
        [Alerts alert:@"Invalid interface type"
        subTextFormat:@"App spec contains invalid interface type '%@'. Falling back to default."];
        [interfaceTypePopupButton selectItemWithTitle:DEFAULT_INTERFACE_TYPE_STRING];
    }
        
    [interpreterPathTextField setStringValue:spec[AppSpecKey_InterpreterPath]];

    // Icon
    [iconController loadIcnsFile:spec[AppSpecKey_IconPath]];
    
    // Checkboxes
    [rootPrivilegesCheckbox setState:[spec[AppSpecKey_Authenticate] boolValue]];
    [acceptsDroppedItemsCheckbox setState:[spec[AppSpecKey_Droppable] boolValue]];
    [self acceptsDroppedItemsClicked:acceptsDroppedItemsCheckbox];
    [runInBackgroundCheckbox setState:[spec[AppSpecKey_RunInBackground] boolValue]];
    [remainRunningCheckbox setState:[spec[AppSpecKey_RemainRunning] boolValue]];
    
    // File list
    [bundledFilesController setToDefaults:self];
    [bundledFilesController addFiles:spec[AppSpecKey_BundledFiles]];
    
    // Drop settings
    [dropSettingsController setSuffixList:spec[AppSpecKey_Suffixes]];
    [dropSettingsController setUniformTypesList:spec[AppSpecKey_Utis]];
    [dropSettingsController setUriSchemesList:spec[AppSpecKey_URISchemes]];
    [dropSettingsController setDocIconPath:spec[AppSpecKey_DocIconPath]];
    [dropSettingsController setAcceptsText:[spec[AppSpecKey_AcceptText] boolValue]];
    [dropSettingsController setAcceptsFiles:[spec[AppSpecKey_AcceptFiles] boolValue]];
    [dropSettingsController setDeclareService:[spec[AppSpecKey_Service] boolValue]];
    [dropSettingsController setPromptsForFileOnLaunch:[spec[AppSpecKey_PromptForFile] boolValue]];
    
    // Args
    [argsController setInterpreterArgs:spec[AppSpecKey_InterpreterArgs]];
    [argsController setScriptArgs:spec[AppSpecKey_ScriptArgs]];
    
    // Text settings
    [textSettingsController setTextFont:[NSFont fontWithName:spec[AppSpecKey_TextFont] size:[spec[AppSpecKey_TextSize] intValue]]];
    [textSettingsController setTextForegroundColor:[NSColor colorFromHexString:spec[AppSpecKey_TextColor]]];
    [textSettingsController setTextBackgroundColor:[NSColor colorFromHexString:spec[AppSpecKey_TextBackgroundColor]]];
    
    // Status menu settings
    if (InterfaceTypeForString(spec[AppSpecKey_InterfaceType]) == PlatypusInterfaceType_StatusMenu) {
        if ([spec[AppSpecKey_StatusItemDisplayType] isEqualToString:PLATYPUS_STATUSITEM_DISPLAY_TYPE_ICON]) {
            NSImage *icon = [[NSImage alloc] initWithData:spec[AppSpecKey_StatusItemIcon]];
            if (icon != nil) {
                [statusItemSettingsController setIcon:icon];
            }
        } else {
            [statusItemSettingsController setTitle:spec[AppSpecKey_StatusItemTitle]];
        }
        [statusItemSettingsController setDisplayType:spec[AppSpecKey_StatusItemDisplayType]];
        [statusItemSettingsController setUsesSystemFont:[spec[AppSpecKey_StatusItemUseSysfont] boolValue]];
        [statusItemSettingsController setUsesTemplateIcon:[spec[AppSpecKey_StatusItemIconIsTemplate] boolValue]];
    }
    
    // Update buttons
    [self performSelector:@selector(controlTextDidChange:) withObject:nil];
    
    [self updateEstimatedAppSize];
}

#pragma mark - Load/Select script

- (IBAction)selectScript:(id)sender {
    [[self window] setTitle:[NSString stringWithFormat:@"%@ - Select Script", PROGRAM_NAME]];
    
    // Create open panel
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setPrompt:@"Select"];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setAllowedFileTypes:@[(NSString *)kUTTypeContent]];
    [oPanel setDelegate:self];
    
    // Run as sheet
    NSWindow *window = [self window];
    [oPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            NSString *filePath = [[oPanel URLs][0] path];
            [self loadScript:filePath];
        }
        [window setTitle:PROGRAM_NAME];
    }];
}

- (IBAction)scriptTypeSelected:(id)sender {
    [self setScriptType:[[sender selectedItem] title]];
}

- (void)selectScriptTypeBasedOnInterpreter {
    NSString *interpreterPath = [interpreterPathTextField stringValue];
    NSString *type = [PlatypusScriptUtils displayNameForInterpreterPath:interpreterPath];
    [scriptTypePopupButton selectItemWithTitle:type];
}

- (void)setScriptType:(NSString *)type {
    // Set the script type based on the number which identifies each type
    NSString *interpreterPath = [PlatypusScriptUtils interpreterPathForDisplayName:type];
    NSArray *interpreterArgs = [PlatypusScriptUtils interpreterArgsForInterpreterPath:interpreterPath];
    NSArray *scriptArgs = [PlatypusScriptUtils scriptArgsForInterpreterPath:interpreterPath];
    
    [interpreterPathTextField setStringValue:interpreterPath];
    [scriptTypePopupButton selectItemWithTitle:type];
    
    [argsController setToDefaults:self];
    if ([interpreterArgs count]) {
        [argsController setInterpreterArgs:interpreterArgs];
    }
    if ([scriptArgs count]) {
        [argsController setScriptArgs:scriptArgs];
    }
    
    [self performSelector:@selector(controlTextDidChange:) withObject:nil];
}

- (void)loadScript:(NSString *)scriptPath {
    // Make sure the file we're loading actually exists
    BOOL isDir;
    if ([FILEMGR fileExistsAtPath:scriptPath isDirectory:&isDir] == NO || isDir) {
        NSBeep();
        return;
    }
    
    // Create a default spec and set controls
    PlatypusAppSpec *spec = [[PlatypusAppSpec alloc] initWithDefaultsForScript:scriptPath];
    spec[AppSpecKey_BundledFiles] = [bundledFilesController filePaths];
    [self controlsFromAppSpec:spec];
    
    [iconController setToDefaults];
    
    // Add to recent documents
    NSURL *scriptURL = [NSURL fileURLWithPath:scriptPath];
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:scriptURL];
}

#pragma mark - Interface actions

- (void)controlTextDidChange:(NSNotification *)aNotification {
    
    // App name or script path was changed
    if (aNotification == nil || [aNotification object] == nil || [aNotification object] == appNameTextField || [aNotification object] == scriptPathTextField) {
        
        BOOL scriptExists = NO;
        BOOL validName = NO;
        
        if ([[appNameTextField stringValue] length] > 0) {
            validName = YES;
        }
        
        [fileWatcherQueue removeAllPaths];
        if ([scriptPathTextField hasValidPath]) {
            [fileWatcherQueue addPath:[scriptPathTextField stringValue]];
            scriptExists = YES;
        }
        
        [editScriptButton setEnabled:scriptExists];
        [revealScriptButton setEnabled:scriptExists];
        
        // Enable/disable create app button
        [createAppButton setEnabled:(validName && scriptExists)];
    }
    
    // Interpreter changed. We try to select script type based on the new value in the field.
    if (aNotification == nil || [aNotification object] == interpreterPathTextField) {
        [self selectScriptTypeBasedOnInterpreter];
    }
    
    if ([aNotification object] == appNameTextField) {
        // Update app bundle identifier
        NSString *idStr = [PlatypusAppSpec bundleIdentifierForAppName:[appNameTextField stringValue]
                                                           authorName:nil
                                                        usingDefaults:YES];
        [bundleIdentifierTextField setStringValue:idStr];
    }
}

- (IBAction)acceptsDroppedItemsClicked:(id)sender {
    [dropSettingsButton setHidden:![acceptsDroppedItemsCheckbox state]];
    [dropSettingsButton setEnabled:[acceptsDroppedItemsCheckbox state]];
}

- (IBAction)interfaceTypeDidChange:(id)sender {
    NSString *interfaceTypeString = [interfaceTypePopupButton titleOfSelectedItem];
    
    // Don't show text settings for interface types None and Web View
    BOOL hasTextSettings = IsTextStyledInterfaceTypeString(interfaceTypeString);
    [textSettingsButton setHidden:!hasTextSettings];
    [textSettingsButton setEnabled:hasTextSettings];
    
    // Disable options that don't make sense for status menu interface type
    if (InterfaceTypeForString(interfaceTypeString) == PlatypusInterfaceType_StatusMenu) {

        // Disable droppable & admin privileges
        [acceptsDroppedItemsCheckbox setIntValue:0];
        [acceptsDroppedItemsCheckbox setEnabled:NO];
        [self acceptsDroppedItemsClicked:self];
        [rootPrivilegesCheckbox setIntValue:0];
        [rootPrivilegesCheckbox setEnabled:NO];
        
        // Force-enable "Remain running"
        [remainRunningCheckbox setIntValue:1];
        [remainRunningCheckbox setEnabled:NO];
        
        // Status Menu apps run in background by default
        [runInBackgroundCheckbox setIntValue:1];
        
        // Show status item settings button
        [statusItemSettingsButton setEnabled:YES];
        [statusItemSettingsButton setHidden:NO];
        
    } else {
        
        if (InterfaceTypeForString(interfaceTypeString) == PlatypusInterfaceType_Droplet) {
            [acceptsDroppedItemsCheckbox setIntValue:1];
            [self acceptsDroppedItemsClicked:self];
        }
        
        // Re-enable droppable
        [acceptsDroppedItemsCheckbox setEnabled:YES];
        [rootPrivilegesCheckbox setEnabled:YES];
        
        // Re-enable remain running
        [remainRunningCheckbox setEnabled:YES];
        
        [runInBackgroundCheckbox setIntValue:0];
        
        // Hide special status item settings
        [statusItemSettingsButton setEnabled:NO];
        [statusItemSettingsButton setHidden:YES];
    }
}

// Clear all controls to their default value
- (IBAction)clearAllFields:(id)sender {
    PlatypusAppSpec *spec = [PlatypusAppSpec specWithDefaults];
    spec[AppSpecKey_Name] = @"";
    [self controlsFromAppSpec:spec];
    
    [iconController setToDefaults];
    [statusItemSettingsController setToDefaults:self];
    [self setScriptType:DEFAULT_SCRIPT_TYPE];
    [self interfaceTypeDidChange:interfaceTypePopupButton];
    [self performSelector:@selector(controlTextDidChange:) withObject:nil];
    [self updateEstimatedAppSize];
}

- (IBAction)showCommandLineString:(id)sender {
    if (![FILEMGR fileExistsAtPath:[scriptPathTextField stringValue]]) {
        [Alerts alert:@"Missing script" subTextFormat:@"No file exists at path '%@'", [scriptPathTextField stringValue]];
        return;
    }
    
    [[self window] setTitle:[NSString stringWithFormat:@"%@ - Shell Command String", PROGRAM_NAME]];
    ShellCommandController *shellCommandController = [[ShellCommandController alloc] init];
    [shellCommandController showModalShellCommandSheetForSpec:[self appSpecFromControls] window:[self window]];
    [[self window] setTitle:PROGRAM_NAME];
}

#pragma mark - App Size estimation

- (void)updateEstimatedAppSize {
    [appSizeTextField setStringValue:[NSString stringWithFormat:@"Estimated final app size: ~%@", [self estimatedAppSizeString]]];
}

- (NSString *)estimatedAppSizeString {
    
    // Estimate the combined size of all the
    // files that will go into application bundle
    UInt64 estimatedAppSize = 0;
    estimatedAppSize += 4096; // Info.plist
    estimatedAppSize += 4096; // AppSettings.plist
    estimatedAppSize += [WORKSPACE fileOrFolderSize:[iconController icnsFilePath]];
    estimatedAppSize += [WORKSPACE fileOrFolderSize:[dropSettingsController docIconPath]];
    estimatedAppSize += [WORKSPACE fileOrFolderSize:[scriptPathTextField stringValue]];
    estimatedAppSize += ([WORKSPACE fileOrFolderSize:[[NSBundle mainBundle] pathForResource:CMDLINE_SCRIPTEXEC_GZIP_NAME ofType:nil]] * 2.68);
    
    // Nib size is much smaller if compiled with ibtool
    UInt64 nibSize = [WORKSPACE fileOrFolderSize:[[NSBundle mainBundle] pathForResource:@"MainMenu.nib" ofType:nil]];
    if ([FILEMGR fileExistsAtPath:IBTOOL_PATH]) {
        nibSize = 0.60 * nibSize; // Compiled nib is approximtely 60% the size of original
    }
    estimatedAppSize += nibSize;
    
    // Bundled files altogether
    estimatedAppSize += [bundledFilesController totalSizeOfFiles];
    
    return [WORKSPACE fileSizeAsHumanReadableString:estimatedAppSize];
}

#pragma mark -

// Create an NSTask from settings
- (NSTask *)taskForCurrentScript {
    if (![FILEMGR fileExistsAtPath:[scriptPathTextField stringValue]]) {
        return nil;
    }
    
    // Create task
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:[interpreterPathTextField stringValue]];
    [task setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    
    // Add arguments
    NSMutableArray *args = [NSMutableArray array];
    [args addObjectsFromArray:[argsController interpreterArgs]];
    [args addObject:[scriptPathTextField stringValue]];
    [args addObjectsFromArray:[argsController scriptArgs]];
    [task setArguments:args];

    return task;
}

#pragma mark - Drag and drop

- (BOOL)performDragOperation:(id <NSDraggingInfo> )sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    // File
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        
        if ([files count] == 1) {
            NSString *filePath = files[0];
            NSString *fileType = [WORKSPACE typeOfFile:filePath error:nil];
            
            // App?
            if ([WORKSPACE type:fileType conformsToType:(NSString *)kUTTypeApplicationBundle]) {
                // Check if it's a Platypus-generated app. If it is, open app's script in editor.
                NSString *scriptPath = [NSString stringWithFormat:@"%@/Contents/Resources/script", filePath];
                BOOL isPlatypusApp = ([FILEMGR fileExistsAtPath:scriptPath]);
                if (isPlatypusApp) {
                    [self performSelector:@selector(openScriptInEditor:)
                               withObject:scriptPath
                               afterDelay:0.1];
                    return YES;
                }
            }
            
            // Icon?
            if ([WORKSPACE type:fileType conformsToType:(NSString *)kUTTypeAppleICNS]) {
                [iconController loadIcnsFile:filePath];
                return YES;
            }
            
            // Profile?
            if ([filePath hasSuffix:PROGRAM_PROFILE_SUFFIX] || [WORKSPACE type:fileType conformsToType:PROGRAM_PROFILE_UTI]) {
                return [profilesController loadProfileAtPath:filePath];
            }
            // Script?
            if ([PlatypusScriptUtils isPotentiallyScriptAtPath:filePath]) {
                [self loadScript:filePath];
                return YES;
            }
        }
        
        [bundledFilesController addFiles:files];
        return YES;
    }
    // String
    else if ([[pboard types] containsObject:NSStringPboardType]) {
        // Create a new script file with the dropped string, load it
        NSString *draggedString = [pboard stringForType:NSStringPboardType];
        NSString *newScriptPath = [self createNewScript:draggedString];
        if (newScriptPath) {
            [self loadScript:newScriptPath];
            return YES;
        }
    }
    
    return NO;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo> )sender {
    
    if ([[[sender draggingPasteboard] types] containsObject:NSFilenamesPboardType]) {
        return NSDragOperationLink;
    } else if ([[[sender draggingPasteboard] types] containsObject:NSStringPboardType]) {
        return NSDragOperationCopy;
    }
    
    return NSDragOperationNone;
}

// If we just created a file with a dragged string, we open it in default editor
- (void)concludeDragOperation:(id <NSDraggingInfo> )sender {
    if ([[[sender draggingPasteboard] types] containsObject:NSStringPboardType]) {
        [self editScript:self];
    }
}

#pragma mark - Menu delegate

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    // "Create app" menu item
    if ([anItem action] == @selector(createButtonPressed:) && [createAppButton isEnabled] == NO) {
        return NO;
    }
    
    // Actions on script file
    BOOL isDir;
    BOOL badScriptFile = (![FILEMGR fileExistsAtPath:[scriptPathTextField stringValue] isDirectory:&isDir] || isDir);
    if (([anItem action] == @selector(editScript:) ||
         [anItem action] == @selector(revealScript:) ||
         [anItem action] == @selector(checkSyntaxOfScript:))
        && badScriptFile) {
        return NO;
    }

    // Show shell command only works if we have a script
    if ([anItem action] == @selector(showCommandLineString:) && badScriptFile) {
        return NO;
    }
    
    return YES;
}

- (void)updateInterfaceTypeMenu:(NSSize)iconSize {
    NSArray *items = [interfaceTypePopupButton itemArray];
    
    for (NSMenuItem *menuItem in items) {
        NSImage *img = [menuItem image];
        if (img == nil) {
            if ([interfaceTypePopupButton itemAtIndex:0] == menuItem) {
                img = [[NSImage imageNamed:@"NSDefaultApplicationIcon"] copy];
            } else {
                NSString *imageName = [[menuItem title] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
                imageName = [NSString stringWithFormat:@"InterfaceType_%@", imageName];
                img = [NSImage imageNamed:imageName];
            }
        }
        [img setSize:iconSize];
        [menuItem setImage:nil];
        [menuItem setImage:img];
    }
}

- (void)menuWillOpen:(NSMenu *)menu {
    if (menu == [interfaceTypePopupButton menu]) {
        [self updateInterfaceTypeMenu:NSMakeSize(32, 32)];
    }
}

- (void)menuDidClose:(NSMenu *)menu {
    if (menu == [interfaceTypePopupButton menu]) {
        [self updateInterfaceTypeMenu:NSMakeSize(16, 16)];
    }
}

#pragma mark - Help/Documentation/Website

// Open Documentation.html file within app bundle
- (IBAction)showHelp:(id)sender {
    [WORKSPACE openPathInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_DOCUMENTATION ofType:nil]];
}

// Open HTML version of platypus command line tool's man page
- (IBAction)showManPage:(id)sender {
    [WORKSPACE openPathInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_MANPAGE ofType:nil]];
}

// Open program website
- (IBAction)openWebsite:(id)sender {
    [WORKSPACE openURL:[NSURL URLWithString:PROGRAM_WEBSITE]];
}

// Open program GitHub website
- (IBAction)openGitHubWebsite:(id)sender {
    [WORKSPACE openURL:[NSURL URLWithString:PROGRAM_GITHUB_WEBSITE]];
}

// Open License HTML file
- (IBAction)openLicense:(id)sender {
    [WORKSPACE openPathInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_LICENSE_FILE ofType:nil]];
}

// Open donations website
- (IBAction)openDonations:(id)sender {
    [WORKSPACE openURL:[NSURL URLWithString:PROGRAM_DONATIONS]];
}

@end
