/*
Copyright (c) 2003-2015, Sveinbjorn Thordarson <sveinbjornt@gmail.com
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of the FreeBSD Project.
 */

#import "PrefsController.h"

@implementation PrefsController

/*****************************************
 - Set controls according to data in NSUserDefaults
 *****************************************/

- (IBAction)showWindow:(id)sender {
    [super loadWindow];
    
    // set controls according to NSUserDefaults
    [defaultEditorMenu setTitle:[DEFAULTS stringForKey:@"DefaultEditor"]];
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
    int i;
    NSSize smallIconSize = { 16, 16 };
    
    for (i = 0; i < [defaultEditorMenu numberOfItems]; i++) {
        if ([[[defaultEditorMenu itemAtIndex:i] title] isEqualToString:DEFAULT_EDITOR] == YES) {
            NSImage *icon = [NSImage imageNamed:@"PlatypusAppIcon"];
            [icon setSize:smallIconSize];
            [[defaultEditorMenu itemAtIndex:i] setImage:icon];
        }
        else if ([[[defaultEditorMenu itemAtIndex:i] title] isEqualToString:@"Select..."] == NO && [[[defaultEditorMenu itemAtIndex:i] title] length] > 0) {
            NSImage *icon = [NSImage imageNamed:@"NSDefaultApplicationIcon"];
            NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:[[defaultEditorMenu itemAtIndex:i] title]];
            if (appPath != NULL) // app found
                icon = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
            [icon setSize:smallIconSize];
            [[defaultEditorMenu itemAtIndex:i] setImage:icon];
        }
    }
}

/*****************************************
 - Set NSUserDefaults according to control settings
 *****************************************/

- (IBAction)applyPrefs:(id)sender {
    // editor
    [DEFAULTS setObject:[defaultEditorMenu titleOfSelectedItem]  forKey:@"DefaultEditor"];
    
    // text encoding
    [DEFAULTS setObject:[NSNumber numberWithInt:[[defaultTextEncodingPopupButton selectedItem] tag]]  forKey:@"DefaultTextEncoding"];
    
    //bundle identifier
    //make sure bundle identifier ends with a '.'
    if ([[defaultBundleIdentifierTextField stringValue] characterAtIndex:[[defaultBundleIdentifierTextField stringValue]length] - 1] != '.')
        [DEFAULTS setObject:[[defaultBundleIdentifierTextField stringValue] stringByAppendingString:@"."]  forKey:@"DefaultBundleIdentifierPrefix"];
    else
        [DEFAULTS setObject:[defaultBundleIdentifierTextField stringValue]  forKey:@"DefaultBundleIdentifierPrefix"];
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
    [defaultEditorMenu setTitle:DEFAULT_EDITOR];
    [defaultTextEncodingPopupButton selectItemWithTag:DEFAULT_OUTPUT_TXT_ENCODING];
    [defaultAuthorTextField setStringValue:NSFullUserName()];
    
    // create default bundle identifier prefix string
    NSString *bundleId = [NSString stringWithFormat:@"org.%@.", NSUserName()];
    bundleId = [[bundleId componentsSeparatedByString:@" "] componentsJoinedByString:@""]; //remove all spaces
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
        [defaultEditorMenu setTitle:editorName];
        [self setIconsForEditorMenu];
    }
    else {
        [defaultEditorMenu setTitle:[DEFAULTS stringForKey:@"DefaultEditor"]];
    }
}

/*****************************************
 - Update report on command line tool install status
 -- both text field and button
 *****************************************/

- (void)updateCLTStatus:(NSTextField *)textField {
    //set status of clt install button and text field
    if ([self isCommandLineToolInstalled]) {
        NSString *versionString = [NSString stringWithContentsOfFile:CMDLINE_VERSION_PATH encoding:NSUTF8StringEncoding error:NULL];
        if ([versionString length] > 3 && [versionString characterAtIndex:3] == '\n')
            versionString = [versionString substringToIndex:3];
        
        if ([versionString isEqualToString:PROGRAM_VERSION]) { // it's installed and current
            [textField setTextColor:[NSColor colorWithCalibratedRed:0.0 green:0.6 blue:0.0 alpha:1.0]];
            [textField setStringValue:@"Command line tool is installed"];
        }
        else { // installed but not this version
            [textField setTextColor:[NSColor orangeColor]];
            
            if ([versionString floatValue] < [PROGRAM_VERSION floatValue])
                [textField setStringValue:@"Old version of command line"];  //older
            else
                [textField setStringValue:@"Newer version of command line"];  //newer
        }
        [installCLTButton setTitle:@"Uninstall"];
    }
    else { // it's not installed at all
        [textField setStringValue:@"Command line tool is not installed"];
        [textField setTextColor:[NSColor redColor]];
        [installCLTButton setTitle:@"Install"];
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

- (void)installCommandLineTool {
    [self runCLTScript:@"InstallCommandLineTool.sh"];
}

/*****************************************
 - Run UNinstall script for CLT stuff
 *****************************************/

- (void)uninstallCommandLineTool {
    [self runCLTScript:@"UninstallCommandLineTool.sh"];
}

- (IBAction)uninstallPlatypus:(id)sender {
    if ([PlatypusUtility proceedWarning:@"Are you sure you want to uninstall Platypus?" subText:@"This will move the Platypus application and all related files to the Trash.  The application will then quit." withAction:@"Uninstall"]) {
        [self runCLTScript:@"UninstallPlatypus.sh"];
        [[NSApplication sharedApplication] terminate:self];
    }
}

/*****************************************
 - Run a script with privileges from the Resources folder
 *****************************************/

- (void)runCLTScript:(NSString *)scriptName {
    [installCLTProgressIndicator setUsesThreadedAnimation:YES];
    [installCLTProgressIndicator startAnimation:self];
    [self executeScriptWithPrivileges:[[NSBundle mainBundle] pathForResource:scriptName ofType:NULL]];
    [self updateCLTStatus:CLTStatusTextField];
    [installCLTProgressIndicator stopAnimation:self];
}

/*****************************************
 - Determine whether command line tool is installed
 *****************************************/

- (BOOL)isCommandLineToolInstalled {
    return     ([FILEMGR fileExistsAtPath:CMDLINE_VERSION_PATH] &&
                [FILEMGR fileExistsAtPath:CMDLINE_TOOL_PATH] &&
                [FILEMGR fileExistsAtPath:CMDLINE_MANPAGE_PATH] &&
                [FILEMGR fileExistsAtPath:CMDLINE_EXEC_PATH] &&
                [FILEMGR fileExistsAtPath:CMDLINE_ICON_PATH]);
}

/*****************************************
 - Run script with privileges using Authentication Manager
 *****************************************/
- (void)executeScriptWithPrivileges:(NSString *)pathToScript {
    // execute path, pass Resources directory and version as arguments 1 and 2
    [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:pathToScript arguments:[NSArray arrayWithObjects:[[NSBundle mainBundle] resourcePath], PROGRAM_VERSION, nil]];
}

@end
