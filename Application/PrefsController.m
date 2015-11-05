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
#import "NSWorkspace+Additions.h"
#import "NSBundle+Templates.h"

@implementation PrefsController

/*****************************************
 - Set controls according to data in NSUserDefaults
 *****************************************/

- (IBAction)showWindow:(id)sender {
    [super loadWindow];
    
    // set controls according to NSUserDefaults
    [defaultEditorPopupButton setTitle:[DEFAULTS stringForKey:@"DefaultEditor"]];
    [defaultTextEncodingPopupButton selectItemWithTag:[[DEFAULTS objectForKey:@"DefaultTextEncoding"] intValue]];
    [defaultBundleIdentifierTextField setStringValue:[DEFAULTS stringForKey:@"DefaultBundleIdentifierPrefix"]];
    [defaultAuthorTextField setStringValue:[DEFAULTS stringForKey:@"DefaultAuthor"]];
    [revealAppCheckbox setState:[DEFAULTS boolForKey:@"RevealApplicationWhenCreated"]];
    [openAppCheckbox setState:[DEFAULTS boolForKey:@"OpenApplicationWhenCreated"]];
    [createOnScriptChangeCheckbox setState:[DEFAULTS boolForKey:@"CreateOnScriptChange"]];
    
    //set icons for editor menu
    [self setIconsForEditorMenu];
    [self updateCLTStatus:CLTStatusTextField];
    
    [super showWindow:sender];
}

/*****************************************
 - Set the icons for the menu items in the Editors list
 *****************************************/

