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

// PlatypusAppSpec is a data wrapper class around an NSDictionary containing
// all the information / specifications for creating a Platypus application.

#import "PlatypusAppSpec.h"
#import "Common.h"
#import "ScriptAnalyser.h"
#import "NSWorkspace+Additions.h"

@interface PlatypusAppSpec()
{
    NSMutableDictionary *properties;
}

- (void)report:(NSString *)format, ...;

@end

@implementation PlatypusAppSpec

#pragma mark - NSMutableDictionary subclass using proxy

- (instancetype)init {
    if (self = [super init]) {
        // proxy dictionary object
        properties = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
    if (self = [super init]) {
        properties = [[NSMutableDictionary alloc] initWithCapacity:numItems];
    }
    return self;
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
    if (self = [super init]) {
        properties = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    }
    return self;
}

- (void)removeObjectForKey:(id)aKey {
    [properties removeObjectForKey:aKey];
}

- (void)setObject:(id)anObject forKey:(id <NSCopying>)aKey {
    [properties setObject:anObject forKey:aKey];
}

- (id)objectForKey:(id)aKey {
    return [properties objectForKey:aKey];
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary {
    [properties addEntriesFromDictionary:otherDictionary];
}

- (NSEnumerator *)keyEnumerator {
    return [properties keyEnumerator];
}

- (NSUInteger) count {
    return [properties count];
}

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
        [properties addEntriesFromDictionary:dict];
    }
    return self;
}

