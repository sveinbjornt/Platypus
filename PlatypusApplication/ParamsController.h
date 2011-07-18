/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C) 2003-2010 Sveinbjorn Thordarson <sveinbjornt@gmail.com>

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
    IBOutlet id addButton;
    IBOutlet id clearButton;
    IBOutlet id interpreterTextField;
    IBOutlet id paramsCommandTextField;
    IBOutlet id paramsTableView;
    IBOutlet id paramsWindow;
    IBOutlet id removeButton;
	IBOutlet id setFirstArgAppPathCheckbox;
	IBOutlet id isDroppableCheckbox;
    IBOutlet id window;
	
	NSMutableArray	*values;
}
- (IBAction)add:(id)sender;
- (void)set: (NSArray *)array;
- (IBAction)apply:(id)sender;
- (IBAction)clear:(id)sender;
- (IBAction)help:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)resetDefaults:(id)sender;
- (IBAction)show:(id)sender;
- (NSString *)constructCommandString;
- (NSArray *)paramsArray;
- (IBAction)appPathCheckboxClicked:(id)sender;
- (BOOL)passAppPathAsFirstArg;
- (void)setAppPathAsFirstArg: (BOOL)state;
@end
