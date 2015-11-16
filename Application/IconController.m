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

#import "IconController.h"
#import "IconFamily.h"
#import "NSWorkspace+Additions.h"
#import "Alerts.h"
#import "Common.h"
#import "VDKQueue.h"

@interface IconController()
{
    IBOutlet STDragImageView *iconImageView;
    IBOutlet NSWindow *window;
    IBOutlet NSStepper *iconToggleButton;
    IBOutlet NSTextField *iconNameTextField;
    IBOutlet NSMenu *iconContextualMenu;
    IBOutlet NSButton *iconActionButton;
    NSString *icnsFilePath;
    VDKQueue *fileWatcherQueue;
}

- (IBAction)iconActionButtonPressed:(id)sender;
- (IBAction)copyIconPath:(id)sender;
- (IBAction)copyIcon:(id)sender;
- (IBAction)pasteIcon:(id)sender;
- (IBAction)revealIconInFinder:(id)sender;
- (IBAction)contentsWereAltered:(id)sender;
- (IBAction)nextIcon:(id)sender;
- (IBAction)previousIcon:(id)sender;
- (IBAction)switchIcons:(id)sender;
- (IBAction)selectIcon:(id)sender;
- (IBAction)selectIcnsFile:(id)sender;

@end

@implementation IconController
@synthesize icnsFilePath = icnsFilePath;

- (instancetype)init {
    if ((self = [super init])) {
        fileWatcherQueue = [[VDKQueue alloc] init];
    }
    return self;
}

- (void)dealloc {
    [[WORKSPACE notificationCenter] removeObserver:self];
    
    if (icnsFilePath != nil) {
        [icnsFilePath release];
    }
    [fileWatcherQueue release];
    [super dealloc];
}

- (void)awakeFromNib {
    // we list ourself as an observer of changes to file system, in case of icns file moving
    [[WORKSPACE notificationCenter]
     addObserver:self selector:@selector(updateIcnsStatus) name:VDKQueueRenameNotification object:nil];
    [[WORKSPACE notificationCenter]
     addObserver:self selector:@selector(updateIcnsStatus) name:VDKQueueDeleteNotification object:nil];
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

- (IBAction)selectIcon:(id)sender {
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

// called when user pastes or cuts in field
- (IBAction)contentsWereAltered:(id)sender {
    [self updateForCustomIcon];
}

- (IBAction)iconActionButtonPressed:(id)sender {
    NSRect screenRect = [window convertRectToScreen:[(NSButton *)sender frame]];
    [iconContextualMenu popUpMenuPositioningItem:nil atLocation:screenRect.origin inView:nil ];
}

- (IBAction)nextIcon:(id)sender {
    if ([iconToggleButton intValue] + 1 > [iconToggleButton maxValue]) {
        [iconToggleButton setIntValue:[iconToggleButton minValue]];
    } else {
        [iconToggleButton setIntValue:[iconToggleButton intValue] + 1];
    }
    [self setAppIconForType:[iconToggleButton intValue]];
}

- (IBAction)previousIcon:(id)sender {
    if ([iconToggleButton intValue] - 1 < [iconToggleButton minValue]) {
        [iconToggleButton setIntValue:[iconToggleButton maxValue]];
    } else {
        [iconToggleButton setIntValue:[iconToggleButton intValue] - 1];
    }
    [self setAppIconForType:[iconToggleButton intValue]];
}

- (IBAction)switchIcons:(id)sender {
    [self setAppIconForType:[sender intValue]];
}

#pragma mark -

- (void)updateIcnsStatus {
    if ([self hasIconFile] && [FILEMGR fileExistsAtPath:icnsFilePath] == FALSE) {
        [iconNameTextField setTextColor:[NSColor redColor]];
    } else {
        [iconNameTextField setTextColor:[NSColor blackColor]];
    }
}

// sets text to custom icon
- (void)updateForCustomIcon {
    NSString *tmpIconPath;
    do {
        tmpIconPath = TMP_ICON_PATH;
    } while ([FILEMGR fileExistsAtPath:tmpIconPath]);
    
    if ([self writeIconToPath:tmpIconPath]) {
        [iconNameTextField setStringValue:@"Custom Icon"];
        [self setIcnsFilePath:tmpIconPath];
    } else {
        [self setToDefaults:self];
    }
}

- (void)setAppIconForType:(PlatypusIconPreset)type {
    [self loadPresetIcon:[self getIconInfoForType:type]];
}

- (NSDictionary *)getIconInfoForType:(int)type {
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
            iconImage = [[[NSImage alloc] initByReferencingFile:installerIconPath] autorelease];
            [iconImage setSize:NSMakeSize(512, 512)];
            iconName = @"Installer";
            iconPath = installerIconPath;
        }
        break;
        
        default:
        case PlatypusPresetIconGenericApplication:
        {
            iconImage = [NSImage imageNamed:@"NSDefaultApplicationIcon"];
            [iconImage setSize:NSMakeSize(512, 512)];
            iconName = @"Generic Application";
            iconPath = nil;
            
            return @{@"Image": iconImage, @"Name": iconName};
        }
        break;
        
    }
    
    return @{@"Image": iconImage, @"Name": iconName, @"Path": iconPath};
}