- (void)setIconsForEditorMenu {
    
    for (int i = 0; i < [defaultEditorPopupButton numberOfItems]; i++) {
        
        NSMenuItem *menuItem = [defaultEditorPopupButton itemAtIndex:i];
        NSSize smallIconSize = { 16, 16 };
        
        if ([[menuItem title] isEqualToString:DEFAULT_EDITOR] == YES) {
            NSImage *icon = [NSImage imageNamed:@"PlatypusAppIcon"];
            [icon setSize:smallIconSize];
            [menuItem setImage:icon];
        } else if ([[menuItem title] isEqualToString:@"Select..."] == NO && [[menuItem title] length] > 0) {
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

/*****************************************
 - Set NSUserDefaults according to control settings
 *****************************************/

- (IBAction)applyPrefs:(id)sender {
    // editor
    [DEFAULTS setObject:[defaultEditorPopupButton titleOfSelectedItem]  forKey:@"DefaultEditor"];
    
    // text encoding
    [DEFAULTS setObject:[NSNumber numberWithInt:[[defaultTextEncodingPopupButton selectedItem] tag]]  forKey:@"DefaultTextEncoding"];
    
    //bundle identifier
    //make sure bundle identifier ends with a '.'
    if ([[defaultBundleIdentifierTextField stringValue] characterAtIndex:[[defaultBundleIdentifierTextField stringValue] length] - 1] != '.') {
        [DEFAULTS setObject:[[defaultBundleIdentifierTextField stringValue] stringByAppendingString:@"."]  forKey:@"DefaultBundleIdentifierPrefix"];
    } else {
        [DEFAULTS setObject:[defaultBundleIdentifierTextField stringValue]  forKey:@"DefaultBundleIdentifierPrefix"];
    }
    
    //author
    [DEFAULTS setObject:[defaultAuthorTextField stringValue]  forKey:@"DefaultAuthor"];
    
    // create on script change
    [DEFAULTS setBool:[createOnScriptChangeCheckbox state]  forKey:@"CreateOnScriptChange"];
    
    // reveal
    [DEFAULTS setBool:[revealAppCheckbox state]  forKey:@"RevealApplicationWhenCreated"];
    
    // open
    [DEFAULTS setBool:[openAppCheckbox state]  forKey:@"OpenApplicationWhenCreated"];
    [DEFAULTS synchronize];
    [[self window] close];
}

- (IBAction)cancel:(id)sender {
    [[self window] close];
}

/*****************************************
 - Restore prefs to their default value
 *****************************************/

- (IBAction)restoreDefaultPrefs:(id)sender {
    [revealAppCheckbox setState:NO];
    [openAppCheckbox setState:NO];
    [createOnScriptChangeCheckbox setState:NO];
    [defaultEditorPopupButton setTitle:DEFAULT_EDITOR];
    [defaultTextEncodingPopupButton selectItemWithTag:DEFAULT_OUTPUT_TXT_ENCODING];
    [defaultAuthorTextField setStringValue:NSFullUserName()];
    
    // create default bundle identifier prefix string
    NSString *bundleId = [NSString stringWithFormat:@"org.%@.", NSUserName()];
    bundleId = [bundleId stringByReplacingOccurrencesOfString:@" " withString:@""];
    [defaultBundleIdentifierTextField setStringValue:bundleId];
    [DEFAULTS synchronize];
}

/*****************************************
 - For selecting any application as the external editor for script
 *****************************************/

- (IBAction)selectScriptEditor:(id)sender {
    //create open panel
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setTitle:@"Select Editor"];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setAllowedFileTypes:[NSArray arrayWithObject:@"app"]];

    //run open panel
    if ([oPanel runModal] == NSOKButton) {
        //set app name minus .app suffix
        NSString *filePath = [[[oPanel URLs] objectAtIndex:0] path];
        NSString *editorName = [[filePath lastPathComponent] stringByDeletingPathExtension];
        [defaultEditorPopupButton setTitle:editorName];
        [self setIconsForEditorMenu];
    } else {
        [defaultEditorPopupButton setTitle:[DEFAULTS stringForKey:@"DefaultEditor"]];
    }
}

/*****************************************
 - Update report on command line tool install status
 -- both text field and button
 *****************************************/

- (void)updateCLTStatus:(NSTextField *)textField {
    //set status of clt install button and text field
    if ([self isCommandLineToolInstalled]) {
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

/*****************************************
 - Install/uninstall CLT based on install status
 *****************************************/

- (IBAction)installCLT:(id)sender {
    [self isCommandLineToolInstalled] == NO ? [self installCommandLineTool] : [self uninstallCommandLineTool];
}

/*****************************************
 - Run install script for CLT stuff
 *****************************************/

- (void)installCommandLineTool {
    [self runCLTTemplateScript:@"InstallCommandLineTool.sh" usingDictionary:[self commandLineEnvDict]];
}

- (NSDictionary *)commandLineEnvDict
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            PROGRAM_NAME, @"PROGRAM_NAME",
            PROGRAM_VERSION, @"PROGRAM_VERSION",
            PROGRAM_STAMP, @"PROGRAM_STAMP",
            PROGRAM_MIN_SYS_VERSION, @"PROGRAM_MIN_SYS_VERSION",
            PROGRAM_BUNDLE_IDENTIFIER, @"PROGRAM_BUNDLE_IDENTIFIER",
            PROGRAM_AUTHOR, @"PROGRAM_AUTHOR",
            CMDLINE_PROGNAME_IN_BUNDLE, @"CMDLINE_PROGNAME_IN_BUNDLE",
            CMDLINE_PROGNAME, @"CMDLINE_PROGNAME",
            CMDLINE_SCRIPTEXEC_BIN_NAME, @"CMDLINE_SCRIPTEXEC_BIN_NAME",
            CMDLINE_DEFAULT_ICON_NAME, @"CMDLINE_DEFAULT_ICON_NAME",
            CMDLINE_NIB_NAME, @"CMDLINE_NIB_NAME",
            CMDLINE_BASE_INSTALL_PATH, @"CMDLINE_BASE_INSTALL_PATH",
            CMDLINE_BIN_PATH, @"CMDLINE_BIN_PATH",
            CMDLINE_TOOL_PATH, @"CMDLINE_TOOL_PATH",
            CMDLINE_SHARE_PATH, @"CMDLINE_SHARE_PATH",
            CMDLINE_VERSION_PATH, @"CMDLINE_VERSION_PATH",
            CMDLINE_MANDIR_PATH, @"CMDLINE_MANDIR_PATH",
            CMDLINE_MANPAGE_PATH, @"CMDLINE_MANPAGE_PATH",
            CMDLINE_EXEC_PATH, @"CMDLINE_EXEC_PATH",
            CMDLINE_NIB_PATH, @"CMDLINE_NIB_PATH",
            CMDLINE_SCRIPT_EXEC_PATH, @"CMDLINE_SCRIPT_EXEC_PATH",
            CMDLINE_ICON_PATH, @"CMDLINE_ICON_PATH", nil];
}

/*****************************************
 - Run UNinstall script for CLT stuff
 *****************************************/

- (void)uninstallCommandLineTool {
    [self runCLTTemplateScript:@"UninstallCommandLineTool.sh" usingDictionary:[self commandLineEnvDict]];
}

- (IBAction)uninstallPlatypus:(id)sender {
    if ([Alerts proceedAlert:@"Are you sure you want to uninstall Platypus?"
                     subText:@"This will move the Platypus application and all related files to the Trash.  The application will then quit."
                  withAction:@"Uninstall"] == YES) {
        [self runCLTTemplateScript:@"UninstallPlatypus.sh" usingDictionary:[self commandLineEnvDict]];
        [[NSApplication sharedApplication] terminate:self];
    }
}

/*****************************************
 - Run a script with privileges from the Resources folder
 *****************************************/

- (void)runCLTTemplateScript:(NSString *)scriptName usingDictionary:(NSDictionary *)placeholderDict {
    [installCLTProgressIndicator setUsesThreadedAnimation:YES];
    [installCLTProgressIndicator startAnimation:self];
    [self executeScriptTemplateWithPrivileges:scriptName usingDictionary:placeholderDict];
    [self updateCLTStatus:CLTStatusTextField];
    [installCLTProgressIndicator stopAnimation:self];
}

/*****************************************
 - Determine whether command line tool is installed
 *****************************************/

- (BOOL)isCommandLineToolInstalled {
    return ([FILEMGR fileExistsAtPath:CMDLINE_VERSION_PATH] &&
            [FILEMGR fileExistsAtPath:CMDLINE_TOOL_PATH] &&
            [FILEMGR fileExistsAtPath:CMDLINE_MANPAGE_PATH] &&
            [FILEMGR fileExistsAtPath:CMDLINE_EXEC_PATH] &&
            [FILEMGR fileExistsAtPath:CMDLINE_ICON_PATH]);
}

/*****************************************
 - Run script with privileges using Authentication Manager
 *****************************************/
- (void)executeScriptTemplateWithPrivileges:(NSString *)scriptName usingDictionary:(NSDictionary *)placeholderDict {
    
    NSString *script = [[NSBundle mainBundle] loadTemplate:scriptName usingDictionary:placeholderDict];
    NSString *tmpScriptPath = [WORKSPACE createTempFileWithContents:script usingTextEncoding:NSUTF8StringEncoding];
    chmod([tmpScriptPath cStringUsingEncoding:NSUTF8StringEncoding], S_IRWXU | S_IRWXG | S_IROTH); // 744
    
    // execute path, pass Resources directory and version as arguments 1 and 2
    [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:tmpScriptPath arguments:[NSArray arrayWithObjects:[[NSBundle mainBundle] resourcePath], PROGRAM_VERSION, nil]];
    
    //[FILEMGR removeItemAtPath:tmpScriptPath error:nil];
}

@end
