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
- (IBAction)addSuffix:(id)sender;
- (IBAction)clearSuffixList:(id)sender;
- (IBAction)openTypesSheet:(id)sender;
- (IBAction)closeTypesSheet:(id)sender;
- (IBAction)removeSuffix:(id)sender;
- (IBAction)selectDocIcon:(id)sender;
- (IBAction)setDefaultTypes:(id)sender;
- (IBAction)acceptsFilesChanged:(id)sender;
- (IBAction)acceptsTextChanged:(id)sender;

- (SuffixList *)suffixes;
- (NSString *)docIconPath;
- (UInt64)docIconSize;
- (void)setDocIconPath:(NSString *)path;
- (BOOL)acceptsText;
- (BOOL)acceptsFiles;
- (BOOL)declareService;
- (BOOL)promptsForFileOnLaunch;
- (void)setAcceptsText: (BOOL)b;
- (void)setAcceptsFiles: (BOOL)b;
- (void)setDeclareService: (BOOL)b;
- (void)setPromptsForFileOnLaunch: (BOOL)b;
- (NSString *)role;
- (void)setRole:(NSString *)role;
@end
