/*
    Copyright (c) 2003-2021, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

#import "SyntaxCheckerController.h"
#import "PlatypusScriptUtils.h"

@interface SyntaxCheckerController()
{
    IBOutlet NSTextView *textView;
    IBOutlet NSTextField *scriptNameTextField;
}
@end

@implementation SyntaxCheckerController

- (instancetype)init {
    return [self initWithWindowNibName:@"SyntaxChecker"];
}

- (void)awakeFromNib {
    [textView setFont:[NSFont userFixedPitchFontOfSize:11.0]];
}

- (void)showModalSyntaxCheckerSheetForFile:(NSString *)filePath
                                scriptName:(NSString *)scriptName
                    usingInterpreterAtPath:(NSString *)interpreterPath
                                    window:(NSWindow *)parentWindow {
    [self loadWindow];
    
    [scriptNameTextField setStringValue:scriptName];
    
    NSString *reportText = [PlatypusScriptUtils checkSyntaxOfFile:filePath
                                              usingInterpreterAtPath:interpreterPath];
    [textView setString:reportText];
    
    [NSApp beginSheet:[self window]
       modalForWindow:parentWindow
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
    
    [[self window] makeFirstResponder:[self window]]; // So enter key closes window
    [NSApp runModalForWindow:[self window]];
}

- (IBAction)close:(id)sender {
    [NSApp stopModal];
    [NSApp endSheet:[self window]];
    [[self window] close];
}

@end
