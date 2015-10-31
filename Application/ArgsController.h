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

#import <Cocoa/Cocoa.h>

@interface ArgsController : NSObject <NSTableViewDataSource>
{
    IBOutlet id argsWindow;
    IBOutlet id commandTextField;
    IBOutlet id interpreterTextField;
    
    IBOutlet id interpreterArgsAddButton;
    IBOutlet id interpreterArgsRemoveButton;
    IBOutlet id interpreterArgsClearButton;
    IBOutlet id interpreterArgsTableView;
    
    IBOutlet id scriptArgsAddButton;
    IBOutlet id scriptArgsRemoveButton;
    IBOutlet id scriptArgsClearButton;
    IBOutlet id scriptArgsTableView;
    
    IBOutlet id isDroppableCheckbox;
    IBOutlet id window;
    
    IBOutlet id scriptArgsContextualMenu;
    IBOutlet id interpreterArgsContextualMenu;
    
    NSMutableArray *interpreterArgs;
    NSMutableArray *scriptArgs;
}
- (NSArray *)interpreterArgs;
- (NSArray *)scriptArgs;
- (void)setInterpreterArgs:(NSArray *)array;
- (void)setScriptArgs:(NSArray *)array;

- (IBAction)apply:(id)sender;

- (IBAction)addInterpreterArg:(id)sender;
- (IBAction)removeInterpreterArg:(id)sender;
- (IBAction)clearInterpreterArgs:(id)sender;

- (IBAction)addScriptArg:(id)sender;
- (IBAction)removeScriptArg:(id)sender;
- (IBAction)clearScriptArgs:(id)sender;

- (IBAction)resetDefaults:(id)sender;

- (IBAction)show:(id)sender;
- (NSString *)constructCommandString;

// table view handling
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

- (IBAction)showHelp:(id)sender;

@end
