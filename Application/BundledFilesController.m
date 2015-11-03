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

// This is a controller class around the Bundled Files list in the Platypus
// window.  It is the data source and delegate of the tableview with the files.
//
// NOTE: It's also a complete mess and needs to be rewritten, it was one of the very first
// pieces of code I ever wrote in Objective C, way back in the days...

#import <Carbon/Carbon.h>
#import "BundledFilesController.h"
#import "VDKQueue.h"
#import "EditorController.h"
#import "PlatypusController.h"
#import "NSFileManager+Additions.h"
#import "Alerts.h"
#import "Common.h"

@implementation BundledFilesController

- (id)init {
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
    [tableView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(itemDoubleClicked:)];
    [tableView setDraggingSourceOperationMask:NSDragOperationCopy | NSDragOperationMove forLocal:NO];
    
    // we list ourself as an observer of changes to file system
    [[WORKSPACE notificationCenter] addObserver:self selector:@selector(trackedFileDidChange) name:VDKQueueRenameNotification object:nil];
    [[WORKSPACE notificationCenter] addObserver:self selector:@selector(trackedFileDidChange) name:VDKQueueDeleteNotification object:nil];
}

#pragma mark -

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

- (void)trackedFileDidChange {
    [tableView reloadData];
}

- (NSString *)filePathAtIndex:(int)index {
    return [[files objectAtIndex:index] objectForKey:@"Path"];
}

- (void)addFile:(NSString *)fileName {
    [self addFiles:[NSArray arrayWithObject:fileName]];
}

- (void)addFiles:(NSArray *)fileNames {
    for (int i = 0; i < [fileNames count]; i++) {
        NSString *filePath = [fileNames objectAtIndex:i];
        
        if (![self hasFile:filePath]) {
            NSMutableDictionary *fileInfoDict = [NSMutableDictionary dictionaryWithCapacity:10];
            [fileInfoDict setObject:filePath forKey:@"Path"];
            
            NSImage *icon = [WORKSPACE iconForFile:filePath];
            [icon setSize:NSMakeSize(16, 16)];
            
            [fileInfoDict setObject:icon forKey:@"Icon"];
            [files addObject:fileInfoDict];
        }
    }
    [tableView reloadData];
    [self tableViewSelectionDidChange:nil];
    [self updateQueueWatch];
    
    [self updateFileSizeField];
}

- (void)updateQueueWatch {
    [fileWatcherQueue removeAllPaths];
    for (NSDictionary *fileItem in files) {
        [fileWatcherQueue addPath:[fileItem objectForKey:@"Path"]];
    }
}

- (BOOL)hasFile:(NSString *)fileName {
    for (int i = 0; i < [files count]; i++) {
        if ([[[files objectAtIndex:i] objectForKey:@"Path"] isEqualToString:fileName]) {
            return YES;
        }
    }
    return NO;
}

- (void)clearList {
    [files removeAllObjects];
    [self updateQueueWatch];
    [tableView reloadData];
}

- (void)removeFile:(int)index {
    [files removeObjectAtIndex:index];
    [self updateQueueWatch];
    [tableView reloadData];
}

- (int)numFiles {
    return([files count]);
}

- (NSArray *)filePaths {
    NSMutableArray *filePaths = [NSMutableArray array];
    for (NSDictionary *fileItem in files) {
        [filePaths addObject:[fileItem objectForKey:@"Path"]];
    }
    return filePaths;
}

- (void)revealInFinder:(int)index {
    BOOL isDir;
    NSString *path = [[files objectAtIndex:index] objectForKey:@"Path"];
    
    if ([FILEMGR fileExistsAtPath:path isDirectory:&isDir]) {
        [WORKSPACE selectFile:path inFileViewerRootedAtPath:@""];
    }
}

- (void)openInFinder:(int)index {
    [WORKSPACE openFile:[[files objectAtIndex:index] objectForKey:@"Path"]];
}

