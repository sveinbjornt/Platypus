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

@implementation ProfilesController

/*****************************************
 - Select file dialog for .platypus profile
 *****************************************/

- (IBAction)loadProfile:(id)sender {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setPrompt:@"Open"];
    [oPanel setTitle:[NSString stringWithFormat:@"Select %@ Profile", PROGRAM_NAME]];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setAllowedFileTypes:[NSArray arrayWithObject:@"platypus"]];
    [oPanel setDirectoryURL:[NSURL fileURLWithPath:[PROFILES_FOLDER stringByExpandingTildeInPath]]];
    
    if ([oPanel runModal] == NSOKButton) {
        NSString *filePath = [[[oPanel URLs] objectAtIndex:0] path];
        [self loadProfileFile:filePath];
    }
}

/*****************************************
 - Deal with dropped .platypus profile files
 *****************************************/

- (void)loadProfileFile:(NSString *)file {
    // note it as a recently opened file
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:file]];
    
    PlatypusAppSpec *spec = [[PlatypusAppSpec alloc] initWithProfile:file];
    
    // make sure we got a spec from the file
    if (spec == nil) {
        [Alerts alert:@"Error" subText:@"Unable to create Platypus spec from profile"];
        return;
    }
    
    // check if it's an example
    if ([spec propertyForKey:@"Example"] != nil) {
        // make sure of the example profile's integrity
        NSString *scriptStr = [spec propertyForKey:@"Script"];
        NSString *scriptName = [spec propertyForKey:@"ScriptName"];
        if (scriptStr == nil || scriptName == nil) {
            [Alerts alert:@"Error loading example" subText:@"Nil script value(s) in this example's profile dictionary."];
            [spec release];
            return;
        }
        
        scriptStr = [scriptStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // write script contained in the example profile dictionary to file
        NSString *scriptPath = [[NSString stringWithFormat:@"%@%@", TEMP_FOLDER, scriptName] stringByExpandingTildeInPath];
        [scriptStr writeToFile:scriptPath atomically:YES encoding:DEFAULT_OUTPUT_TXT_ENCODING error:nil];
        
        // set this path as the source script path
        [spec setProperty:scriptPath forKey:@"ScriptPath"];
    }
    
    // warn if created with a different version of Platypus
    //	if (![[spec propertyForKey: @"Creator"] isEqualToString: PROGRAM_STAMP])
    //		[PlatypusUtility alert:@"Version clash" subText: @"The profile you selected was created with a different version of Platypus and may not load correctly."];
    
    [platypusController controlsFromAppSpec:spec];
    [spec release];
}

/*****************************************
 - Save a profile with values from fields 
   in default location
 *****************************************/

- (IBAction)saveProfile:(id)sender;
{
    if (![platypusController verifyFieldContents])
        return;
    
    // get profile from platypus controls
    NSDictionary *profileDict = [[platypusController appSpecFromControls] properties];
    
    // create path for profile file and write to it
    NSString *profileDestPath = [NSString stringWithFormat:@"%@/%@.%@",
                                 [PROFILES_FOLDER stringByExpandingTildeInPath],
                                 [profileDict objectForKey:@"Name"],
                                 PROFILES_SUFFIX];
    [self writeProfile:profileDict toFile:profileDestPath];
}

/*****************************************
 - Save a profile with in user-specified 
   location
 *****************************************/

- (IBAction)saveProfileToLocation:(id)sender;
{
    if (![platypusController verifyFieldContents]) {
        return;
    }
    
    // get profile from platypus controls
    NSDictionary *profileDict = [[platypusController appSpecFromControls] properties];
    NSString *defaultName = [NSString stringWithFormat:@"%@.%@", [profileDict objectForKey:@"Name"], PROFILES_SUFFIX];
    
    NSSavePanel *sPanel = [NSSavePanel savePanel];
    [sPanel setTitle:[NSString stringWithFormat:@"Save %@ Profile", PROGRAM_NAME]];
    [sPanel setPrompt:@"Save"];
    [sPanel setDirectoryURL:[NSURL fileURLWithPath:[PROFILES_FOLDER stringByExpandingTildeInPath]]];
    [sPanel setNameFieldStringValue:defaultName];
    
    if ([sPanel runModal] == NSFileHandlingPanelOKButton) {
        NSString *fileName = [[sPanel URL] path];
        if (![fileName hasSuffix:PROFILES_SUFFIX]) {
            fileName = [NSString stringWithFormat:@"%@.%@", fileName, PROFILES_SUFFIX];
        }
        [self writeProfile:profileDict toFile:fileName];
    }    
}


/*****************************************
 - Write profile dictionary to path
 *****************************************/

