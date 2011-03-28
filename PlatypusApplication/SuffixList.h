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

// SuffixList is a controller class around the Suffix list in the Platypus
// Edit Types window.  It is the data source and delegate of this tableview.


#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface SuffixList : NSObject
{
	NSMutableArray  *items;
}

- (NSString *)getSuffixAtIndex:(int)index;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void) addSuffix: (NSString *)suffix;
- (void) addSuffixes: (NSArray *)suffixes;
- (BOOL) hasSuffix: (NSString *)suffix;
- (BOOL) hasAllSuffixes;
- (void) clearList;
- (int) numSuffixes;
- (void) removeSuffix: (int)index;
- (NSArray *) getSuffixArray;
@end
