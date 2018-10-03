/*
 Copyright (c) 2003-2018, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

#import "IconController.h"
#import "IconFamily.h"
#import "NSWorkspace+Additions.h"
#import "Common.h"
#import "VDKQueue.h"

typedef NS_ENUM(NSUInteger, PlatypusIconPreset) {
    PlatypusPresetIconDefault = 0,
    PlatypusPresetIconInstaller = 1,
    PlatypusPresetIconGenericApplication = 2
};

@interface IconController()
{
    IBOutlet STDragImageView *iconImageView;
    IBOutlet NSWindow *window;
    IBOutlet NSStepper *iconToggleButton;
    IBOutlet NSTextField *iconNameTextField;
    IBOutlet NSMenu *iconContextualMenu;
    IBOutlet NSButton *iconActionButton;
    
    VDKQueue *fileWatcherQueue;
    dispatch_queue_t iconWritingDispatchQueue;
}

- (IBAction)iconActionButtonPressed:(id)sender;
- (IBAction)copyIconPath:(id)sender;
- (IBAction)copyIcon:(id)sender;
- (IBAction)pasteIcon:(id)sender;
- (IBAction)revealIconInFinder:(id)sender;
- (IBAction)nextIcon:(id)sender;
- (IBAction)previousIcon:(id)sender;
- (IBAction)switchIcons:(id)sender;
- (IBAction)selectImageFile:(id)sender;
- (IBAction)selectIcnsFile:(id)sender;

@end

@implementation IconController

- (instancetype)init {
    if (self = [super init]) {
        fileWatcherQueue = [[VDKQueue alloc] init];
        iconWritingDispatchQueue = dispatch_queue_create("platypus.iconDispatchQueue", NULL);
    }
    return self;
}

- (void)dealloc {
    [[WORKSPACE notificationCenter] removeObserver:self];
    dispatch_release(iconWritingDispatchQueue);
}

- (void)awakeFromNib {
    // we list ourself as an observer of changes to watched file paths, in case icns file is deleted or moved
    [[WORKSPACE notificationCenter] addObserver:self selector:@selector(updateIcnsStatus) name:VDKQueueRenameNotification object:nil];
    [[WORKSPACE notificationCenter] addObserver:self selector:@selector(updateIcnsStatus) name:VDKQueueDeleteNotification object:nil];
}

#pragma mark - Interface actions

- (IBAction)copyIconPath:(id)sender {
    
    [[NSPasteboard generalPasteboard] declareTypes:@[NSStringPboardType] owner:self];
    [[NSPasteboard generalPasteboard] setString:[self icnsFilePath] forType:NSStringPboardType];
}

- (IBAction)copyIcon:(id)sender {
    [[NSPasteboard generalPasteboard] declareTypes:@[NSTIFFPboardType] owner:self];
    [[NSPasteboard generalPasteboard] setData:[[iconImageView image] TIFFRepresentation] forType:NSTIFFPboardType];
}

- (IBAction)pasteIcon:(id)sender {
    [self loadImageFromPasteboard];
}

- (IBAction)revealIconInFinder:(id)sender {
    [WORKSPACE selectFile:[self icnsFilePath] inFileViewerRootedAtPath:[self icnsFilePath]];
}

- (IBAction)selectImageFile:(id)sender {
    [window setTitle:[NSString stringWithFormat:@"%@ - Select an image file", PROGRAM_NAME]];
    
    // create open panel
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setPrompt:@"Select"];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setAllowedFileTypes:[NSImage imageTypes]];
    
    // run open panel sheet
    [oPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        [window setTitle:PROGRAM_NAME];
        if (result != NSOKButton) {
            return;
        }
        
        NSString *filename = [[oPanel URLs][0] path];
        NSString *fileType = [WORKSPACE typeOfFile:filename error:nil];
        
        if ([WORKSPACE type:fileType conformsToType:(NSString *)kUTTypeAppleICNS]) {
            [self loadIcnsFile:filename];
        } else {
            [self loadImageFile:filename];
        }
    }];
}

- (IBAction)selectIcnsFile:(id)sender {
    [window setTitle:[NSString stringWithFormat:@"%@ - Select an icns file", PROGRAM_NAME]];
    
    // create open panel
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setPrompt:@"Select"];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setAllowedFileTypes:@[(NSString *)kUTTypeAppleICNS]];
    
    //run open panel
    [oPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        [window setTitle:PROGRAM_NAME];
        if (result == NSOKButton) {
            NSString *filename = [[oPanel URLs][0] path];
            [self loadIcnsFile:filename];
        }
    }];
}

- (IBAction)iconActionButtonPressed:(id)sender {
    NSRect screenRect = [window convertRectToScreen:[(NSButton *)sender frame]];
    [iconContextualMenu popUpMenuPositioningItem:nil atLocation:screenRect.origin inView:nil];
}

- (IBAction)nextIcon:(id)sender {
    if ([iconToggleButton intValue] + 1 > [iconToggleButton maxValue]) {
        [iconToggleButton setIntValue:[iconToggleButton minValue]];
    } else {
        [iconToggleButton setIntValue:[iconToggleButton intValue] + 1];
    }
    [self setAppIconForType:(PlatypusIconPreset)[iconToggleButton intValue]];
}

- (IBAction)previousIcon:(id)sender {
    if ([iconToggleButton intValue] - 1 < [iconToggleButton minValue]) {
        [iconToggleButton setIntValue:[iconToggleButton maxValue]];
    } else {
        [iconToggleButton setIntValue:[iconToggleButton intValue] - 1];
    }
    [self setAppIconForType:(PlatypusIconPreset)[iconToggleButton intValue]];
}

- (IBAction)switchIcons:(id)sender {
    [self setAppIconForType:(PlatypusIconPreset)[sender intValue]];
}

#pragma mark -

- (void)updateIcnsStatus {
    // show question mark if icon file is missing
    if ([self hasIconFile] && [FILEMGR fileExistsAtPath:_icnsFilePath] == FALSE) {
        IconFamily *iconFam = [[IconFamily alloc] initWithSystemIcon:kQuestionMarkIcon];
        [iconImageView setImage:[iconFam imageWithAllReps]];
        [iconNameTextField setTextColor:[NSColor redColor]];
    } else {
        // otherwise, read icns image from path and put it in image view
        NSImage *img = [[NSImage alloc] initByReferencingFile:_icnsFilePath];
        if (img == nil) {
            img = [NSImage imageNamed:@"NSDefaultApplicationIcon"];
        }
        [iconImageView setImage:img];
        [iconNameTextField setTextColor:[NSColor controlTextColor]];
    }
}

- (void)createAndLoadCustomImageAsIcon:(NSImage *)image {
    NSString *tmpIconPath;
    do {
        tmpIconPath = [NSString stringWithFormat:@"%@/PlatypusIcon-%d.icns", PROGRAM_APP_SUPPORT_PATH, arc4random() % 99999];
    } while ([FILEMGR fileExistsAtPath:tmpIconPath]);
    
    dispatch_async(iconWritingDispatchQueue, ^{
        BOOL success = [self writeImageAsIcon:image toPath:tmpIconPath];
        
        // UI updates on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [iconNameTextField setStringValue:@"Custom Icon"];
                [self setIcnsFilePath:tmpIconPath];
            } else {
                [self setToDefaults];
            }
        });
    });
}

- (void)setAppIconForType:(PlatypusIconPreset)type {
    [self loadPresetIcon:[self getIconInfoForType:type]];
}

- (NSDictionary *)getIconInfoForType:(PlatypusIconPreset)type {
    NSImage *iconImage;
    NSString *iconName;
    NSString *iconPath;
    
    switch (type) {
            
        case PlatypusPresetIconDefault:
        {
            iconImage = [NSImage imageNamed:@"PlatypusDefault"];
            iconName = @"Platypus Default";
            [iconImage setSize:NSMakeSize(512, 512)];
            iconPath = [[NSBundle mainBundle] pathForResource:@"PlatypusDefault" ofType:@"icns"];
        }
            break;
            
        case PlatypusPresetIconInstaller:
        {
            NSString *installerIconPath = @"/System/Library/CoreServices/Installer.app/Contents/Resources/Installer.icns";
            iconImage = [[NSImage alloc] initByReferencingFile:installerIconPath];
            [iconImage setSize:NSMakeSize(512, 512)];
            iconName = @"Installer";
            iconPath = installerIconPath;
        }
            break;
        
        case PlatypusPresetIconGenericApplication:
        {
            iconImage = [NSImage imageNamed:@"NSDefaultApplicationIcon"];
            [iconImage setSize:NSMakeSize(512, 512)];
            iconName = @"Generic Application";
            
            return @{@"Name": iconName, @"Image": iconImage};
        }
    }
    
    return @{@"Name": iconName, @"Path": iconPath, @"Image": iconImage};
}

- (IBAction)setToDefaults {
    [self setAppIconForType:PlatypusPresetIconDefault];
}

#pragma mark -

- (BOOL)writeImageAsIcon:(NSImage *)iconImage toPath:(NSString *)path {
    if (iconImage == nil) {
        return NO;
    }
    IconFamily *iconFamily = [[IconFamily alloc] initWithThumbnailsOfImage:iconImage];
    if (iconFamily == nil) {
        PLog(@"Failed to create IconFamily from image");
        return NO;
    }
    [iconFamily writeToFile:path];
    return YES;
}

- (BOOL)hasIconFile {
    return (_icnsFilePath != nil);
}

- (void)setIcnsFilePath:(NSString *)path {
    
    if (_icnsFilePath != nil) {
        [fileWatcherQueue removePath:_icnsFilePath];
        _icnsFilePath = nil;
    }
    
    if (path != nil && [_icnsFilePath isEqualToString:@""] == NO) {
        _icnsFilePath = [[NSString alloc] initWithString:path];
        [fileWatcherQueue addPath:_icnsFilePath];
    }
    
    [self updateIcnsStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:PLATYPUS_APP_SIZE_CHANGED_NOTIFICATION object:nil];
}

- (BOOL)isPresetIcon:(NSString *)str {
    return [str hasPrefix:[[NSBundle mainBundle] resourcePath]];
}

#pragma mark - Loading icon

- (BOOL)loadIcnsFile:(NSString *)filePath {
    if (filePath == nil || [filePath isEqualToString:@""]) {
        [self setAppIconForType:PlatypusPresetIconGenericApplication];
        return YES;
    }
    
    NSImage *img = [[NSImage alloc] initWithContentsOfFile:filePath];
    if (img == nil) {
        NSBeep();
        [self setAppIconForType:PlatypusPresetIconGenericApplication];
         return NO;
    }
    
    [iconNameTextField setStringValue:[filePath lastPathComponent]];
    [self setIcnsFilePath:filePath];
    
    return YES;
}

- (BOOL)loadImageFile:(NSString *)filePath {
    NSImage *img = [[NSImage alloc] initByReferencingFile:filePath];
    if (img == nil) {
        return NO;
    }
    
    [self createAndLoadCustomImageAsIcon:img];
    return YES;
}

- (BOOL)loadImageFromPasteboard {
    NSImage *img = [[NSImage alloc] initWithPasteboard:[NSPasteboard generalPasteboard]];
    if (img == nil) {
        return NO;
    }
    
    [self createAndLoadCustomImageAsIcon:img];
    return YES;
}

- (BOOL)loadPresetIcon:(NSDictionary *)iconInfo {
    if (!iconInfo) {
        return NO;
    }
    
    [iconNameTextField setStringValue:iconInfo[@"Name"]];
    
    NSImage *img = iconInfo[@"Image"];
    if (img == nil) {
        return NO;
    }
    
    [self setIcnsFilePath:iconInfo[@"Path"]];
    
    return YES;
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    if ([[anItem title] isEqualToString:@"Paste Icon"]) {
        NSArray *pbTypes = @[NSTIFFPboardType, NSPDFPboardType, NSPostScriptPboardType];
        NSString *type = [[NSPasteboard generalPasteboard] availableTypeFromArray:pbTypes];

        if (type == nil) {
            return NO;
        }
    }
    if ([[anItem title] isEqualToString:@"Copy Icon Path"] || [[anItem title] isEqualToString:@"Show in Finder"]) {
        return [FILEMGR fileExistsAtPath:[self icnsFilePath]];
    }
    return YES;
}

#pragma mark - STDragImageViewDelegate

- (BOOL)performDragOperation:(id <NSDraggingInfo> )sender {
    NSPasteboard *pboard = [sender draggingPasteboard];

    if (![[pboard types] containsObject:NSFilenamesPboardType]) {
        return NO;
    }
    
    NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
    
    // first, we look for an icns file, and load it if there is one
    for (NSString *filename in files) {
        NSString *fileType = [WORKSPACE typeOfFile:filename error:nil];
        if ([WORKSPACE type:fileType conformsToType:(NSString *)kUTTypeAppleICNS]) {
            return [self loadIcnsFile:filename];
        }
    }
    
    // since no icns file, search for an image, load the first one we find
    NSArray *supportedImageTypes = [NSImage imageTypes];
    for (NSString *filename in files) {
        NSString *uti = [[NSWorkspace sharedWorkspace] typeOfFile:filename error:nil];
        if ([supportedImageTypes containsObject:uti]) {
            return [self loadImageFile:filename];
        }
    }
    
    return NO;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo> )sender {
    // we accept dragged files only
    if ([[[sender draggingPasteboard] types] containsObject:NSFilenamesPboardType] == NO) {
        return NSDragOperationNone;
    }

    NSArray *files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    
    // link operation for icns file, but not if it's a preset icon
    for (NSString *filename in files) {
        if ([self isPresetIcon:filename]) {
            return NSDragOperationNone;
        }
        NSString *fileType = [WORKSPACE typeOfFile:filename error:nil];
        if ([WORKSPACE type:fileType conformsToType:(NSString *)kUTTypeAppleICNS]) {
            return NSDragOperationLink;
        }
    }
    
    // copy operation icon for image file
    NSArray *supportedImageTypes = [NSImage imageTypes];
    for (NSString *filename in files) {
        NSString *uti = [[NSWorkspace sharedWorkspace] typeOfFile:filename error:nil];
        if ([supportedImageTypes containsObject:uti]) {
            return NSDragOperationCopy;
        }
    }
    
    return NSDragOperationNone;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
    // this is here to prevent superclass method from being invoked
}

@end
