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

#import "ProfilesController.h"
#import "PlatypusAppSpec.h"
#import "PlatypusWindowController.h"
#import "Common.h"
#import "Alerts.h"

#define EXAMPLES_TAG 7

@interface ProfilesController()
{
    IBOutlet NSMenu *profilesMenu;
    IBOutlet PlatypusWindowController *platypusController;
    IBOutlet NSMenuItem *examplesMenuItem;
    
    NSInteger numNonDynamicMenuitems;
}

- (IBAction)loadProfile:(id)sender;
- (IBAction)saveProfile:(id)sender;
- (IBAction)clearAllProfiles:(id)sender;
- (IBAction)constructMenus:(id)sender;

@end

@implementation ProfilesController

- (void)awakeFromNib {
    numNonDynamicMenuitems = [profilesMenu numberOfItems];
}

#pragma mark - Loading

- (IBAction)loadProfile:(id)sender {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setAllowedFileTypes:@[PROGRAM_PROFILE_SUFFIX, PROGRAM_PROFILE_UTI]];
    [oPanel setDirectoryURL:[NSURL fileURLWithPath:PROGRAM_PROFILES_PATH]];
    
    if ([oPanel runModal] == NSOKButton) {
        NSString *filePath = [[oPanel URLs][0] path];
        [self loadProfileAtPath:filePath];
    }
}

- (void)loadProfileAtPath:(NSString *)filePath {
    PlatypusAppSpec *spec = [[PlatypusAppSpec alloc] initWithProfile:filePath];
    
    // Make sure we got a spec from the file
    if (spec == nil) {
        [Alerts alert:@"Error loading profile"
        subTextFormat:@"Unable to load %@ profile at path '%@'.", PROGRAM_NAME, filePath];
        return;
    }
    
    // Note it as a recently opened file
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:filePath]];
    
    // Check if it's an example
    if (spec[AppSpecKey_IsExample] != nil && [spec[AppSpecKey_IsExample] boolValue] == YES) {
        
        // Check the example profile's integrity
        NSString *scriptStr = spec[AppSpecKey_ScriptText];
        NSString *scriptName = spec[AppSpecKey_ScriptName];
        if (scriptStr == nil || scriptName == nil) {
            [Alerts alert:@"Error loading example"
            subTextFormat:@"Nil %@ or %@ in profile dictionary.", AppSpecKey_ScriptText, AppSpecKey_ScriptName];
            return;
        }
        
        scriptStr = [scriptStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // Write script text in the example profile to file and set as script path
        NSString *scriptPath = [NSString stringWithFormat:@"%@%@", PROGRAM_TEMPDIR_PATH, scriptName];
        NSError *err;
        BOOL succ = [scriptStr writeToFile:scriptPath atomically:YES encoding:DEFAULT_TEXT_ENCODING error:&err];
        if (succ == NO) {
            [Alerts alert:@"Error writing script to file" subTextFormat:@"%@", [err localizedDescription]];
            return;
        }

        spec[AppSpecKey_ScriptPath] = scriptPath;
    }
    
    // Let's keep this code around if we ever want to use it:
    // Warn if created with a different version of Platypus
//    	if ([spec[AppSpecKey_Creator] isEqualToString:PROGRAM_CREATOR_STAMP] == NO) {
//    		[Alerts alert:@"Version clash"
//                  subText: @"Profile was created with a different version of Platypus and may not load correctly."];
//        }
    [platypusController controlsFromAppSpec:spec];
}

#pragma mark - Saving

