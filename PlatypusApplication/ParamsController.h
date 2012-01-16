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

@interface ParamsController : NSObject 
{
    IBOutlet id paramsWindow;
    IBOutlet id paramsCommandTextField;
    IBOutlet id interpreterTextField;
    
    IBOutlet id interpreterArgsAddButton;
    IBOutlet id interpreterArgsRemoveButton;
    IBOutlet id interpreterArgsClearButton;
    IBOutlet id interpreterArgsTableView;
    
    IBOutlet id scriptArgsAddButton;
    IBOutlet id scriptArgsRemoveButton;
    IBOutlet id scriptArgsClearButton;
    IBOutlet id scriptArgsTableView;
    
	IBOutlet id isDroppableCheckbox;
    IBOutlet id window;
	
    IBOutlet id scriptArgsContextualMenu;
    IBOutlet id interpreterArgsContextualMenu;
    
	NSMutableArray *interpreterArgs;
    NSMutableArray *scriptArgs;
}
// accessors

- (NSArray *)interpreterArgs;
- (NSArray *)scriptArgs;
- (void)setInterpreterArgs: (NSArray *)array;
- (void)setScriptArgs: (NSArray *)array;
- (NSArray *)interpreterArgs;
- (NSArray *)scriptArgs;

- (IBAction)apply:(id)sender;

- (IBAction)addInterpreterArg:(id)sender;
- (IBAction)removeInterpreterArg:(id)sender;
- (IBAction)clearInterpreterArgs:(id)sender;

- (IBAction)addScriptArg:(id)sender;
- (IBAction)removeScriptArg:(id)sender;
- (IBAction)clearScriptArgs:(id)sender;

- (IBAction)resetDefaults:(id)sender;

- (IBAction)show:(id)sender;
- (NSString *)constructCommandString;
- (IBAction)appPathCheckboxClicked:(id)sender;

// table view handling
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue: anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

@end
