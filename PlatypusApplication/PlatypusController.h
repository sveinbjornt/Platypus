/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C) 2003-2011 Sveinbjorn Thordarson <sveinbjornt@gmail.com>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

*/

// PlatypusController class is the controller class for the basic Platypus 
// main window interface.  Also delegate for the application, and for menus.

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

#import "Common.h"

#import "PlatypusAppSpec.h"
#import "ScriptAnalyser.h"

#import "IconController.h"
#import "ParamsController.h"
#import "ProfilesController.h"
#import "PrefsController.h"
#import "TextSettingsController.h"
#import "StatusItemSettingsController.h"
#import "EditorController.h"
#import "ShellCommandController.h"

#import "FileTypesController.h"
#import "SuffixList.h"
#import "TypesList.h"

#import "PlatypusUtility.h"
#import "STPathTextField.h"
#import "STFileList.h"
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
    
    IBOutlet id showAdvancedArrow;
	IBOutlet id showOptionsTextField;
	
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
	IBOutlet id toggleAdvancedMenuItem;
	
	IBOutlet id appSizeTextField;
	
	// create app dialog view extension
	IBOutlet id debugSaveOptionView;
	IBOutlet id developmentVersionCheckbox;
	IBOutlet id optimizeApplicationCheckbox;
				
	//windows
	IBOutlet id window;
	
	//progress bar for creating
	IBOutlet id progressDialogWindow;
	IBOutlet id progressBar;
	IBOutlet id progressDialogMessageLabel;
    IBOutlet id progressDialogStatusLabel;
    
	
	// interface controllers
	IBOutlet id iconControl;
	IBOutlet id typesControl;
	IBOutlet id paramsControl;
	IBOutlet id profilesControl;
	IBOutlet id textSettingsControl;
	IBOutlet id statusItemSettingsControl;
		
	IBOutlet id fileList;
}

- (IBAction)newScript:(id)sender;
- (NSString *)createNewScript: (NSString *)scriptText;
- (IBAction)revealScript:(id)sender;
- (IBAction)editScript:(id)sender;
- (IBAction)runScript:(id)sender;
- (IBAction)checkSyntaxOfScript: (id)sender;
- (void)openScriptInBuiltInEditor: (NSString *)path;

- (IBAction)createButtonPressed: (id)sender;
- (void)createConfirmed:(NSSavePanel *)sPanel returnCode:(int)result contextInfo:(void *)contextInfo;
- (BOOL)createApplicationFromTimer: (NSTimer *)theTimer;
- (BOOL)createApplication: (NSString *)destination overwrite: (BOOL)overwrite;

- (id)appSpecFromControls;
- (void)controlsFromAppSpec: (id)spec;

- (BOOL)verifyFieldContents;
- (IBAction)scriptTypeSelected:(id)sender;
- (void)selectScriptTypeBasedOnInterpreter;
- (void)setScriptType: (NSString *)type;
- (IBAction)selectScript:(id)sender;
- (void)selectScriptPanelDidEnd:(NSOpenPanel *)oPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)loadScript:(NSString *)filename;
- (IBAction)isDroppableWasClicked:(id)sender;
- (IBAction)outputTypeWasChanged:(id)sender;
- (IBAction)clearAllFields:(id)sender;
- (IBAction)showCommandLineString: (id)sender;
- (void)updateEstimatedAppSize;
- (NSString *)estimatedAppSize;

//Help
- (IBAction) showHelp:(id)sender;
- (IBAction) showReadme:(id)sender;
- (IBAction) showManPage:(id)sender;
- (IBAction) openWebsite: (id)sender;
- (IBAction) openLicense: (id)sender;
- (IBAction) openDonations: (id)sender;


@end
