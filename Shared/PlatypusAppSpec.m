/*
    Copyright (c) 2003-2023, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

// PlatypusAppSpec is a wrapper class around an NSDictionary containing all
// the information / specifications needed to create a Platypus application.

#import "Common.h"
#import "PlatypusAppSpec.h"
#import "PlatypusScriptUtils.h"
#import "NSWorkspace+Additions.h"
#import "NSFileManager+TempFiles.h"

@implementation PlatypusAppSpec

#pragma mark - Create spec

- (instancetype)initWithDefaults {
    if (self = [self init]) {
        [self setDefaults];
    }
    return self;
}

- (instancetype)initWithDefaultsForScript:(NSString *)scriptPath {
    if (self = [self initWithDefaults]) {
        [self setDefaultsForScript:scriptPath];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [self initWithDefaults]) {
        [self addEntriesFromDictionary:dict];
        
        // Backwards compatibility, mapping old spec key names to new
        if (dict[AppSpecKey_InterpreterPath_Legacy]) {
            self[AppSpecKey_InterpreterPath] = dict[AppSpecKey_InterpreterPath_Legacy];
        }
        if (dict[AppSpecKey_InterfaceType_Legacy]) {
            self[AppSpecKey_InterfaceType] = dict[AppSpecKey_InterfaceType_Legacy];
        }
        if (dict[AppSpecKey_DocIconPath_Legacy]) {
            self[AppSpecKey_DocIconPath] = dict[AppSpecKey_DocIconPath_Legacy];
        }
        if (dict[AppSpecKey_RunInBackground_Legacy]) {
            self[AppSpecKey_RunInBackground] = dict[AppSpecKey_RunInBackground_Legacy];
        }        
    }
    return self;
}

- (instancetype)initWithProfile:(NSString *)profilePath {
    NSDictionary *profileDict = [NSDictionary dictionaryWithContentsOfFile:profilePath];
    if (profileDict == nil) {
        return nil;
    }
    
    NSMutableDictionary *updatedDict = [profileDict mutableCopy];
    NSString *basePath = [profilePath stringByDeletingLastPathComponent];
    
    // Find all non-absolute paths and resolve them
    // relative to the profile's containing folder
    for (NSString *key in profileDict) {
        
        // Keys ending with "Path", e.g. "InterpreterPath"
        if ([key hasSuffix:@"Path"] && ![profileDict[key] isEqualToString:@""]
            && [profileDict[key] isAbsolutePath] == NO) {
            NSString *absPath = [NSString stringWithFormat:@"%@/%@", basePath, profileDict[key]];
            updatedDict[key] = [absPath stringByStandardizingPath];
        }
        
        // Bundled files
        if ([key isEqualToString:AppSpecKey_BundledFiles]) {
            NSArray <NSString *> *paths = profileDict[key];
            updatedDict[key] = [NSMutableArray array];
            for (NSString *path in paths) {
                NSString *absPath = path;
                if ([path isAbsolutePath] == NO) {
                    absPath = [NSString stringWithFormat:@"%@/%@", basePath, path];
                }
                [updatedDict[key] addObject:absPath];
            }
        }
    }
    
    return [self initWithDictionary:(NSDictionary *)updatedDict];
}

+ (instancetype)specWithDefaults {
    return [[self alloc] initWithDefaults];
}

+ (instancetype)specWithDictionary:(NSDictionary *)dict {
    return [[self alloc] initWithDictionary:dict];
}

+ (instancetype)specWithProfile:(NSString *)profilePath {
    return [[self alloc] initWithProfile:profilePath];
}

+ (instancetype)specWithDefaultsFromScript:(NSString *)scriptPath {
    return [[self alloc] initWithDefaultsForScript:scriptPath];
}

#pragma mark - Set default values

- (void)setDefaults {
    self[AppSpecKey_Creator] = PROGRAM_CREATOR_STAMP;
    
    self[AppSpecKey_ExecutablePath] = CMDLINE_SCRIPT_EXEC_PATH;
    self[AppSpecKey_NibPath] = CMDLINE_NIB_PATH;
    self[AppSpecKey_DestinationPath] = DEFAULT_DESTINATION_PATH;
    self[AppSpecKey_Overwrite] = @NO;
    self[AppSpecKey_SymlinkFiles] = @NO;
    self[AppSpecKey_StripNib] = @NO;
    
    self[AppSpecKey_Name] = DEFAULT_APP_NAME;
    self[AppSpecKey_ScriptPath] = @"";
    self[AppSpecKey_InterfaceType] = DEFAULT_INTERFACE_TYPE_STRING;
    self[AppSpecKey_IconPath] = @"";
    
    self[AppSpecKey_InterpreterPath] = DEFAULT_INTERPRETER_PATH;
    self[AppSpecKey_InterpreterArgs] = @[];
    self[AppSpecKey_ScriptArgs] = @[];
    self[AppSpecKey_Version] = DEFAULT_VERSION;
    self[AppSpecKey_Identifier] = [PlatypusAppSpec bundleIdentifierForAppName:nil
                                                                   authorName:nil
                                                                usingDefaults:YES];
    
    NSString *defaultsAuthor = [DEFAULTS stringForKey:DefaultsKey_DefaultAuthor];
    self[AppSpecKey_Author] = defaultsAuthor ? defaultsAuthor : NSFullUserName();;
    
    self[AppSpecKey_Droppable] = @NO;
    self[AppSpecKey_Authenticate] = @NO;
    self[AppSpecKey_RemainRunning] = @YES;
    self[AppSpecKey_RunInBackground] = @NO;
    self[AppSpecKey_SendNotifications] = @NO;
    
    self[AppSpecKey_BundledFiles] = [NSMutableArray array];
    
    // File/drag acceptance properties
    self[AppSpecKey_Suffixes] = DEFAULT_SUFFIXES;
    self[AppSpecKey_Utis] = DEFAULT_UTIS;
    self[AppSpecKey_URISchemes] = DEFAULT_URI_PROTOCOLS;
    self[AppSpecKey_AcceptText] = @NO;
    self[AppSpecKey_AcceptFiles] = @NO;
    self[AppSpecKey_Service] = @NO;
    self[AppSpecKey_PromptForFile] = @NO;
    self[AppSpecKey_DocIconPath] = @"";
    
    // Text window settings
    self[AppSpecKey_TextFont] = DEFAULT_TEXT_FONT_NAME;
    self[AppSpecKey_TextSize] = @(DEFAULT_TEXT_FONT_SIZE);
    self[AppSpecKey_TextColor] = DEFAULT_TEXT_FG_COLOR;
    self[AppSpecKey_TextBackgroundColor] = DEFAULT_TEXT_BG_COLOR;
    
    // Status item settings
    self[AppSpecKey_StatusItemDisplayType] = PLATYPUS_STATUSITEM_DISPLAY_TYPE_DEFAULT;
    self[AppSpecKey_StatusItemTitle] = DEFAULT_STATUS_ITEM_TITLE;
    self[AppSpecKey_StatusItemIcon] = [NSData data];
    self[AppSpecKey_StatusItemUseSysfont] = @YES;
    self[AppSpecKey_StatusItemIconIsTemplate] = @NO;
}

/********************************************************
 Init with default values and then analyse script, then
 load default values based on analysed script properties
 ********************************************************/