- (instancetype)initWithProfile:(NSString *)profilePath {
    NSDictionary *profileDict = [NSDictionary dictionaryWithContentsOfFile:profilePath];
    if (profileDict == nil) {
        return nil;
    }
    return [self initWithDictionary:profileDict];
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

/************************************************
 init a spec with default values for everything
 ************************************************/

- (void)setDefaults {
    // stamp the spec with the creator
    self[AppSpecKey_Creator] = PROGRAM_CREATOR_STAMP;
    
    //prior properties
    self[AppSpecKey_ExecutablePath] = CMDLINE_EXEC_PATH;
    self[AppSpecKey_NibPath] = CMDLINE_NIB_PATH;
    self[AppSpecKey_DestinationPath] = DEFAULT_DESTINATION_PATH;
    self[AppSpecKey_Overwrite] = @NO;
    self[AppSpecKey_SymlinkFiles] = @NO;
    self[AppSpecKey_StripNib] = @YES;
    self[AppSpecKey_XMLPlistFormat] = @NO;
    
    self[AppSpecKey_Name] = DEFAULT_APP_NAME;
    self[AppSpecKey_ScriptPath] = @"";
    self[AppSpecKey_InterfaceType] = DEFAULT_INTERFACE_TYPE_STRING;
    self[AppSpecKey_IconPath] = CMDLINE_ICON_PATH;
    
    self[AppSpecKey_Interpreter] = DEFAULT_INTERPRETER_PATH;
    self[AppSpecKey_InterpreterArgs] = [NSArray array];
    self[AppSpecKey_ScriptArgs] = [NSArray array];
    self[AppSpecKey_Version] = DEFAULT_VERSION;
    self[AppSpecKey_Identifier] = [PlatypusAppSpec bundleIdentifierForAppName:nil
                                                                   authorName:nil
                                                                usingDefaults:YES];
    self[AppSpecKey_Author] = NSFullUserName();
    
    self[AppSpecKey_Droppable] = @NO;
    self[AppSpecKey_Secure] = @NO;
    self[AppSpecKey_Authenticate] = @NO;
    self[AppSpecKey_RemainRunning] = @YES;
    self[AppSpecKey_RunInBackground] = @NO;
    
    // bundled files
    self[AppSpecKey_BundledFiles] = [NSMutableArray array];
    
    // file/drag acceptance properties
    self[AppSpecKey_Suffixes] = DEFAULT_SUFFIXES;
    self[AppSpecKey_Utis] = DEFAULT_UTIS;
    self[AppSpecKey_AcceptText] = @NO;
    self[AppSpecKey_AcceptFiles] = @YES;
    self[AppSpecKey_Service] = @NO;
    self[AppSpecKey_PromptForFile] = @NO;
    self[AppSpecKey_DocIconPath] = @"";
    
    // text window settings
    self[AppSpecKey_TextEncoding] = @(DEFAULT_TEXT_ENCODING);
    self[AppSpecKey_TextFont] = DEFAULT_TEXT_FONT_NAME;
    self[AppSpecKey_TextSize] = @(DEFAULT_TEXT_FONT_SIZE);
    self[AppSpecKey_TextColor] = DEFAULT_TEXT_FG_COLOR;
    self[AppSpecKey_TextBackgroundColor] = DEFAULT_TEXT_BG_COLOR;
    
    // status item settings
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
    // start with a dict populated with defaults
    [self setDefaults];
    
    // set script path
    self[AppSpecKey_ScriptPath] = scriptPath;
    
    //determine app name based on script filename
    self[AppSpecKey_Name] = [ScriptAnalyser appNameFromScriptFile:scriptPath];
    
    //find an interpreter for it
    NSString *interpreterPath = [ScriptAnalyser determineInterpreterPathForScriptFile:scriptPath];
    if (interpreterPath == nil || [interpreterPath isEqualToString:@""]) {
        interpreterPath = DEFAULT_INTERPRETER_PATH;
    } else {
        // get parameters to interpreter
        NSMutableArray *shebangCmdComponents = [NSMutableArray arrayWithArray:[ScriptAnalyser parseInterpreterInScriptFile:scriptPath]];
        [shebangCmdComponents removeObjectAtIndex:0];
        self[AppSpecKey_InterpreterArgs] = shebangCmdComponents;
    }
    self[AppSpecKey_Interpreter] = interpreterPath;
    
    // find parent folder wherefrom we create destination path of app bundle
    NSString *parentFolder = [scriptPath stringByDeletingLastPathComponent];
    NSString *destPath = [NSString stringWithFormat:@"%@/%@.app", parentFolder, self[AppSpecKey_Name]];
    self[AppSpecKey_DestinationPath] = destPath;
    self[AppSpecKey_Identifier] = [PlatypusAppSpec bundleIdentifierForAppName:self[AppSpecKey_Name]
                                                           authorName:nil
                                                        usingDefaults:YES];
}

#pragma mark -

/****************************************
 This function creates the app bundle
 based on the data contained in the spec.
 ****************************************/

- (BOOL)create {
    
    //check if app already exists
    if ([FILEMGR fileExistsAtPath:self[AppSpecKey_DestinationPath]]) {
        if ([self[AppSpecKey_Overwrite] boolValue] == FALSE) {
            _error = [NSString stringWithFormat:@"App already exists at path %@. Use -y flag to overwrite.", self[AppSpecKey_DestinationPath]];
            return FALSE;
        } else {
            [self report:@"Overwriting app at path %@", self[AppSpecKey_DestinationPath]];
        }
    }
    
    // check if executable exists
    NSString *execPath = self[AppSpecKey_ExecutablePath];
    if (![FILEMGR fileExistsAtPath:execPath] || ![FILEMGR isReadableFileAtPath:execPath]) {
        [self report:@"Executable %@ does not exist. Aborting.", execPath];
        return NO;
    }
    
    // check if source nib exists
    NSString *nibPath = self[AppSpecKey_NibPath];
    if (![FILEMGR fileExistsAtPath:nibPath] || ![FILEMGR isReadableFileAtPath:nibPath]) {
        [self report:@"Nib file %@ does not exist. Aborting.", nibPath];
        return NO;
    }
    
    ////////////////////////// CREATE THE FOLDER HIERARCHY //////////////////////////
    
    // we begin by creating the basic application bundle hierarchy
    [self report:@"Creating application bundle folder hierarchy"];
    
    // .app bundle
    // get temporary directory, make sure it's kosher.  Apparently NSTemporaryDirectory() can return nil
    // see http://www.cocoadev.com/index.pl?NSTemporaryDirectory
    NSString *tmpPath = NSTemporaryDirectory();
    if (tmpPath == nil) {
        tmpPath = @"/tmp/";
    }
    // make sure we can write to temp path
    if ([FILEMGR isWritableFileAtPath:tmpPath] == NO) {
        _error = [NSString stringWithFormat:@"Could not write to the temp directory '%@'.", tmpPath];
        return FALSE;
    }
    // create bundle directory
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
    
    ////////////////////////// COPY FILES TO THE APP BUNDLE //////////////////////////////////
    
    [self report:@"Copying executable to bundle"];
    
    // copy exec file
    // .app/Contents/Resources/MacOS/ScriptExec
    NSString *execDestinationPath = [macosPath stringByAppendingString:@"/"];
    execDestinationPath = [execDestinationPath stringByAppendingString:self[AppSpecKey_Name]];
    [FILEMGR copyItemAtPath:execPath toPath:execDestinationPath error:nil];
    NSDictionary *execAttrDict = @{NSFilePosixPermissions: @0755UL};
    [FILEMGR setAttributes:execAttrDict ofItemAtPath:execDestinationPath error:nil];
    
    // copy nib file to app bundle
    // .app/Contents/Resources/MainMenu.nib
    [self report:@"Copying nib file to bundle"];
    NSString *nibDestinationPath = [resourcesPath stringByAppendingString:@"/MainMenu.nib"];
    [FILEMGR copyItemAtPath:nibPath toPath:nibDestinationPath error:nil];
    
    if ([self[AppSpecKey_StripNib] boolValue] == YES && [FILEMGR fileExistsAtPath:IBTOOL_PATH]) {
        [self report:@"Optimizing nib file"];
        [PlatypusAppSpec optimizeNibFile:nibDestinationPath];
    }
    
    // create script file in app bundle
    // .app/Contents/Resources/script
    [self report:@"Copying script"];
    
    NSData *scriptData = [NSData data];
    if ([self[AppSpecKey_Secure] boolValue]) {
        NSString *path = self[AppSpecKey_ScriptPath];
        scriptData = [NSData dataWithContentsOfFile:path];
    } else {
        NSString *scriptFilePath = [resourcesPath stringByAppendingString:@"/script"];
        
        if ([self[AppSpecKey_SymlinkFiles] boolValue] == YES) {
            [FILEMGR createSymbolicLinkAtPath:scriptFilePath
                          withDestinationPath:self[AppSpecKey_ScriptPath]
                                        error:nil];
        } else {
            // copy script over
            [FILEMGR copyItemAtPath:self[AppSpecKey_ScriptPath] toPath:scriptFilePath error:nil];
        }
        
        NSDictionary *fileAttrDict = @{NSFilePosixPermissions: @0755UL};
        [FILEMGR setAttributes:fileAttrDict ofItemAtPath:scriptFilePath error:nil];
    }
    
    // create AppSettings.plist file
    // .app/Contents/Resources/AppSettings.plist
    [self report:@"Creating AppSettings property list"];
    NSMutableDictionary *appSettingsPlist = [self appSettingsPlist];
    if ([self[AppSpecKey_Secure] boolValue]) {
        // if script is "secured" we encode it into AppSettings property list
        appSettingsPlist[@"TextSettings"] = [NSKeyedArchiver archivedDataWithRootObject:scriptData];
    }
    NSString *appSettingsPlistPath = [resourcesPath stringByAppendingString:@"/AppSettings.plist"];
    if ([self[AppSpecKey_XMLPlistFormat] boolValue] == FALSE) {
        NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:appSettingsPlist
                                                                       format:NSPropertyListBinaryFormat_v1_0
                                                                      options:0
                                                                        error:nil];
        [plistData writeToFile:appSettingsPlistPath atomically:YES];
    } else {
        [appSettingsPlist writeToFile:appSettingsPlistPath atomically:YES];
    }
    
    // create icon
    // .app/Contents/Resources/appIcon.icns
    if (self[AppSpecKey_IconPath] && ![self[AppSpecKey_IconPath] isEqualToString:@""]) {
        [self report:@"Writing application icon"];
        NSString *iconPath = [resourcesPath stringByAppendingString:@"/appIcon.icns"];
        [FILEMGR copyItemAtPath:self[AppSpecKey_IconPath] toPath:iconPath error:nil];
    }
    
    // document icon
    // .app/Contents/Resources/docIcon.icns
    if (self[AppSpecKey_DocIconPath] && ![self[AppSpecKey_DocIconPath] isEqualToString:@""]) {
        [self report:@"Writing document icon"];
        NSString *docIconPath = [resourcesPath stringByAppendingString:@"/docIcon.icns"];
        [FILEMGR copyItemAtPath:self[AppSpecKey_DocIconPath] toPath:docIconPath error:nil];
    }
    
    // create Info.plist file
    // .app/Contents/Info.plist
    [self report:@"Writing Info.plist"];
    NSDictionary *infoPlist = [self infoPlist];
    NSString *infoPlistPath = [contentsPath stringByAppendingString:@"/Info.plist"];
    BOOL success = YES;
    // if binary
    if ([self[AppSpecKey_XMLPlistFormat] boolValue] == NO) {
        NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:infoPlist
                                                                       format:NSPropertyListBinaryFormat_v1_0
                                                                      options:0
                                                                        error:nil];
        if (plistData == nil || ![plistData writeToFile:infoPlistPath atomically:YES]) {
            success = NO;
        }
    }
    // if XML
    else {
        success = [infoPlist writeToFile:infoPlistPath atomically:YES];
    }
    // raise error on failure
    if (success == NO) {
        _error = @"Error writing Info.plist";
        return FALSE;
    }
    
    // copy bundled files to Resources folder
    // .app/Contents/Resources/*
    
    NSInteger numBundledFiles = [self[AppSpecKey_BundledFiles] count];
    if (numBundledFiles) {
        [self report:@"Copying %d bundled files", numBundledFiles];
    }
    for (NSString *bundledFilePath in self[AppSpecKey_BundledFiles]) {
        NSString *fileName = [bundledFilePath lastPathComponent];
        NSString *bundledFileDestPath = [resourcesPath stringByAppendingString:@"/"];
        bundledFileDestPath = [bundledFileDestPath stringByAppendingString:fileName];
        
        // if it's a development version, we just symlink it
        if ([self[AppSpecKey_SymlinkFiles] boolValue]) {
            [self report:@"Symlinking to \"%@\" in bundle", fileName];
            [FILEMGR createSymbolicLinkAtPath:bundledFileDestPath withDestinationPath:bundledFilePath error:nil];
        } else {
            [self report:@"Copying \"%@\" to bundle", fileName];
            
            // otherwise we copy it
            // first remove any file in destination path
            // NB: This means any previously copied files are overwritten
            // and so users can bundle in their own MainMenu.nib etc.
            if ([FILEMGR fileExistsAtPath:bundledFileDestPath]) {
                [FILEMGR removeItemAtPath:bundledFileDestPath error:nil];
            }
            [FILEMGR copyItemAtPath:bundledFilePath toPath:bundledFileDestPath error:nil];
        }
    }
    
    // COPY APP OVER TO FINAL DESTINATION
    // we've created the application bundle in the temporary directory
    // now it's time to move it to the destination specified by the user
    [self report:@"Moving app to destination directory '%@'", self[AppSpecKey_DestinationPath]];
    
    NSString *destPath = self[AppSpecKey_DestinationPath];
    
    // first, let's see if there's anything there.  If we have overwrite set, we just delete that stuff
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
    
    // now, move the newly created app to the destination
    [FILEMGR moveItemAtPath:tmpPath toPath:destPath error:nil];
    
    // if move wasn't a success, clean up app in tmp dir
    if (![FILEMGR fileExistsAtPath:destPath]) {
        [FILEMGR removeItemAtPath:tmpPath error:nil];
        _error = @"Failed to create application at the specified destination";
        return FALSE;
    }
    
    // make sure app represenation in Finder is updated
    [WORKSPACE notifyFinderFileChangedAtPath:destPath];
    
    // register/update in the launch services database
    [self report:@"Registering with Launch Services"];
    LSRegisterURL((__bridge CFURLRef)([NSURL fileURLWithPath:destPath]), YES);
    
    // update Services
    if ([self[AppSpecKey_Service] boolValue]) {
        [self report:@"Updating Dynamic Services"];
        [WORKSPACE flushServices];
    }
    
    [self report:@"Done"];
    
    return TRUE;
}

