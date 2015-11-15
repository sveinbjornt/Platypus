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
            [Alerts alert:@"Error" subText:[NSString stringWithFormat:@"Could not create directory '%@'", [APP_SUPPORT_FOLDER stringByExpandingTildeInPath]]];
    }
    
    // profiles folder
    if (![FILEMGR fileExistsAtPath:PROFILES_FOLDER isDirectory:&isDir]) {
        if (![FILEMGR createDirectoryAtPath:PROFILES_FOLDER withIntermediateDirectories:NO attributes:nil error:nil]) {
            [Alerts alert:@"Error" subText:[NSString stringWithFormat:@"Could not create directory '%@'", PROFILES_FOLDER]];
        }
    }
    
    if ([DEFAULTS objectForKey:@"FirstLaunch"] == nil) {
        // TODO: Create sample profile in Profiles folder
    }
    
    // we list ourself as an observer of changes to file system, for script
    [[WORKSPACE notificationCenter] addObserver:self selector:@selector(scriptFileSystemChange) name:VDKQueueRenameNotification object:nil];
    [[WORKSPACE notificationCenter] addObserver:self selector:@selector(scriptFileSystemChange) name:VDKQueueDeleteNotification object:nil];
    [[WORKSPACE notificationCenter] addObserver:self selector:@selector(scriptFileChanged:) name:VDKQueueWriteNotification object:nil];
    
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
    //show window
    [window center];
    [window makeKeyAndOrderFront:self];
    [appNameTextField becomeFirstResponder];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [DEFAULTS setObject:@NO forKey:@"FirstLaunch"];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    if ([filename hasSuffix:PROFILES_SUFFIX]) {
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
    NSString *tempScript, *defaultScript;
    NSString *interpreter = [interpreterTextField stringValue];
    
    // get a random number to append to script name in temp dir
    do {
        int randnum =  random() / 1000000;
        tempScript = [NSString stringWithFormat:@"%@/%@.%d", [TEMP_FOLDER stringByExpandingTildeInPath], NEW_SCRIPT_FILENAME, randnum];
    } while ([FILEMGR fileExistsAtPath:tempScript]);
    
    //put shebang line in the new script text file
    NSString *contentString = [NSString stringWithFormat:@"#!%@\n\n", interpreter];
    
    if (scriptText != nil) {
        contentString = [contentString stringByAppendingString:scriptText];
    } else {
        defaultScript = [ScriptAnalyser helloWorldProgramForDisplayName:[scriptTypePopupButton titleOfSelectedItem]];
        if (defaultScript != nil) {
            contentString = [contentString stringByAppendingString:defaultScript];
        }
    }
    
    //write the default content to the new script
    NSError *err;
    BOOL success = [contentString writeToFile:tempScript atomically:YES encoding:[[DEFAULTS objectForKey:@"DefaultTextEncoding"] intValue] error:&err];
    if (!success) {
        [Alerts alert:@"Error creating file" subText:[err localizedDescription]];
        return nil;
    }
    
    return tempScript;
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
            [Alerts alert:@"Application not found" subText:[NSString stringWithFormat:@"The application '%@' could not be found on your system.  Reverting to the built-in editor.", defaultEditor]];
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
    
    [[[SyntaxCheckerController alloc] init]
     showSyntaxCheckerForFile:[scriptPathTextField stringValue]
     withInterpreter:[interpreterTextField stringValue]
     window:window];
    
    [window setTitle:PROGRAM_NAME];
}

- (void)openScriptInBuiltInEditor:(NSString *)path {
    [window setTitle:[NSString stringWithFormat:@"%@ - Script Editor", PROGRAM_NAME]];
    [[[EditorController alloc] init] showEditorForFile:[scriptPathTextField stringValue] window:window];
    [window setTitle:PROGRAM_NAME];
}

