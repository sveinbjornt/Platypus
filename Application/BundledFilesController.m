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

#import "BundledFilesController.h"
#import "VDKQueue.h"
#import "EditorController.h"
#import "NSWorkspace+Additions.h"
#import "Alerts.h"
#import "Common.h"

@interface BundledFilesController()
{
    UInt64 totalFileSize;
    NSMutableArray *files;
    VDKQueue *fileWatcherQueue;
    
    IBOutlet NSWindow *window;
    IBOutlet NSButton *addFileButton;
    IBOutlet NSButton *removeFileButton;
    IBOutlet NSButton *editFileButton;
    IBOutlet NSButton *revealFileButton;
    IBOutlet NSButton *clearFileListButton;
    IBOutlet NSTableView *tableView;
    IBOutlet NSTextField *bundleSizeTextField;
    IBOutlet NSMenu *contextualMenu;
}

- (IBAction)copyFilenames:(id)sender;
- (IBAction)copyPaths:(id)sender;
- (IBAction)editFileInFileList:(id)sender;
- (IBAction)addFileToFileList:(id)sender;
- (IBAction)revealFileInFileList:(id)sender;
- (IBAction)openFileInFileList:(id)sender;
- (IBAction)removeFileFromFileList:(id)sender;

@end

@implementation BundledFilesController

- (instancetype)init {
    if ((self = [super init])) {
        files = [[NSMutableArray alloc] init];
        fileWatcherQueue = [[VDKQueue alloc] init];
    }
    return self;
}

- (void)dealloc {
    [files release];
    [fileWatcherQueue release];
    [super dealloc];
}

- (void)awakeFromNib {
    totalFileSize = 0;
    [tableView registerForDraggedTypes:@[NSFilenamesPboardType]];
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(itemDoubleClicked:)];
    [tableView setDraggingSourceOperationMask:NSDragOperationCopy | NSDragOperationMove forLocal:NO];
    
    // we list ourself as an observer of changes to file system
    [[WORKSPACE notificationCenter] addObserver:self selector:@selector(trackedFileDidChange) name:VDKQueueRenameNotification object:nil];
    [[WORKSPACE notificationCenter] addObserver:self selector:@selector(trackedFileDidChange) name:VDKQueueDeleteNotification object:nil];
}

#pragma mark -

- (void)trackedFileDidChange {
    [tableView reloadData];
}

- (void)addFiles:(NSArray *)filePaths {
    for (NSString *filePath in filePaths) {
        if ([self hasFile:filePath] == NO) {
            NSMutableDictionary *fileInfoDict = [NSMutableDictionary dictionary];
            
            NSImage *icon = [WORKSPACE iconForFile:filePath];
            [icon setSize:NSMakeSize(16, 16)];
            fileInfoDict[@"Icon"] = icon;
            fileInfoDict[@"Path"] = filePath;

            [files addObject:fileInfoDict];
        }
    }
    
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

- (void)updateFileSizeField {
    
    //if there are no items
    if ([files count] == 0) {
        totalFileSize = 0;
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
        totalFileSize = size;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PLATYPUS_APP_SIZE_CHANGED_NOTIFICATION object:nil];
        
        //run UI updates on main thread
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [bundleSizeTextField setStringValue:itemsSizeString];
            [bundleSizeTextField setToolTip:tooltipString];
        });
    });
}

- (BOOL)hasFile:(NSString *)filePath {
    for (NSDictionary *fileInfoDict in files) {
        if ([fileInfoDict[@"Path"] isEqualToString:filePath]) {
            return YES;
        }
    }
    return NO;
}

- (void)removeFileAtIndex:(int)index {
    [files removeObjectAtIndex:index];
    [self updateQueueWatch];
    [tableView reloadData];
}

