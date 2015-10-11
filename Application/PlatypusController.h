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

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

#import "Common.h"

#import "PlatypusAppSpec.h"
#import "ScriptAnalyser.h"

#import "IconController.h"
#import "ArgsController.h"
#import "ProfilesController.h"
#import "PrefsController.h"
#import "TextSettingsController.h"
#import "StatusItemSettingsController.h"
#import "EditorController.h"
#import "ShellCommandController.h"

#import "DropSettingsController.h"
#import "SuffixListController.h"

#import "PlatypusUtility.h"
#import "STPathTextField.h"
#import "BundledFilesController.h"
#import "NSColor+HexTools.h"

#import "IconFamily.h"
#import "UKKQueue.h"

@class ProfilesController, StatusItemSettingsController, IconController;
@interface PlatypusController : NSObject
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
    
    //progress bar for creating
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
}

- (IBAction)newScript:(id)sender;
- (NSString *)createNewScript:(NSString *)scriptText;
- (IBAction)revealScript:(id)sender;
- (IBAction)editScript:(id)sender;
- (IBAction)runScriptInTerminal:(id)sender;
- (IBAction)checkSyntaxOfScript:(id)sender;
- (void)openScriptInBuiltInEditor:(NSString *)path;

- (IBAction)createButtonPressed:(id)sender;
- (void)createConfirmed:(NSSavePanel *)sPanel returnCode:(int)result;
- (BOOL)createApplicationFromTimer:(NSTimer *)theTimer;
- (BOOL)createApplication:(NSString *)destination;

- (id)appSpecFromControls;
- (void)controlsFromAppSpec:(id)spec;

- (BOOL)verifyFieldContents;
- (IBAction)scriptTypeSelected:(id)sender;
- (void)selectScriptTypeBasedOnInterpreter;
- (void)setScriptType:(NSString *)type;
- (IBAction)selectScript:(id)sender;
- (void)loadScript:(NSString *)filename;
- (IBAction)isDroppableWasClicked:(id)sender;
- (IBAction)outputTypeWasChanged:(id)sender;
- (IBAction)clearAllFields:(id)sender;
- (IBAction)showCommandLineString:(id)sender;
- (void)updateEstimatedAppSize;
- (NSString *)estimatedAppSize;
- (NSTask *)taskForCurrentScript;
- (NSWindow *)window;

//Help
- (IBAction)showHelp:(id)sender;
- (IBAction)showReadme:(id)sender;
- (IBAction)showManPage:(id)sender;
- (IBAction)openWebsite:(id)sender;
- (IBAction)openLicense:(id)sender;
- (IBAction)openDonations:(id)sender;


@end
