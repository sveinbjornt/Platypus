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

#import "PlatypusController.h"
#import "Common.h"
#import "PlatypusAppSpec.h"
#import "ScriptAnalyser.h"
#import "IconController.h"
#import "ArgsController.h"
#import "ProfilesController.h"
#import "TextSettingsController.h"
#import "StatusItemSettingsController.h"
#import "EditorController.h"
#import "ShellCommandController.h"
#import "STPathTextField.h"
#import "DropSettingsController.h"
#import "SuffixTypeListController.h"
#import "SyntaxCheckerController.h"
#import "BundledFilesController.h"
#import "PrefsController.h"
#import "NSWorkspace+Additions.h"
#import "Alerts.h"
#import "NSColor+HexTools.h"
#import "VDKQueue.h"

@interface PlatypusController()
{
    //basic controls
    IBOutlet NSTextField *appNameTextField;
    IBOutlet NSPopUpButton *scriptTypePopupButton;
    IBOutlet STPathTextField *scriptPathTextField;
    IBOutlet NSButton *editScriptButton;
    IBOutlet NSButton *revealScriptButton;
    IBOutlet NSPopUpButton *outputTypePopupMenu;
    IBOutlet NSButton *createAppButton;
    IBOutlet NSButton *textOutputSettingsButton;
    IBOutlet NSButton *statusItemSettingsButton;
    
    //advanced options controls
    IBOutlet NSTextField *interpreterTextField;
    IBOutlet NSTextField *versionTextField;
    IBOutlet NSTextField *bundleIdentifierTextField;
    IBOutlet NSTextField *authorTextField;
    
    IBOutlet NSButton *rootPrivilegesCheckbox;
    IBOutlet NSButton *encryptCheckbox;
    IBOutlet NSButton *isDroppableCheckbox;
    IBOutlet NSButton *showInDockCheckbox;
    IBOutlet NSButton *remainRunningCheckbox;
    
    IBOutlet NSButton *dropSettingsButton;
    
    IBOutlet NSTextField *appSizeTextField;
    
    // create app dialog view extension
    IBOutlet NSView *debugSaveOptionView;
    IBOutlet NSButton *developmentVersionCheckbox;
    IBOutlet NSButton *optimizeApplicationCheckbox;
    IBOutlet NSButton *xmlPlistFormatCheckbox;
    
    //windows
    IBOutlet NSWindow *window;
    
    //progress sheet when creating
    IBOutlet NSWindow *progressDialogWindow;
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSTextField *progressDialogMessageLabel;
    IBOutlet NSTextField *progressDialogStatusLabel;
    
    // interface controllers
    IBOutlet IconController *iconController;
    IBOutlet DropSettingsController *dropSettingsController;
    IBOutlet ArgsController *argsController;
    IBOutlet ProfilesController *profilesController;
    IBOutlet TextSettingsController *textSettingsController;
    IBOutlet StatusItemSettingsController *statusItemSettingsController;
    IBOutlet PrefsController *prefsController;
    IBOutlet BundledFilesController *bundledFilesController;
    
    VDKQueue *fileWatcherQueue;
}

- (IBAction)newScript:(id)sender;
- (IBAction)revealScript:(id)sender;
- (IBAction)editScript:(id)sender;
- (IBAction)runScriptInTerminal:(id)sender;
- (IBAction)checkSyntaxOfScript:(id)sender;
- (IBAction)createButtonPressed:(id)sender;
- (IBAction)scriptTypeSelected:(id)sender;
- (IBAction)selectScript:(id)sender;
- (IBAction)isDroppableWasClicked:(id)sender;
- (IBAction)outputTypeWasChanged:(id)sender;
- (IBAction)clearAllFields:(id)sender;
- (IBAction)showCommandLineString:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)showReadme:(id)sender;
- (IBAction)showManPage:(id)sender;
- (IBAction)openWebsite:(id)sender;
- (IBAction)openGitHubWebsite:(id)sender;
- (IBAction)openLicense:(id)sender;
- (IBAction)openDonations:(id)sender;

@end

@implementation PlatypusController

#pragma mark - Application