- (void)scriptFileSystemChange
{
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
    
    // development version checkbox: always disable this option if secure bundled script is checked
    [developmentVersionCheckbox setEnabled:![encryptCheckbox intValue]];
    if ([encryptCheckbox intValue]) {
        [DEFAULTS setObject:@NO forKey:@"OnCreateDevVersion"];
    }
    
    // optimize nib is enabled and on by default if ibtool is present
    BOOL ibtoolInstalled = [FILEMGR fileExistsAtPath:IBTOOL_PATH];
    if (ibtoolInstalled == FALSE) {
        [DEFAULTS setObject:@NO forKey:@"OnCreateOptimizeNib"];
    }
    
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
                                                 name:PLATYPUS_APP_SPEC_CREATED_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateEstimatedAppSize)
                                                 name:PLATYPUS_APP_SIZE_CHANGED_NOTIFICATION
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
    [spec setProperty:@YES forKey:@"DestinationOverride"];
    
    // verify that the values in the spec are OK
    if (![spec verify]) {
        [Alerts alert:@"Spec verification failed" subText:[spec error]];
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
        
        [Alerts alert:@"Creating from spec failed" subText:[spec error]];
        return NO;
    }
    
    // check if icon creation failed
//    NSString *appIconPath = [NSString stringWithFormat:@"%@/Contents/Resources/appIcon.icns", appPath];
//    unsigned long long fileSize = [[FILEMGR attributesOfItemAtPath:appIconPath error:nil] fileSize];
//    if (fileSize == 0) {
//        [Alerts alert:@"Failed to create icon" subText:@"Creating the application has failed. Please report this bug."];
//    }

    // reveal newly create app in Finder, if prefs say so
    if ([DEFAULTS boolForKey:@"RevealApplicationWhenCreated"]) {
        [WORKSPACE selectFile:appPath inFileViewerRootedAtPath:appPath];
    }
    
    // open newly create app, if prefs say so
    if ([DEFAULTS boolForKey:@"OpenApplicationWhenCreated"]) {
        [WORKSPACE launchApplication:appPath];
    }
    
    [developmentVersionCheckbox setIntValue:0];
    [optimizeApplicationCheckbox setIntValue:0];
    
    // Dialog ends here.
    [NSApp endSheet:progressDialogWindow];
    [progressDialogWindow orderOut:self];
    
    return YES;
}