// generate AppSettings.plist dictionary
- (NSMutableDictionary *)appSettingsPlist {
    
    NSMutableDictionary *appSettingsPlist = [NSMutableDictionary dictionary];
    
    appSettingsPlist[AppSpecKey_Authenticate] = self[AppSpecKey_Authenticate];
    appSettingsPlist[AppSpecKey_Droppable] = self[AppSpecKey_Droppable];
    appSettingsPlist[AppSpecKey_RemainRunning] = self[AppSpecKey_RemainRunning];
    appSettingsPlist[AppSpecKey_Secure] = self[AppSpecKey_Secure];
    appSettingsPlist[AppSpecKey_InterfaceType] = self[AppSpecKey_InterfaceType];
    appSettingsPlist[AppSpecKey_Interpreter] = self[AppSpecKey_Interpreter];
    appSettingsPlist[AppSpecKey_Creator] = PROGRAM_CREATOR_STAMP;
    appSettingsPlist[AppSpecKey_InterpreterArgs] = self[AppSpecKey_InterpreterArgs];
    appSettingsPlist[AppSpecKey_ScriptArgs] = self[AppSpecKey_ScriptArgs];
    appSettingsPlist[AppSpecKey_PromptForFile] = self[AppSpecKey_PromptForFile];
    
    appSettingsPlist[AppSpecKey_TextFont] = self[AppSpecKey_TextFont];
    appSettingsPlist[AppSpecKey_TextSize] = self[AppSpecKey_TextSize];
    appSettingsPlist[AppSpecKey_TextColor] = self[AppSpecKey_TextColor];
    appSettingsPlist[AppSpecKey_TextBackgroundColor] = self[AppSpecKey_TextBackgroundColor];
    appSettingsPlist[AppSpecKey_TextEncoding] = self[AppSpecKey_TextEncoding];

    appSettingsPlist[AppSpecKey_StatusItemDisplayType] = self[AppSpecKey_StatusItemDisplayType];
    appSettingsPlist[AppSpecKey_StatusItemTitle] = self[AppSpecKey_StatusItemTitle];
    appSettingsPlist[AppSpecKey_StatusItemIcon] = self[AppSpecKey_StatusItemIcon];
    appSettingsPlist[AppSpecKey_StatusItemUseSysfont] = self[AppSpecKey_StatusItemUseSysfont];
    appSettingsPlist[AppSpecKey_StatusItemIconIsTemplate] = self[AppSpecKey_StatusItemIconIsTemplate];
    
    appSettingsPlist[AppSpecKey_AcceptFiles] = self[AppSpecKey_AcceptFiles];
    appSettingsPlist[AppSpecKey_AcceptText] = self[AppSpecKey_AcceptText];
    appSettingsPlist[AppSpecKey_Suffixes] = self[AppSpecKey_Suffixes];
    appSettingsPlist[AppSpecKey_Utis] = self[AppSpecKey_Utis];
    
    return appSettingsPlist;
}

