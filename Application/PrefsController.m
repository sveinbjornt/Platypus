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

#import "PrefsController.h"
#import <sys/stat.h>
#import "Alerts.h"
#import "STPrivilegedTask.h"
#import "Common.h"
#import "PlatypusController.h"
#import "NSWorkspace+Additions.h"
#import "NSBundle+Templates.h"
#import "PlatypusAppSpec.h"

@interface PrefsController()
{
    IBOutlet NSButton *revealAppCheckbox;
    IBOutlet NSButton *openAppCheckbox;
    IBOutlet NSButton *createOnScriptChangeCheckbox;
    IBOutlet NSPopUpButton *defaultEditorPopupButton;
    IBOutlet NSPopUpButton *defaultTextEncodingPopupButton;
    IBOutlet NSTextField *defaultBundleIdentifierTextField;
    IBOutlet NSTextField *defaultAuthorTextField;
    IBOutlet NSTextField *CLTStatusTextField;
    IBOutlet NSButton *installCLTButton;
    IBOutlet NSProgressIndicator *installCLTProgressIndicator;
    IBOutlet NSWindow *prefsWindow;
    IBOutlet PlatypusController *platypusController;
}

@property (nonatomic, getter=isCommandLineToolInstalled, readonly) BOOL commandLineToolInstalled;

- (IBAction)showWindow:(id)sender;
- (IBAction)applyPrefs:(id)sender;
- (IBAction)restoreDefaultPrefs:(id)sender;
- (IBAction)commandLineInstallButtonClicked:(id)sender;
- (IBAction)uninstallPlatypus:(id)sender;
- (IBAction)selectScriptEditor:(id)sender;

@end

@implementation PrefsController

- (IBAction)showWindow:(id)sender {
    [self window];
    [self updateCLTStatus:CLTStatusTextField];
    [self setIconsForEditorMenu];
    [super showWindow:sender];
}

- (void)setIconsForEditorMenu {
    for (int i = 0; i < [defaultEditorPopupButton numberOfItems]; i++) {
        
        NSMenuItem *menuItem = [defaultEditorPopupButton itemAtIndex:i];
        NSSize smallIconSize = { 16, 16 };
        
        if ([[menuItem title] isEqualToString:DEFAULT_EDITOR]) {
            NSImage *icon = [NSImage imageNamed:@"PlatypusAppIcon"];
            [icon setSize:smallIconSize];
            [menuItem setImage:icon];
        } else if ([[menuItem title] isEqualToString:@"Select..."] == FALSE) {
            NSImage *icon = [NSImage imageNamed:@"NSDefaultApplicationIcon"];
            NSString *appPath = [WORKSPACE fullPathForApplication:[menuItem title]];
            if (appPath != nil) {
                icon = [WORKSPACE iconForFile:appPath];
            }
            [icon setSize:smallIconSize];
            [menuItem setImage:icon];
        }
    }
}

+ (NSDictionary *)defaultsDictionary {
    NSMutableDictionary *defaultPrefs = [NSMutableDictionary dictionary];
    
    // create default bundle identifier string from usename
    NSString *bundleId = [PlatypusAppSpec standardBundleIdForAppName:@""
                                                          authorName:nil
                                                       usingDefaults:NO];
    
    defaultPrefs[@"DefaultBundleIdentifierPrefix"] = bundleId;
    defaultPrefs[@"DefaultEditor"] = DEFAULT_EDITOR;
    defaultPrefs[@"Profiles"] = @[];
    defaultPrefs[@"RevealApplicationWhenCreated"] = @NO;
    defaultPrefs[@"OpenApplicationWhenCreated"] = @NO;
    defaultPrefs[@"CreateOnScriptChange"] = @NO;
    defaultPrefs[@"DefaultTextEncoding"] = @(DEFAULT_OUTPUT_TXT_ENCODING);
    defaultPrefs[@"DefaultAuthor"] = NSFullUserName();
    defaultPrefs[@"OnCreateDevVersion"] = @NO;
    defaultPrefs[@"OnCreateOptimizeNib"] = @YES;
    defaultPrefs[@"OnCreateUseXMLPlist"] = @NO;
    
    return defaultPrefs;
}

#pragma mark - Interface actions

- (IBAction)applyPrefs:(id)sender {
    //make sure bundle identifier ends with a '.'
    NSString *identifier = [defaultBundleIdentifierTextField stringValue];
    if ([identifier characterAtIndex:[identifier length] - 1] != '.') {
        [DEFAULTS setObject:[identifier stringByAppendingString:@"."]  forKey:@"DefaultBundleIdentifierPrefix"];
    }
    [prefsWindow makeFirstResponder:nil];
    [DEFAULTS synchronize];
    [[self window] close];
}

- (IBAction)restoreDefaultPrefs:(id)sender {
    NSDictionary *dict = [PrefsController defaultsDictionary];
    for (NSString *key in dict) {
        [DEFAULTS setObject:dict[key] forKey:key];
    }
    [DEFAULTS synchronize];
}

- (IBAction)selectScriptEditor:(id)sender {
    //create open panel
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setTitle:@"Select Editor"];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setAllowedFileTypes:@[(NSString *)kUTTypeApplicationBundle]];

    //run open panel
    if ([oPanel runModal] == NSOKButton) {
        //set app name minus .app suffix
        NSString *filePath = [[oPanel URLs][0] path];
        NSString *editorName = [[filePath lastPathComponent] stringByDeletingPathExtension];
        [defaultEditorPopupButton setTitle:editorName];
        [self setIconsForEditorMenu];
    } else {
        [defaultEditorPopupButton setTitle:[DEFAULTS stringForKey:@"DefaultEditor"]];
    }
}

