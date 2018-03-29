/*
 Copyright (c) 2003-2018, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

#import "TypeListController.h"

@interface TypeListController()
{
    NSMutableArray OF_NSDICTIONARY *items;
}
@end

@implementation TypeListController

- (instancetype)init {
    if (self = [super init]) {
        items = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addItem:(NSString *)item {
    NSImage *icon = [self iconForItem:item];
    NSDictionary *infoDict = @{@"name": item, @"icon": icon};
    [items addObject:infoDict];
}

- (void)addNewItem {
    [self addItem:[self defaultItemString]];
}

- (NSImage *)iconForItem:(NSString *)item {
    NSImage *icon = [WORKSPACE iconForFileType:item];
    if (icon != nil) {
        return icon;
    }
    return [WORKSPACE iconForFileType:NSFileTypeForHFSTypeCode(kGenericDocumentIcon)];
}

- (void)addItems:(NSArray *)itemsToAdd {
    for (id item in itemsToAdd) {
        [self addItem:item];
    }
}

- (void)removeAllItems {
    [items removeAllObjects];
}

- (NSUInteger)itemCount {
    return [items count];
}

- (void)removeItemAtIndex:(NSInteger)index {
    if ([items count] > index) {
        [items removeObjectAtIndex:index];
    }
}

- (NSArray *)itemsArray {
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *itemDict in items) {
        [array addObject:itemDict[@"name"]];
    }
    return [NSArray arrayWithArray:array];
}

- (TypeListItemStringValidity)validateItemString:(NSString *)itemString {
    return TypeListItemStringValid;
}

- (NSString *)defaultItemString {
    return @"item";
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [items count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if (![items count]) {
        return nil;
    }
    
    if ([[aTableColumn identifier] isEqualToString:@"2"]) {
        NSString *itemString = items[rowIndex][@"name"];
        NSColor *stringColor;

        if ([aTableView isEnabled] == NO) {
            stringColor = [NSColor grayColor];
        } else {

            TypeListItemStringValidity validity = [self validateItemString:itemString];
            switch (validity) {
                case TypeListItemStringInvalid:
                    stringColor = [NSColor redColor];
                    break;

                case TypeListItemStringQuestionable:
                    stringColor = [NSColor orangeColor];
                    break;

                case TypeListItemStringValid:
                    stringColor = [NSColor blackColor];
                    break;
            }
        }
        NSDictionary *attrs = @{ NSForegroundColorAttributeName: stringColor };
        NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:itemString
                                                                      attributes:attrs];
        return attrStr;
    } else if ([[aTableColumn identifier] isEqualToString:@"1"]) {
        // set cell type for column, only needed once
        if (rowIndex == 0) {
            NSImageCell *iconCell;
            iconCell = [[NSImageCell alloc] init];
            [aTableColumn setDataCell:iconCell];
        }
        
        return items[rowIndex][@"icon"];
    }
    return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    NSString *item = (NSString *)anObject;
    if ([item isEqualToString:@""]) {
        NSBeep();
        return;
    }
    NSImage *icon = [self iconForItem:item];
    NSDictionary *infoDict = @{@"name": item, @"icon": icon};
    items[rowIndex] = infoDict;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo> )info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *draggedFiles = [pboard propertyListForType:NSFilenamesPboardType];
    for (NSString *filePath in draggedFiles) {
        [self addItem:filePath];
    }
    [tv reloadData];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo> )info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
    return NSDragOperationCopy;
}

@end
