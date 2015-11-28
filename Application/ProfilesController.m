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

#import "ProfilesController.h"
#import "PlatypusAppSpec.h"
#import "PlatypusController.h"
#import "Common.h"
#import "Alerts.h"

#define EXAMPLES_TAG 7

@interface ProfilesController()
{
    IBOutlet NSMenu *profilesMenu;
    IBOutlet PlatypusController *platypusController;
    IBOutlet NSMenuItem *examplesMenuItem;
}

- (IBAction)loadProfile:(id)sender;
- (IBAction)saveProfile:(id)sender;
- (IBAction)saveProfileToLocation:(id)sender;
- (IBAction)clearAllProfiles:(id)sender;
- (IBAction)constructMenus:(id)sender;

@end

@implementation ProfilesController

#pragma mark - Loading

- (IBAction)loadProfile:(id)sender {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setAllowedFileTypes:@[PROGRAM_PROFILE_SUFFIX, PROGRAM_PROFILE_UTI]];
    [oPanel setDirectoryURL:[NSURL fileURLWithPath:[PROFILES_FOLDER stringByExpandingTildeInPath]]];
    
    if ([oPanel runModal] == NSOKButton) {
        NSString *filePath = [[oPanel URLs][0] path];
        [self loadProfileAtPath:filePath];
    }
}

- (void)loadProfileAtPath:(NSString *)file {
    // note it as a recently opened file
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:file]];
    
    PlatypusAppSpec *spec = [[PlatypusAppSpec alloc] initWithProfile:file];
    
    // make sure we got a spec from the file
    if (spec == nil) {
        [Alerts alert:@"Error" subText:@"Unable to create Platypus spec from profile"];
        return;
    }
    
    // check if it's an example
    if (spec[@"Example"] != nil) {
        // make sure of the example profile's integrity
        NSString *scriptStr = spec[@"Script"];
        NSString *scriptName = spec[@"ScriptName"];
        if (scriptStr == nil || scriptName == nil) {
            [Alerts alert:@"Error loading example" subText:@"Nil script value(s) in this example's profile dictionary."];
            [spec release];
            return;
        }
        
        scriptStr = [scriptStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // write script contained in the example profile dictionary to file and set as script path
        NSString *scriptPath = [[NSString stringWithFormat:@"%@%@", TEMP_FOLDER, scriptName] stringByExpandingTildeInPath];
        [scriptStr writeToFile:scriptPath atomically:YES encoding:DEFAULT_OUTPUT_TXT_ENCODING error:nil];
        spec[@"ScriptPath"] = scriptPath;
    }
    
    // warn if created with a different version of Platypus
    //	if (![[spec propertyForKey: @"Creator"] isEqualToString: PROGRAM_STAMP])
    //		[PlatypusUtility alert:@"Version clash" subText: @"The profile you selected was created with a different version of Platypus and may not load correctly."];
    
    [platypusController controlsFromAppSpec:spec];
    [spec release];
}

#pragma mark - Saving

- (IBAction)saveProfile:(id)sender;
{
    if (![platypusController verifyFieldContents]) {
        return;
    }
    
    // get profile from platypus controls
    PlatypusAppSpec *spec = [platypusController appSpecFromControls];

    // create path for profile file and write to it
    NSString *profileDestPath = [NSString stringWithFormat:@"%@/%@.%@",
                                 [PROFILES_FOLDER stringByExpandingTildeInPath],
                                 spec[@"Name"],
                                 PROGRAM_PROFILE_SUFFIX];
    [spec writeToFile:profileDestPath];
}

- (IBAction)saveProfileToLocation:(id)sender {
    if ([platypusController verifyFieldContents] == NO) {
        return;
    }
    
    // get profile from platypus controls
    PlatypusAppSpec *spec = [platypusController appSpecFromControls];
    NSString *defaultName = [NSString stringWithFormat:@"%@.%@", spec[@"Name"], PROGRAM_PROFILE_SUFFIX];
    
    NSSavePanel *sPanel = [NSSavePanel savePanel];
    [sPanel setTitle:[NSString stringWithFormat:@"Save %@ Profile", PROGRAM_NAME]];
    [sPanel setPrompt:@"Save"];
    [sPanel setDirectoryURL:[NSURL fileURLWithPath:[PROFILES_FOLDER stringByExpandingTildeInPath]]];
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
    // we do this lazily
    [self constructMenus:self];
}

