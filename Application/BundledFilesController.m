/*
 Copyright (c) 2003-2016, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
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

#import "BundledFilesController.h"
#import "VDKQueue.h"
#import "EditorController.h"
#import "NSWorkspace+Additions.h"
#import "Alerts.h"
#import "Common.h"

@interface BundledFilesController()
{
    IBOutlet NSButton *removeFileButton;
    IBOutlet NSButton *editFileButton;
    IBOutlet NSButton *revealFileButton;
    IBOutlet NSButton *clearFileListButton;
    IBOutlet NSTableView *tableView;
    IBOutlet NSTextField *bundleSizeTextField;

    NSMutableArray OF_NSDICTIONARY *files;
    VDKQueue *fileWatcherQueue;
    
    NSWindow *window;
}

- (IBAction)copyFilenames:(id)sender;
- (IBAction)copyPaths:(id)sender;
- (IBAction)editSelectedFile:(id)sender;
- (IBAction)addFilesToList:(id)sender;
- (IBAction)revealSelectedFilesInFinder:(id)sender;
- (IBAction)openSelectedFiles:(id)sender;
- (IBAction)removeSelectedFiles:(id)sender;

@end

@implementation BundledFilesController

- (instancetype)init {
    if (self = [super init]) {
        files = [[NSMutableArray alloc] init];
        fileWatcherQueue = [[VDKQueue alloc] init];
    }
    return self;
}

- (void)awakeFromNib {
    window = [tableView window];
    
    [tableView registerForDraggedTypes:@[NSFilenamesPboardType]];
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(itemDoubleClicked:)];
    [tableView setDraggingSourceOperationMask:NSDragOperationCopy | NSDragOperationMove forLocal:NO];
    
    // we list ourself as an observer of file system changes for items in file watcher queue
    [[WORKSPACE notificationCenter] addObserver:self selector:@selector(trackedFileDidChange) name:VDKQueueRenameNotification object:nil];
    [[WORKSPACE notificationCenter] addObserver:self selector:@selector(trackedFileDidChange) name:VDKQueueDeleteNotification object:nil];
}

#pragma mark -

- (void)trackedFileDidChange {
    [tableView reloadData];
}

- (void)addFiles:(NSArray *)filePaths {
    if (filePaths == nil) {
        return;
    }
    BOOL addedFile = NO;
    for (NSString *filePath in filePaths) {
        if ([self hasFilePath:filePath]) {
            continue;
        }
        NSImage *icon = [WORKSPACE iconForFile:filePath];
        [icon setSize:NSMakeSize(16, 16)];
        NSDictionary *fileInfoDict = @{ @"Icon":icon, @"Path":filePath };
        [files addObject:fileInfoDict];
        addedFile = YES;
    }
    
    if (addedFile) {
        [self updateUI];
    }
}

- (void)updateUI {
    [tableView reloadData];
    [self updateButtonStatus];
    [self updateQueueWatch];
    [self updateFileSizeField];
}

- (void)updateQueueWatch {
    [fileWatcherQueue removeAllPaths];
    for (NSDictionary *fileItem in files) {
        [fileWatcherQueue addPath:fileItem[@"Path"]];
    }
}

- (void)updateButtonStatus {
    BOOL hasSelection = [[tableView selectedRowIndexes] count];
    [removeFileButton setEnabled:hasSelection];
    [revealFileButton setEnabled:hasSelection];
    [editFileButton setEnabled:hasSelection];
    [clearFileListButton setEnabled:([files count] != 0)];
}

- (void)updateFileSizeField {
    
    //if there are no items
    if ([files count] == 0) {
        _totalSizeOfFiles = 0;
        [bundleSizeTextField setStringValue:@""];
        [[NSNotificationCenter defaultCenter] postNotificationName:PLATYPUS_APP_SIZE_CHANGED_NOTIFICATION object:nil];
        return;
    }
    
    //otherwise, loop through all files, calculate size in a separate queue
    [bundleSizeTextField setStringValue:@"Calculating size..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void){
        
        UInt64 size = 0;
        for (NSDictionary *fileInfoDict in files) {
            size += [WORKSPACE fileOrFolderSize:fileInfoDict[@"Path"]];
        }
        
        NSString *totalSizeString = [WORKSPACE fileSizeAsHumanReadableString:size];
        NSString *pluralS = ([files count] > 1) ? @"s" : @"";
        NSString *itemsSizeString = [NSString stringWithFormat:@"%lu item%@, %@", (unsigned long)[files count], pluralS, totalSizeString];
        NSString *tooltipString = [NSString stringWithFormat:@"%lu item%@ (%llu bytes)", (unsigned long)[files count], pluralS, size];
        _totalSizeOfFiles = size;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PLATYPUS_APP_SIZE_CHANGED_NOTIFICATION object:nil];
        
        //run UI updates on main thread
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [bundleSizeTextField setStringValue:itemsSizeString];
            [bundleSizeTextField setToolTip:tooltipString];
        });
    });
}

- (BOOL)hasFilePath:(NSString *)filePath {
    for (NSDictionary *fileInfoDict in files) {
        if ([fileInfoDict[@"Path"] isEqualToString:filePath]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray OF_NSSTRING *)filePaths {
    NSMutableArray OF_NSSTRING *filePaths = [NSMutableArray array];
    for (NSDictionary *fileItem in files) {
        [filePaths addObject:fileItem[@"Path"]];
    }
    return [filePaths copy];
}

- (void)setFilePaths:(NSArray OF_NSSTRING *)filePaths {
    [files removeAllObjects];
    [self addFiles:filePaths];
}

- (IBAction)setToDefaults:(id)sender {
    [self clearFileList:self];
}

#pragma mark - Interface actions

- (void)itemDoubleClicked:(id)sender {
    if ([tableView clickedRow] == -1) {
        return;
    }
    
    BOOL commandKeyDown = (([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask);
    if (commandKeyDown) {
        [self revealInFinder:[tableView clickedRow]];
    } else {
        [self openInFinder:[tableView clickedRow]];
    }
}

- (void)revealInFinder:(NSInteger)index {
    BOOL isDir;
    NSString *path = files[index][@"Path"];
    
    if ([FILEMGR fileExistsAtPath:path isDirectory:&isDir]) {
        [WORKSPACE selectFile:path inFileViewerRootedAtPath:@""];
    }
}

- (void)openInFinder:(NSInteger)index {
    [WORKSPACE openFile:files[index][@"Path"]];
}

- (void)openInEditor:(int)index {
    NSString *defaultEditor = [DEFAULTS stringForKey:DefaultsKey_DefaultEditor];
    NSString *path = files[index][@"Path"];
    
    if ([defaultEditor isEqualToString:DEFAULT_EDITOR] == NO) {
        // open it in the external application
        if ([WORKSPACE fullPathForApplication:defaultEditor] == nil) {
            [Alerts alert:@"Editor not found" subTextFormat:@"The application '%@' could not be found.  Reverting to the built-in editor.", defaultEditor];
            [DEFAULTS setObject:DEFAULT_EDITOR forKey:DefaultsKey_DefaultEditor];
        } else {
            [WORKSPACE openFile:path withApplication:defaultEditor];
            return;
        }
    }
    
    // Open in built-in editor
    [window setTitle:[NSString stringWithFormat:@"%@ - Editing %@", PROGRAM_NAME, [path lastPathComponent]]];
    EditorController *editorController = [[EditorController alloc] init];
    [editorController showModalEditorSheetForFile:path window:window];
    [window setTitle:PROGRAM_NAME];
}

- (IBAction)copyFilenames:(id)sender {
    [self copyFilenamesToPasteboard:YES];
}

- (IBAction)copyPaths:(id)sender {
    [self copyFilenamesToPasteboard:NO];
}

- (void)copyFilenamesToPasteboard:(BOOL)basenameOnly {
    NSMutableString *copyStr = [[NSMutableString alloc] initWithString:@""];
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    
    for (int i = 0; i < [files count]; i++) {
        if ([selectedItems containsIndex:i]) {
            NSDictionary *fileInfoDict = files[i];
            NSString *name = basenameOnly ? fileInfoDict[@"Path"] : [fileInfoDict[@"Path"] lastPathComponent];
            [copyStr appendString:[NSString stringWithFormat:@"%@ ", name]];
        }
    }

    [[NSPasteboard generalPasteboard] declareTypes:@[NSStringPboardType] owner:self];
    [[NSPasteboard generalPasteboard] setString:copyStr forType:NSStringPboardType];
}

- (IBAction)addFilesToList:(id)sender {
    [window setTitle:[NSString stringWithFormat:@"%@ - Select files or folders to add", PROGRAM_NAME]];
    
    // create open panel
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setPrompt:@"Add"];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setAllowsMultipleSelection:YES];
    
    //run open panel sheet
    [oPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        
        [window setTitle:PROGRAM_NAME];
        if (result != NSOKButton) {
            return;
        }
        
        // convert NSURLs to paths
        NSMutableArray *filePaths = [NSMutableArray array];
        for (NSURL *url in [oPanel URLs]) {
            [filePaths addObject:[url path]];
        }
        
        [self addFiles:filePaths];
        
    }];
}

- (IBAction)clearFileList:(id)sender {
    [files removeAllObjects];
    [self updateUI];
}

- (IBAction)revealSelectedFilesInFinder:(id)sender {
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    for (int i = 0; i < [files count]; i++) {
        if ([selectedItems containsIndex:i]) {
            [self revealInFinder:i];
        }
    }
}

- (IBAction)openSelectedFiles:(id)sender {
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    for (int i = 0; i < [files count]; i++) {
        if ([selectedItems containsIndex:i]) {
            [self openInFinder:i];
        }
    }
}

- (IBAction)editSelectedFile:(id)sender {
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    for (int i = 0; i < [files count]; i++) {
        if ([selectedItems containsIndex:i]) {
            [self openInEditor:i];
            return;
        }
    }
}

- (IBAction)removeSelectedFiles:(id)sender {
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    for (NSInteger i = [files count]; i >= 0; i--) {
        if ([selectedItems containsIndex:i]) {
            [files removeObjectAtIndex:i];
        }
    }
    if ([tableView numberOfRows]) {
        NSUInteger rowToSelect = [selectedItems firstIndex] - 1;
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowToSelect] byExtendingSelection:NO];
    }
    
    [self updateUI];
}

#pragma mark - NSTableViewDelegate/DataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [files count];
}

- (NSView *)tableView:(NSTableView *)tv viewForTableColumn:(NSTableColumn *)tc row:(NSInteger)row {
    NSTableCellView *cellView = [tv makeViewWithIdentifier:@"MainCell" owner:self];
    cellView.textField.stringValue = files[row][@"Path"];
    cellView.imageView.objectValue = files[row][@"Icon"];
    return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self updateButtonStatus];
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo> )info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *draggedFiles = [pboard propertyListForType:NSFilenamesPboardType];
    [self addFiles:draggedFiles];
    return YES;
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    NSMutableArray *filenames = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
    NSInteger index = [rowIndexes firstIndex];
    
    while (NSNotFound != index) {
        [filenames addObject:files[index][@"Path"]];
        index = [rowIndexes indexGreaterThanIndex:index];
    }
    
    [pboard declareTypes:@[NSFilenamesPboardType] owner:nil];
    [pboard setPropertyList:filenames forType:NSFilenamesPboardType];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo> )info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
    return NSDragOperationLink;
}

- (CGFloat)tableView:(NSTableView *)theTableView heightOfRow:(NSInteger)row {
    return 18;
}

#pragma mark - Menu delegate

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    if ([tableView selectedRow] == -1) {
        return NO;
    }
    
    if ([[anItem title] isEqualToString:@"Add File"] || [[anItem title] isEqualToString:@"Add File To Bundle"]) {
        return YES;
    }
    if ([[anItem title] isEqualToString:@"Clear File List"] && [files count] >= 1) {
        return YES;
    }
    
    // Folders are never editable
    if ([[anItem title] isEqualToString:@"Open in Editor"])  {
        NSIndexSet *selectedItems = [tableView selectedRowIndexes];
        for (int i = 0; i < [files count]; i++) {
            if ([selectedItems containsIndex:i]) {
                NSString *filename = files[i][@"Path"];
                BOOL isFolder;
                [FILEMGR fileExistsAtPath:filename isDirectory:&isFolder];
                return !isFolder;
            }
        }
    }
    
    return YES;
}

@end