- (void)setDefaultsForScript:(NSString *)scriptPath {
    // Start with a dict populated with defaults
    [self setDefaults];
    
    // Set script path
    self[AppSpecKey_ScriptPath] = scriptPath;
    
    // Determine app name based on script filename
    self[AppSpecKey_Name] = [PlatypusScriptUtils appNameFromScriptFile:scriptPath];
    
    // Find an interpreter for it
    NSString *interpreterPath = [PlatypusScriptUtils determineInterpreterPathForScriptFile:scriptPath];
    if (interpreterPath == nil || [interpreterPath isEqualToString:@""]) {
        interpreterPath = DEFAULT_INTERPRETER_PATH;
    } else {
        // Get args for interpreter
        NSMutableArray *shebangCmdComponents = [NSMutableArray arrayWithArray:[PlatypusScriptUtils parseInterpreterInScriptFile:scriptPath]];
        [shebangCmdComponents removeObjectAtIndex:0];
        self[AppSpecKey_InterpreterArgs] = shebangCmdComponents;
    }
    self[AppSpecKey_InterpreterPath] = interpreterPath;
    self[AppSpecKey_InterpreterArgs] = [PlatypusScriptUtils interpreterArgsForInterpreterPath:interpreterPath];
    self[AppSpecKey_ScriptArgs] = [PlatypusScriptUtils scriptArgsForInterpreterPath:interpreterPath];
    
    // Find parent folder wherefrom we create destination path of app bundle
    NSString *parentFolder = [scriptPath stringByDeletingLastPathComponent];
    NSString *destPath = [NSString stringWithFormat:@"%@/%@.app", parentFolder, self[AppSpecKey_Name]];
    self[AppSpecKey_DestinationPath] = destPath;
    self[AppSpecKey_Identifier] = [PlatypusAppSpec bundleIdentifierForAppName:self[AppSpecKey_Name]
                                                                   authorName:nil
                                                                usingDefaults:YES];
}

#pragma mark -