- (IBAction)commandLineInstallButtonClicked:(id)sender {
    [self isCommandLineToolInstalled] == NO ? [self installCommandLineTool] : [self uninstallCommandLineTool];
}

#pragma mark - Install/Uninstall

- (void)updateCLTStatus:(NSTextField *)textField {
    //set status of clt install button and text field
    if ([self isCommandLineToolInstalled] == YES) {
        NSString *versionString = [NSString stringWithContentsOfFile:CMDLINE_VERSION_PATH encoding:NSUTF8StringEncoding error:nil];
        versionString = [versionString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        
        if (versionString && [versionString isEqualToString:PROGRAM_VERSION]) { // it's installed and current
            [textField setTextColor:[NSColor colorWithCalibratedRed:0.0 green:0.6 blue:0.0 alpha:1.0]];
            [textField setStringValue:@"Command line tool is installed"];
        } else if (versionString) {
            // installed but not this version
            [textField setTextColor:[NSColor orangeColor]];
            if ([versionString floatValue] < [PROGRAM_VERSION floatValue]) {
                [textField setStringValue:@"Old version of command line"];  //older
            } else {
                [textField setStringValue:@"Newer version of command line"];  //newer
            }
        }
        [installCLTButton setTitle:@"Uninstall"];
    } else {
        [textField setStringValue:@"Command line tool is not installed"];
        [textField setTextColor:[NSColor redColor]];
        [installCLTButton setTitle:@"Install"];
    }
}

- (BOOL)isCommandLineToolInstalled {
    return ([FILEMGR fileExistsAtPath:CMDLINE_VERSION_PATH] &&
            [FILEMGR fileExistsAtPath:CMDLINE_TOOL_PATH] &&
            [FILEMGR fileExistsAtPath:CMDLINE_MANPAGE_PATH] &&
            [FILEMGR fileExistsAtPath:CMDLINE_EXEC_PATH] &&
            [FILEMGR fileExistsAtPath:CMDLINE_ICON_PATH]);
}

- (void)installCommandLineTool {
    [self runCLTTemplateScript:@"InstallCommandLineTool.sh" usingDictionary:[self commandLineEnvDict]];
}

- (void)uninstallCommandLineTool {
    [self runCLTTemplateScript:@"UninstallCommandLineTool.sh" usingDictionary:[self commandLineEnvDict]];
}

- (IBAction)uninstallPlatypus:(id)sender {
    if ([Alerts proceedAlert:@"Are you sure you want to uninstall Platypus?"
                     subText:@"This will move the Platypus application and all related files to the Trash. The application will then quit."
                  withAction:@"Uninstall"] == YES) {
        [self runCLTTemplateScript:@"UninstallPlatypus.sh" usingDictionary:[self commandLineEnvDict]];
        [[NSApplication sharedApplication] terminate:self];
    }
}

- (NSDictionary *)commandLineEnvDict
{
    return @{@"PROGRAM_NAME": PROGRAM_NAME,
            @"PROGRAM_VERSION": PROGRAM_VERSION,
            @"PROGRAM_STAMP": PROGRAM_STAMP,
            @"PROGRAM_MIN_SYS_VERSION": PROGRAM_MIN_SYS_VERSION,
            @"PROGRAM_BUNDLE_IDENTIFIER": PROGRAM_BUNDLE_IDENTIFIER,
            @"PROGRAM_AUTHOR": PROGRAM_AUTHOR,
            @"CMDLINE_PROGNAME_IN_BUNDLE": CMDLINE_PROGNAME_IN_BUNDLE,
            @"CMDLINE_PROGNAME": CMDLINE_PROGNAME,
            @"CMDLINE_SCRIPTEXEC_BIN_NAME": CMDLINE_SCRIPTEXEC_BIN_NAME,
            @"CMDLINE_DEFAULT_ICON_NAME": CMDLINE_DEFAULT_ICON_NAME,
            @"CMDLINE_NIB_NAME": CMDLINE_NIB_NAME,
            @"CMDLINE_BASE_INSTALL_PATH": CMDLINE_BASE_INSTALL_PATH,
            @"CMDLINE_BIN_PATH": CMDLINE_BIN_PATH,
            @"CMDLINE_TOOL_PATH": CMDLINE_TOOL_PATH,
            @"CMDLINE_SHARE_PATH": CMDLINE_SHARE_PATH,
            @"CMDLINE_VERSION_PATH": CMDLINE_VERSION_PATH,
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
        [Alerts alert:@"Error running script" subText:[NSString stringWithFormat:@"Could not run script '%@'", scriptName]];
    }
    [self updateCLTStatus:CLTStatusTextField];
    [installCLTProgressIndicator stopAnimation:self];
}

- (BOOL)executeScriptTemplateWithPrivileges:(NSString *)scriptName usingDictionary:(NSDictionary *)placeholderDict {
    
    NSString *script = [[NSBundle mainBundle] loadTemplate:scriptName usingDictionary:placeholderDict];
    if (script == nil) {
        return NO;
    }
    NSString *tmpScriptPath = [WORKSPACE createTempFileWithContents:script];
    chmod([tmpScriptPath cStringUsingEncoding:NSUTF8StringEncoding], S_IRWXU | S_IRWXG | S_IROTH); // 744
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scriptTaskFinished:)
                                                 name:STPrivilegedTaskDidTerminateNotification
                                               object:tmpScriptPath];
    
    // execute path, pass Resources directory and version as arguments 1 and 2
    NSArray *args = @[[[NSBundle mainBundle] resourcePath], PROGRAM_VERSION];
    [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:tmpScriptPath arguments:args];
    
    return YES;
}

- (void)scriptTaskFinished:(NSNotification *)notification {
    //[FILEMGR removeItemAtPath:tmpScriptPath error:nil];
    NSLog(@"Script finished: %@", [notification object]);
}

@end
