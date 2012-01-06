/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C)  Sveinbjorn Thordarson <sveinbjornt@gmail.com>

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

// TypesList is a controller class around the Types list in the Platypus
// Edit Types window.  It is the data source and delegate of this tableview.

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface TypesList : NSObject
{
	NSMutableArray  *items;
}

- (NSString *)getTypeAtIndex:(int)index;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation;
- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation;

- (void) addType: (NSString *)suffix;
- (void) addTypes: (NSArray *)types;
- (BOOL) hasType: (NSString *)suffix;
- (BOOL) hasAllTypes;
- (BOOL) hasFolderType;
- (void) clearList;
- (int) numTypes;
- (void) removeType: (int)index;
- (NSArray *) getTypesArray;


@end
