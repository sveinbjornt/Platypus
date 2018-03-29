/*
 Copyright (c) 2003-2018, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

#import "PreferencesController.h"
#import <sys/stat.h>
#import "Alerts.h"
#import "STPrivilegedTask.h"
#import "Common.h"
#import "NSWorkspace+Additions.h"
#import "NSBundle+Templates.h"
#import "PlatypusAppSpec.h"

@interface PreferencesController()
{
    IBOutlet NSPopUpButton *defaultEditorPopupButton;
    IBOutlet NSTextField *defaultBundleIdentifierTextField;
    IBOutlet NSTextField *defaultAuthorTextField;
    IBOutlet NSTextField *CLTStatusTextField;
    IBOutlet NSButton *installCLTButton;
    IBOutlet NSProgressIndicator *installCLTProgressIndicator;
}

- (IBAction)showWindow:(id)sender;
- (IBAction)applyPrefs:(id)sender;
- (IBAction)restoreDefaultPrefs:(id)sender;
- (IBAction)commandLineInstallButtonClicked:(id)sender;
- (IBAction)uninstallPlatypus:(id)sender;
- (IBAction)selectScriptEditor:(id)sender;

@end

@implementation PreferencesController

- (IBAction)showWindow:(id)sender {
    [self window];
    [self updateCLTStatus];

    // we lazily fetch icons for editor apps in Editors menu
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        [self setIconForEditorMenuItemAtIndex:[defaultEditorPopupButton indexOfSelectedItem]];
    });
    
    [super showWindow:sender];
}

- (void)setIconsForEditorMenu {
    for (int i = 0; i < [defaultEditorPopupButton numberOfItems]; i++) {
        [self setIconForEditorMenuItemAtIndex:i];
    }
}

- (void)setIconForEditorMenuItemAtIndex:(NSInteger)index {
    NSMenuItem *menuItem = [defaultEditorPopupButton itemAtIndex:index];
    if ([menuItem image] != nil) {
        return; // already has an icon
    }
    NSSize smallIconSize = { 16, 16 };
    
    if ([[menuItem title] isEqualToString:DEFAULT_EDITOR]) {
        NSImage *icon = [NSApp applicationIconImage];
        [icon setSize:smallIconSize];
        [menuItem setImage:icon];
    } else if ([[menuItem title] isEqualToString:@"Select..."] == FALSE) {
        NSImage *icon;
        NSString *appPath = [WORKSPACE fullPathForApplication:[menuItem title]];
        if (appPath) {
            icon = [WORKSPACE iconForFile:appPath];
        } else {
            icon = [NSImage imageNamed:@"NSDefaultApplicationIcon"];
        }
        [icon setSize:smallIconSize];
        [menuItem setImage:icon];
    }
}

+ (NSDictionary *)defaultsDictionary {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    
    // create default bundle identifier string from usename
    NSString *bundleId = [PlatypusAppSpec bundleIdentifierForAppName:@""
                                                          authorName:nil
                                                       usingDefaults:NO];
    
    defaults[DefaultsKey_BundleIdentifierPrefix] = bundleId;
    defaults[DefaultsKey_DefaultEditor] = DEFAULT_EDITOR;
    defaults[DefaultsKey_RevealApplicationWhenCreated] = @NO;
    defaults[DefaultsKey_OpenApplicationWhenCreated] = @NO;
    defaults[DefaultsKey_DefaultAuthor] = NSFullUserName();
    defaults[DefaultsKey_SymlinkFiles] = @NO;
    defaults[DefaultsKey_StripNib] = @YES;
    defaults[DefaultsKey_UseXMLPlistFormat] = @NO;
    
    return defaults;
}

- (void)menuWillOpen:(NSMenu *)menu {
    if (menu == [defaultEditorPopupButton menu]) {
        // this only needs to happen once
        static dispatch_once_t predicate;
        dispatch_once(&predicate, ^{
            [self setIconsForEditorMenu];
        });
    }
}

#pragma mark - Interface actions

- (IBAction)applyPrefs:(id)sender {
    //make sure bundle identifier ends with a '.'
    NSString *identifier = [defaultBundleIdentifierTextField stringValue];
    if ([identifier characterAtIndex:[identifier length] - 1] != '.') {
        [DEFAULTS setObject:[identifier stringByAppendingString:@"."]  forKey:DefaultsKey_BundleIdentifierPrefix];
    }
    [[self window] makeFirstResponder:nil];
    [DEFAULTS synchronize];
    [[self window] close];
}

- (IBAction)restoreDefaultPrefs:(id)sender {
    NSDictionary *dict = [PreferencesController defaultsDictionary];
    for (NSString *key in dict) {
        [DEFAULTS setObject:dict[key] forKey:key];
    }
    [DEFAULTS synchronize];
}

- (IBAction)selectScriptEditor:(id)sender {
    //create open panel
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setAllowedFileTypes:@[(NSString *)kUTTypeApplicationBundle]];

    // set Applications folder as file dialog directory
    NSArray *applicationFolderPaths = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationDirectory inDomains:NSLocalDomainMask];
    if ([applicationFolderPaths count]) {
        [oPanel setDirectoryURL:applicationFolderPaths[0]];
    }
    
    //run open panel
    if ([oPanel runModal] == NSOKButton) {
        //set app name minus .app suffix
        NSString *filePath = [[oPanel URLs][0] path];
        NSString *editorName = [[filePath lastPathComponent] stringByDeletingPathExtension];
        [defaultEditorPopupButton setTitle:editorName];
        [self setIconsForEditorMenu];
    } else {
        [defaultEditorPopupButton setTitle:[DEFAULTS stringForKey:DefaultsKey_DefaultEditor]];
    }
}

- (IBAction)commandLineInstallButtonClicked:(id)sender {
    [PreferencesController isCommandLineToolInstalled] ? [self uninstallCommandLineTool] : [self installCommandLineTool];
}

#pragma mark - Install/Uninstall

+ (BOOL)isCommandLineToolInstalled {
    return [FILEMGR fileExistsAtPath:CMDLINE_TOOL_PATH];
}

+ (void)putCommandLineToolInstallStatusInTextField:(NSTextField *)textField {
    
    static dispatch_queue_t cltStatusDispatchQueue;

    // create queue lazily
    if (cltStatusDispatchQueue == NULL) {
        cltStatusDispatchQueue = dispatch_queue_create("platypus.cltStatusDispatchQueue", NULL);
    }

    dispatch_async(cltStatusDispatchQueue, ^{

        BOOL isInstalled = [PreferencesController isCommandLineToolInstalled];
        NSString *versionString;
        
        if (isInstalled) {
            // determine command line tool version by running it
            NSTask *task = [[NSTask alloc] init];
            [task setLaunchPath:CMDLINE_TOOL_PATH];
            [task setArguments:@[[NSString stringWithFormat:@"--%s", CMDLINE_VERSION_ARG_FLAG]]];
            
            NSPipe *outputPipe = [NSPipe pipe];
            [task setStandardOutput:outputPipe];
            [task setStandardError:outputPipe];
            
            [task launch];
            [task waitUntilExit];
            
            // get output string and parse for version number
            NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
            NSString *outputString = [[NSString alloc] initWithData:outputData encoding:DEFAULT_TEXT_ENCODING];
            
            NSArray *words = [outputString componentsSeparatedByString:@" "];
            versionString = [words[2] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            PLog(@"Command line tool is installed (version %@)", versionString);
        } else {
            PLog(@"Command line tool is not installed");
        }
    
        // Update UI on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            // not installed
            if (isInstalled == NO) {
                [textField setTextColor:[NSColor redColor]];
                [textField setStringValue:@"Command line tool is not installed"];
            }
            // it's installed and current
            else if ([versionString isEqualToString:PROGRAM_VERSION]) {
                [textField setTextColor:[NSColor colorWithCalibratedRed:0.0 green:0.6 blue:0.0 alpha:1.0]];
                [textField setStringValue:@"Command line tool is installed"];
            }
            // installed but not this version
            else {
                [textField setTextColor:[NSColor orangeColor]];
                if ([versionString floatValue] < [PROGRAM_VERSION floatValue]) {
                    [textField setStringValue:[NSString stringWithFormat:@"Old version of command line tool (%@)", versionString]];
                } else {
                    [textField setStringValue:[NSString stringWithFormat:@"Newer version of command line tool (%@)", versionString]];
                }
            }
        });
    });
}

- (void)updateCLTStatus {
    NSString *buttonTitle = [PreferencesController isCommandLineToolInstalled] ? @"Uninstall" : @"Install";
    [installCLTButton setTitle:buttonTitle];
    [PreferencesController putCommandLineToolInstallStatusInTextField:CLTStatusTextField];
}

- (void)installCommandLineTool {
    [self runCLTTemplateScript:@"InstallCommandLineTool.sh" usingDictionary:[self commandEnvironmentDictionary]];
}

- (void)uninstallCommandLineTool {
    [self runCLTTemplateScript:@"UninstallCommandLineTool.sh" usingDictionary:[self commandEnvironmentDictionary]];
}

- (IBAction)uninstallPlatypus:(id)sender {
    if ([Alerts proceedAlert:@"Are you sure you want to uninstall Platypus?"
                     subText:@"This will move the Platypus application and all related files to the Trash. The application will then quit."
             withActionNamed:@"Uninstall"] == YES) {
        [self runCLTTemplateScript:@"UninstallPlatypus.sh" usingDictionary:[self commandEnvironmentDictionary]];
        [[NSApplication sharedApplication] terminate:self];
    }
}

- (NSDictionary *)commandEnvironmentDictionary {
    // a little more introspection would be nice here but...
    return @{@"PROGRAM_NAME": PROGRAM_NAME,
            @"PROGRAM_VERSION": PROGRAM_VERSION,
            @"PROGRAM_CREATOR_STAMP": PROGRAM_CREATOR_STAMP,
            @"PROGRAM_MIN_SYS_VERSION": PROGRAM_MIN_SYS_VERSION,
            @"PROGRAM_BUNDLE_IDENTIFIER": PROGRAM_BUNDLE_IDENTIFIER,
            @"PROGRAM_AUTHOR": PROGRAM_AUTHOR,
            @"CMDLINE_PROGNAME_IN_BUNDLE": CMDLINE_PROGNAME_IN_BUNDLE,
            @"CMDLINE_PROGNAME": CMDLINE_PROGNAME,
            @"CMDLINE_SCRIPTEXEC_BIN_NAME": CMDLINE_SCRIPTEXEC_BIN_NAME,
            @"CMDLINE_SCRIPTEXEC_ZIP_NAME": CMDLINE_SCRIPTEXEC_ZIP_NAME,
            @"CMDLINE_DEFAULT_ICON_NAME": CMDLINE_DEFAULT_ICON_NAME,
            @"CMDLINE_NIB_NAME": CMDLINE_NIB_NAME,
            @"CMDLINE_BASE_INSTALL_PATH": CMDLINE_BASE_INSTALL_PATH,
            @"CMDLINE_BIN_PATH": CMDLINE_BIN_PATH,
            @"CMDLINE_TOOL_PATH": CMDLINE_TOOL_PATH,
            @"CMDLINE_SHARE_PATH": CMDLINE_SHARE_PATH,
            @"CMDLINE_MANDIR_PATH": CMDLINE_MANDIR_PATH,
            @"CMDLINE_MANPAGE_PATH": CMDLINE_MANPAGE_PATH,
            @"CMDLINE_EXEC_PATH": CMDLINE_EXEC_PATH,
            @"CMDLINE_NIB_PATH": CMDLINE_NIB_PATH,
            @"CMDLINE_SCRIPT_EXEC_PATH": CMDLINE_SCRIPT_EXEC_PATH,
            @"CMDLINE_ICON_PATH": CMDLINE_ICON_PATH};
}

#pragma mark - Utils

- (void)runCLTTemplateScript:(NSString *)scriptName usingDictionary:(NSDictionary *)placeholderDict {
    [installCLTProgressIndicator setUsesThreadedAnimation:YES];
    [installCLTProgressIndicator startAnimation:self];
    if ([self executeScriptTemplateWithPrivileges:scriptName usingDictionary:placeholderDict] == NO) {
        [Alerts alert:@"Error running script"
        subTextFormat:@"Could not run script '%@'", scriptName];
    }
    [installCLTProgressIndicator stopAnimation:self];
}

- (BOOL)executeScriptTemplateWithPrivileges:(NSString *)scriptName usingDictionary:(NSDictionary *)placeholderDict {
    PLog(@"Running task with script %@", scriptName);
    NSString *script = [[NSBundle mainBundle] loadTemplate:scriptName usingDictionary:placeholderDict];
    if (script == nil) {
        return NO;
    }
    
    // create script at temp path and make it executable
    NSString *tmpScriptPath = [WORKSPACE createTempFileWithContents:script];
    chmod([tmpScriptPath cStringUsingEncoding:NSUTF8StringEncoding], S_IRWXU|S_IRWXG|S_IROTH); // 744
    
    // create script task with Resources path and program version as arguments 1 and 2
    NSArray *args = @[[[NSBundle mainBundle] resourcePath], PROGRAM_VERSION];
    
    // create task
    STPrivilegedTask *privTask = [[STPrivilegedTask alloc] initWithLaunchPath:tmpScriptPath arguments:args];
    privTask.terminationHandler = ^(STPrivilegedTask *task) {
        PLog(@"Terminating task: %@", [task description]);
        [FILEMGR removeItemAtPath:[task launchPath] error:nil];
        PLog(@"Removed tmp script: %@", [task launchPath]);
        [self updateCLTStatus];
    };
    
    // launch task
    OSStatus err = [privTask launch];
    if (err != errAuthorizationSuccess) {
        if (err == errAuthorizationCanceled) {
            PLog(@"User cancelled");
            return YES;
        }
        
        PLog(@"Something went wrong. Authorization framework error %d", err);
        return NO;
    }
    
    return YES;
}

@end