- (IBAction)constructMenus:(id)sender {
    NSArray *profiles = [self readProfilesList];
    NSArray *examples = [self readExamplesList];
    
    // Create icon
    NSImage *icon = [NSImage imageNamed:@"PlatypusProfile"];
    [icon setSize:NSMakeSize(16, 16)];
    
    // Create Examples menu
    NSMenu *examplesMenu = [[[NSMenu alloc] init] autorelease];
    
    for (NSString *exampleName in examples) {
        NSMenuItem *menuItem = [examplesMenu addItemWithTitle:exampleName
                                                       action:@selector(profileMenuItemSelected:)
                                                keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setEnabled:YES];
        [menuItem setImage:icon];
        [menuItem setTag:EXAMPLES_TAG];
    }
    [examplesMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *examplesFolderItem = [examplesMenu addItemWithTitle:@"Open Examples Folder" action:@selector(openExamplesFolder) keyEquivalent:@""];
    [examplesFolderItem setTarget:self];
    [examplesFolderItem setEnabled:YES];
    
    [(NSMenuItem *)examplesMenuItem setSubmenu:examplesMenu];
    
    //clear out all menu items
    while ([profilesMenu numberOfItems] > 6) {
        [profilesMenu removeItemAtIndex:6];
    }
    
    if ([profiles count] > 0) {
        for (NSString *profileName in profiles) {
            NSMenuItem *menuItem = [profilesMenu addItemWithTitle:profileName
                                                           action:@selector(profileMenuItemSelected:)
                                                    keyEquivalent:@""];
            [menuItem setTarget:self];
            [menuItem setEnabled:YES];
            [menuItem setImage:icon];
        }
        
        [profilesMenu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *menuItem = [profilesMenu addItemWithTitle:@"Open Profiles Folder" action:@selector(openProfilesFolder) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setEnabled:YES];
        
    } else {
        [profilesMenu addItemWithTitle:@"Empty" action:nil keyEquivalent:@""];
    }
}

#pragma mark - Menu actions

- (void)profileMenuItemSelected:(id)sender {
    BOOL isExample = ([sender tag]  == EXAMPLES_TAG);
    NSString *folder = PROFILES_FOLDER;
    if (isExample) {
        folder = [NSString stringWithFormat:@"%@/Examples/", [[NSBundle mainBundle] resourcePath]];
    }
    
    NSString *profilePath = [NSString stringWithFormat:@"%@/%@", [folder stringByExpandingTildeInPath], [sender title]];
    
    // if command key is down, we reveal in finder
    BOOL commandKeyDown = (([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask);
    if (commandKeyDown) {
        [WORKSPACE selectFile:profilePath inFileViewerRootedAtPath:profilePath];
    } else {
        [self loadProfileAtPath:profilePath];
    }
}

- (IBAction)clearAllProfiles:(id)sender {
    if ([Alerts proceedAlert:@"Delete all profiles?" subText:@"This will permanently delete all profiles in your Profiles folder." withAction:@"Delete"] == NO) {
        return;
    }
    
    //delete all .platypus files in PROFILES_FOLDER
    NSFileManager *manager = FILEMGR;
    NSDirectoryEnumerator *dirEnumerator = [manager enumeratorAtPath:[PROFILES_FOLDER stringByExpandingTildeInPath]];
    NSString *filename;
    
    while ((filename = [dirEnumerator nextObject]) != nil) {
        if ([filename hasSuffix:PROGRAM_PROFILE_SUFFIX]) {
            NSString *path = [NSString stringWithFormat:@"%@/%@", [PROFILES_FOLDER stringByExpandingTildeInPath], filename];
            if (![manager isDeletableFileAtPath:path]) {
                [Alerts alert:@"Error" subTextFormat:@"Cannot delete file %@.", path];
            } else {
                [manager removeItemAtPath:path error:nil];
            }
        }
    }
    
    [self constructMenus:self];
}

- (void)openProfilesFolder {
    [WORKSPACE selectFile:nil inFileViewerRootedAtPath:[PROFILES_FOLDER stringByExpandingTildeInPath]];
}

- (void)openExamplesFolder {
    [WORKSPACE selectFile:nil inFileViewerRootedAtPath:[[NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath], PROGRAM_EXAMPLES_FOLDER] stringByExpandingTildeInPath]];
}

#pragma mark -

- (NSArray *)readProfilesList {
    NSMutableArray *profilesArray = [NSMutableArray array];
    NSDirectoryEnumerator *dirEnumerator = [FILEMGR enumeratorAtPath:[PROFILES_FOLDER stringByExpandingTildeInPath]];
    NSString *filename;
    while ((filename = [dirEnumerator nextObject]) != nil) {
        if ([filename hasSuffix:PROGRAM_PROFILE_SUFFIX]) {
            [profilesArray addObject:filename];
        }
    }
    return profilesArray;
}

- (NSArray *)readExamplesList {
    NSMutableArray *examplesArray = [NSMutableArray array];
    NSDirectoryEnumerator *dirEnumerator = [FILEMGR enumeratorAtPath:[NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath], PROGRAM_EXAMPLES_FOLDER]];
    NSString *filename;
    while ((filename = [dirEnumerator nextObject]) != nil) {
        if ([filename hasSuffix:PROGRAM_PROFILE_SUFFIX]) {
            [examplesArray addObject:filename];
        }
    }
    return examplesArray;
}

@end