// Create app bundle based on spec data
- (BOOL)create {
    
    // Check if app already exists
    if ([FILEMGR fileExistsAtPath:self[AppSpecKey_DestinationPath]]) {
        if ([self[AppSpecKey_Overwrite] boolValue] == FALSE) {
            _error = [NSString stringWithFormat:@"App already exists at path %@. Use -y flag to overwrite.", self[AppSpecKey_DestinationPath]];
            return FALSE;
        }
        [self report:@"Overwriting app at path %@", self[AppSpecKey_DestinationPath]];
    }
    
    // Check if executable exists
    NSString *execSrcPath = self[AppSpecKey_ExecutablePath];
    if (![FILEMGR fileExistsAtPath:execSrcPath] || ![FILEMGR isReadableFileAtPath:execSrcPath]) {
        [self report:@"Executable %@ does not exist. Aborting.", execSrcPath];
        return NO;
    }
    
    // Check if source nib exists
    NSString *nibPath = self[AppSpecKey_NibPath];
    if (![FILEMGR fileExistsAtPath:nibPath] || ![FILEMGR isReadableFileAtPath:nibPath]) {
        [self report:@"Nib file %@ does not exist. Aborting.", nibPath];
        return NO;
    }
    
    [self report:@"Creating application bundle folder hierarchy"];
    
    // .app bundle
    // Get temporary directory, make sure it's kosher. Apparently NSTemporaryDirectory() can return nil
    // See http://www.cocoadev.com/index.pl?NSTemporaryDirectory
    NSString *tmpPath = NSTemporaryDirectory();
    if (tmpPath == nil) {
        tmpPath = @"/tmp/"; // Fallback, just in case
    }
    
    // Make sure we can write to temp path
    if ([FILEMGR isWritableFileAtPath:tmpPath] == NO) {
        _error = [NSString stringWithFormat:@"Could not write to the temp directory '%@'.", tmpPath];
        return FALSE;
    }
    
    // .app
    tmpPath = [tmpPath stringByAppendingString:[self[AppSpecKey_DestinationPath] lastPathComponent]];
    [FILEMGR createDirectoryAtPath:tmpPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    // .app/Contents
    NSString *contentsPath = [tmpPath stringByAppendingString:@"/Contents"];
    [FILEMGR createDirectoryAtPath:contentsPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    // .app/Contents/MacOS
    NSString *macosPath = [contentsPath stringByAppendingString:@"/MacOS"];
    [FILEMGR createDirectoryAtPath:macosPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    // .app/Contents/Resources
    NSString *resourcesPath = [contentsPath stringByAppendingString:@"/Resources"];
    [FILEMGR createDirectoryAtPath:resourcesPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    [self report:@"Copying executable to bundle"];
    
    // Copy exec file
    // .app/Contents/Resources/MacOS/ScriptExec
    NSString *outFolder = [macosPath stringByAppendingString:@"/"];
    NSString *execDestPath = [outFolder stringByAppendingString:self[AppSpecKey_Name]];
    if ([execSrcPath hasSuffix:GZIP_SUFFIX]) {
        // Create empty file
        [FILEMGR createFileAtPath:execDestPath contents:nil attributes:nil];
        NSFileHandle *outFile = [NSFileHandle fileHandleForWritingAtPath:execDestPath];
        // Extract gzip destination folder
        // gunzip -c ScriptExec.gz > filehandle
        NSTask *gunzipTask = [[NSTask alloc] init];
        [gunzipTask setLaunchPath:@"/usr/bin/gunzip"];
        [gunzipTask setArguments:@[@"-c", execSrcPath]];
        [gunzipTask setStandardOutput:outFile];
        [gunzipTask launch];
        [gunzipTask waitUntilExit];
    } else {
        [FILEMGR copyItemAtPath:execSrcPath toPath:execDestPath error:nil];
    }
    NSDictionary *execAttrDict = @{ NSFilePosixPermissions:[NSNumber numberWithShort:0777] };
    [FILEMGR setAttributes:execAttrDict ofItemAtPath:execDestPath error:nil];
    
    // Copy nib file to app bundle
    // .app/Contents/Resources/MainMenu.nib
    [self report:@"Copying nib file to bundle"];
    NSString *nibDestinationPath = [resourcesPath stringByAppendingString:@"/MainMenu.nib"];
    [FILEMGR copyItemAtPath:nibPath toPath:nibDestinationPath error:nil];
    
    if ([self[AppSpecKey_StripNib] boolValue] == YES) {
        [self report:@"Optimizing nib file"];
        [PlatypusAppSpec optimizeNibFile:nibDestinationPath];
    }
    
    // Create script file in app bundle
    // .app/Contents/Resources/script
    [self report:@"Copying script to bundle"];
    
    NSString *scriptFilePath = [resourcesPath stringByAppendingString:@"/script"];
    
    if ([self[AppSpecKey_SymlinkFiles] boolValue] == YES) {
        [FILEMGR createSymbolicLinkAtPath:scriptFilePath
                      withDestinationPath:self[AppSpecKey_ScriptPath]
                                    error:nil];
    } else {
        // Copy script over
        [FILEMGR copyItemAtPath:self[AppSpecKey_ScriptPath] toPath:scriptFilePath error:nil];
    }
    
    NSDictionary *fileAttrDict = @{NSFilePosixPermissions: @0755UL};
    [FILEMGR setAttributes:fileAttrDict ofItemAtPath:scriptFilePath error:nil];
    
    // Create AppSettings property list in binary format
    // .app/Contents/Resources/AppSettings.plist
    [self report:@"Writing AppSettings.plist"];
    NSMutableDictionary *appSettingsPlist = [self appSettingsPlist];
    NSString *appSettingsPlistPath = [resourcesPath stringByAppendingString:@"/AppSettings.plist"];
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:appSettingsPlist
                                                                   format:NSPropertyListBinaryFormat_v1_0
                                                                  options:0
                                                                    error:nil];
    [plistData writeToFile:appSettingsPlistPath atomically:YES];
    
    // Create icon
    // .app/Contents/Resources/appIcon.icns
    if (self[AppSpecKey_IconPath]) {
        if ([FILEMGR fileExistsAtPath:self[AppSpecKey_IconPath]]) {
            [self report:@"Writing application icon"];
            NSString *iconPath = [resourcesPath stringByAppendingString:@"/AppIcon.icns"];
            [FILEMGR copyItemAtPath:self[AppSpecKey_IconPath] toPath:iconPath error:nil];
        } else {
            [self report:@"No icon at path %@", self[AppSpecKey_IconPath]];
        }
    }
    
    // Create document icon
    // .app/Contents/Resources/docIcon.icns
    if (self[AppSpecKey_DocIconPath] && ![self[AppSpecKey_DocIconPath] isEqualToString:@""]) {
        [self report:@"Writing document icon"];
        NSString *docIconPath = [resourcesPath stringByAppendingString:@"/docIcon.icns"];
        [FILEMGR copyItemAtPath:self[AppSpecKey_DocIconPath] toPath:docIconPath error:nil];
    }
    
    // Create Info.plist file in binary format
    // .app/Contents/Info.plist
    [self report:@"Writing Info.plist"];
    NSDictionary *infoPlist = [self infoPlist];
    NSString *infoPlistPath = [contentsPath stringByAppendingString:@"/Info.plist"];
    NSData *infoData = [NSPropertyListSerialization dataWithPropertyList:infoPlist
                                                                  format:NSPropertyListBinaryFormat_v1_0
                                                                 options:0
                                                                   error:nil];
    if (!infoData || ![infoData writeToFile:infoPlistPath atomically:YES]) {
        _error = @"Error writing Info.plist";
        return FALSE;
    }
    
    // Copy bundled files to Resources folder
    // .app/Contents/Resources/*
    NSInteger numBundledFiles = [self[AppSpecKey_BundledFiles] count];
    if (numBundledFiles) {
        [self report:@"Copying %d bundled files", numBundledFiles];
    }
    for (id bundledFile in self[AppSpecKey_BundledFiles]) {
        
        // Check if it's an embedded file or a path string
        NSString *bundledFilePath;
        if ([bundledFile isKindOfClass:[NSDictionary class]]) {
            
            // Bundled files can be embedded in Platypus Profiles
            // If an entry in the array is a dictionary with a "Name"
            // and "Data" key, we create a file in a tmp directory
            // and then use its path
            NSDictionary *bundledFileDict = (NSDictionary *)bundledFile;
            NSString *name = bundledFileDict[@"Name"];
            NSData *data = bundledFileDict[@"Data"];
            if (!name || !data) {
                continue;
            }
            NSString *path = [FILEMGR createTempFileNamed:name withContents:@""];
            if (path) {
                [data writeToFile:path atomically:NO];
            } else {
                DLog(@"Warning: Could not create tmp file named '%@'", name);
            }
        } else if ([bundledFile isKindOfClass:[NSString class]]) {
            bundledFilePath = (NSString *)bundledFile;
        } else {
            continue;
        }
        
        NSString *fileName = [bundledFilePath lastPathComponent];
        NSString *bundledFileDestPath = [resourcesPath stringByAppendingString:@"/"];
        bundledFileDestPath = [bundledFileDestPath stringByAppendingString:fileName];
        
        // If it's a development version, we just symlink it
        if ([self[AppSpecKey_SymlinkFiles] boolValue]) {
            [self report:@"Symlinking to \"%@\" in bundle", fileName];
            [FILEMGR createSymbolicLinkAtPath:bundledFileDestPath withDestinationPath:bundledFilePath error:nil];
        } else {
            [self report:@"Copying '%@' to bundle", fileName];
            
            // Otherwise we copy it
            // First remove any file in destination path
            // NB: This means any previously copied files are overwritten
            // and so users can bundle in their own MainMenu.nib etc.
            if ([FILEMGR fileExistsAtPath:bundledFileDestPath]) {
                [FILEMGR removeItemAtPath:bundledFileDestPath error:nil];
            }
            if ([FILEMGR fileExistsAtPath:bundledFilePath]) {
                [FILEMGR copyItemAtPath:bundledFilePath toPath:bundledFileDestPath error:nil];
            } else {
                [self report:@"Bundled file '%@' does not exist, skipping.", fileName];
            }
        }
    }
    
    // Sign app if signing identity has been provided
    if (self[AppSpecKey_SigningIdentity]) {
        [self report:@"Signing '%@'", [tmpPath lastPathComponent]];
        int err = [PlatypusAppSpec signApp:tmpPath usingIdentity:self[AppSpecKey_SigningIdentity]];
        if (err) {
            [self report:@"Failed to sign app. codesign err %d", err];
        }
    }
    
    // COPY APP OVER TO FINAL DESTINATION
    // We've created the application bundle in the temporary directory
    // now it's time to move it to the destination specified by the user
    [self report:@"Moving app to destination '%@'", self[AppSpecKey_DestinationPath]];
    
    NSString *destPath = self[AppSpecKey_DestinationPath];
    
    // First, let's see if there's anything there.  If we have overwrite set, we just delete that stuff
    if ([FILEMGR fileExistsAtPath:destPath]) {
        if ([self[AppSpecKey_Overwrite] boolValue]) {
            BOOL removed = [FILEMGR removeItemAtPath:destPath error:nil];
            if (!removed) {
                _error = [NSString stringWithFormat:@"Could not remove pre-existing item at path '%@'", destPath];
                return FALSE;
            }
        } else {
            _error = [NSString stringWithFormat:@"File already exists at path '%@'", destPath];
            return FALSE;
        }
    }
    
    // Now, move the newly created app to the destination
    [FILEMGR moveItemAtPath:tmpPath toPath:destPath error:nil];
    
    // If move wasn't a success, clean up app in tmp dir
    if (![FILEMGR fileExistsAtPath:destPath]) {
        [FILEMGR removeItemAtPath:tmpPath error:nil];
        _error = @"Failed to create application at the specified destination";
        return FALSE;
    }
    
    // Register app with macOS Launch Services to update its database
    [self report:@"Registering app with Launch Services"];
    [WORKSPACE registerAppWithLaunchServices:destPath];
    
    [self report:@"Done"];
    
    return TRUE;
}

// Generate AppSettings.plist dictionary
- (NSMutableDictionary *)appSettingsPlist {
    
    NSMutableDictionary *appSettingsPlist = [NSMutableDictionary dictionary];
    
    NSMutableArray *keys = [@[AppSpecKey_Authenticate,
                              AppSpecKey_Creator,
                              AppSpecKey_RemainRunning,
                              AppSpecKey_InterfaceType,
                              AppSpecKey_InterpreterPath,
                              AppSpecKey_InterpreterArgs,
                              AppSpecKey_ScriptArgs,
                              AppSpecKey_TextFont,
                              AppSpecKey_TextSize,
                              AppSpecKey_TextColor,
                              AppSpecKey_TextBackgroundColor,
                              AppSpecKey_Droppable,
                              AppSpecKey_SendNotifications,
                              AppSpecKey_AcceptFiles,
                              AppSpecKey_AcceptText,
                              AppSpecKey_PromptForFile,
                              AppSpecKey_Suffixes,
                              AppSpecKey_Utis,
                              AppSpecKey_URISchemes] mutableCopy];
    
    // Status menu info
    if (InterfaceTypeForString(self[AppSpecKey_InterfaceType]) == PlatypusInterfaceType_StatusMenu) {
        NSArray *statusMenuKeys = @[AppSpecKey_StatusItemDisplayType,
                                    AppSpecKey_StatusItemTitle,
                                    AppSpecKey_StatusItemIcon,
                                    AppSpecKey_StatusItemUseSysfont,
                                    AppSpecKey_StatusItemIconIsTemplate];
        [keys addObjectsFromArray:statusMenuKeys];
    }
    
    // Map keys from self to plist
    for (NSString *k in keys) {
        appSettingsPlist[k] = self[k];
    }
    
    appSettingsPlist[AppSpecKey_Creator] = PROGRAM_CREATOR_STAMP;

    return appSettingsPlist;
}

// Generate Info.plist dictionary
- (NSDictionary *)infoPlist {
    
    // Create copyright string with current year
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy"];
    NSString *yearString = [formatter stringFromDate:[NSDate date]];
    NSString *copyrightString = [NSString stringWithFormat:@"© %@ %@", yearString, self[AppSpecKey_Author]];
    
    // Create dict
    NSMutableDictionary *infoPlist = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        @"en",                                  @"CFBundleDevelopmentRegion",
        self[AppSpecKey_Name],                  @"CFBundleExecutable",
        self[AppSpecKey_Name],                  @"CFBundleName",
        self[AppSpecKey_Name],                  @"CFBundleDisplayName",
        copyrightString,                        @"NSHumanReadableCopyright",
        self[AppSpecKey_Version],               @"CFBundleShortVersionString",
        self[AppSpecKey_Identifier],            @"CFBundleIdentifier",
        self[AppSpecKey_RunInBackground],       @"LSUIElement",
        @"6.0",                                 @"CFBundleInfoDictionaryVersion",
        @"MainMenu",                            @"NSMainNibFile",
        @"APPL",                                @"CFBundlePackageType",
        PROGRAM_MIN_SYS_VERSION,                @"LSMinimumSystemVersion",
        @"NSApplication",                       @"NSPrincipalClass",
        @{@"NSAllowsArbitraryLoads": @YES},     @"NSAppTransportSecurity",
    nil];
    
    // Add icon name if icon is set
    if (self[AppSpecKey_IconPath] && [FILEMGR fileExistsAtPath:self[AppSpecKey_IconPath]]) {
        infoPlist[@"CFBundleIconFile"] = @"AppIcon.icns";
    }
    
    // If droppable, we declare the accepted file types
    if ([self[AppSpecKey_Droppable] boolValue]) {
        
        NSMutableDictionary *typesAndSuffixesDict = [NSMutableDictionary dictionary];
        
        typesAndSuffixesDict[@"CFBundleTypeExtensions"] = self[AppSpecKey_Suffixes];
        typesAndSuffixesDict[@"CFBundleTypeRole"] = @"Viewer";
        
        if (self[AppSpecKey_Utis] != nil && [self[AppSpecKey_Utis] count] > 0) {
            typesAndSuffixesDict[@"LSItemContentTypes"] = self[AppSpecKey_Utis];
        }
        
        // Document icon
        if (self[AppSpecKey_DocIconPath] && [FILEMGR fileExistsAtPath:self[AppSpecKey_DocIconPath]]) {
            typesAndSuffixesDict[@"CFBundleTypeIconFile"] = @"docIcon.icns";
        }
        
        // Set file types and suffixes
        infoPlist[@"CFBundleDocumentTypes"] = @[typesAndSuffixesDict];
        
        // Add service settings to Info.plist
        if ([self[AppSpecKey_Service] boolValue]) {
            
            NSMutableDictionary *serviceDict = [NSMutableDictionary dictionary];
            
            serviceDict[@"NSMenuItem"] = @{@"default": [NSString stringWithFormat:@"Process with %@", self[AppSpecKey_Name]]};
            serviceDict[@"NSMessage"] = @"dropService";
            serviceDict[@"NSPortName"] = self[AppSpecKey_Name];
            serviceDict[@"NSTimeout"] = @(3000);
            
            // Service data type handling
            NSMutableArray *sendTypes = [NSMutableArray array];
            if ([self[AppSpecKey_AcceptFiles] boolValue]) {
                [sendTypes addObject:@"NSFilenamesPboardType"];
                serviceDict[@"NSSendFileTypes"] = @[(NSString *)kUTTypeItem];
            }
            if ([self[AppSpecKey_AcceptText] boolValue]) {
                [sendTypes addObject:@"NSStringPboardType"];
            }
            serviceDict[@"NSSendTypes"] = sendTypes;
            
//            serviceDict[@"NSSendFileTypes"] = @[];
//            serviceDict[@"NSServiceDescription"]
            
            infoPlist[@"NSServices"] = @[serviceDict];
        }
    }
    
    // If any URI protocol handling
    if (self[AppSpecKey_URISchemes] && [self[AppSpecKey_URISchemes] count]) {
        
        NSDictionary *dict = @{ @"CFBundleURLName": self[AppSpecKey_Name],
                                @"CFBundleURLSchemes": self[AppSpecKey_URISchemes] };
        
        infoPlist[@"CFBundleURLTypes"] = @[dict];
    }
    
    return infoPlist;
}

- (void)report:(NSString *)format, ... {
    if ([self silentMode]) {
        return;
    }
    
    va_list args;
    
    va_start(args, format);
    NSString *string  = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    fprintf(stderr, "%s\n", [string UTF8String]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PLATYPUS_APP_SPEC_CREATION_NOTIFICATION object:string];
}

// Check spec for basic sanity
- (BOOL)verify {
    
    if ([self[AppSpecKey_DestinationPath] hasSuffix:APPBUNDLE_SUFFIX] == FALSE) {
        _error = @"Destination must end with .app";
        return NO;
    }
    
    if ([NSFont fontWithName:self[AppSpecKey_TextFont] size:13] == nil) {
        [self report:@"Warning: Font \"%@\" cannot be instantiated.", self[AppSpecKey_TextFont]];
    }
    
    if ([self[AppSpecKey_Name] isEqualToString:@""]) {
        _error = @"Empty app name";
        return NO;
    }
    
    BOOL isDir;
    if (![FILEMGR fileExistsAtPath:self[AppSpecKey_ScriptPath] isDirectory:&isDir] || isDir) {
        _error = [NSString stringWithFormat:@"Script not found at path '%@'", self[AppSpecKey_ScriptPath], nil];
        return NO;
    }
    
    if (![FILEMGR fileExistsAtPath:self[AppSpecKey_ExecutablePath] isDirectory:&isDir] || isDir) {
        _error = [NSString stringWithFormat:@"Executable binary not found at path '%@'", self[AppSpecKey_ExecutablePath], nil];
        return NO;
    }
    
    if (![FILEMGR fileExistsAtPath:self[AppSpecKey_NibPath]]) {
        _error = [NSString stringWithFormat:@"Nib not found at path '%@'", self[AppSpecKey_NibPath], nil];
        return NO;
    }
    
    if (![FILEMGR fileExistsAtPath:[self[AppSpecKey_DestinationPath] stringByDeletingLastPathComponent] isDirectory:&isDir] || !isDir) {
        _error = [NSString stringWithFormat:@"Destination directory '%@' does not exist.", [self[AppSpecKey_DestinationPath] stringByDeletingLastPathComponent], nil];
        return NO;
    }
    
    if (![FILEMGR isWritableFileAtPath:[self[AppSpecKey_DestinationPath] stringByDeletingLastPathComponent]]) {
        _error = [NSString stringWithFormat:@"Don't have permission to write to the destination directory '%@'", self[AppSpecKey_DestinationPath]];
        return NO;
    }
    
    for (NSString *path in self[AppSpecKey_BundledFiles]) {
        if (![FILEMGR fileExistsAtPath:path]) {
            _error = @"One or more bundled files no longer exist at the specified path.";
            return NO;
        }
    }
    
    return YES;
}

#pragma mark -

- (void)writeToFile:(NSString *)filePath {
    [self writeToFile:filePath atomically:YES];
}

// Dump spec dictionary to stdout in XML plist format
- (void)dump {
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:self
                                                              format:NSPropertyListXMLFormat_v1_0
                                                             options:0
                                                               error:nil];
    [[NSFileHandle fileHandleWithStandardOutput] writeData:data];
}

#pragma mark - Command string generation

- (NSString *)commandStringUsingShortOpts:(BOOL)shortOpts {
    NSString *checkboxParamStr = @"";
    NSString *iconParamStr = @"";
    NSString *versionString = @"";
    NSString *authorString = @"";
    NSString *suffixesString = @"";
    NSString *uniformTypesString = @"";
    NSString *uriSchemesString = @"";
    NSString *parametersString = @"";
    NSString *textSettingsString = @"";
    NSString *statusMenuOptionsString = @"";
    
    if ([self[AppSpecKey_Authenticate] boolValue]) {
        NSString *str = shortOpts ? @"-A " : @"--admin-privileges ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([self[AppSpecKey_AcceptFiles] boolValue] && [self[AppSpecKey_Droppable] boolValue]) {
        NSString *str = shortOpts ? @"-D " : @"--droppable ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([self[AppSpecKey_AcceptText] boolValue] && [self[AppSpecKey_Droppable] boolValue]) {
        NSString *str = shortOpts ? @"-F " : @"--text-droppable ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([self[AppSpecKey_Service] boolValue] && [self[AppSpecKey_Droppable] boolValue]) {
        NSString *str = shortOpts ? @"-N " : @"--service ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([self[AppSpecKey_RunInBackground] boolValue]) {
        NSString *str = shortOpts ? @"-B " : @"--background ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([self[AppSpecKey_RemainRunning] boolValue] == FALSE) {
        NSString *str = shortOpts ? @"-R " : @"--quit-after-execution ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([self[AppSpecKey_Version] isEqualToString:DEFAULT_VERSION] == FALSE) {
        NSString *str = shortOpts ? @"-V" : @"--app-version";
        versionString = [NSString stringWithFormat:@" %@ '%@' ", str, self[AppSpecKey_Version]];
    }
    
    if (![self[AppSpecKey_Author] isEqualToString:NSFullUserName()]) {
        NSString *str = shortOpts ? @"-u" : @"--author";
        authorString = [NSString stringWithFormat:@" %@ '%@' ", str, self[AppSpecKey_Author]];
    }
    
    NSString *promptForFileString = @"";
    if ([self[AppSpecKey_Droppable] boolValue]) {
        //  Suffixes
        if ([self[AppSpecKey_Suffixes] count]) {
            NSString *str = shortOpts ? @"-X" : @"--suffixes";
            suffixesString = [self[AppSpecKey_Suffixes] componentsJoinedByString:CMDLINE_ARG_SEPARATOR];
            suffixesString = [NSString stringWithFormat:@"%@ '%@' ", str, suffixesString];
        }
        // UTIs
        if ([self[AppSpecKey_Utis] count]) {
            NSString *str = shortOpts ? @"-T" : @"--uniform-type-identifiers";
            uniformTypesString = [self[AppSpecKey_Utis] componentsJoinedByString:CMDLINE_ARG_SEPARATOR];
            uniformTypesString = [NSString stringWithFormat:@"%@ '%@' ", str, uniformTypesString];
        }
        // File prompt
        if ([self[AppSpecKey_PromptForFile] boolValue]) {
            NSString *str = shortOpts ? @"-Z" : @"--file-prompt";
            promptForFileString = [NSString stringWithFormat:@"%@ ", str];
        }
    }
    
    // Uniform type identifier params
    if ([self[AppSpecKey_URISchemes] count]) {
        NSString *str = shortOpts ? @"-U" : @"--uri-schemes";
        uriSchemesString = [self[AppSpecKey_URISchemes] componentsJoinedByString:CMDLINE_ARG_SEPARATOR];
        uriSchemesString = [NSString stringWithFormat:@"%@ '%@' ", str, uriSchemesString];
    }
    
    // Create bundled files string
    NSString *bundledFilesCmdString = @"";
    NSArray *bundledFiles = self[AppSpecKey_BundledFiles];
    for (int i = 0; i < [bundledFiles count]; i++) {
        NSString *str = shortOpts ? @"-f" : @"--bundled-file";
        bundledFilesCmdString = [bundledFilesCmdString stringByAppendingString:[NSString stringWithFormat:@"%@ '%@' ", str, bundledFiles[i]]];
    }
    
    // Create interpreter and script args flags
    if ([self[AppSpecKey_InterpreterArgs] count]) {
        NSString *str = shortOpts ? @"-G" : @"--interpreter-args";
        NSString *arg = [self[AppSpecKey_InterpreterArgs] componentsJoinedByString:CMDLINE_ARG_SEPARATOR];
        parametersString = [parametersString stringByAppendingString:[NSString stringWithFormat:@"%@ '%@' ", str, arg]];
    }
    if ([self[AppSpecKey_ScriptArgs] count]) {
        NSString *str = shortOpts ? @"-C" : @"--script-args";
        NSString *arg = [self[AppSpecKey_ScriptArgs] componentsJoinedByString:CMDLINE_ARG_SEPARATOR];
        parametersString = [parametersString stringByAppendingString:[NSString stringWithFormat:@"%@ '%@' ", str, arg]];
    }
    
    // Create args for text settings
    if (IsTextStyledInterfaceTypeString(self[AppSpecKey_InterfaceType])) {
        
        NSString *textFgString = @"", *textBgString = @"", *textFontString = @"";
        if (![self[AppSpecKey_TextColor] isEqualToString:DEFAULT_TEXT_FG_COLOR]) {
            NSString *str = shortOpts ? @"-g" : @"--text-foreground-color";
            textFgString = [NSString stringWithFormat:@" %@ '%@' ", str, self[AppSpecKey_TextColor]];
        }
        
        if (![self[AppSpecKey_TextBackgroundColor] isEqualToString:DEFAULT_TEXT_BG_COLOR]) {
            NSString *str = shortOpts ? @"-b" : @"--text-background-color";
            textBgString = [NSString stringWithFormat:@" %@ '%@' ", str, self[AppSpecKey_TextColor]];
        }
        
        if ([self[AppSpecKey_TextSize] floatValue] != DEFAULT_TEXT_FONT_SIZE ||
            ![self[AppSpecKey_TextFont] isEqualToString:DEFAULT_TEXT_FONT_NAME]) {
            NSString *str = shortOpts ? @"-n" : @"--text-font";
            textFontString = [NSString stringWithFormat:@" %@ '%@ %2.f' ", str, self[AppSpecKey_TextFont], [self[AppSpecKey_TextSize] floatValue]];
        }
        
        textSettingsString = [NSString stringWithFormat:@"%@%@%@", textFgString, textBgString, textFontString];
    }
    
    // Custom icon arg
    if (![self[AppSpecKey_IconPath] isEqualToString:@""]) {
        NSString *str = shortOpts ? @"-i" : @"--app-icon";
        iconParamStr = [NSString stringWithFormat:@"%@ '%@' ", str, self[AppSpecKey_IconPath]];
    }
    
    // Custom document icon arg
    if (self[AppSpecKey_DocIconPath] && ![self[AppSpecKey_DocIconPath] isEqualToString:@""]) {
        NSString *str = shortOpts ? @"-Q" : @"--document-icon";
        iconParamStr = [iconParamStr stringByAppendingFormat:@" %@ '%@' ", str, self[AppSpecKey_DocIconPath]];
    }
    
    // Status menu settings, if interface type is status menu
    if (InterfaceTypeForString(self[AppSpecKey_InterfaceType]) == PlatypusInterfaceType_StatusMenu) {
        // -K kind
        NSString *str = shortOpts ? @"-K" : @"--status-item-kind";
        statusMenuOptionsString = [statusMenuOptionsString stringByAppendingFormat:@"%@ '%@' ", str, self[AppSpecKey_StatusItemDisplayType]];
        
        // -L /path/to/image
        if ([self[AppSpecKey_StatusItemDisplayType] isEqualToString:PLATYPUS_STATUSITEM_DISPLAY_TYPE_ICON]) {
            str = shortOpts ? @"-L" : @"--status-item-icon";
            statusMenuOptionsString = [statusMenuOptionsString stringByAppendingFormat:@"%@ '/path/to/image' ", str];
        }
        
        // -Y 'Title'
        else if ([self[AppSpecKey_StatusItemDisplayType] isEqualToString:PLATYPUS_STATUSITEM_DISPLAY_TYPE_TEXT]) {
            str = shortOpts ? @"-Y" : @"--status-item-title";
            statusMenuOptionsString = [statusMenuOptionsString stringByAppendingFormat:@"%@ '%@' ", str, self[AppSpecKey_StatusItemTitle]];
        }
        
        // -c
        if ([self[AppSpecKey_StatusItemUseSysfont] boolValue]) {
            str = shortOpts ? @"-c" : @"--status-item-sysfont";
            statusMenuOptionsString = [statusMenuOptionsString stringByAppendingFormat:@"%@ ", str];
        }
        
        // -q
        if ([self[AppSpecKey_StatusItemIconIsTemplate] boolValue]) {
            str = shortOpts ? @"-q" : @"--status-item-template-icon";
            statusMenuOptionsString = [statusMenuOptionsString stringByAppendingFormat:@"%@ ", str];
        }
    }
    
    // Only set app name arg if we have a proper value
    NSString *appNameArg = @"";
    if ([self[AppSpecKey_Name] isEqualToString:@""] == FALSE) {
        NSString *str = shortOpts ? @"-a" : @"--name";
        appNameArg = [NSString stringWithFormat: @" %@ '%@' ", str,  self[AppSpecKey_Name]];
    }
    
    // Only add identifier argument if it varies from default
    NSString *identifierArg = @"";
    NSString *standardIdentifier = [PlatypusAppSpec bundleIdentifierForAppName:self[AppSpecKey_Name] authorName:nil usingDefaults: NO];
    if ([self[AppSpecKey_Identifier] isEqualToString:standardIdentifier] == FALSE) {
        NSString *str = shortOpts ? @"-I" : @"--bundle-identifier";
        identifierArg = [NSString stringWithFormat: @" %@ %@ ", str, self[AppSpecKey_Identifier]];
    }
    
    // Interface type
    NSString *str = shortOpts ? @"-o" : @"--interface-type";
    NSString *interfaceArg = [NSString stringWithFormat:@" %@ '%@' ", str, self[AppSpecKey_InterfaceType]];
    
    // Interpreter
    str = shortOpts ? @"-p" : @"--interpreter";
    NSString *interpreterArg = [NSString stringWithFormat:@" %@ '%@' ", str, self[AppSpecKey_InterpreterPath]];
    
    // Finally, generate the command
    NSString *commandStr = [NSString stringWithFormat:
                            @"%@ %@%@%@%@%@%@ %@%@%@%@%@%@%@%@%@%@ '%@'",
                            CMDLINE_TOOL_PATH,
                            checkboxParamStr,
                            iconParamStr,
                            appNameArg,
                            interfaceArg,
                            interpreterArg,
                            authorString,
                            versionString,
                            identifierArg,
                            suffixesString,
                            uniformTypesString,
                            uriSchemesString,
                            promptForFileString,
                            bundledFilesCmdString,
                            parametersString,
                            textSettingsString,
                            statusMenuOptionsString,
                            self[AppSpecKey_ScriptPath],
                            nil];
    
    return commandStr;
}

#pragma mark - Class Methods

// Generate bundle identifier for app
+ (NSString *)bundleIdentifierForAppName:(NSString *)name authorName:(NSString *)authorName usingDefaults:(BOOL)def {
    NSString *appName = name ? name : DEFAULT_APP_NAME;
    NSString *defaults = def ? [DEFAULTS stringForKey:DefaultsKey_BundleIdentifierPrefix] : nil;
    NSString *author = authorName ? [authorName stringByReplacingOccurrencesOfString:@" " withString:@""] : NSUserName();
    NSString *pre = (defaults == nil) ? [NSString stringWithFormat:@"org.%@.", author] : defaults;
    
    NSString *identifierString = [NSString stringWithFormat:@"%@%@", pre, appName];
    identifierString = [identifierString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSData *asciiData = [identifierString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    identifierString = [[NSString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding];

    return identifierString;
}

// Use ibtool to strip a given nib file.
// This makes the file uneditable in Interface Builder.
+ (void)optimizeNibFile:(NSString *)nibPath {
    if ([FILEMGR fileExistsAtPath:IBTOOL_PATH] == NO) {
        DLog(@"Unable to strip nib file, ibtool not found at path %@", IBTOOL_PATH);
        return;
    }
    NSTask *ibToolTask = [[NSTask alloc] init];
    [ibToolTask setLaunchPath:IBTOOL_PATH];
    [ibToolTask setArguments:@[@"--strip", nibPath, nibPath]];
    [ibToolTask launch];
    [ibToolTask waitUntilExit];
}

// Run code signing tool on an app or binary
+ (int)signApp:(NSString *)path usingIdentity:(NSString *)identity {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:CODESIGN_PATH];
    [task setArguments:@[@"-s", identity, path]];
    [task launch];
    [task waitUntilExit];
    
    return [task terminationStatus];
}

@end
