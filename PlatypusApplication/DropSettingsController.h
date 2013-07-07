/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C) 2003-2013 Sveinbjorn Thordarson <sveinbjornt@gmail.com>

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

#import <Cocoa/Cocoa.h>
#import "SuffixList.h"
#import "PlatypusUtility.h"

@interface DropSettingsController : NSObject <NSTableViewDelegate>
{
	IBOutlet id appFunctionRadioButtons;
    IBOutlet id addSuffixButton;
    IBOutlet id numSuffixesTextField;
    IBOutlet id removeSuffixButton;
    IBOutlet NSTableView *suffixListDataBrowser;
    IBOutlet id suffixTextField;
    IBOutlet id promptForFileOnLaunchCheckbox;

    IBOutlet id typesWindow;
    IBOutlet id window;
    IBOutlet id typesErrorTextField;
	
	IBOutlet id acceptDroppedTextCheckbox;
	IBOutlet id acceptDroppedFilesCheckbox;
    IBOutlet id declareServiceCheckbox;
    IBOutlet id docIconImageView;
    
	IBOutlet id droppedFilesSettingsBox;
    IBOutlet id selectDocumentIconButton;
	
    NSString    *docIconPath;
	SuffixList	*suffixList;
}
-(IBAction)addSuffix:(id)sender;
-(IBAction)clearSuffixList:(id)sender;
-(IBAction)openDropSettingsSheet:(id)sender;
-(IBAction)closeDropSettingsSheet:(id)sender;
-(IBAction)removeSuffix:(id)sender;
-(IBAction)selectDocIcon:(id)sender;
-(IBAction)setToDefaults:(id)sender;
-(IBAction)acceptsFilesChanged:(id)sender;
-(IBAction)acceptsTextChanged:(id)sender;

-(SuffixList *)suffixes;
-(UInt64)docIconSize;

// getter/setters
-(NSString *)docIconPath;
-(void)setDocIconPath:(NSString *)path;

-(BOOL)acceptsText;
-(void)setAcceptsText: (BOOL)b;

-(BOOL)acceptsFiles;
-(void)setAcceptsFiles: (BOOL)b;

-(BOOL)declareService;
-(void)setDeclareService: (BOOL)b;

-(BOOL)promptsForFileOnLaunch;
-(void)setPromptsForFileOnLaunch: (BOOL)b;

-(NSString *)role;
-(void)setRole:(NSString *)role;
@end