- (IBAction)saveProfile:(id)sender {
    if ([platypusController verifyFieldContents] == NO) {
        return;
    }
    
    // Get spec from platypus controls
    PlatypusAppSpec *spec = [platypusController appSpecFromControls];
    NSString *defaultName = [NSString stringWithFormat:@"%@.%@", spec[AppSpecKey_Name], PROGRAM_PROFILE_SUFFIX];
    
    NSSavePanel *sPanel = [NSSavePanel savePanel];
    [sPanel setTitle:[NSString stringWithFormat:@"Save %@ Profile", PROGRAM_NAME]];
    [sPanel setPrompt:@"Save"];
    [sPanel setDirectoryURL:[NSURL fileURLWithPath:PROGRAM_PROFILES_PATH]];
    [sPanel setNameFieldStringValue:defaultName];
    
    if ([sPanel runModal] == NSFileHandlingPanelOKButton) {
        NSString *filePath = [[sPanel URL] path];
        if ([filePath hasSuffix:PROGRAM_PROFILE_SUFFIX] == NO) {
            filePath = [NSString stringWithFormat:@"%@.%@", filePath, PROGRAM_PROFILE_SUFFIX];
        }
        [spec writeToFile:filePath];
        [self constructMenus:self];
    }
}

#pragma mark - Menu

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    if (([[anItem title] isEqualToString:@"Clear All Profiles"] && [[self readProfilesList] count] < 1) ||
        [[anItem title] isEqualToString:@"Empty"]) {
        return NO;
    }
    return YES;
}

- (void)menuWillOpen:(NSMenu *)menu {
    [self constructMenus:self];
}

