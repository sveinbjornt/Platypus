/*
 Copyright (c) 2003-2015, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 
 3. Neither the name of the copyright holder nor the names of its contributors may
 be used to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

// SuffixList is a controller class around the Suffix list in the Platypus
// Edit Types window.  It is the data source and delegate of this tableview.

#import "SuffixListController.h"
#import "Common.h"

@implementation SuffixListController

- (id)init {
    if ((self = [super init])) {
        items = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [items release];
    [super dealloc];
}

- (NSString *)getSuffixAtIndex:(int)index {
    return ([[items objectAtIndex:index] objectForKey:@"suffix"]);
}

- (void)addSuffix:(NSString *)suffix {
    if ([self hasSuffix:suffix]) {
        return;
    }
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType:suffix];
    NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
                            suffix, @"suffix", icon, @"icon", nil];
    [items addObject:infoDict];
}

- (void)addSuffixes:(NSArray *)suffixes {
    int i;
    
    for (i = 0; i < [suffixes count]; i++) {
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType:[suffixes objectAtIndex:i]];
        [items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                          [suffixes objectAtIndex:i], @"suffix",
                          icon, @"icon", nil]];
    }
}

- (BOOL)hasSuffix:(NSString *)suffix {
    int i;
    for (i = 0; i < [items count]; i++) {
        if ([[[items objectAtIndex:i] objectForKey:@"suffix"] isEqualToString:suffix]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)hasAllSuffixes {
    int i;
    for (i = 0; i < [items count]; i++) {
        if ([[[items objectAtIndex:i] objectForKey:@"suffix"] isEqualToString:@"*"]) {
            return YES;
        }
    }
    return NO;
}

- (void)clearList {
    [items removeAllObjects];
}

- (int)numSuffixes {
    return [items count];
}

- (void)removeSuffix:(int)index {
    if ([items count] > 0) {
        [items removeObjectAtIndex:index];
    }
}

- (NSArray *)getSuffixArray {
    short i;
    NSMutableArray *suffices = [NSMutableArray arrayWithCapacity:PROGRAM_MAX_LIST_ITEMS];
    
    for (i = 0; i < [items count]; i++) {
        NSString *suffix = [[items objectAtIndex:i] objectForKey:@"suffix"];
        [suffices addObject:suffix];
    }
    
    return suffices;
}

#pragma mark - NSTableViewDelegate / DataSource

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [items count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    
    if ([[aTableColumn identifier] caseInsensitiveCompare:@"2"] == NSOrderedSame) {
        return([[items objectAtIndex:rowIndex] objectForKey:@"suffix"]);
    } else if ([[aTableColumn identifier] caseInsensitiveCompare:@"1"] == NSOrderedSame) {
        if (rowIndex == 0) {
            NSImageCell *iconCell;
            iconCell = [[[NSImageCell alloc] init] autorelease];
            [aTableColumn setDataCell:iconCell];
        }
        
        return [[items objectAtIndex:rowIndex] objectForKey:@"icon"];
    }
    return(@"");
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo> )info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
    int i;
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *draggedFiles = [pboard propertyListForType:NSFilenamesPboardType];
    
    for (i = 0; i < [draggedFiles count]; i++) {
        if (![[[draggedFiles objectAtIndex:i] pathExtension] isEqualToString:@""]) {
            [self addSuffix:[[draggedFiles objectAtIndex:i] pathExtension]];
        }
    }
    [tv reloadData];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo> )info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
    return NSDragOperationCopy;
}

@end