- (BOOL)verifyFieldContents {
    BOOL isDir;
    NSFileManager *fileManager = FILEMGR;
    
    //make sure a name has been assigned
    if ([[appNameTextField stringValue] length] == 0) {
        [Alerts sheetAlert:@"Invalid Application Name" subText:@"You must specify a name for your application" forWindow:window];
        return NO;
    }
    
    //verify that script exists at path
    if (([fileManager fileExistsAtPath:[scriptPathTextField stringValue] isDirectory:&isDir] == NO) || isDir) { //make sure script exists and isn't a folder
        [Alerts sheetAlert:@"Invalid Script Path" subText:@"No file exists at the script path you have specified" forWindow:window];
        return NO;
    }
    
    //make sure we have an icon
    if (([iconController hasIcns] && ![[iconController icnsFilePath] isEqualToString:@""] && ![fileManager fileExistsAtPath:[iconController icnsFilePath]])) {
        [Alerts sheetAlert:@"Missing Icon" subText:@"You must set an icon for your application." forWindow:window];
        return NO;
    }
    
    //let's be certain that the bundled files list doesn't contain entries that have been moved
    if (![bundledFilesController areAllPathsAreValid]) {
        [Alerts sheetAlert:@"Bundled files missing" subText:@"One or more of the files that are to be bundled with the application could not be found. Please rectify this and try again." forWindow:window];
        return NO;
    }
    
    //interpreter
    if ([fileManager fileExistsAtPath:[interpreterTextField stringValue]] == NO) {
        if ([Alerts proceedAlert:@"Invalid Interpreter" subText:[NSString stringWithFormat:@"The interpreter '%@' does not exist on this system.  Do you wish to proceed anyway?", [interpreterTextField stringValue]] withAction:@"Proceed"] == NO) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Generate/read AppSpec

- (id)appSpecFromControls {
    PlatypusAppSpec *spec = [[[PlatypusAppSpec alloc] initWithDefaults] autorelease];
    
    [spec setProperty:[appNameTextField stringValue] forKey:@"Name"];
    [spec setProperty:[scriptPathTextField stringValue] forKey:@"ScriptPath"];
    
    // set output type to the name of the output type, minus spaces
    [spec setProperty:[outputTypePopupMenu titleOfSelectedItem] forKey:@"Output"];
    
    // icon
    if ([iconController hasIcns]) {
        [spec setProperty:[iconController icnsFilePath] forKey:@"IconPath"];
    } else {
        NSString *tmpIconPath = [NSString stringWithFormat:@"%@%@.icns", APP_SUPPORT_FOLDER, [appNameTextField stringValue]];
        [spec setProperty:tmpIconPath forKey:@"IconPath"];
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
    [spec setProperty:[bundledFilesController filePaths] forKey:@"BundledFiles"];
    
    // file types
    [spec setProperty:(NSMutableArray *)[(SuffixTypeListController *)[dropSettingsController suffixListController] getItemsArray] forKey:@"Suffixes"];
    [spec setProperty:(NSMutableArray *)[(UniformTypeListController *)[dropSettingsController uniformTypesListController] getItemsArray] forKey:@"UniformTypes"];
    [spec setProperty:[dropSettingsController docIconPath] forKey:@"DocIcon"];
    [spec setProperty:@([dropSettingsController acceptsText]) forKey:@"AcceptsText"];
    [spec setProperty:@([dropSettingsController acceptsFiles]) forKey:@"AcceptsFiles"];
    [spec setProperty:@([dropSettingsController declareService]) forKey:@"DeclareService"];
    [spec setProperty:@([dropSettingsController promptsForFileOnLaunch]) forKey:@"PromptForFileOnLaunch"];
    
    //  text output text settings
    [spec setProperty:@((int)[textSettingsController textEncoding]) forKey:@"TextEncoding"];
    [spec setProperty:[[textSettingsController textFont] fontName] forKey:@"TextFont"];
    [spec setProperty:[NSNumber numberWithFloat:[[textSettingsController textFont] pointSize]] forKey:@"TextSize"];
    [spec setProperty:[[textSettingsController textForegroundColor] hexString] forKey:@"TextForeground"];
    [spec setProperty:[[textSettingsController textBackgroundColor] hexString] forKey:@"TextBackground"];
    
    // status menu settings
    if ([[outputTypePopupMenu titleOfSelectedItem] isEqualToString:@"Status Menu"]) {
        [spec setProperty:[statusItemSettingsController displayType] forKey:@"StatusItemDisplayType"];
        [spec setProperty:[statusItemSettingsController title] forKey:@"StatusItemTitle"];
        [spec setProperty:[[statusItemSettingsController icon] TIFFRepresentation] forKey:@"StatusItemIcon"];
        [spec setProperty:@([statusItemSettingsController usesSystemFont]) forKey:@"StatusItemUseSystemFont"];
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
    [bundledFilesController clearFileList:self];
    [bundledFilesController addFiles:[spec propertyForKey:@"BundledFiles"]];
    
    //update button status
    [bundledFilesController performSelector:@selector(tableViewSelectionDidChange:) withObject:nil];
    
    //drop settings
    [(SuffixTypeListController *)[dropSettingsController suffixListController] removeAllItems];
    [(SuffixTypeListController *)[dropSettingsController suffixListController] addItems:[spec propertyForKey:@"Suffixes"]];
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
    [textSettingsController setTextForegroundColor:[NSColor colorFromHex:[spec propertyForKey:@"TextForeground"]]];
    [textSettingsController setTextBackgroundColor:[NSColor colorFromHex:[spec propertyForKey:@"TextBackground"]]];
    
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
        [statusItemSettingsController setUsesSystemFont:[spec propertyForKey:@"StatusItemUseSystemFont"]];
    }
    
    //update buttons
    [self performSelector:@selector(controlTextDidChange:) withObject:nil];
    
    [self updateEstimatedAppSize];
    
    [bundleIdentifierTextField setStringValue:[spec propertyForKey:@"Identifier"]];
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
    
    PlatypusAppSpec *spec = [[PlatypusAppSpec alloc] initWithDefaultsFromScript:filename];
    [self controlsFromAppSpec:spec];
    [spec release];
    
    [iconController setToDefaults];
    
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
        [bundleIdentifierTextField setStringValue:[PlatypusAppSpec standardBundleIdForAppName:[appNameTextField stringValue] authorName:nil usingDefaults:YES]];
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
    [versionTextField setStringValue:@"1.0"];
    
    [bundleIdentifierTextField setStringValue:[PlatypusAppSpec standardBundleIdForAppName:[appNameTextField stringValue] authorName:nil usingDefaults:YES]];
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
    [textSettingsController setToDefaults:self];
    
    //set status item settings to default
    [statusItemSettingsController setToDefaults:self];
    
    //set script type
    [self setScriptType:@"Shell"];
    
    //set output type
    [outputTypePopupMenu selectItemWithTitle:DEFAULT_OUTPUT_TYPE];
    [self outputTypeWasChanged:outputTypePopupMenu];
    
    //update button status
    [self performSelector:@selector(controlTextDidChange:) withObject:nil];
    
    [appSizeTextField setStringValue:@""];
    
    [iconController setToDefaults];
}

- (IBAction)showCommandLineString:(id)sender {
    if (![FILEMGR fileExistsAtPath:[scriptPathTextField stringValue]]) {
        [Alerts alert:@"Missing script"
              subText:[NSString stringWithFormat:@"No file exists at path '%@'", [scriptPathTextField stringValue]]];
        return;
    }
    
    [window setTitle:[NSString stringWithFormat:@"%@ - Shell Command String", PROGRAM_NAME]];
    ShellCommandController *shellCommandController = [[ShellCommandController alloc] init];
    [shellCommandController setPrefsController:prefsController];
    [shellCommandController showShellCommandForSpec:[self appSpecFromControls] window:window];
    
    [window setTitle:PROGRAM_NAME];
}

#pragma mark - App Size estimation

- (void)updateEstimatedAppSize {
    [appSizeTextField setStringValue:[NSString stringWithFormat:@"Estimated final app size: ~%@", [self estimatedAppSize]]];
}

- (NSString *)estimatedAppSize {
    
    // estimate the combined size of all the
    // files that will go into application bundle
    UInt64 estimatedAppSize = 0;
    estimatedAppSize += 4096; // Info.plist
    estimatedAppSize += 4096; // AppSettings.plist
    estimatedAppSize += [iconController iconSize];
    estimatedAppSize += [dropSettingsController docIconSize];
    estimatedAppSize += [WORKSPACE fileOrFolderSize:[scriptPathTextField stringValue]];
    estimatedAppSize += [WORKSPACE fileOrFolderSize:[[NSBundle mainBundle] pathForResource:@"ScriptExec" ofType:nil]];
    
    // nib size is much smaller if compiled with ibtool
    UInt64 nibSize = [WORKSPACE fileOrFolderSize:[[NSBundle mainBundle] pathForResource:@"MainMenu.nib" ofType:nil]];
    if ([FILEMGR fileExistsAtPath:IBTOOL_PATH]) {
        nibSize = 0.60 * nibSize; // compiled nib is approximtely 65% of original
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
        NSString *filename = files[0]; //we only load the first dragged item
        NSString *fileType = [WORKSPACE typeOfFile:filename error:nil];
        

        BOOL isDir;
        if ([FILEMGR fileExistsAtPath:filename isDirectory:&isDir] && !isDir) {
            if ([filename hasSuffix:PROFILES_SUFFIX] || [WORKSPACE type:fileType conformsToType:PROGRAM_PROFILE_UTI]) {
                [profilesController loadProfileAtPath:filename];
            } else if ([WORKSPACE type:fileType conformsToType:(NSString *)kUTTypeImage]) {
                if ([WORKSPACE type:fileType conformsToType:(NSString *)kUTTypeAppleICNS]) {
                    [iconController loadIcnsFile:filename];
                } else {
                    [iconController loadImageFile:filename];
                }
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