- (void)writeProfile:(NSDictionary *)dict toFile:(NSString *)profileDestPath;
{
    // if there's a file already, make sure we can overwrite
    if ([FILEMGR fileExistsAtPath:profileDestPath] && ![FILEMGR isDeletableFileAtPath:profileDestPath]) {
        [Alerts alert:@"Error" subText:[NSString stringWithFormat:@"Cannot overwrite file '%@'.", profileDestPath]];
        return;
    }
    [dict writeToFile:profileDestPath atomically:YES];
    [self constructMenus:self];
}


/*****************************************
 - Fill Platypus fields in with data from 
   profile when it's selected in the menu
 *****************************************/

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
        [self loadProfileFile:profilePath];
    }
}

/*****************************************
 - Clear the profiles list
 *****************************************/

- (IBAction)clearAllProfiles:(id)sender {
    if ([Alerts proceedAlert:@"Delete all profiles?" subText:@"This will permanently delete all profiles in your Profiles folder." withAction:@"Delete"] == NO) {
        return;
    }
    
    //delete all .platypus files in PROFILES_FOLDER
    
    NSFileManager *manager = FILEMGR;
    NSDirectoryEnumerator *dirEnumerator = [manager enumeratorAtPath:[PROFILES_FOLDER stringByExpandingTildeInPath]];
    NSString *filename;
    
    while ((filename = [dirEnumerator nextObject]) != nil) {
        if ([filename hasSuffix:PROFILES_SUFFIX]) {
            NSString *path = [NSString stringWithFormat:@"%@/%@", [PROFILES_FOLDER stringByExpandingTildeInPath], filename];
            if (![manager isDeletableFileAtPath:path]) {
                [Alerts alert:@"Error" subText:[NSString stringWithFormat:@"Cannot delete file %@.", path]];
            } else {
                [manager removeItemAtPath:path error:nil];
            }
        }
    }
    
    //regenerate the menu
    [self constructMenus:self];
}

/*****************************************
 - Generate the Profiles menu according to the save profiles
 *****************************************/

- (IBAction)constructMenus:(id)sender {
    NSArray *profiles = [self getProfilesList];
    NSArray *examples = [self getExamplesList];
    
    // Create icon
    NSImage *icon = [NSImage imageNamed:@"PlatypusProfile"];
    [icon setSize:NSMakeSize(16, 16)];
    
    // Create Examples menu
    NSMenu *examplesMenu = [[[NSMenu alloc] init] autorelease];
    for (int i = 0; i < [examples count]; i++) {
        NSMenuItem *menuItem = [examplesMenu addItemWithTitle:[examples objectAtIndex:i] action:@selector(profileMenuItemSelected:) keyEquivalent:@""];
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
        //populate with contents of array
        for (int i = 0; i < [profiles count]; i++) {
            NSMenuItem *menuItem = [profilesMenu addItemWithTitle:[profiles objectAtIndex:i] action:@selector(profileMenuItemSelected:) keyEquivalent:@""];
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

- (void)openProfilesFolder {
    [WORKSPACE selectFile:nil inFileViewerRootedAtPath:[PROFILES_FOLDER stringByExpandingTildeInPath]];
}

- (void)openExamplesFolder {
    [WORKSPACE selectFile:nil inFileViewerRootedAtPath:[[NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath], PROGRAM_EXAMPLES_FOLDER] stringByExpandingTildeInPath]];
}



/*****************************************
 - Get list of .platypus files in Profiles folder
 *****************************************/

- (NSArray *)getProfilesList {
    NSMutableArray *profilesArray = [NSMutableArray array];
    NSDirectoryEnumerator *dirEnumerator = [FILEMGR enumeratorAtPath:[PROFILES_FOLDER stringByExpandingTildeInPath]];
    NSString *filename;
    while ((filename = [dirEnumerator nextObject]) != nil) {
        if ([filename hasSuffix:PROFILES_SUFFIX]) {
            [profilesArray addObject:filename];
        }
    }
    return profilesArray;
}

- (NSArray *)getExamplesList {
    NSMutableArray *examplesArray = [NSMutableArray array];
    NSDirectoryEnumerator *dirEnumerator = [FILEMGR enumeratorAtPath:[NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath], PROGRAM_EXAMPLES_FOLDER]];
    NSString *filename;
    while ((filename = [dirEnumerator nextObject]) != nil) {
        if ([filename hasSuffix:PROFILES_SUFFIX]) {
            [examplesArray addObject:filename];
        }
    }
    return examplesArray;
}

/*****************************************
 - Profile menu item validation
 *****************************************/

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    if (([[anItem title] isEqualToString:@"Clear All Profiles"] && [[self getProfilesList] count] < 1) ||
        [[anItem title] isEqualToString:@"Empty"]) {
        return NO;
    }
    return YES;
}

- (void)menuWillOpen:(NSMenu *)menu {
    // we do this lazily
    [self constructMenus:self];
}

@end
