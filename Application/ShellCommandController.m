/*
 Copyright (c) 2003-2017, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
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

#import "ShellCommandController.h"
#import "PrefsController.h"
#import "PlatypusAppSpec.h"
#import "Common.h"
#import "NSWorkspace+Additions.h"

@interface ShellCommandController()
{
    IBOutlet NSTextView *textView;
    IBOutlet NSTextField *CLTStatusTextField;
    IBOutlet NSButton *useShortOptsCheckbox;
    
    PlatypusAppSpec *appSpec;
}

- (IBAction)close:(id)sender;
- (IBAction)useShortOptsCheckboxClicked:(id)sender;
- (IBAction)runInTerminal:(id)sender;

@end

@implementation ShellCommandController

- (instancetype)init {
    return [self initWithWindowNibName:@"ShellCommandWindow"];
}

- (void)awakeFromNib {
    [textView setFont:SHELL_COMMAND_STRING_FONT];
}

#pragma mark -

- (void)showModalShellCommandSheetForSpec:(PlatypusAppSpec *)spec window:(NSWindow *)theWindow {
    [self loadWindow];
    appSpec = spec;
    NSString *cmdStr = [appSpec commandStringUsingShortOpts:[useShortOptsCheckbox intValue]];
    [textView setString:cmdStr];
    
    // get rid of this ugly connection to PrefsController :/
    [PrefsController putCommandLineToolInstallStatusInTextField:CLTStatusTextField];
    
    [NSApp beginSheet:[self window]
       modalForWindow:theWindow
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
    
    [[self window] makeFirstResponder:[self window]]; // so enter key closes window
    [NSApp runModalForWindow:[self window]];
}

#pragma mark - Interface actions

- (IBAction)close:(id)sender {
    [NSApp endSheet:[self window]];
    [NSApp stopModal];
    [[self window] close];
}

- (IBAction)useShortOptsCheckboxClicked:(id)sender {
    [textView setString:[appSpec commandStringUsingShortOpts:[sender intValue]]];
}

- (IBAction)runInTerminal:(id)sender {
    [WORKSPACE runCommandInTerminal:[textView string]];
}

@end