- (IBAction)constructMenus:(id)sender {
    NSArray *profiles = [self readProfilesList];
    NSArray *examples = [self readExamplesList];
    
    // Create icon
    NSImage *icon = [NSImage imageNamed:@"PlatypusProfile"];
    [icon setSize:NSMakeSize(16, 16)];
    
    // Create Examples menu
    NSMenu *examplesMenu = [[NSMenu alloc] init];
    
    for (NSString *exampleName in examples) {
        NSMenuItem *menuItem = [examplesMenu addItemWithTitle:[exampleName stringByDeletingPathExtension]
                                                       action:@selector(profileMenuItemSelected:)
                                                keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setEnabled:YES];
        [menuItem setImage:icon];
        [menuItem setTag:EXAMPLES_TAG];
    }
    [examplesMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *examplesFolderItem = [examplesMenu addItemWithTitle:@"Open Examples Folder"
                                                             action:@selector(openExamplesFolder)
                                                      keyEquivalent:@""];
    [examplesFolderItem setTarget:self];
    [examplesFolderItem setEnabled:YES];
    
    [examplesMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *createExamplesMenu = [examplesMenu addItemWithTitle:@"Build All Examples"
                                                             action:@selector(buildAllExamples)
                                                      keyEquivalent:@""];
    [createExamplesMenu setTarget:self];
    [createExamplesMenu setEnabled:YES];
    
    [examplesMenuItem setSubmenu:examplesMenu];
    
    // Clear out all menu items
    while ([profilesMenu numberOfItems] > numNonDynamicMenuitems) {
        [profilesMenu removeItemAtIndex:numNonDynamicMenuitems];
    }
    
    if ([profiles count] > 0) {
        for (NSString *profileName in profiles) {
            NSMenuItem *menuItem = [profilesMenu addItemWithTitle:[profileName stringByDeletingPathExtension]
                                                           action:@selector(profileMenuItemSelected:)
                                                    keyEquivalent:@""];
            [menuItem setTarget:self];
            [menuItem setEnabled:YES];
            [menuItem setImage:icon];
        }
        
        [profilesMenu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *menuItem = [profilesMenu addItemWithTitle:@"Open Profiles Folder"
                                                       action:@selector(openProfilesFolder)
                                                keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setEnabled:YES];
        
    } else {
        [profilesMenu addItemWithTitle:@"Empty" action:nil keyEquivalent:@""];
    }
}

#pragma mark - Menu actions

- (void)profileMenuItemSelected:(id)sender {
    BOOL isExample = ([sender tag]  == EXAMPLES_TAG);
    NSString *folder = isExample ? PROGRAM_EXAMPLES_PATH : PROGRAM_PROFILES_PATH;
    NSString *profilePath = [NSString stringWithFormat:@"%@/%@.%@", folder, [sender title], PROGRAM_PROFILE_SUFFIX];
    
    // If command key is down, we reveal in finder
    BOOL commandKeyDown = (([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask);
    if (commandKeyDown) {
        [WORKSPACE selectFile:profilePath inFileViewerRootedAtPath:profilePath];
    } else {
        [self loadProfileAtPath:profilePath];
    }
}

- (IBAction)clearAllProfiles:(id)sender {
    if ([Alerts proceedAlert:@"Delete all profiles?"
                     subText:@"This will permanently delete all profiles in your Profiles folder."
             withActionNamed:@"Delete"] == NO) {
        return;
    }
    
    // Delete all .platypus files in Profiles folder
    NSDirectoryEnumerator *dirEnumerator = [FILEMGR enumeratorAtPath:PROGRAM_PROFILES_PATH];
    NSString *filename;
    while ((filename = [dirEnumerator nextObject]) != nil) {
        if ([filename hasSuffix:PROGRAM_PROFILE_SUFFIX]) {
            NSString *path = [NSString stringWithFormat:@"%@/%@", PROGRAM_PROFILES_PATH, filename];
            if ([FILEMGR isDeletableFileAtPath:path] == NO) {
                [Alerts alert:@"Error deleting profile" subTextFormat:@"Unable to delete file '%@'.", path];
            } else {
                [FILEMGR removeItemAtPath:path error:nil];
            }
        }
    }
    
    [self constructMenus:self];
}

- (void)openProfilesFolder {
    [WORKSPACE selectFile:nil inFileViewerRootedAtPath:PROGRAM_PROFILES_PATH];
}

- (void)openExamplesFolder {
    [WORKSPACE selectFile:nil inFileViewerRootedAtPath:PROGRAM_EXAMPLES_PATH];
}

- (void)buildAllExamples {
    NSSavePanel *sPanel = [NSSavePanel savePanel];
    [sPanel setTitle:@"Create Example Apps"];
    [sPanel setPrompt:@"Create"];
    [sPanel setNameFieldStringValue:@"App Examples Folder"];
    
    if ([sPanel runModal] != NSFileHandlingPanelOKButton) {
        return;
    }
    
    // Create folder
    NSString *outFolderPath = [[sPanel URL] path];
    NSError *err;
    if (![FILEMGR createDirectoryAtPath:outFolderPath withIntermediateDirectories:NO attributes:nil error:&err]) {
        [Alerts alert:@"Unable to create directory" subText:[err localizedDescription]];
        return;
    }

    // Run make examples script
    NSString *examplesFolderPath = [[NSBundle mainBundle] pathForResource:@"Examples" ofType:nil];
    NSString *platypusToolPath = [[NSBundle mainBundle] pathForResource:@"platypus_clt" ofType:nil];
    NSString *buildScriptPath = [[NSBundle mainBundle] pathForResource:@"make_examples.pl" ofType:nil];
    
    [NSTask launchedTaskWithLaunchPath:@"/usr/bin/perl"
                             arguments:@[buildScriptPath,
                                         examplesFolderPath,
                                         outFolderPath,
                                         platypusToolPath]];
}

#pragma mark -

- (NSArray *)readProfilesList {
    return [self profilesInFolder:PROGRAM_PROFILES_PATH];
}

- (NSArray *)readExamplesList {
    return [self profilesInFolder:PROGRAM_EXAMPLES_PATH];
}

- (NSArray *)profilesInFolder:(NSString *)folderPath {
    NSMutableArray *arr = [NSMutableArray array];
    NSDirectoryEnumerator *dirEnumerator = [FILEMGR enumeratorAtPath:folderPath];
    NSString *filename;
    while ((filename = [dirEnumerator nextObject]) != nil) {
        if ([filename hasSuffix:PROGRAM_PROFILE_SUFFIX]) {
            [arr addObject:filename];
        }
    }
    return arr;
}

@end
