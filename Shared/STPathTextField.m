/*
 STPathTextField.m
 
 Created by Sveinbjorn Thordarson on 6/27/08.
 Copyright (C) 2009 Sveinbjorn Thordarson. All rights reserved.
 
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
 
 ************************ LICENSE ***************************
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 **************************************************************
 */

#import "STPathTextField.h"

@implementation STPathTextField

/*******************************************
 Set all field settings to their default value
 ********************************************/

- (void)awakeFromNib
{
    // default settings for the text field
    autocompleteStyle = STShellAutocomplete;
    colorInvalidPath = YES;
    foldersAreValid = NO;
    expandTildeInPath = YES;
    
    [self registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
}

/*******************************************
 This will set the value of the text field
 to the file path of the dragged file
 This will NOT work if the field is being edited,
 since the receiver will then be the text editor
 See http://developer.apple.com/documentation/Cocoa/Conceptual/TextEditing/Tasks/HandlingDrops.html
 ********************************************/

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender 
{    
    if ([[[sender draggingPasteboard] types] containsObject:NSFilenamesPboardType] ) 
        return NSDragOperationLink;
    
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender 
{
    if ([[[sender draggingPasteboard] types] containsObject:NSFilenamesPboardType]) 
    {
        NSArray *files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
        [self setStringValue: [files objectAtIndex: 0]];
        return YES;
    }
    return NO;
}

/*******************************************
 Tell us whether the path in the path text 
 field is valid
 *********************************************/

-(BOOL)hasValidPath
{
    BOOL isDir;
    NSString *path = expandTildeInPath ? [[self stringValue] stringByExpandingTildeInPath] : [self stringValue];
    return ([[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDir] && (!(isDir && !foldersAreValid)));
}

/*******************************************
 If we're autocompleting browser-style, we
 perform the expansion and selection every time
 a key is released, unless it's navigation or deletion
 ********************************************/

-(void)keyUp:(NSEvent *)event
{
    int keyCode = [ [event characters] characterAtIndex: 0];
    
    if (autocompleteStyle == STBrowserAutocomplete)
    {
        if (keyCode != 13 && keyCode != 9 && keyCode != 127 && keyCode != NSLeftArrowFunctionKey && keyCode != NSRightArrowFunctionKey) 
            [self autoComplete: self];
    }
    [super keyUp:event];
    [self updateTextColoring];
}


/*******************************************
 Changed string value means we update coloring
 ********************************************/

- (void)setStringValue:(NSString *)aString
{
    [super setStringValue: aString];
    [self textDidChange: NULL];
}

/*******************************************
 If coloring is enabled, we set text color
 to red if invalid path, black if valid
 ********************************************/
-(void)updateTextColoring
{
    if (!colorInvalidPath)
        return;
    
    NSColor *textColor = [self hasValidPath] ? [NSColor blackColor]: [NSColor redColor];
    [self setTextColor: textColor];
}

/*******************************************
 This is the function that does the actual
 autocompletion.
 ********************************************/

-(int)autoComplete: (id)sender
{
    NSString *autocompletedPath = NULL;
    NSString *path = [self stringValue];
    char firstchar;
    int dlen, len = [path length];
    BOOL isDir;
    
    // let's not waste time if the string is empty
    if (len == 0)
        return 0;
    
    // we only try to expand if this looks like a real path, i.e. starts with / or ~
    firstchar = [path characterAtIndex: 0];
    if (firstchar != '/' && firstchar != '~')
        return 0;
    
    // expand tilde to home dir
    if (firstchar == '~' && expandTildeInPath)
    {
        path = [[self stringValue] stringByExpandingTildeInPath];
        len = [path length];
    }
    
    // get suggestion for autocompletion
    [path completePathIntoString: &autocompletedPath caseSensitive: YES matchesIntoArray: NULL filterTypes: NULL];
    
    // stop if no suggestions
    if (autocompletedPath == NULL)
        return 0;
    
    // stop if suggestion is current value and current value is a valid path
    if ([autocompletedPath isEqualToString: [self stringValue]] && 
        [[NSFileManager defaultManager] fileExistsAtPath: autocompletedPath isDirectory: &isDir] && 
        !(isDir && !foldersAreValid)) 
        return 0;
    
    // replace field string with autocompleted string
    [self setStringValue: autocompletedPath];
    
    // if browser style autocompletion is enabled
    // we select the autocomplete extension to the previous string
    if (autocompleteStyle == STBrowserAutocomplete)
    {
        dlen = [autocompletedPath length];
        [[self currentEditor] setSelectedRange: NSMakeRange(len, dlen)];
    }
    
    return 1;
}

// we make sure coloring is correct whenever text changes
- (void)textDidChange:(NSNotification *)aNotification
{
    if (colorInvalidPath)
        [self updateTextColoring];

    if ([self delegate] && [[self delegate] respondsToSelector: @selector(controlTextDidChange:)])
        [[self delegate] performSelector: @selector(controlTextDidChange:) withObject: nil];
}


/*******************************************
 We intercept tab inserts and try to autocomplete
 ********************************************/

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{    
    // intercept tab
    if (aSelector == @selector(insertTab:) && autocompleteStyle == STShellAutocomplete)
    {
        NSString *string = [self stringValue];
        BOOL result = NO;
        NSRange selectedRange = [aTextView selectedRange];
        
        // we only do tab autocomplete if the insertion point is at the end of the field
        // and if selection in the field is empty
        if (selectedRange.length == 0 && selectedRange.location == [[self stringValue] length])
            result = [self autoComplete: self];
        
        // we only let the user tab out of the field if it's empty or has valid path
        if ([[self stringValue] length] == 0 || ([self hasValidPath] && [string isEqualToString: [self stringValue]]))
            return NO;
        
        return result;
    }
    return false;
//    return [super textView: aTextView doCommandBySelector: aSelector];
}

/*******************************************
 Accessor functions for settings
 ********************************************/

-(void)setAutocompleteStyle: (int)style
{
    autocompleteStyle = style;
}

-(int)autocompleteStyle
{
    return autocompleteStyle;
}

-(void)setColorInvalidPath: (BOOL)val
{
    colorInvalidPath = val;
}

-(BOOL)colorInvalidPath
{
    return colorInvalidPath;
}

-(void)setFoldersAreValid: (BOOL)val
{
    foldersAreValid = val;
}

-(BOOL)foldersAreValid
{
    return foldersAreValid;
}

-(void)setExpandTildeInPath: (BOOL)val
{
    expandTildeInPath = val;
}

-(BOOL)expandTildeInPath
{
    return expandTildeInPath;
}

@end