- (void)openInEditor:(int)index {

    NSString *defaultEditor = [DEFAULTS stringForKey:@"DefaultEditor"];
    NSString *path = [[files objectAtIndex:index] objectForKey:@"Path"];
    
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

- (IBAction)copyFilename:(id)sender {
    
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    NSString *copyStr = @"";
    for (int i = 0; i < [self numFiles]; i++) {
        if ([selectedItems containsIndex:i]) {
            NSString *filename = [[[files objectAtIndex:i] objectForKey:@"Path"] lastPathComponent];
            copyStr = [copyStr stringByAppendingString:[NSString stringWithFormat:@"%@ ", filename]];
        }
    }
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
    [[NSPasteboard generalPasteboard] setString:copyStr forType:NSStringPboardType];
}

- (IBAction)copyPaths:(id)sender {
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    NSString *copyStr = @"";
    for (int i = 0; i < [self numFiles]; i++) {
        if ([selectedItems containsIndex:i]) {
            NSString *filename = [[files objectAtIndex:i] objectForKey:@"Path"];
            copyStr = [copyStr stringByAppendingString:[NSString stringWithFormat:@"%@ ", filename]];
        }
    }
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
    [[NSPasteboard generalPasteboard] setString:copyStr forType:NSStringPboardType];
}

/*****************************************
 - called when a [+] button is pressed
 *****************************************/

- (IBAction)addFileToFileList:(id)sender {
    [window setTitle:[NSString stringWithFormat:@"%@ - Select files or folders to add", PROGRAM_NAME]];
    
    // create open panel
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setPrompt:@"Add"];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setAllowsMultipleSelection:YES];
    
    //run open panel sheet
    [oPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        
        if (result != NSOKButton) {
            return;
        }
        
        // convert NSURLs to paths
        NSMutableArray *filePaths = [NSMutableArray array];
        for (NSURL *url in [oPanel URLs]) {
            [filePaths addObject:[url path]];
        }
        
        [self addFiles:filePaths];
        [window setTitle:PROGRAM_NAME];
    }];
}

/*****************************************
 - called when [C] button is pressed
 *****************************************/

- (IBAction)clearFileList:(id)sender {
    [self clearList];
    [self updateQueueWatch];
    [tableView reloadData];
    [self tableViewSelectionDidChange:nil];
    [self updateFileSizeField];
}

- (IBAction)revealFileInFileList:(id)sender {
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    for (int i = 0; i < [self numFiles]; i++) {
        if ([selectedItems containsIndex:i]) {
            [self revealInFinder:i];
        }
    }
}

- (IBAction)openFileInFileList:(id)sender {
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    for (int i = 0; i < [self numFiles]; i++) {
        if ([selectedItems containsIndex:i]) {
            [self openInFinder:i];
        }
    }
}

- (IBAction)editFileInFileList:(id)sender {
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    for (int i = 0; i < [self numFiles]; i++) {
        if ([selectedItems containsIndex:i]) {
            [self openInEditor:i];
        }
    }
}

/*****************************************
 - called when [-] button is pressed
 *****************************************/

- (IBAction)removeFileFromFileList:(id)sender {
    int rowToSelect;
    NSIndexSet *selectedItems = [tableView selectedRowIndexes];
    int selectedRow = [selectedItems firstIndex];
    
    for (int i = [self numFiles]; i >= 0; i--) {
        if ([selectedItems containsIndex:i]) {
            [self removeFile:i];
        }
    }
    if ([tableView numberOfRows]) {
        rowToSelect = selectedRow - 1;
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowToSelect] byExtendingSelection:NO];
    }
    
    [tableView reloadData];
    [self tableViewSelectionDidChange:nil];
    [self updateFileSizeField];
}

/*****************************************
 - Updates text field listing total size of bundled files
 *****************************************/
- (void)updateFileSizeField {
    
    totalFileSize = 0;
    
    //if there are no items, we just list it as 0 items
    if ([self numFiles] == 0) {
        [bundleSizeTextField setStringValue:@""];
        [platypusController updateEstimatedAppSize];
        return;
    }
    
    //otherwise, loop through all files, calculate size in a separate queue
    [bundleSizeTextField setStringValue:@"Calculating size..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        for (int i = 0; i < [self numFiles]; i++) {
            totalFileSize += [FILEMGR fileOrFolderSize:[self filePathAtIndex:i]];
        }
        
        NSString *totalSizeString = [FILEMGR sizeAsHumanReadable:totalFileSize];
        NSString *pluralS = ([self numFiles] > 1) ? @"s" : @"";

        //run UI updates on main thread
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [bundleSizeTextField setStringValue:[NSString stringWithFormat:@"%d item%@, %@", [self numFiles], pluralS, totalSizeString]];
            [platypusController updateEstimatedAppSize];
        });
    });
}

