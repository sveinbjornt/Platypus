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
#include <Security/Authorization.h>
#import "PlatypusUtility.h"
#import "STPrivilegedTask.h"
#import "Common.h"
#import "NSFileManager+TempFile.h"

@interface PrefsController : NSWindowController
{
    IBOutlet id revealAppCheckbox;
    IBOutlet id openAppCheckbox;
    IBOutlet id createOnScriptChangeCheckbox;
    IBOutlet id defaultEditorMenu;
    IBOutlet id defaultTextEncodingPopupButton;
    IBOutlet id defaultBundleIdentifierTextField;
    IBOutlet id defaultAuthorTextField;
    IBOutlet id CLTStatusTextField;
    IBOutlet id installCLTButton;
    IBOutlet id installCLTProgressIndicator;
    IBOutlet id prefsWindow;
}
- (IBAction)showWindow:(id)sender;
- (IBAction)applyPrefs:(id)sender;
- (void)setIconsForEditorMenu;
- (IBAction)restoreDefaultPrefs:(id)sender;
- (IBAction)installCLT:(id)sender;
- (void)installCommandLineTool;
- (void)uninstallCommandLineTool;
- (IBAction)uninstallPlatypus:(id)sender;
- (void)runCLTTemplateScript:(NSString *)scriptName usingDictionary:(NSDictionary *)placeholderDict;
- (BOOL)isCommandLineToolInstalled;
- (void)executeScriptTemplateWithPrivileges:(NSString *)scriptName usingDictionary:(NSDictionary *)placeholderDict;
- (IBAction)selectScriptEditor:(id)sender;
- (void)updateCLTStatus:(NSTextField *)textField;
- (IBAction)cancel:(id)sender;
@end