- (IBAction)setToDefaults:(id)sender {
    [self setAppIconForType:0];
}

#pragma mark -

- (BOOL)writeIconToPath:(NSString *)path {
    if ([iconImageView image] == nil) {
        return NO;
    }
    IconFamily *iconFam = [[IconFamily alloc] initWithThumbnailsOfImage:[iconImageView image]];
    if (!iconFam) {
        NSLog(@"Failed to create IconFamily from image");
        return NO;
    }
    [iconFam writeToFile:path];
    [iconFam release];
    return YES;
}

- (BOOL)hasIconFile {
    return (icnsFilePath != nil);
}

- (void)setIcnsFilePath:(NSString *)path {
    
    if (icnsFilePath != nil) {
        [fileWatcherQueue removePath:icnsFilePath];
        [icnsFilePath release];
        icnsFilePath = nil;
    }
    
    if (path != nil && [icnsFilePath isEqualToString:@""] == NO) {
        icnsFilePath = [[NSString alloc] initWithString:path];
        [fileWatcherQueue addPath:icnsFilePath];
    }
    
    [self updateIcnsStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:PLATYPUS_APP_SIZE_CHANGED_NOTIFICATION object:nil];
}

- (UInt64)iconFileSize {
    if (icnsFilePath == nil) {
        return 0;
    }
    
    if (![FILEMGR fileExistsAtPath:icnsFilePath]) {
        return 500000; // just guess the icon will be 400k in size
    }
    // else, just size of icns file
    return [WORKSPACE fileOrFolderSize:[self icnsFilePath]];
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
    
    [iconNameTextField setStringValue:[filePath lastPathComponent]];
    
    NSImage *img = [[[NSImage alloc] initByReferencingFile:filePath] autorelease];
    
    if (img == nil) {
        IconFamily *iconFam = [[[IconFamily alloc] initWithSystemIcon:kQuestionMarkIcon] autorelease];
        [iconImageView setImage:[iconFam imageWithAllReps]];
        return NO;
    }
    
    [iconImageView setImage:img];
    [self setIcnsFilePath:filePath];
    
    return YES;
}

- (BOOL)loadImageFile:(NSString *)filePath {
    NSImage *img = [[[NSImage alloc] initByReferencingFile:filePath] autorelease];
    if (img == nil) {
        return NO;
    }
    
    [iconImageView setImage:img];
    [self updateForCustomIcon];
    return YES;
}

- (BOOL)loadImageWithData:(NSData *)imgData {
    NSImage *img = [[[NSImage alloc] initWithData:imgData] autorelease];
    if (img == nil) {
        return NO;
    }
    
    [iconImageView setImage:img];
    [self updateForCustomIcon];
    return YES;
}

- (BOOL)loadImageFromPasteboard {
    NSImage *img = [[[NSImage alloc] initWithPasteboard:[NSPasteboard generalPasteboard]] autorelease];
    if (img == nil) {
        return NO;
    }
    
    [iconImageView setImage:img];
    [self updateForCustomIcon];
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
    [iconImageView setImage:img];
    
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
        if ([self icnsFilePath] == nil || [[self icnsFilePath] isEqualToString:@""]) {
            return NO;
        }
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
    // we accept dragged files
    if ([[[sender draggingPasteboard] types] containsObject:NSFilenamesPboardType]) {

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
    }
    
    return NSDragOperationNone;
}

@end
