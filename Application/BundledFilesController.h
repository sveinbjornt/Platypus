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

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

@interface BundledFilesController : NSObject <NSTableViewDataSource>
{
    UInt64 totalSize;
    NSMutableArray *files;
    
    IBOutlet id window;
    IBOutlet id addFileButton;
    IBOutlet id removeFileButton;
    IBOutlet id editFileButton;
    IBOutlet id revealFileButton;
    IBOutlet id clearFileListButton;
    IBOutlet id tableView;
    IBOutlet id bundleSizeTextField;
    IBOutlet id contextualMenu;
    IBOutlet id platypusController;
}
- (void)itemDoubleClicked:(id)sender;
- (NSString *)getFileAtIndex:(int)index;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)addFile:(NSString *)file;
- (void)addFiles:(NSArray *)fileNames;
- (BOOL)hasFile:(NSString *)fileName;
- (void)clearList;
- (int)numFiles;
- (void)updateQueueWatch;
- (NSArray *)getFilesArray;
- (void)removeFile:(int)index;
- (void)revealInFinder:(int)index;
- (void)openInFinder:(int)index;
- (IBAction)editFileInFileList:(id)sender;
- (IBAction)addFileToFileList:(id)sender;
- (IBAction)clearFileList:(id)sender;
- (IBAction)revealFileInFileList:(id)sender;
- (IBAction)openFileInFileList:(id)sender;
- (IBAction)removeFileFromFileList:(id)sender;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo> ) info row:(int)row dropOperation:(NSTableViewDropOperation)operation;
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard;
- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo> ) info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation;
- (void)updateFileSizeField;
- (BOOL)allPathsAreValid;
- (UInt64)getTotalSize;
- (void)trackedFileDidChange;

@end
