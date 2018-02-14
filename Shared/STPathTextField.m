/*
 Copyright (c) 2003-2018, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
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
 
 STPathTextField.m
 
 ************************ ABOUT *****************************
 
 STPathTextField is a subclass of NSTextField for receiving
 and displaying a file system path.  It supports path validation
 and autocompletion.  Autocompletion can use "web browser" style -
 e.g. expansion and selection, or shell autocompletion style -
 tab-expansion.
 
 To use STPathTextField, just add a text field to a window in
 Interface Builder, and set its class to STPathTextField.
 
 See code on how to set the settings for the text field.
 Defaults are the following:
 
 autocompleteStyle = STNoAutocomplete;
 colorInvalidPath = YES;
 foldersAreValid = NO;
 expandTildeInPath = YES;
 
 There are three settings for autocompleteStyle
 
 enum
 {
    STNoAutocomplete = 0,
    STShellAutocomplete = 1,
    STBrowserAutocomplete = 2
 };

*/

#import "STPathTextField.h"

@implementation STPathTextField

- (void)awakeFromNib {
    // default settings
    self.autocompleteStyle = STShellAutocomplete;
    self.colorInvalidPath = YES;
    self.foldersAreValid = NO;
    self.expandTildeInPath = YES;
//    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
}

/*********************************************
 This will set the value of the text field
 to the file path of the dragged file
 This will NOT work if the field is being edited,
 since the receiver will then be the text editor
 See http://developer.apple.com/documentation/Cocoa/Conceptual/TextEditing/Tasks/HandlingDrops.html
 ********************************************/

//- (NSDragOperation)draggingEntered:(id <NSDraggingInfo> )sender {
//    if ([[[sender draggingPasteboard] types] containsObject:NSFilenamesPboardType]) {
//        return NSDragOperationLink;
//    }
//    
//    return NSDragOperationNone;
//}
//
//- (BOOL)performDragOperation:(id <NSDraggingInfo> )sender {
//    if ([[[sender draggingPasteboard] types] containsObject:NSFilenamesPboardType]) {
//        NSArray *files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
//        [self setStringValue:files[0]];
//        return YES;
//    }
//    return NO;
//}

/*********************************************
 Tell us whether path in text field is valid
 *********************************************/

- (BOOL)hasValidPath {
    BOOL isDir;
    NSString *path = self.expandTildeInPath ? [[self stringValue] stringByExpandingTildeInPath] : [self stringValue];
    return [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && ((isDir && !self.foldersAreValid) == NO);
}

/*********************************************
 If we're autocompleting browser-style, we
 perform the expansion and selection every time
 a key is released, unless it's navigation or deletion
 ********************************************/

- (void)keyUp:(NSEvent *)event {
    int keyCode = [[event characters] characterAtIndex:0];
    
    if (self.autocompleteStyle == STBrowserAutocomplete) {
        if (keyCode != 13 && keyCode != 9 && keyCode != 127 && keyCode != NSLeftArrowFunctionKey && keyCode != NSRightArrowFunctionKey)
            [self autoComplete:self];
    }
    [super keyUp:event];
    [self updateTextColoring];
}

/*********************************************
 Changed string value means we update coloring
 ********************************************/

- (void)setStringValue:(NSString *)aString {
    [super setStringValue:aString];
    [self performSelector:@selector(textDidChange:) withObject:nil];
}

/*********************************************
 If coloring is enabled, we set text color
 to red if invalid path, black if valid
 ********************************************/
- (void)updateTextColoring {
    if (!self.colorInvalidPath) {
        return;
    }
    NSColor *textColor = [self hasValidPath] ? [NSColor blackColor] : [NSColor redColor];
    [self setTextColor:textColor];
}

/*******************************************
 This is the function that does the actual
 autocompletion.
 ********************************************/

- (BOOL)autoComplete:(id)sender {
    NSString *autocompletedPath = nil;
    NSString *path = [self stringValue];
    unichar firstchar;
    NSInteger dlen, len = [path length];
    BOOL isDir;
    
    // let's not waste time if the string is empty
    if (len == 0) {
        return NO;
    }
    // we only try to expand if this looks like a real path, i.e. starts with / or ~
    firstchar = [path characterAtIndex:0];
    if (firstchar != '/' && firstchar != '~') {
        return NO;
    }
    
    // expand tilde to home dir
    if (firstchar == '~' && self.expandTildeInPath) {
        path = [[self stringValue] stringByExpandingTildeInPath];
        len = [path length];
    }
    
    // get suggestion for autocompletion
    [path completePathIntoString:&autocompletedPath caseSensitive:YES matchesIntoArray:nil filterTypes:nil];
    
    // stop if no suggestions
    if (autocompletedPath == nil) {
        return NO;
    }
    
    // stop if suggestion is current value and current value is a valid path
    if ([autocompletedPath isEqualToString:[self stringValue]] &&
        [[NSFileManager defaultManager] fileExistsAtPath:autocompletedPath isDirectory:&isDir] &&
        !(isDir && !self.foldersAreValid)) {
        return NO;
    }
    
    // replace field string with autocompleted string
    [self setStringValue:autocompletedPath];
    
    // if browser style autocompletion is enabled
    // we select the autocomplete extension to the previous string
    if (self.autocompleteStyle == STBrowserAutocomplete) {
        dlen = [autocompletedPath length];
        [[self currentEditor] setSelectedRange:NSMakeRange(len, dlen)];
    }
    
    return YES;
}

// we make sure coloring is correct whenever text changes
- (void)textDidChange:(NSNotification *)aNotification {
    if (self.colorInvalidPath) {
        [self updateTextColoring];
    }
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(controlTextDidChange:)]) {
        [[self delegate] performSelector:@selector(controlTextDidChange:) withObject:nil];
    }
}

/*************************************************
 We intercept tab inserts and try to autocomplete
 ************************************************/

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
    // intercept tab
    if (aSelector == @selector(insertTab:) && self.autocompleteStyle == STShellAutocomplete) {
        
        NSString *string = [self stringValue];
        BOOL result = NO;
        NSRange selectedRange = [aTextView selectedRange];
        
        // we only do tab autocomplete if the insertion point is at the end of the field
        // and if selection in the field is empty
        if (selectedRange.length == 0 && selectedRange.location == [[self stringValue] length]) {
            result = [self autoComplete:self];
        }
        
        // we only let the user tab out of the field if it's empty or has valid path
        if ([[self stringValue] length] == 0 || ([self hasValidPath] && [string isEqualToString:[self stringValue]])) {
            return NO;
        }
        
        return result;
    }
    return NO;
}

@end
