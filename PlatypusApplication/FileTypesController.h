/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C) 2003-2010 Sveinbjorn Thordarson <sveinbjornt@simnet.is>

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
#import "STUtil.h"

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
	
	IBOutlet id droppedFilesSettingsBox;
	
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

- (TypesList *) types;
- (SuffixList *) suffixes;
- (NSString *)role;
-(void) setRole: (NSString *)role;
@end