- (NSArray *)filePaths {
    NSMutableArray *filePaths = [NSMutableArray array];
    for (NSDictionary *fileItem in files) {
        [filePaths addObject:fileItem[@"Path"]];
    }
    return filePaths;
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

- (void)revealInFinder:(int)index {
    BOOL isDir;
    NSString *path = files[index][@"Path"];
    
    if ([FILEMGR fileExistsAtPath:path isDirectory:&isDir]) {
        [WORKSPACE selectFile:path inFileViewerRootedAtPath:@""];
    }
}

- (void)openInFinder:(int)index {
    [WORKSPACE openFile:files[index][@"Path"]];
}

- (void)openInEditor:(int)index {

    NSString *defaultEditor = [DEFAULTS stringForKey:@"DefaultEditor"];
    NSString *path = files[index][@"Path"];
    
    if ([defaultEditor isEqualToString:DEFAULT_EDITOR] == NO) {
        // open it in the external application
        if ([WORKSPACE fullPathForApplication:defaultEditor] != nil) {
            [WORKSPACE openFile:path withApplication:defaultEditor];
            return;
        } else {
            [Alerts alert:@"Editor not found" subText:[NSString stringWithFormat:@"The application '%@' could not be found on your system.  Reverting to the built-in editor.", defaultEditor]];
            [DEFAULTS setObject:DEFAULT_EDITOR forKey:@"DefaultEditor"];
        }
    }
    
    // Open in built-in editor
    [window setTitle:[NSString stringWithFormat:@"%@ - Editing %@", PROGRAM_NAME, [path lastPathComponent]]];
    EditorController *editorController = [[EditorController alloc] init];
    [editorController showEditorForFile:path window:window];
    [window setTitle:PROGRAM_NAME];
}

- (IBAction)copyFilenames:(id)sender {
    
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    NSString *copyStr = @"";
    for (int i = 0; i < [files count]; i++) {
        if ([selectedItems containsIndex:i]) {
            NSString *filename = [files[i][@"Path"] lastPathComponent];
            copyStr = [copyStr stringByAppendingString:[NSString stringWithFormat:@"%@ ", filename]];
        }
    }
    [[NSPasteboard generalPasteboard] declareTypes:@[NSStringPboardType] owner:self];
    [[NSPasteboard generalPasteboard] setString:copyStr forType:NSStringPboardType];
}

- (IBAction)copyPaths:(id)sender {
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    NSString *copyStr = @"";
    for (int i = 0; i < [files count]; i++) {
        if ([selectedItems containsIndex:i]) {
            NSString *filename = files[i][@"Path"];
            copyStr = [copyStr stringByAppendingString:[NSString stringWithFormat:@"%@ ", filename]];
        }
    }
    [[NSPasteboard generalPasteboard] declareTypes:@[NSStringPboardType] owner:self];
    [[NSPasteboard generalPasteboard] setString:copyStr forType:NSStringPboardType];
}

- (IBAction)addFileToFileList:(id)sender {
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
    [self updateQueueWatch];
    [self updateFileSizeField];
    [tableView reloadData];
    [self updateButtonStatus];
}

- (IBAction)revealFileInFileList:(id)sender {
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    for (int i = 0; i < [files count]; i++) {
        if ([selectedItems containsIndex:i]) {
            [self revealInFinder:i];
        }
    }
}

- (IBAction)openFileInFileList:(id)sender {
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    for (int i = 0; i < [files count]; i++) {
        if ([selectedItems containsIndex:i]) {
            [self openInFinder:i];
        }
    }
}

- (IBAction)editFileInFileList:(id)sender {
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    for (int i = 0; i < [files count]; i++) {
        if ([selectedItems containsIndex:i]) {
            [self openInEditor:i];
        }
    }
}

- (IBAction)removeFileFromFileList:(id)sender {
    int rowToSelect;
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    int selectedRow = [selectedItems firstIndex];
    
    for (int i = [files count]; i >= 0; i--) {
        if ([selectedItems containsIndex:i]) {
            [self removeFileAtIndex:i];
        }
    }
    if ([tableView numberOfRows]) {
        rowToSelect = selectedRow - 1;
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowToSelect] byExtendingSelection:NO];
    }
    
    [tableView reloadData];
    [self updateButtonStatus];
    [self updateFileSizeField];
}

#pragma mark - NSTableViewDelegate/DataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [files count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] caseInsensitiveCompare:@"2"] == NSOrderedSame) { //path
        // check if bundled file still exists at path
        NSString *filePath = files[rowIndex][@"Path"];
        if ([FILEMGR fileExistsAtPath:filePath]) {
            return(files[rowIndex][@"Path"]);
        } else {
            // if not, we hilight red
            NSDictionary *attr = @{NSForegroundColorAttributeName: [NSColor redColor]};
            return [[[NSAttributedString alloc] initWithString:filePath attributes:attr] autorelease];
        }
    } else if ([[aTableColumn identifier] caseInsensitiveCompare:@"1"] == NSOrderedSame) {
        return files[rowIndex][@"Icon"];
    }
    
    return nil;
}

- (void)updateButtonStatus {
    //selection changed in File List
    int selected = 0;
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    for (int i = 0; i < [files count]; i++) {
        if ([selectedItems containsIndex:i]) {
            selected++;
        }
    }
    
    //update button status
    if (selected == 0) {
        [removeFileButton setEnabled:NO];
        [revealFileButton setEnabled:NO];
        [editFileButton setEnabled:NO];
    } else {
        [removeFileButton setEnabled:YES];
        [revealFileButton setEnabled:YES];
        [editFileButton setEnabled:YES];
    }
    
    [clearFileListButton setEnabled:([files count] != 0)];
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

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 20;
}

#pragma mark - Menu delegate

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    int selectedRow = [tableView selectedRow];
    
    if ([[anItem title] isEqualToString:@"Add New File"] || [[anItem title] isEqualToString:@"Add File To Bundle"]) {
        return YES;
    }
    if ([[anItem title] isEqualToString:@"Clear File List"] && [files count] >= 1) {
        return YES;
    }
    if (selectedRow == -1) {
        return NO;
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

#pragma mark -

- (BOOL)areAllPathsAreValid {
    for (NSDictionary *fileInfoDict in files) {
        if (![FILEMGR fileExistsAtPath:fileInfoDict[@"Path"]]) {
            return NO;
        }
    }
    return YES;
}

- (UInt64)totalFileSize {
    return totalFileSize;
}

@end