// generate Info.plist dictionary
- (NSDictionary *)infoPlist {
    
    // create copyright string with current year
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy"];
    NSString *yearString = [formatter stringFromDate:[NSDate date]];
    NSString *copyrightString = [NSString stringWithFormat:@"© %@ %@", yearString, self[AppSpecKey_Author]];
    
    // create dict
    NSMutableDictionary *infoPlist = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      
                                      @"en",                                    @"CFBundleDevelopmentRegion",
                                      self[AppSpecKey_Name],                            @"CFBundleExecutable",
                                      self[AppSpecKey_Name],                            @"CFBundleName",
                                      copyrightString,                          @"NSHumanReadableCopyright",
                                      self[AppSpecKey_Version],                         @"CFBundleVersion",
                                      self[AppSpecKey_Version],                         @"CFBundleShortVersionString",
                                      self[AppSpecKey_Identifier],                      @"CFBundleIdentifier",
                                      self[AppSpecKey_RunInBackground],                      @"LSUIElement",
                                      @"6.0",                                   @"CFBundleInfoDictionaryVersion",
                                      @"APPL",                                  @"CFBundlePackageType",
                                      @"????",                                  @"CFBundleSignature",
                                      @"MainMenu",                              @"NSMainNibFile",
                                      PROGRAM_MIN_SYS_VERSION,                  @"LSMinimumSystemVersion",
                                      @"NSApplication",                         @"NSPrincipalClass",
                                      @{@"NSAllowsArbitraryLoads": @YES},       @"NSAppTransportSecurity",
                                      
                                      nil];
    
    // add icon name if icon is set
    if (self[AppSpecKey_IconPath] != nil && [self[AppSpecKey_IconPath] isEqualToString:@""] == NO) {
        infoPlist[@"CFBundleIconFile"] = @"appIcon.icns";
    }
    
    // if droppable, we declare the accepted file types
    if ([self[AppSpecKey_Droppable] boolValue] == YES) {
        
        NSMutableDictionary *typesAndSuffixesDict = [NSMutableDictionary dictionary];
        
        typesAndSuffixesDict[@"CFBundleTypeExtensions"] = self[AppSpecKey_Suffixes];
        
        if (self[AppSpecKey_Utis] != nil && [self[AppSpecKey_Utis] count] > 0) {
            typesAndSuffixesDict[@"LSItemContentTypes"] = self[AppSpecKey_Utis];
        }
        
        // document icon
        if (self[AppSpecKey_DocIconPath] && [FILEMGR fileExistsAtPath:self[AppSpecKey_DocIconPath]]) {
            typesAndSuffixesDict[@"CFBundleTypeIconFile"] = @"docIcon.icns";
        }
        
        // set file types and suffixes
        infoPlist[@"CFBundleDocumentTypes"] = @[typesAndSuffixesDict];
        
        // add service settings to Info.plist
        if ([self[AppSpecKey_Service] boolValue] == YES) {
            
            NSMutableDictionary *serviceDict = [NSMutableDictionary dictionary];
            
            serviceDict[@"NSMenuItem"] = @{@"default": [NSString stringWithFormat:@"Process with %@", self[AppSpecKey_Name]]};
            serviceDict[@"NSMessage"] = @"dropService";
            serviceDict[@"NSPortName"] = self[AppSpecKey_Name];
            serviceDict[@"NSTimeout"] = [NSNumber numberWithInt:3000];
            
            // service data type handling
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
    return infoPlist;
}

- (void)report:(NSString *)format, ... {
    if ([self silentMode] == YES) {
        return;
    }
    
    va_list args;
    
    va_start(args, format);
    NSString *string  = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    fprintf(stderr, "%s\n", [string UTF8String]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PLATYPUS_APP_SPEC_CREATION_NOTIFICATION object:string];
}

/****************************************
 Make sure the data in the spec is sane
 ****************************************/

- (BOOL)verify {
    BOOL isDir;
    
    if ([self[AppSpecKey_DestinationPath] hasSuffix:@"app"] == FALSE) {
        _error = @"Destination must end with .app";
        return NO;
    }
    
    // warn if font can't be instantiated
    if ([NSFont fontWithName:self[AppSpecKey_TextFont] size:13] == nil) {
        [self report:@"Warning: Font \"%@\" cannot be instantiated.", self[AppSpecKey_TextFont]];
    }
    
    if ([self[AppSpecKey_Name] isEqualToString:@""]) {
        _error = @"Empty app name";
        return NO;
    }
    
    if (![FILEMGR fileExistsAtPath:self[AppSpecKey_ScriptPath] isDirectory:&isDir] || isDir) {
        _error = [NSString stringWithFormat:@"Script not found at path '%@'", self[AppSpecKey_ScriptPath], nil];
        return NO;
    }
    
    if (![FILEMGR fileExistsAtPath:self[AppSpecKey_NibPath]]) {
        _error = [NSString stringWithFormat:@"Nib not found at path '%@'", self[AppSpecKey_NibPath], nil];
        return NO;
    }
    
    if (![FILEMGR fileExistsAtPath:self[AppSpecKey_ExecutablePath] isDirectory:&isDir] || isDir) {
        _error = [NSString stringWithFormat:@"Executable not found at path '%@'", self[AppSpecKey_ExecutablePath], nil];
        return NO;
    }
    
    //make sure destination directory exists
    if (![FILEMGR fileExistsAtPath:[self[AppSpecKey_DestinationPath] stringByDeletingLastPathComponent] isDirectory:&isDir] || !isDir) {
        _error = [NSString stringWithFormat:@"Destination directory '%@' does not exist.", [self[AppSpecKey_DestinationPath] stringByDeletingLastPathComponent], nil];
        return NO;
    }
    
    //make sure we have write privileges for the destination directory
    if (![FILEMGR isWritableFileAtPath:[self[AppSpecKey_DestinationPath] stringByDeletingLastPathComponent]]) {
        _error = [NSString stringWithFormat:@"Don't have permission to write to the destination directory '%@'", self[AppSpecKey_DestinationPath]];
        return NO;
    }
    
    return YES;
}

#pragma mark -

- (void)writeToFile:(NSString *)filePath {
    [self writeToFile:filePath atomically:YES];
}

- (void)dump {
    fprintf(stdout, "%s\n", [[self description] UTF8String]);
}

#pragma mark - Command string generation

- (NSString *)commandStringUsingShortOpts:(BOOL)shortOpts {
    NSString *checkboxParamStr = @"";
    NSString *iconParamStr = @"";
    NSString *versionString = @"";
    NSString *authorString = @"";
    NSString *suffixesString = @"";
    NSString *uniformTypesString = @"";
    NSString *parametersString = @"";
    NSString *textEncodingString = @"";
    NSString *textSettingsString = @"";
    NSString *statusMenuOptionsString = @"";
    
    // checkbox parameters
    if ([self[AppSpecKey_Authenticate] boolValue]) {
        NSString *str = shortOpts ? @"-A " : @"--admin-privileges ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([self[AppSpecKey_Secure] boolValue]) {
        NSString *str = shortOpts ? @"-S " : @"--secure-script ";
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
    
    if ([self[AppSpecKey_Version] isEqualToString:@"1.0"] == FALSE) {
        NSString *str = shortOpts ? @"-V" : @"--app-version";
        versionString = [NSString stringWithFormat:@" %@ '%@' ", str, self[AppSpecKey_Version]];
    }
    
    if (![self[AppSpecKey_Author] isEqualToString:NSFullUserName()]) {
        NSString *str = shortOpts ? @"-u" : @"--author";
        authorString = [NSString stringWithFormat:@" %@ '%@' ", str, self[AppSpecKey_Author]];
    }
    
    NSString *promptForFileString = @"";
    if ([self[AppSpecKey_Droppable] boolValue]) {
        //  suffixes param
        if ([self[AppSpecKey_Suffixes] count]) {
            NSString *str = shortOpts ? @"-X" : @"--suffixes";
            suffixesString = [self[AppSpecKey_Suffixes] componentsJoinedByString:CMDLINE_ARG_SEPARATOR];
            suffixesString = [NSString stringWithFormat:@"%@ '%@' ", str, suffixesString];
        }
        // uniform type identifier params
        if ([self[AppSpecKey_Utis] count]) {
            NSString *str = shortOpts ? @"-T" : @"--uniform-type-identifiers";
            uniformTypesString = [self[AppSpecKey_Utis] componentsJoinedByString:CMDLINE_ARG_SEPARATOR];
            uniformTypesString = [NSString stringWithFormat:@"%@ '%@' ", str, uniformTypesString];
        }
        // file prompt
        if ([self[AppSpecKey_PromptForFile] boolValue]) {
            NSString *str = shortOpts ? @"-Z" : @"--file-prompt";
            promptForFileString = [NSString stringWithFormat:@"%@ ", str];
        }
    }
    
    //create bundled files string
    NSString *bundledFilesCmdString = @"";
    NSArray *bundledFiles = self[AppSpecKey_BundledFiles];
    for (int i = 0; i < [bundledFiles count]; i++) {
        NSString *str = shortOpts ? @"-f" : @"--bundled-file";
        bundledFilesCmdString = [bundledFilesCmdString stringByAppendingString:[NSString stringWithFormat:@"%@ '%@' ", str, bundledFiles[i]]];
    }
    
    // create interpreter and script args flags
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
    
    //  create args for text settings
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
    
    //text encoding
    if ([self[AppSpecKey_TextEncoding] intValue] != DEFAULT_TEXT_ENCODING) {
        NSString *str = shortOpts ? @"-E" : @"--text-encoding";
        textEncodingString = [NSString stringWithFormat:@" %@ %d ", str, [self[AppSpecKey_TextEncoding] intValue]];
    }
    
    //create custom icon string
    if (![self[AppSpecKey_IconPath] isEqualToString:CMDLINE_ICON_PATH] && ![self[AppSpecKey_IconPath] isEqualToString:@""]) {
        NSString *str = shortOpts ? @"-i" : @"--app-icon";
        iconParamStr = [NSString stringWithFormat:@"%@ '%@' ", str, self[AppSpecKey_IconPath]];
    }
    
    //create custom icon string
    if (self[AppSpecKey_DocIconPath] && ![self[AppSpecKey_DocIconPath] isEqualToString:@""]) {
        NSString *str = shortOpts ? @"-Q" : @"--document-icon";
        iconParamStr = [iconParamStr stringByAppendingFormat:@" %@ '%@' ", str, self[AppSpecKey_DocIconPath]];
    }
    
    //status menu settings, if interface type is status menu
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
    
    // only set app name arg if we have a proper value
    NSString *appNameArg = @"";
    if ([self[AppSpecKey_Name] isEqualToString:@""] == FALSE) {
        NSString *str = shortOpts ? @"-a" : @"--name";
        appNameArg = [NSString stringWithFormat: @" %@ '%@' ", str,  self[AppSpecKey_Name]];
    }
    
    // only add identifier argument if it varies from default
    NSString *identifierArg = @"";
    NSString *standardIdentifier = [PlatypusAppSpec bundleIdentifierForAppName:self[AppSpecKey_Name] authorName:nil usingDefaults: NO];
    if ([self[AppSpecKey_Identifier] isEqualToString:standardIdentifier] == FALSE) {
        NSString *str = shortOpts ? @"-I" : @"--bundle-identifier";
        identifierArg = [NSString stringWithFormat: @" %@ %@ ", str, self[AppSpecKey_Identifier]];
    }
    
    // interface type
    NSString *str = shortOpts ? @"-o" : @"--interface-type";
    NSString *interfaceArg = [NSString stringWithFormat:@" %@ '%@' ", str, self[AppSpecKey_InterfaceType]];
    
    // interpreter
    str = shortOpts ? @"-p" : @"--interpreter";
    NSString *interpreterArg = [NSString stringWithFormat:@" %@ '%@' ", str, self[AppSpecKey_Interpreter]];
    
    
    // finally, generate the command
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
                            promptForFileString,
                            bundledFilesCmdString,
                            parametersString,
                            textEncodingString,
                            textSettingsString,
                            statusMenuOptionsString,
                            self[AppSpecKey_ScriptPath],
                            nil];
    
    return commandStr;
}

#pragma mark - Class Methods

/*******************************************************************
 - Return the bundle identifier for the application to be generated
 - based on username etc. e.g. org.username.AppName
 ******************************************************************/

+ (NSString *)bundleIdentifierForAppName:(NSString *)appName authorName:(NSString *)authorName usingDefaults:(BOOL)def {
    if (appName == nil) {
        appName = DEFAULT_APP_NAME;
    }
    NSString *defaults = def ? [DEFAULTS stringForKey:DefaultsKey_BundleIdentifierPrefix] : nil;
    NSString *author = authorName ? [authorName stringByReplacingOccurrencesOfString:@" " withString:@""] : NSUserName();
    NSString *pre = defaults == nil ? [NSString stringWithFormat:@"org.%@.", author] : defaults;
    NSString *identifierString = [NSString stringWithFormat:@"%@%@", pre, appName];
    identifierString = [identifierString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSData *asciiData = [identifierString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    identifierString = [[NSString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding];

    return identifierString;
}

+ (void)optimizeNibFile:(NSString *)nibPath {
    NSTask *ibToolTask = [[NSTask alloc] init];
    [ibToolTask setLaunchPath:IBTOOL_PATH];
    [ibToolTask setArguments:@[@"--strip", nibPath, nibPath]];
    [ibToolTask launch];
    [ibToolTask waitUntilExit];
}

@end