- (instancetype)init {
    if ((self = [super init])) {
        fileWatcherQueue = [[VDKQueue alloc] init];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [fileWatcherQueue release];
    [super dealloc];
}

+ (void)initialize {
    // register the dictionary of defaults
    [DEFAULTS registerDefaults:[PrefsController defaultsDictionary]];
}

- (void)awakeFromNib {
    // put application icon in window title bar
    [window setRepresentedURL:[NSURL URLWithString:PROGRAM_WEBSITE]];
    NSButton *button = [window standardWindowButton:NSWindowDocumentIconButton];
    [button setImage:[NSApp applicationIconImage]];
    
    // make sure application support folder and subfolders exist
    BOOL isDir;
    
    // app support folder
    if (![FILEMGR fileExistsAtPath:APP_SUPPORT_FOLDER isDirectory:&isDir] && ![FILEMGR createDirectoryAtPath:APP_SUPPORT_FOLDER withIntermediateDirectories:NO attributes:nil error:nil]) {
            [Alerts alert:@"Error"
            subTextFormat:@"Could not create directory '%@'", [APP_SUPPORT_FOLDER stringByExpandingTildeInPath], nil];
    }
    
    // profiles folder
    if (![FILEMGR fileExistsAtPath:PROFILES_FOLDER isDirectory:&isDir]) {
        if (![FILEMGR createDirectoryAtPath:PROFILES_FOLDER withIntermediateDirectories:NO attributes:nil error:nil]) {
            [Alerts alert:@"Error"
            subTextFormat:@"Could not create directory '%@'", PROFILES_FOLDER, nil];
        }
    }
    
    if ([DEFAULTS objectForKey:@"FirstLaunch"] == nil) {
        // TODO: Create sample profile in Profiles folder
    }
    
    // we list ourself as an observer of changes to file system, for script
    [[WORKSPACE notificationCenter] addObserver:self selector:@selector(scriptFileSystemChange) name:VDKQueueRenameNotification object:nil];
    [[WORKSPACE notificationCenter] addObserver:self selector:@selector(scriptFileSystemChange) name:VDKQueueDeleteNotification object:nil];
    [[WORKSPACE notificationCenter] addObserver:self selector:@selector(scriptFileChanged:) name:VDKQueueWriteNotification object:nil];
    
    // listen for app size change notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateEstimatedAppSize)
                                                 name:PLATYPUS_APP_SIZE_CHANGED_NOTIFICATION
                                               object:nil];

    
    //populate script type menu
    [scriptTypePopupButton addItemsWithTitles:[ScriptAnalyser interpreterDisplayNames]];
    for (int i = 0; i < [[scriptTypePopupButton itemArray] count]; i++) {
        NSImage *icon = [NSImage imageNamed:[[scriptTypePopupButton itemAtIndex:i] title]];
        [icon setSize:NSMakeSize(16, 16)];
        [[scriptTypePopupButton itemAtIndex:i] setImage:icon];
    }
    
    //populate output type menu
    [self updateOutputTypeMenu:NSMakeSize(16, 16)];
    
    [window registerForDraggedTypes:@[NSFilenamesPboardType, NSStringPboardType]];
    [window makeFirstResponder:appNameTextField];
    
    // if we haven't already loaded a profile via openfile delegate method
    // we set all fields to their defaults.  Any profile must contain a name
    // so we can be sure that one hasn't been loaded if the app name field is empty
    if ([[appNameTextField stringValue] isEqualToString:@""]) {
        [self clearAllFields:self];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [DEFAULTS setObject:@NO forKey:@"FirstLaunch"];
    [window center];
    [window makeKeyAndOrderFront:self];
    [appNameTextField becomeFirstResponder];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    NSString *fileType = [WORKSPACE typeOfFile:filename error:nil];
    if ([filename hasSuffix:PROFILES_SUFFIX] || [WORKSPACE type:fileType conformsToType:PROGRAM_PROFILE_UTI]) {
        [profilesController loadProfileAtPath:filename];
    } else {
        [self loadScript:filename];
    }
    return YES;
}

- (NSWindow *)window {
    return window;
}

- (BOOL)window:(NSWindow *)window shouldPopUpDocumentPathMenu:(NSMenu *)menu {
    // prevent popup menu when window icon/title is cmd-clicked
    return NO;
}

- (BOOL)window:(NSWindow *)window shouldDragDocumentWithEvent:(NSEvent *)event from:(NSPoint)dragImageLocation withPasteboard:(NSPasteboard *)pasteboard {
    // prevent dragging of title bar icon
    return NO;
}

#pragma mark - Script functions

- (IBAction)newScript:(id)sender {
    NSString *newScriptPath = [self createNewScript:nil];
    [self loadScript:newScriptPath];
    [self editScript:self];
}

- (NSString *)createNewScript:(NSString *)scriptText {
    NSString *interpreter = [interpreterTextField stringValue];
    NSString *suffix = [ScriptAnalyser filenameSuffixForInterpreter:interpreter];
    
    NSString *appName = [appNameTextField stringValue];
    if ([appName isEqualToString:@""]) {
        appName = NEW_SCRIPT_FILENAME;
    }

    NSString *tmpScriptPath = [NSString stringWithFormat:@"%@/%@%@", [TEMP_FOLDER stringByExpandingTildeInPath], appName, suffix];
    
    // increment digit appended to script name until no script exists
    int incr = 1;
    while ([FILEMGR fileExistsAtPath:tmpScriptPath]) {
        tmpScriptPath = [NSString stringWithFormat:@"%@/%@-%d%@", [TEMP_FOLDER stringByExpandingTildeInPath], appName, incr, suffix];
        incr++;
    }
    
    //put shebang line in the new script text file
    NSString *contentString = [NSString stringWithFormat:@"#!%@\n\n", interpreter];
    
    if (scriptText != nil) {
        contentString = [contentString stringByAppendingString:scriptText];
    } else {
        NSString *defaultScriptText = [ScriptAnalyser helloWorldProgramForDisplayName:[scriptTypePopupButton titleOfSelectedItem]];
        if (defaultScriptText != nil) {
            contentString = [contentString stringByAppendingString:defaultScriptText];
        }
    }
    
    //write the default content to the new script
    NSError *err;
    BOOL success = [contentString writeToFile:tmpScriptPath
                                   atomically:YES
                                     encoding:[[DEFAULTS objectForKey:@"DefaultTextEncoding"] intValue]
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
    //see if file exists
    if (![FILEMGR fileExistsAtPath:[scriptPathTextField stringValue]]) {
        [Alerts alert:@"File does not exist" subText:@"No file exists at the specified path"];
        return;
    }
    
    // if the default editor is the built-in editor, we pop down the editor sheet
    if ([[DEFAULTS stringForKey:@"DefaultEditor"] isEqualToString:DEFAULT_EDITOR]) {
        [self openScriptInBuiltInEditor:[scriptPathTextField stringValue]];
    } else { // open it in the external application
        NSString *defaultEditor = [DEFAULTS stringForKey:@"DefaultEditor"];
        if ([WORKSPACE fullPathForApplication:defaultEditor] != nil) {
            [WORKSPACE openFile:[scriptPathTextField stringValue] withApplication:defaultEditor];
        } else {
            // Complain if editor is not found, set it to the built-in editor
            [Alerts alert:@"Application not found"
            subTextFormat:@"The application '%@' could not be found on your system.  Reverting to the built-in editor.", defaultEditor, nil];
            [DEFAULTS setObject:DEFAULT_EDITOR forKey:@"DefaultEditor"];
            [self openScriptInBuiltInEditor:[scriptPathTextField stringValue]];
        }
    }
}

- (IBAction)runScriptInTerminal:(id)sender {
    NSString *cmd = [NSString stringWithFormat:@"%@ '%@'", [interpreterTextField stringValue], [scriptPathTextField stringValue]];
    [WORKSPACE runCommandInTerminal:cmd];
}

- (IBAction)checkSyntaxOfScript:(id)sender {
    [window setTitle:[NSString stringWithFormat:@"%@ - Syntax Checker", PROGRAM_NAME]];
    SyntaxCheckerController *controller = [[SyntaxCheckerController alloc] init];
    [controller showSyntaxCheckerForFile:[scriptPathTextField stringValue]
                         withInterpreter:[interpreterTextField stringValue]
                                  window:window];
    [controller release];
    [window setTitle:PROGRAM_NAME];
}

- (void)openScriptInBuiltInEditor:(NSString *)path {
    [window setTitle:[NSString stringWithFormat:@"%@ - Script Editor", PROGRAM_NAME]];
    EditorController *controller = [[EditorController alloc] init];
    [controller showEditorForFile:[scriptPathTextField stringValue] window:window];
    [controller release];
    [window setTitle:PROGRAM_NAME];
}

- (void)scriptFileSystemChange {
    [scriptPathTextField updateTextColoring];
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

- (IBAction)createButtonPressed:(id)sender {
    
    //are there invalid values in the fields?
    if (![self verifyFieldContents]) {
        return;
    }
    
    [window setTitle:[NSString stringWithFormat:@"%@ - Select destination", PROGRAM_NAME]];
    
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
    
    // development version checkbox: always disable this option if secure script is checked
    [developmentVersionCheckbox setEnabled:![encryptCheckbox intValue]];
    if ([encryptCheckbox intValue]) {
        [DEFAULTS setObject:@NO forKey:@"OnCreateDevVersion"];
    }
    
    // optimize nib is enabled and on by default if ibtool is present
    BOOL ibtoolInstalled = [FILEMGR fileExistsAtPath:IBTOOL_PATH];
    if ([[DEFAULTS objectForKey:@"OnCreateOptimizeNib"] boolValue] == YES && ibtoolInstalled == NO) {
        [DEFAULTS setObject:@NO forKey:@"OnCreateOptimizeNib"];
    }
    [optimizeApplicationCheckbox setEnabled:ibtoolInstalled];
    
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
    // observe create and size changed notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(creationStatusUpdated:)
                                                 name:PLATYPUS_APP_SPEC_CREATION_NOTIFICATION
                                               object:nil];
    
    // we begin by making sure destination path ends in .app
    NSString *appPath = destination;
    if (![appPath hasSuffix:@".app"]) {
        appPath = [appPath stringByAppendingString:@".app"];
    }
    
    // create spec from controls and verify
    PlatypusAppSpec *spec = [self appSpecFromControls];
    
    // we set this specifically
    spec[@"Destination"] = appPath;
    spec[@"ExecutablePath"] = [[NSBundle mainBundle] pathForResource:@"ScriptExec" ofType:nil];
    spec[@"NibPath"] = [[NSBundle mainBundle] pathForResource:@"MainMenu.nib" ofType:nil];
    spec[@"DevelopmentVersion"] = @((BOOL)[developmentVersionCheckbox intValue]);
    spec[@"OptimizeApplication"] = @((BOOL)[optimizeApplicationCheckbox intValue]);
    spec[@"UseXMLPlistFormat"] = @((BOOL)[xmlPlistFormatCheckbox intValue]);
    spec[@"DestinationOverride"] = @YES;
    
    // verify that the values in the spec are OK
    if (![spec verify]) {
        [Alerts alert:@"Spec verification failed" subText:[spec error]];
        return NO;
    }
    
    // ok, now we try to create the app
    
    // first, show progress dialog
    [progressDialogMessageLabel setStringValue:[NSString stringWithFormat:@"Creating application %@", spec[@"Name"]]];
    [progressBar setUsesThreadedAnimation:YES];
    [progressBar startAnimation:self];

    [NSApp beginSheet:progressDialogWindow
       modalForWindow:window
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
    
    // create the app from spec
    if (![spec create]) {
        // Dialog ends here.
        [NSApp endSheet:progressDialogWindow];
        [progressDialogWindow orderOut:self];
        
        [Alerts alert:@"Creating from spec failed" subText:[spec error]];
        return NO;
    }

    // reveal newly created app in Finder
    if ([DEFAULTS boolForKey:@"RevealApplicationWhenCreated"]) {
        [WORKSPACE selectFile:appPath inFileViewerRootedAtPath:appPath];
    }
    
    // open newly created app
    if ([DEFAULTS boolForKey:@"OpenApplicationWhenCreated"]) {
        [WORKSPACE launchApplication:appPath];
    }
    
    // Dialog ends here
    [NSApp endSheet:progressDialogWindow];
    [progressDialogWindow orderOut:self];
    
    return YES;
}

- (BOOL)verifyFieldContents {
    
    //make sure a name has been assigned
    if ([[appNameTextField stringValue] length] == 0) {
        [Alerts sheetAlert:@"Invalid Application Name" subText:@"You must specify a name for your application" forWindow:window];
        return NO;
    }
    
    //verify that script exists at path and isn't a directory
    BOOL isDir;
    if ([FILEMGR fileExistsAtPath:[scriptPathTextField stringValue] isDirectory:&isDir] == NO || isDir) {
        [Alerts sheetAlert:@"Invalid Script Path" subText:@"No file exists at the script path you have specified" forWindow:window];
        return NO;
    }
    
    //make sure we have an icon
    if (([iconController hasIconFile] && ![[iconController icnsFilePath] isEqualToString:@""] && ![FILEMGR fileExistsAtPath:[iconController icnsFilePath]])) {
        [Alerts sheetAlert:@"Missing Icon" subText:@"You must set an icon for your application." forWindow:window];
        return NO;
    }
    
    //let's be certain that the bundled files list doesn't contain entries that have been moved
    if ([bundledFilesController allPathsAreValid] == NO) {
        [Alerts sheetAlert:@"Bundled files missing" subText:@"One or more of the files that are to be bundled with the application could not be found. Please rectify this and try again." forWindow:window];
        return NO;
    }
    
    //interpreter
    if ([FILEMGR fileExistsAtPath:[interpreterTextField stringValue]] == NO) {
        if ([Alerts proceedAlert:@"Invalid Interpreter" subText:[NSString stringWithFormat:@"The interpreter '%@' does not exist on this system.  Do you wish to proceed anyway?", [interpreterTextField stringValue]] withAction:@"Proceed"] == NO) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Generate/read AppSpec

- (id)appSpecFromControls {
    PlatypusAppSpec *spec = [[[PlatypusAppSpec alloc] initWithDefaults] autorelease];
    
    spec[@"Name"] = [appNameTextField stringValue];
    spec[@"ScriptPath"] = [scriptPathTextField stringValue];
    spec[@"Output"] = [outputTypePopupMenu titleOfSelectedItem];
    spec[@"IconPath"] = [iconController hasIconFile] ? [iconController icnsFilePath] : @"";
    
    spec[@"Interpreter"] = [interpreterTextField stringValue];
    spec[@"InterpreterArgs"] = [argsController interpreterArgs];
    spec[@"ScriptArgs"] = [argsController scriptArgs];
    spec[@"Version"] = [versionTextField stringValue];
    spec[@"Identifier"] = [bundleIdentifierTextField stringValue];
    spec[@"Author"] = [authorTextField stringValue];
    
    spec[@"Droppable"] = @((BOOL)[isDroppableCheckbox state]);
    spec[@"Secure"] = @((BOOL)[encryptCheckbox state]);
    spec[@"Authentication"] = @((BOOL)[rootPrivilegesCheckbox state]);
    spec[@"RemainRunning"] = @((BOOL)[remainRunningCheckbox state]);
    spec[@"ShowInDock"] = @((BOOL)[showInDockCheckbox state]);
    
    spec[@"BundledFiles"] = [bundledFilesController filePaths];
    
    spec[@"Suffixes"] = [dropSettingsController suffixList];
    spec[@"UniformTypes"] = [dropSettingsController uniformTypesList];
    spec[@"DocIcon"] = [dropSettingsController docIconPath];
    spec[@"AcceptsText"] = @((BOOL)[dropSettingsController acceptsText]);
    spec[@"AcceptsFiles"] = @((BOOL)[dropSettingsController acceptsFiles]);
    spec[@"DeclareService"] = @((BOOL)[dropSettingsController declareService]);
    spec[@"PromptForFileOnLaunch"] = @((BOOL)[dropSettingsController promptsForFileOnLaunch]);
    
    spec[@"TextEncoding"] = @((int)[textSettingsController textEncoding]);
    spec[@"TextFont"] = [[textSettingsController textFont] fontName];
    spec[@"TextSize"] = @((float)[[textSettingsController textFont] pointSize]);
    spec[@"TextForeground"] = [[textSettingsController textForegroundColor] hexString];
    spec[@"TextBackground"] = [[textSettingsController textBackgroundColor] hexString];
    
    // status menu settings
    if ([[outputTypePopupMenu titleOfSelectedItem] isEqualToString:@"Status Menu"]) {
        spec[@"StatusItemDisplayType"] = [statusItemSettingsController displayType];
        spec[@"StatusItemTitle"] = [statusItemSettingsController title];
        spec[@"StatusItemIcon"] = [[statusItemSettingsController icon] TIFFRepresentation];
        spec[@"StatusItemUseSystemFont"] = @((BOOL)[statusItemSettingsController usesSystemFont]);
    }
    
    return spec;
}

- (void)controlsFromAppSpec:(id)spec {
    [appNameTextField setStringValue:spec[@"Name"]];
    [scriptPathTextField setStringValue:spec[@"ScriptPath"]];
    
    [versionTextField setStringValue:spec[@"Version"]];
    [authorTextField setStringValue:spec[@"Author"]];
    
    [outputTypePopupMenu selectItemWithTitle:spec[@"Output"]];
    [self outputTypeWasChanged:nil];
    [interpreterTextField setStringValue:spec[@"Interpreter"]];
    
    //icon
    [iconController loadIcnsFile:spec[@"IconPath"]];
    
    //checkboxes
    [rootPrivilegesCheckbox setState:[spec[@"Authentication"] boolValue]];
    [isDroppableCheckbox setState:[spec[@"Droppable"] boolValue]];
    [self isDroppableWasClicked:isDroppableCheckbox];
    [encryptCheckbox setState:[spec[@"Secure"] boolValue]];
    [showInDockCheckbox setState:[spec[@"ShowInDock"] boolValue]];
    [remainRunningCheckbox setState:[spec[@"RemainRunning"] boolValue]];
    
    //file list
    [bundledFilesController setFilePaths:spec[@"BundledFiles"]];
    
    //drop settings
    [dropSettingsController setSuffixList:spec[@"Suffixes"]];
    [dropSettingsController setUniformTypesList:spec[@"UniformTypes"]];
    [dropSettingsController setDocIconPath:spec[@"DocIcon"]];
    [dropSettingsController setAcceptsText:[spec[@"AcceptsText"] boolValue]];
    [dropSettingsController setAcceptsFiles:[spec[@"AcceptsFiles"] boolValue]];
    [dropSettingsController setDeclareService:[spec[@"DeclareService"] boolValue]];
    [dropSettingsController setPromptsForFileOnLaunch:[spec[@"PromptForFileOnLaunch"] boolValue]];
    
    // args
    [argsController setInterpreterArgs:spec[@"InterpreterArgs"]];
    [argsController setScriptArgs:spec[@"ScriptArgs"]];
    
    // text output settings
    [textSettingsController setTextEncoding:[spec[@"TextEncoding"] intValue]];
    [textSettingsController setTextFont:[NSFont fontWithName:spec[@"TextFont"] size:[spec[@"TextSize"] intValue]]];
    [textSettingsController setTextForegroundColor:[NSColor colorFromHex:spec[@"TextForeground"]]];
    [textSettingsController setTextBackgroundColor:[NSColor colorFromHex:spec[@"TextBackground"]]];
    
    // status menu settings
    if ([spec[@"Output"] isEqualToString:@"Status Menu"]) {
        if (![spec[@"StatusItemDisplayType"] isEqualToString:@"Text"]) {
            NSImage *icon = [[[NSImage alloc] initWithData:spec[@"StatusItemIcon"]] autorelease];
            if (icon != nil) {
                [statusItemSettingsController setIcon:icon];
            }
        }
        [statusItemSettingsController setTitle:spec[@"StatusItemTitle"]];
        [statusItemSettingsController setDisplayType:spec[@"StatusItemDisplayType"]];
        [statusItemSettingsController setUsesSystemFont:spec[@"StatusItemUseSystemFont"]];
    }
    
    //update buttons
    [self performSelector:@selector(controlTextDidChange:) withObject:nil];
    
    [self updateEstimatedAppSize];
    
    [bundleIdentifierTextField setStringValue:spec[@"Identifier"]];
}

#pragma mark - Load/Select script

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
    NSString *type = [ScriptAnalyser displayNameForInterpreter:[interpreterTextField stringValue]];
    [scriptTypePopupButton selectItemWithTitle:type];
}

- (void)setScriptType:(NSString *)type {
    // set the script type based on the number which identifies each type
    NSString *interpreter = [ScriptAnalyser interpreterForDisplayName:type];
    [interpreterTextField setStringValue:interpreter];
    [scriptTypePopupButton selectItemWithTitle:type];
    [self performSelector:@selector(controlTextDidChange:) withObject:nil];
}

- (void)loadScript:(NSString *)filename {
    //make sure file we're loading actually exists
    BOOL isDir;
    if (![FILEMGR fileExistsAtPath:filename isDirectory:&isDir] || isDir) {
        return;
    }
    
    PlatypusAppSpec *spec = [[PlatypusAppSpec alloc] initWithDefaultsForScript:filename];
    [self controlsFromAppSpec:spec];
    [spec release];
    
    [iconController setToDefaults:self];
    
    // add to recent items menu
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:filename]];
    
    [self updateEstimatedAppSize];
}

#pragma mark - Interface actions

- (void)controlTextDidChange:(NSNotification *)aNotification {
    BOOL isDir, exists = NO, validName = NO;
    
    //app name or script path was changed
    if (aNotification == nil || [aNotification object] == nil || [aNotification object] == appNameTextField || [aNotification object] == scriptPathTextField) {
        if ([[appNameTextField stringValue] length] > 0) {
            validName = YES;
        }
        
        [fileWatcherQueue removeAllPaths];
        if ([scriptPathTextField hasValidPath]) {
            [fileWatcherQueue addPath:[scriptPathTextField stringValue]];
            exists = YES;
        }
        
        [editScriptButton setEnabled:exists];
        [revealScriptButton setEnabled:exists];
        
        //enable/disable create app button
        [createAppButton setEnabled:validName && exists];
    }
    if (aNotification != nil && [aNotification object] == appNameTextField) {
        //update identifier
        [bundleIdentifierTextField setStringValue:[PlatypusAppSpec bundleIdentifierForAppName:[appNameTextField stringValue] authorName:nil usingDefaults:YES]];
    }
    
    //interpreter changed -- we try to select type based on the value in the field, also color red if path doesn't exist
    if (aNotification == nil || [aNotification object] == interpreterTextField || [aNotification object] == nil) {
        [self selectScriptTypeBasedOnInterpreter];
        NSColor *textColor = ([FILEMGR fileExistsAtPath:[interpreterTextField stringValue] isDirectory:&isDir] && !isDir) ? [NSColor blackColor] : [NSColor redColor];
        [interpreterTextField setTextColor:textColor];
    }
}

- (IBAction)isDroppableWasClicked:(id)sender {
    [dropSettingsButton setHidden:![isDroppableCheckbox state]];
    [dropSettingsButton setEnabled:[isDroppableCheckbox state]];
}

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

- (IBAction)clearAllFields:(id)sender {
    //clear all text field to start value
    [appNameTextField setStringValue:@""];
    [scriptPathTextField setStringValue:@""];
    [versionTextField setStringValue:DEFAULT_VERSION];
    
    NSString *bundleId = [PlatypusAppSpec bundleIdentifierForAppName:[appNameTextField stringValue] authorName:nil usingDefaults:YES];
    [bundleIdentifierTextField setStringValue:bundleId];
    [authorTextField setStringValue:[DEFAULTS objectForKey:@"DefaultAuthor"]];
    
    //uncheck all options
    [isDroppableCheckbox setIntValue:0];
    [self isDroppableWasClicked:isDroppableCheckbox];
    [encryptCheckbox setIntValue:0];
    [rootPrivilegesCheckbox setIntValue:0];
    [remainRunningCheckbox setIntValue:1];
    [showInDockCheckbox setIntValue:0];
    
    [bundledFilesController setToDefaults:self];
    [dropSettingsController setToDefaults:self];
    [argsController setToDefaults:self];
    [textSettingsController setToDefaults:self];
    [statusItemSettingsController setToDefaults:self];
    [iconController setToDefaults:self];

    //set script type
    [self setScriptType:DEFAULT_SCRIPT_TYPE];
    
    //set output type
    [outputTypePopupMenu selectItemWithTitle:DEFAULT_OUTPUT_TYPE];
    [self outputTypeWasChanged:outputTypePopupMenu];
    
    //update button status
    [self performSelector:@selector(controlTextDidChange:) withObject:nil];
    
    [self updateEstimatedAppSize];
}

- (IBAction)showCommandLineString:(id)sender {
    if (![FILEMGR fileExistsAtPath:[scriptPathTextField stringValue]]) {
        [Alerts alert:@"Missing script"
        subTextFormat:@"No file exists at path '%@'", [scriptPathTextField stringValue], nil];
        return;
    }
    
    [window setTitle:[NSString stringWithFormat:@"%@ - Shell Command String", PROGRAM_NAME]];
    ShellCommandController *shellCommandController = [[ShellCommandController alloc] init];
    [shellCommandController showShellCommandForSpec:[self appSpecFromControls] window:window];
    [shellCommandController release];
    [window setTitle:PROGRAM_NAME];
}

#pragma mark - App Size estimation

- (void)updateEstimatedAppSize {
    [appSizeTextField setStringValue:[NSString stringWithFormat:@"Estimated final app size: ~%@", [self estimatedAppSizeString]]];
}

- (NSString *)estimatedAppSizeString {
    
    // estimate the combined size of all the
    // files that will go into application bundle
    UInt64 estimatedAppSize = 0;
    estimatedAppSize += 4096; // Info.plist
    estimatedAppSize += 4096; // AppSettings.plist
    estimatedAppSize += [iconController iconFileSize];
    estimatedAppSize += [dropSettingsController docIconSize];
    estimatedAppSize += [WORKSPACE fileOrFolderSize:[scriptPathTextField stringValue]];
    estimatedAppSize += [WORKSPACE fileOrFolderSize:[[NSBundle mainBundle] pathForResource:@"ScriptExec" ofType:nil]];
    
    // nib size is much smaller if compiled with ibtool
    UInt64 nibSize = [WORKSPACE fileOrFolderSize:[[NSBundle mainBundle] pathForResource:@"MainMenu.nib" ofType:nil]];
    if ([FILEMGR fileExistsAtPath:IBTOOL_PATH]) {
        nibSize = 0.60 * nibSize; // compiled nib is approximtely 60% the size of original
    }
    estimatedAppSize += nibSize;
    
    // bundled files altogether
    estimatedAppSize += [bundledFilesController totalFileSize];
    
    return [WORKSPACE fileSizeAsHumanReadableString:estimatedAppSize];
}

#pragma mark -

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

- (BOOL)performDragOperation:(id <NSDraggingInfo> )sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    // File
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSString *filename = files[0]; // only load the first dragged item
        NSString *fileType = [WORKSPACE typeOfFile:filename error:nil];

        // We don't accept folders
        BOOL isDir;
        if ([FILEMGR fileExistsAtPath:filename isDirectory:&isDir] == NO || isDir) {
            return NO;
        }

        // profile
        if ([filename hasSuffix:PROFILES_SUFFIX] || [WORKSPACE type:fileType conformsToType:PROGRAM_PROFILE_UTI]) {
            [profilesController loadProfileAtPath:filename];
        }
        // image
        else if ([WORKSPACE type:fileType conformsToType:(NSString *)kUTTypeImage]) {
            [iconController performDragOperation:sender];
        }
        // something else
        else {
            [self loadScript:filename];
        }
        
        return YES;
    }
    // String
    else if ([[pboard types] containsObject:NSStringPboardType]) {
        // create a new script file with the dropped string, load it
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

// if we just created a file with a dragged string, we open it in default editor
- (void)concludeDragOperation:(id <NSDraggingInfo> )sender {
    if ([[[sender draggingPasteboard] types] containsObject:NSStringPboardType]) {
        [self editScript:self];
    }
}

#pragma mark - Menu delegate

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    
    //create app menu item
    if ([anItem action]  == @selector(createButtonPressed:) && [createAppButton isEnabled] == NO) {
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
    NSImage *img = [NSImage imageNamed:@"NSDefaultApplicationIcon"];
    for (NSMenuItem *menuItem in items) {
        if ([outputTypePopupMenu itemAtIndex:0] != menuItem) {
            NSString *imageName = [[menuItem title] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
            img = [NSImage imageNamed:imageName];
        }
        img.size = iconSize;
        [menuItem setImage:nil];
        [menuItem setImage:img];
    }
}

- (void)menuWillOpen:(NSMenu *)menu {
    if (menu == [outputTypePopupMenu menu]) {
        [self updateOutputTypeMenu:NSMakeSize(32, 32)];
    }
}

- (void)menuDidClose:(NSMenu *)menu {
    if (menu == [outputTypePopupMenu menu]) {
        [self updateOutputTypeMenu:NSMakeSize(16, 16)];
    }
}

#pragma mark - Help/Documentation

// Open Documentation.html file within app bundle
- (IBAction)showHelp:(id)sender {
    [WORKSPACE openPathInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_DOCUMENTATION ofType:nil]];
}

// Open html version of 'platypus' command line tool's man page
- (IBAction)showManPage:(id)sender {
    [WORKSPACE openPathInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_MANPAGE ofType:nil]];
}

// Open Readme.html
- (IBAction)showReadme:(id)sender {
    [WORKSPACE openPathInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_README_FILE ofType:nil]];
}

// Open program website
- (IBAction)openWebsite:(id)sender {
    [WORKSPACE openURL:[NSURL URLWithString:PROGRAM_WEBSITE]];
}

// Open program GitHub website
- (IBAction)openGitHubWebsite:(id)sender {
    [WORKSPACE openURL:[NSURL URLWithString:PROGRAM_GITHUB_WEBSITE]];
}

// Open License html file
- (IBAction)openLicense:(id)sender {
    [WORKSPACE openPathInDefaultBrowser:[[NSBundle mainBundle] pathForResource:PROGRAM_LICENSE_FILE ofType:nil]];
}

// Open donations website
- (IBAction)openDonations:(id)sender {
    [WORKSPACE openURL:[NSURL URLWithString:PROGRAM_DONATIONS]];
}

@end
