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
#import "SuffixList.h"

#import "PlatypusUtility.h"
#import "STPathTextField.h"
#import "BundledFilesController.h"
#import "NSColor+HexTools.h"

#import "IconFamily.h"
#import "UKKQueue.h"

@interface PlatypusController : NSObject
{
    //basic controls
    IBOutlet id appNameTextField;
    IBOutlet id scriptTypePopupMenu;
    IBOutlet id scriptPathTextField;
    IBOutlet id editScriptButton;
    IBOutlet id revealScriptButton;
    IBOutlet id outputTypePopupMenu;
    IBOutlet id createAppButton;
    IBOutlet id textOutputSettingsButton;
    IBOutlet id statusItemSettingsButton;
    
    //advanced options controls
    IBOutlet id interpreterTextField;
    IBOutlet id versionTextField;
    IBOutlet id bundleIdentifierTextField;
    IBOutlet id authorTextField;
    
    IBOutlet id rootPrivilegesCheckbox;
    IBOutlet id encryptCheckbox;
    IBOutlet id isDroppableCheckbox;
    IBOutlet id showInDockCheckbox;
    IBOutlet id remainRunningCheckbox;
    
    IBOutlet id editTypesButton;
    
    IBOutlet id appSizeTextField;
    
    // create app dialog view extension
    IBOutlet id debugSaveOptionView;
    IBOutlet id developmentVersionCheckbox;
    IBOutlet id optimizeApplicationCheckbox;
    IBOutlet id xmlPlistFormatCheckbox;
    
    //windows
    IBOutlet id window;
    
    //progress bar for creating
    IBOutlet id progressDialogWindow;
    IBOutlet id progressBar;
    IBOutlet id progressDialogMessageLabel;
    IBOutlet id progressDialogStatusLabel;
    
    // interface controllers
    IBOutlet id iconController;
    IBOutlet id dropSettingsController;
    IBOutlet id argsController;
    IBOutlet id profilesController;
    IBOutlet id textSettingsController;
    IBOutlet id statusItemSettingsController;
    
    IBOutlet id fileList;
}

- (IBAction)newScript:(id)sender;
- (NSString *)createNewScript:(NSString *)scriptText;
- (IBAction)revealScript:(id)sender;
- (IBAction)editScript:(id)sender;
- (IBAction)runScript:(id)sender;
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

//Help
- (IBAction)showHelp:(id)sender;
- (IBAction)showReadme:(id)sender;
- (IBAction)showManPage:(id)sender;
- (IBAction)openWebsite:(id)sender;
- (IBAction)openLicense:(id)sender;
- (IBAction)openDonations:(id)sender;


@end
