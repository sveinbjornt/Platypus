/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C) 2003-2012 Sveinbjorn Thordarson <sveinbjornt@gmail.com>

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
#import "TypesList.h"
#import "SuffixList.h"
#import "PlatypusUtility.h"

@interface FileTypesController : NSObject
{
	IBOutlet id appFunctionRadioButtons;
    IBOutlet id addSuffixButton;
    IBOutlet id addTypeButton;
    IBOutlet id numSuffixesTextField;
    IBOutlet id numTypesTextField;
    IBOutlet id removeSuffixButton;
    IBOutlet id removeTypeButton;
    IBOutlet id suffixListDataBrowser;
    IBOutlet id suffixTextField;
    IBOutlet id typeCodeTextField;
    IBOutlet id typesErrorTextField;
    IBOutlet id typesListDataBrowser;
	IBOutlet id showTypesButton;
    IBOutlet id typesWindow;
    IBOutlet id window;
	
	IBOutlet id acceptDroppedTextCheckbox;
	IBOutlet id acceptDroppedFilesCheckbox;
    IBOutlet id declareServiceCheckbox;
    IBOutlet id docIconImageView;
    
	IBOutlet id droppedFilesSettingsBox;
	
    NSString    *docIconPath;
	SuffixList	*suffixList;
	TypesList	*typesList;
}
- (IBAction)acceptDroppedFilesClicked:(id)sender;
- (IBAction)addSuffix:(id)sender;
- (IBAction)addType:(id)sender;
- (IBAction)clearSuffixList:(id)sender;
- (IBAction)clearTypesList:(id)sender;
- (IBAction)openTypesSheet:(id)sender;
- (IBAction)closeTypesSheet:(id)sender;
- (IBAction)removeSuffix:(id)sender;
- (IBAction)removeType:(id)sender;
- (IBAction)setDefaultTypes:(id)sender;
- (IBAction)selectDocIcon:(id)sender;

- (TypesList *)types;
- (SuffixList *)suffixes;
- (NSString *)docIconPath;
- (UInt64)docIconSize;
- (void)setDocIconPath:(NSString *)path;
- (BOOL)acceptsText;
- (BOOL)acceptsFiles;
- (BOOL)declareService;
- (void)setAcceptsText: (BOOL)b;
- (void)setAcceptsFiles: (BOOL)b;
- (void)setDeclareService: (BOOL)b;
- (NSString *)role;
- (void)setRole:(NSString *)role;
@end
