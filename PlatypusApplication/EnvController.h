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

@interface EnvController : NSObject
{
    IBOutlet id envTableView;
    IBOutlet id envWindow;
	IBOutlet id window;
	
	IBOutlet id addButton;
	IBOutlet id removeButton;
	IBOutlet id clearButton;
	
	NSMutableArray	*keys;
	NSMutableArray	*values;
	NSMutableDictionary *environmentDictionary;
}
- (IBAction)add:(id)sender;
- (void)set: (NSDictionary *)array;
- (IBAction)apply:(id)sender;
- (IBAction)clear:(id)sender;
- (IBAction)help:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)resetDefaults:(id)sender;
- (IBAction)show:(id)sender;
- (NSMutableDictionary *)environmentDictionary;
@end