#pragma mark - NSTableViewDelegate/DataSource

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [self numFiles];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if ([[aTableColumn identifier] caseInsensitiveCompare:@"2"] == NSOrderedSame) { //path
        // check if bundled file still exists at path
        NSString *filePath = [[files objectAtIndex:rowIndex] objectForKey:@"Path"];
        if ([FILEMGR fileExistsAtPath:filePath]) {
            return([[files objectAtIndex:rowIndex] objectForKey:@"Path"]);
        } else {
            // if not, we hilight red
            NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor redColor], NSForegroundColorAttributeName, nil];
            return [[[NSAttributedString alloc] initWithString:filePath attributes:attr] autorelease];
        }
    } else if ([[aTableColumn identifier] caseInsensitiveCompare:@"1"] == NSOrderedSame) {
        return [[files objectAtIndex:rowIndex] objectForKey:@"Icon"];
    }
    
    return nil;
}

/*****************************************
 - Delegate managing selection in the Bundled Files list
 *****************************************/

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    int selected = 0;
    NSIndexSet *selectedItems;
    
    //selection changed in File List
    if ([aNotification object] == tableView || [aNotification object] == nil) {
        selectedItems = [tableView selectedRowIndexes];
        for (int i = 0; i < [self numFiles]; i++) {
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
        
        if ([self numFiles] == 0) {
            [clearFileListButton setEnabled:NO];
        } else {
            [clearFileListButton setEnabled:YES];
        }
    }
}

/*****************************************
 - Drag and drop handling
 *****************************************/
- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo> )info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *draggedFiles = [pboard propertyListForType:NSFilenamesPboardType];
    [self addFiles:draggedFiles];
    return YES;
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    NSMutableArray *filenames = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
    NSInteger index = [rowIndexes firstIndex];
    
    while (NSNotFound != index) {
        [filenames addObject:[[files objectAtIndex:index] objectForKey:@"Path"]];
        index = [rowIndexes indexGreaterThanIndex:index];
    }
    
    [pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
    [pboard setPropertyList:filenames forType:NSFilenamesPboardType];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo> )info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
    return NSDragOperationLink;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 20;
}

#pragma mark -

/*****************************************
 - Delegate for enabling and disabling contextual menu items
 *****************************************/
- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    int selectedRow = [tableView selectedRow];
    
    if ([[anItem title] isEqualToString:@"Add New File"] || [[anItem title] isEqualToString:@"Add File To Bundle"]) {
        return YES;
    }
    if ([[anItem title] isEqualToString:@"Clear File List"] && [self numFiles] >= 1) {
        return YES;
    }
    if (selectedRow == -1) {
        return NO;
    }
    
    // Folders are never editable
    if ([[anItem title] isEqualToString:@"Open in Editor"])  {
        NSIndexSet *selectedItems = [tableView selectedRowIndexes];
        for (int i = 0; i < [self numFiles]; i++) {
            if ([selectedItems containsIndex:i]) {
                NSString *filename = [[files objectAtIndex:i] objectForKey:@"Path"];
                BOOL isFolder;
                [FILEMGR fileExistsAtPath:filename isDirectory:&isFolder];
                return !isFolder;
            }
        }
    }
    
    return YES;
}

#pragma mark -

/*****************************************
 - Tells us whether there are missing/moved files on the list
 *****************************************/
- (BOOL)allPathsAreValid {
    for (int i = 0; i < [self numFiles]; i++) {
        if (![FILEMGR fileExistsAtPath:[[files objectAtIndex:i] objectForKey:@"Path"]]) {
            return NO;
        }
    }
    return YES;
}

/*****************************************
 - Returns the total size of all bundled files at the moment
 *****************************************/

- (UInt64)totalFileSize {
    return totalFileSize;
}

@end
