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

#if !__has_feature(objc_arc)
- (void)dealloc {
    [properties release];
    [super dealloc];
}
#endif

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

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        properties = [[NSMutableDictionary alloc] initWithCoder:aDecoder];
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
    id spec = [[self alloc] initWithDefaults];
#if !__has_feature(objc_arc)
    [spec autorelease];
#endif
    return spec;
}

+ (instancetype)specWithDictionary:(NSDictionary *)dict {
    id spec = [[self alloc] initWithDictionary:dict];
#if !__has_feature(objc_arc)
    [spec autorelease];
#endif
    return spec;
}

+ (instancetype)specWithProfile:(NSString *)profilePath {
    id spec = [[self alloc] initWithProfile:profilePath];
#if !__has_feature(objc_arc)
    [spec autorelease];
#endif
    return spec;
}

+ (instancetype)specWithDefaultsFromScript:(NSString *)scriptPath {
    id spec = [[self alloc] initWithDefaultsForScript:scriptPath];
#if !__has_feature(objc_arc)
    [spec autorelease];
#endif
    return spec;
}

#pragma mark - Set default values

/************************************************
 init a spec with default values for everything
 ************************************************/

- (void)setDefaults {
    // stamp the spec with the creator
    self[APPSPEC_KEY_CREATOR] = PROGRAM_CREATOR_STAMP;
    
    //prior properties
    self[APPSPEC_KEY_EXECUTABLE_PATH] = CMDLINE_EXEC_PATH;
    self[APPSPEC_KEY_NIB_PATH] = CMDLINE_NIB_PATH;
    self[APPSPEC_KEY_DESTINATION_PATH] = DEFAULT_DESTINATION_PATH;
    self[APPSPEC_KEY_OVERWRITE] = @NO;
    self[APPSPEC_KEY_SYMLINK_FILES] = @NO;
    self[APPSPEC_KEY_STRIP_NIB] = @YES;
    self[APPSPEC_KEY_XML_PLIST_FORMAT] = @NO;
    
    self[APPSPEC_KEY_NAME] = DEFAULT_APP_NAME;
    self[APPSPEC_KEY_SCRIPT_PATH] = @"";
    self[APPSPEC_KEY_INTERFACE_TYPE] = DEFAULT_OUTPUT_TYPE_STRING;
    self[APPSPEC_KEY_ICON_PATH] = CMDLINE_ICON_PATH;
    
    self[APPSPEC_KEY_INTERPRETER] = DEFAULT_INTERPRETER;
    self[APPSPEC_KEY_INTERPRETER_ARGS] = [NSArray array];
    self[APPSPEC_KEY_SCRIPT_ARGS] = [NSArray array];
    self[APPSPEC_KEY_VERSION] = DEFAULT_VERSION;
    self[APPSPEC_KEY_IDENTIFIER] = [PlatypusAppSpec bundleIdentifierForAppName:DEFAULT_APP_NAME authorName:nil usingDefaults:YES];
    self[APPSPEC_KEY_AUTHOR] = NSFullUserName();
    
    self[APPSPEC_KEY_DROPPABLE] = @NO;
    self[APPSPEC_KEY_SECURE] = @NO;
    self[APPSPEC_KEY_AUTHENTICATE] = @NO;
    self[APPSPEC_KEY_REMAIN_RUNNING] = @YES;
    self[APPSPEC_KEY_RUN_IN_BACKGROUND] = @NO;
    
    // bundled files
    self[APPSPEC_KEY_BUNDLED_FILES] = [NSMutableArray array];
    
    // file/drag acceptance properties
    self[APPSPEC_KEY_SUFFIXES] = DEFAULT_SUFFIXES;
    self[APPSPEC_KEY_UTIS] = DEFAULT_UTIS;
    self[APPSPEC_KEY_ACCEPT_TEXT] = @NO;
    self[APPSPEC_KEY_ACCEPT_FILES] = @YES;
    self[APPSPEC_KEY_SERVICE] = @NO;
    self[APPSPEC_KEY_PROMPT_FOR_FILE] = @NO;
    self[APPSPEC_KEY_DOC_ICON_PATH] = @"";
    
    // text output settings
    self[APPSPEC_KEY_TEXT_ENCODING] = @(DEFAULT_OUTPUT_TXT_ENCODING);
    self[APPSPEC_KEY_TEXT_FONT] = DEFAULT_OUTPUT_FONT;
    self[APPSPEC_KEY_TEXT_SIZE] = @(DEFAULT_OUTPUT_FONTSIZE);
    self[APPSPEC_KEY_TEXT_COLOR] = DEFAULT_OUTPUT_FG_COLOR;
    self[APPSPEC_KEY_TEXT_BGCOLOR] = DEFAULT_OUTPUT_BG_COLOR;
    
    // status item settings
    self[APPSPEC_KEY_STATUSITEM_DISPLAY_TYPE] = PLATYPUS_STATUSITEM_DISPLAY_TYPE_DEFAULT;
    self[APPSPEC_KEY_STATUSITEM_TITLE] = DEFAULT_APP_NAME;
    self[APPSPEC_KEY_STATUSITEM_ICON] = [NSData data];
    self[APPSPEC_KEY_STATUSITEM_USE_SYSFONT] = @YES;
}

/********************************************************
 Init with default values and then analyse script, then
 load default values based on analysed script properties
 ********************************************************/

- (void)setDefaultsForScript:(NSString *)scriptPath {
    // start with a dict populated with defaults
    [self setDefaults];
    
    // set script path
    self[APPSPEC_KEY_SCRIPT_PATH] = scriptPath;
    
    //determine app name based on script filename
    self[APPSPEC_KEY_NAME] = [ScriptAnalyser appNameFromScriptFilePath:scriptPath];
    
    //find an interpreter for it
    NSString *interpreter = [ScriptAnalyser determineInterpreterForScriptFile:scriptPath];
    if (interpreter == nil) {
        interpreter = DEFAULT_INTERPRETER;
    } else {
        // get parameters to interpreter
        NSMutableArray *shebangCmdComponents = [NSMutableArray arrayWithArray:[ScriptAnalyser parseInterpreterFromShebang:scriptPath]];
        [shebangCmdComponents removeObjectAtIndex:0];
        self[APPSPEC_KEY_INTERPRETER_ARGS] = shebangCmdComponents;
    }
    self[APPSPEC_KEY_INTERPRETER] = interpreter;
    
    // find parent folder wherefrom we create destination path of app bundle
    NSString *parentFolder = [scriptPath stringByDeletingLastPathComponent];
    NSString *destPath = [NSString stringWithFormat:@"%@/%@.app", parentFolder, self[APPSPEC_KEY_NAME]];
    self[APPSPEC_KEY_DESTINATION_PATH] = destPath;
    self[APPSPEC_KEY_IDENTIFIER] = [PlatypusAppSpec bundleIdentifierForAppName:self[APPSPEC_KEY_NAME]
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
    if ([FILEMGR fileExistsAtPath:self[APPSPEC_KEY_DESTINATION_PATH]]) {
        if ([self[APPSPEC_KEY_OVERWRITE] boolValue] == FALSE) {
            _error = [NSString stringWithFormat:@"App already exists at path %@. Use -y flag to overwrite.", self[APPSPEC_KEY_DESTINATION_PATH]];
            return FALSE;
        } else {
            [self report:@"Overwriting app at path %@", self[APPSPEC_KEY_DESTINATION_PATH]];
        }
    }
    
    // check if executable exists
    NSString *execPath = self[APPSPEC_KEY_EXECUTABLE_PATH];
    if (![FILEMGR fileExistsAtPath:execPath] || ![FILEMGR isReadableFileAtPath:execPath]) {
        [self report:@"Executable %@ does not exist. Aborting.", execPath];
        return NO;
    }
    
    // check if source nib exists
    NSString *nibPath = self[APPSPEC_KEY_NIB_PATH];
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
    tmpPath = [tmpPath stringByAppendingString:[self[APPSPEC_KEY_DESTINATION_PATH] lastPathComponent]];
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
    execDestinationPath = [execDestinationPath stringByAppendingString:self[APPSPEC_KEY_NAME]];
    [FILEMGR copyItemAtPath:execPath toPath:execDestinationPath error:nil];
    NSDictionary *execAttrDict = @{NSFilePosixPermissions: @0755UL};
    [FILEMGR setAttributes:execAttrDict ofItemAtPath:execDestinationPath error:nil];
    
    // copy nib file to app bundle
    // .app/Contents/Resources/MainMenu.nib
    [self report:@"Copying nib file to bundle"];
    NSString *nibDestinationPath = [resourcesPath stringByAppendingString:@"/MainMenu.nib"];
    [FILEMGR copyItemAtPath:nibPath toPath:nibDestinationPath error:nil];
    
    if ([self[APPSPEC_KEY_STRIP_NIB] boolValue] == YES && [FILEMGR fileExistsAtPath:IBTOOL_PATH]) {
        [self report:@"Optimizing nib file"];
        [PlatypusAppSpec optimizeNibFile:nibDestinationPath];
    }
    
    // create script file in app bundle
    // .app/Contents/Resources/script
    [self report:@"Copying script"];
    
    NSData *scriptData = [NSData data];
    if ([self[APPSPEC_KEY_SECURE] boolValue]) {
        NSString *path = self[APPSPEC_KEY_SCRIPT_PATH];
        scriptData = [NSData dataWithContentsOfFile:path];
    } else {
        NSString *scriptFilePath = [resourcesPath stringByAppendingString:@"/script"];
        
        if ([self[APPSPEC_KEY_SYMLINK_FILES] boolValue] == YES) {
            [FILEMGR createSymbolicLinkAtPath:scriptFilePath
                          withDestinationPath:self[APPSPEC_KEY_SCRIPT_PATH]
                                        error:nil];
        } else {
            // copy script over
            [FILEMGR copyItemAtPath:self[APPSPEC_KEY_SCRIPT_PATH] toPath:scriptFilePath error:nil];
        }
        
        NSDictionary *fileAttrDict = @{NSFilePosixPermissions: @0755UL};
        [FILEMGR setAttributes:fileAttrDict ofItemAtPath:scriptFilePath error:nil];
    }
    
    // create AppSettings.plist file
    // .app/Contents/Resources/AppSettings.plist
    [self report:@"Creating AppSettings property list"];
    NSMutableDictionary *appSettingsPlist = [self appSettingsPlist];
    if ([self[APPSPEC_KEY_SECURE] boolValue]) {
        // if script is "secured" we encode it into AppSettings property list
        appSettingsPlist[@"TextSettings"] = [NSKeyedArchiver archivedDataWithRootObject:scriptData];
    }
    NSString *appSettingsPlistPath = [resourcesPath stringByAppendingString:@"/AppSettings.plist"];
    if ([self[APPSPEC_KEY_XML_PLIST_FORMAT] boolValue] == FALSE) {
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
    if (self[APPSPEC_KEY_ICON_PATH] && ![self[APPSPEC_KEY_ICON_PATH] isEqualToString:@""]) {
        [self report:@"Writing application icon"];
        NSString *iconPath = [resourcesPath stringByAppendingString:@"/appIcon.icns"];
        [FILEMGR copyItemAtPath:self[APPSPEC_KEY_ICON_PATH] toPath:iconPath error:nil];
    }
    
    // document icon
    // .app/Contents/Resources/docIcon.icns
    if (self[APPSPEC_KEY_DOC_ICON_PATH] && ![self[APPSPEC_KEY_DOC_ICON_PATH] isEqualToString:@""]) {
        [self report:@"Writing document icon"];
        NSString *docIconPath = [resourcesPath stringByAppendingString:@"/docIcon.icns"];
        [FILEMGR copyItemAtPath:self[APPSPEC_KEY_DOC_ICON_PATH] toPath:docIconPath error:nil];
    }
    
    // create Info.plist file
    // .app/Contents/Info.plist
    [self report:@"Writing Info.plist"];
    NSDictionary *infoPlist = [self infoPlist];
    NSString *infoPlistPath = [contentsPath stringByAppendingString:@"/Info.plist"];
    BOOL success = YES;
    // if binary
    if ([self[APPSPEC_KEY_XML_PLIST_FORMAT] boolValue] == NO) {
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
    
    int numBundledFiles = [self[APPSPEC_KEY_BUNDLED_FILES] count];
    if (numBundledFiles) {
        [self report:@"Copying %d bundled files", numBundledFiles];
    }
    for (NSString *bundledFilePath in self[APPSPEC_KEY_BUNDLED_FILES]) {
        NSString *fileName = [bundledFilePath lastPathComponent];
        NSString *bundledFileDestPath = [resourcesPath stringByAppendingString:@"/"];
        bundledFileDestPath = [bundledFileDestPath stringByAppendingString:fileName];
        
        // if it's a development version, we just symlink it
        if ([self[APPSPEC_KEY_SYMLINK_FILES] boolValue]) {
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
    [self report:@"Moving app to destination directory '%@'", self[APPSPEC_KEY_DESTINATION_PATH]];
    
    NSString *destPath = self[APPSPEC_KEY_DESTINATION_PATH];
    
    // first, let's see if there's anything there.  If we have overwrite set, we just delete that stuff
    if ([FILEMGR fileExistsAtPath:destPath]) {
        if ([self[APPSPEC_KEY_OVERWRITE] boolValue]) {
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
    if ([self[APPSPEC_KEY_SERVICE] boolValue]) {
        [self report:@"Updating Dynamic Services"];
        [WORKSPACE flushServices];
    }
    
    [self report:@"Done"];
    
    return TRUE;
}

// generate AppSettings.plist dictionary
- (NSMutableDictionary *)appSettingsPlist {
    
    NSMutableDictionary *appSettingsPlist = [NSMutableDictionary dictionary];
    
    appSettingsPlist[APPSPEC_KEY_AUTHENTICATE] = self[APPSPEC_KEY_AUTHENTICATE];
    appSettingsPlist[APPSPEC_KEY_DROPPABLE] = self[APPSPEC_KEY_DROPPABLE];
    appSettingsPlist[APPSPEC_KEY_REMAIN_RUNNING] = self[APPSPEC_KEY_REMAIN_RUNNING];
    appSettingsPlist[APPSPEC_KEY_SECURE] = self[APPSPEC_KEY_SECURE];
    appSettingsPlist[APPSPEC_KEY_INTERFACE_TYPE] = self[APPSPEC_KEY_INTERFACE_TYPE];
    appSettingsPlist[APPSPEC_KEY_INTERPRETER] = self[APPSPEC_KEY_INTERPRETER];
    appSettingsPlist[APPSPEC_KEY_CREATOR] = PROGRAM_CREATOR_STAMP;
    appSettingsPlist[APPSPEC_KEY_INTERPRETER_ARGS] = self[APPSPEC_KEY_INTERPRETER_ARGS];
    appSettingsPlist[APPSPEC_KEY_SCRIPT_ARGS] = self[APPSPEC_KEY_SCRIPT_ARGS];
    appSettingsPlist[APPSPEC_KEY_PROMPT_FOR_FILE] = self[APPSPEC_KEY_PROMPT_FOR_FILE];
    
    appSettingsPlist[APPSPEC_KEY_TEXT_FONT] = self[APPSPEC_KEY_TEXT_FONT];
    appSettingsPlist[APPSPEC_KEY_TEXT_SIZE] = self[APPSPEC_KEY_TEXT_SIZE];
    appSettingsPlist[APPSPEC_KEY_TEXT_COLOR] = self[APPSPEC_KEY_TEXT_COLOR];
    appSettingsPlist[APPSPEC_KEY_TEXT_BGCOLOR] = self[APPSPEC_KEY_TEXT_BGCOLOR];
    appSettingsPlist[APPSPEC_KEY_TEXT_ENCODING] = self[APPSPEC_KEY_TEXT_ENCODING];

    appSettingsPlist[APPSPEC_KEY_STATUSITEM_DISPLAY_TYPE] = self[APPSPEC_KEY_STATUSITEM_DISPLAY_TYPE];
    appSettingsPlist[APPSPEC_KEY_STATUSITEM_TITLE] = self[APPSPEC_KEY_STATUSITEM_TITLE];
    appSettingsPlist[APPSPEC_KEY_STATUSITEM_ICON] = self[APPSPEC_KEY_STATUSITEM_ICON];
    appSettingsPlist[APPSPEC_KEY_STATUSITEM_USE_SYSFONT] = self[APPSPEC_KEY_STATUSITEM_USE_SYSFONT];
    
    appSettingsPlist[APPSPEC_KEY_ACCEPT_FILES] = self[APPSPEC_KEY_ACCEPT_FILES];
    appSettingsPlist[APPSPEC_KEY_ACCEPT_TEXT] = self[APPSPEC_KEY_ACCEPT_TEXT];
    appSettingsPlist[APPSPEC_KEY_SUFFIXES] = self[APPSPEC_KEY_SUFFIXES];
    appSettingsPlist[APPSPEC_KEY_UTIS] = self[APPSPEC_KEY_UTIS];
    
    return appSettingsPlist;
}

// generate Info.plist dictionary
- (NSDictionary *)infoPlist {
    
    // create copyright string with current year
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
#if !__has_feature(objc_arc)
    [formatter autorelease];
#endif
    [formatter setDateFormat:@"yyyy"];
    NSString *yearString = [formatter stringFromDate:[NSDate date]];
    NSString *copyrightString = [NSString stringWithFormat:@"© %@ %@", yearString, self[APPSPEC_KEY_AUTHOR]];
    
    // create dict
    NSMutableDictionary *infoPlist = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      
                                      @"en",                                    @"CFBundleDevelopmentRegion",
                                      self[APPSPEC_KEY_NAME],                            @"CFBundleExecutable",
                                      self[APPSPEC_KEY_NAME],                            @"CFBundleName",
                                      copyrightString,                          @"NSHumanReadableCopyright",
                                      self[APPSPEC_KEY_VERSION],                         @"CFBundleVersion",
                                      self[APPSPEC_KEY_VERSION],                         @"CFBundleShortVersionString",
                                      self[APPSPEC_KEY_IDENTIFIER],                      @"CFBundleIdentifier",
                                      self[APPSPEC_KEY_RUN_IN_BACKGROUND],                      @"LSUIElement",
                                      @"6.0",                                   @"CFBundleInfoDictionaryVersion",
                                      @"APPL",                                  @"CFBundlePackageType",
                                      @"????",                                  @"CFBundleSignature",
                                      @"MainMenu",                              @"NSMainNibFile",
                                      PROGRAM_MIN_SYS_VERSION,                  @"LSMinimumSystemVersion",
                                      @"NSApplication",                         @"NSPrincipalClass",
                                      @{@"NSAllowsArbitraryLoads": @YES},       @"NSAppTransportSecurity",
                                      
                                      nil];
    
    // add icon name if icon is set
    if (self[APPSPEC_KEY_ICON_PATH] != nil && [self[APPSPEC_KEY_ICON_PATH] isEqualToString:@""] == NO) {
        infoPlist[@"CFBundleIconFile"] = @"appIcon.icns";
    }
    
    // if droppable, we declare the accepted file types
    if ([self[APPSPEC_KEY_DROPPABLE] boolValue] == YES) {
        
        NSMutableDictionary *typesAndSuffixesDict = [NSMutableDictionary dictionary];
        
        typesAndSuffixesDict[@"CFBundleTypeExtensions"] = self[APPSPEC_KEY_SUFFIXES];
        
        if (self[APPSPEC_KEY_UTIS] != nil && [self[APPSPEC_KEY_UTIS] count] > 0) {
            typesAndSuffixesDict[@"LSItemContentTypes"] = self[APPSPEC_KEY_UTIS];
        }
        
        // document icon
        if (self[APPSPEC_KEY_DOC_ICON_PATH] && [FILEMGR fileExistsAtPath:self[APPSPEC_KEY_DOC_ICON_PATH]]) {
            typesAndSuffixesDict[@"CFBundleTypeIconFile"] = @"docIcon.icns";
        }
        
        // set file types and suffixes
        infoPlist[@"CFBundleDocumentTypes"] = @[typesAndSuffixesDict];
        
        // add service settings to Info.plist
        if ([self[APPSPEC_KEY_SERVICE] boolValue] == YES) {
            
            NSMutableDictionary *serviceDict = [NSMutableDictionary dictionary];
            
            serviceDict[@"NSMenuItem"] = @{@"default": [NSString stringWithFormat:@"Process with %@", self[APPSPEC_KEY_NAME]]};
            serviceDict[@"NSMessage"] = @"dropService";
            serviceDict[@"NSPortName"] = self[APPSPEC_KEY_NAME];
            serviceDict[@"NSTimeout"] = [NSNumber numberWithInt:3000];
            
            // service data type handling
            NSMutableArray *sendTypes = [NSMutableArray array];
            if ([self[APPSPEC_KEY_ACCEPT_FILES] boolValue]) {
                [sendTypes addObject:@"NSFilenamesPboardType"];
                serviceDict[@"NSSendFileTypes"] = @[(NSString *)kUTTypeItem];
            }
            if ([self[APPSPEC_KEY_ACCEPT_TEXT] boolValue]) {
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
    
#if !__has_feature(objc_arc)
    [string autorelease];
#endif
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PLATYPUS_APP_SPEC_CREATION_NOTIFICATION object:string];
}

/****************************************
 Make sure the data in the spec is sane
 ****************************************/

- (BOOL)verify {
    BOOL isDir;
    
    if ([self[APPSPEC_KEY_DESTINATION_PATH] hasSuffix:@"app"] == FALSE) {
        _error = @"Destination must end with .app";
        return NO;
    }
    
    // warn if font can't be instantiated
    if ([NSFont fontWithName:self[APPSPEC_KEY_TEXT_FONT] size:13] == nil) {
        [self report:@"Warning: Font \"%@\" cannot be instantiated.", self[APPSPEC_KEY_TEXT_FONT]];
    }
    
    if ([self[APPSPEC_KEY_NAME] isEqualToString:@""]) {
        _error = @"Empty app name";
        return NO;
    }
    
    if (![FILEMGR fileExistsAtPath:self[APPSPEC_KEY_SCRIPT_PATH] isDirectory:&isDir] || isDir) {
        _error = [NSString stringWithFormat:@"Script not found at path '%@'", self[APPSPEC_KEY_SCRIPT_PATH], nil];
        return NO;
    }
    
    if (![FILEMGR fileExistsAtPath:self[APPSPEC_KEY_NIB_PATH] isDirectory:&isDir] || isDir) {
        _error = [NSString stringWithFormat:@"Nib not found at path '%@'", self[APPSPEC_KEY_NIB_PATH], nil];
        return NO;
    }
    
    if (![FILEMGR fileExistsAtPath:self[APPSPEC_KEY_EXECUTABLE_PATH] isDirectory:&isDir] || isDir) {
        _error = [NSString stringWithFormat:@"Executable not found at path '%@'", self[APPSPEC_KEY_EXECUTABLE_PATH], nil];
        return NO;
    }
    
    //make sure destination directory exists
    if (![FILEMGR fileExistsAtPath:[self[APPSPEC_KEY_DESTINATION_PATH] stringByDeletingLastPathComponent] isDirectory:&isDir] || !isDir) {
        _error = [NSString stringWithFormat:@"Destination directory '%@' does not exist.", [self[APPSPEC_KEY_DESTINATION_PATH] stringByDeletingLastPathComponent], nil];
        return NO;
    }
    
    //make sure we have write privileges for the destination directory
    if (![FILEMGR isWritableFileAtPath:[self[APPSPEC_KEY_DESTINATION_PATH] stringByDeletingLastPathComponent]]) {
        _error = [NSString stringWithFormat:@"Don't have permission to write to the destination directory '%@'", self[APPSPEC_KEY_DESTINATION_PATH]];
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
    NSString *textOutputString = @"";
    NSString *statusMenuOptionsString = @"";
    
    // checkbox parameters
    if ([self[APPSPEC_KEY_AUTHENTICATE] boolValue]) {
        NSString *str = shortOpts ? @"-A " : @"--admin-privileges ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([self[APPSPEC_KEY_SECURE] boolValue]) {
        NSString *str = shortOpts ? @"-S " : @"--secure-script ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([self[APPSPEC_KEY_ACCEPT_FILES] boolValue] && [self[APPSPEC_KEY_DROPPABLE] boolValue]) {
        NSString *str = shortOpts ? @"-D " : @"--droppable ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([self[APPSPEC_KEY_ACCEPT_TEXT] boolValue] && [self[APPSPEC_KEY_DROPPABLE] boolValue]) {
        NSString *str = shortOpts ? @"-F " : @"--text-droppable ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([self[APPSPEC_KEY_SERVICE] boolValue] && [self[APPSPEC_KEY_DROPPABLE] boolValue]) {
        NSString *str = shortOpts ? @"-N " : @"--service ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([self[APPSPEC_KEY_RUN_IN_BACKGROUND] boolValue]) {
        NSString *str = shortOpts ? @"-B " : @"--background ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([self[APPSPEC_KEY_REMAIN_RUNNING] boolValue] == FALSE) {
        NSString *str = shortOpts ? @"-R " : @"--quit-after-execution ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([self[APPSPEC_KEY_VERSION] isEqualToString:@"1.0"] == FALSE) {
        NSString *str = shortOpts ? @"-V" : @"--app-version";
        versionString = [NSString stringWithFormat:@" %@ '%@' ", str, self[APPSPEC_KEY_VERSION]];
    }
    
    if (![self[APPSPEC_KEY_AUTHOR] isEqualToString:NSFullUserName()]) {
        NSString *str = shortOpts ? @"-u" : @"--author";
        authorString = [NSString stringWithFormat:@" %@ '%@' ", str, self[APPSPEC_KEY_AUTHOR]];
    }
    
    NSString *promptForFileString = @"";
    if ([self[APPSPEC_KEY_DROPPABLE] boolValue]) {
        //  suffixes param
        if ([self[APPSPEC_KEY_SUFFIXES] count]) {
            NSString *str = shortOpts ? @"-X" : @"--suffixes";
            suffixesString = [self[APPSPEC_KEY_SUFFIXES] componentsJoinedByString:CMDLINE_ARG_SEPARATOR];
            suffixesString = [NSString stringWithFormat:@"%@ '%@' ", str, suffixesString];
        }
        // uniform type identifier params
        if ([self[APPSPEC_KEY_UTIS] count]) {
            NSString *str = shortOpts ? @"-T" : @"--uniform-type-identifiers";
            uniformTypesString = [self[APPSPEC_KEY_UTIS] componentsJoinedByString:CMDLINE_ARG_SEPARATOR];
            uniformTypesString = [NSString stringWithFormat:@"%@ '%@' ", str, uniformTypesString];
        }
        // file prompt
        if ([self[APPSPEC_KEY_PROMPT_FOR_FILE] boolValue]) {
            NSString *str = shortOpts ? @"-Z" : @"--file-prompt";
            promptForFileString = [NSString stringWithFormat:@"%@ ", str];
        }
    }
    
    //create bundled files string
    NSString *bundledFilesCmdString = @"";
    NSArray *bundledFiles = self[APPSPEC_KEY_BUNDLED_FILES];
    for (int i = 0; i < [bundledFiles count]; i++) {
        NSString *str = shortOpts ? @"-f" : @"--bundled-file";
        bundledFilesCmdString = [bundledFilesCmdString stringByAppendingString:[NSString stringWithFormat:@"%@ '%@' ", str, bundledFiles[i]]];
    }
    
    // create interpreter and script args flags
    if ([self[APPSPEC_KEY_INTERPRETER_ARGS] count]) {
        NSString *str = shortOpts ? @"-G" : @"--interpreter-args";
        NSString *arg = [self[APPSPEC_KEY_INTERPRETER_ARGS] componentsJoinedByString:CMDLINE_ARG_SEPARATOR];
        parametersString = [parametersString stringByAppendingString:[NSString stringWithFormat:@"%@ '%@' ", str, arg]];
    }
    if ([self[APPSPEC_KEY_SCRIPT_ARGS] count]) {
        NSString *str = shortOpts ? @"-C" : @"--script-args";
        NSString *arg = [self[APPSPEC_KEY_SCRIPT_ARGS] componentsJoinedByString:CMDLINE_ARG_SEPARATOR];
        parametersString = [parametersString stringByAppendingString:[NSString stringWithFormat:@"%@ '%@' ", str, arg]];
    }
    
    //  create args for text settings
    if (IsTextStyledOutputTypeString(self[APPSPEC_KEY_INTERFACE_TYPE])) {
        
        NSString *textFgString = @"", *textBgString = @"", *textFontString = @"";
        if (![self[APPSPEC_KEY_TEXT_COLOR] isEqualToString:DEFAULT_OUTPUT_FG_COLOR]) {
            NSString *str = shortOpts ? @"-g" : @"--text-foreground-color";
            textFgString = [NSString stringWithFormat:@" %@ '%@' ", str, self[APPSPEC_KEY_TEXT_COLOR]];
        }
        
        if (![self[APPSPEC_KEY_TEXT_BGCOLOR] isEqualToString:DEFAULT_OUTPUT_BG_COLOR]) {
            NSString *str = shortOpts ? @"-b" : @"--text-background-color";
            textBgString = [NSString stringWithFormat:@" %@ '%@' ", str, self[APPSPEC_KEY_TEXT_COLOR]];
        }
        
        if ([self[APPSPEC_KEY_TEXT_SIZE] floatValue] != DEFAULT_OUTPUT_FONTSIZE ||
            ![self[APPSPEC_KEY_TEXT_FONT] isEqualToString:DEFAULT_OUTPUT_FONT]) {
            NSString *str = shortOpts ? @"-n" : @"--text-font";
            textFontString = [NSString stringWithFormat:@" %@ '%@ %2.f' ", str, self[APPSPEC_KEY_TEXT_FONT], [self[APPSPEC_KEY_TEXT_SIZE] floatValue]];
        }
        
        textOutputString = [NSString stringWithFormat:@"%@%@%@", textFgString, textBgString, textFontString];
    }
    
    //text encoding
    if ([self[APPSPEC_KEY_TEXT_ENCODING] intValue] != DEFAULT_OUTPUT_TXT_ENCODING) {
        NSString *str = shortOpts ? @"-E" : @"--text-encoding";
        textEncodingString = [NSString stringWithFormat:@" %@ %d ", str, [self[APPSPEC_KEY_TEXT_ENCODING] intValue]];
    }
    
    //create custom icon string
    if (![self[APPSPEC_KEY_ICON_PATH] isEqualToString:CMDLINE_ICON_PATH] && ![self[APPSPEC_KEY_ICON_PATH] isEqualToString:@""]) {
        NSString *str = shortOpts ? @"-i" : @"--app-icon";
        iconParamStr = [NSString stringWithFormat:@"%@ '%@' ", str, self[APPSPEC_KEY_ICON_PATH]];
    }
    
    //create custom icon string
    if (self[APPSPEC_KEY_DOC_ICON_PATH] && ![self[APPSPEC_KEY_DOC_ICON_PATH] isEqualToString:@""]) {
        NSString *str = shortOpts ? @"-Q" : @"--document-icon";
        iconParamStr = [iconParamStr stringByAppendingFormat:@" %@ '%@' ", str, self[APPSPEC_KEY_DOC_ICON_PATH]];
    }
    
    //status menu settings, if output mode is status menu
    if ([self[APPSPEC_KEY_INTERFACE_TYPE] isEqualToString:PLATYPUS_OUTPUT_STRING_STATUS_MENU]) {
        // -K kind
        NSString *str = shortOpts ? @"-K" : @"--status-item-kind";
        statusMenuOptionsString = [statusMenuOptionsString stringByAppendingFormat:@"%@ '%@' ", str, self[APPSPEC_KEY_STATUSITEM_DISPLAY_TYPE]];
        
        // -L /path/to/image
        if ([self[APPSPEC_KEY_STATUSITEM_DISPLAY_TYPE] isEqualToString:PLATYPUS_STATUSITEM_DISPLAY_TYPE_ICON]) {
            str = shortOpts ? @"-L" : @"--status-item-icon";
            statusMenuOptionsString = [statusMenuOptionsString stringByAppendingFormat:@"%@ '/path/to/image' ", str];
        }
        // -Y 'Title'
        else if ([self[APPSPEC_KEY_STATUSITEM_DISPLAY_TYPE] isEqualToString:PLATYPUS_STATUSITEM_DISPLAY_TYPE_TEXT]) {
            str = shortOpts ? @"-Y" : @"--status-item-title";
            statusMenuOptionsString = [statusMenuOptionsString stringByAppendingFormat:@"%@ '%@' ", str, self[APPSPEC_KEY_STATUSITEM_TITLE]];
        }
        
        // -c
        if ([self[APPSPEC_KEY_STATUSITEM_USE_SYSFONT] boolValue]) {
            str = shortOpts ? @"-c" : @"--status-item-sysfont";
            statusMenuOptionsString = [statusMenuOptionsString stringByAppendingFormat:@"%@ ", str];
        }
    }
    
    // only set app name arg if we have a proper value
    NSString *appNameArg = @"";
    if ([self[APPSPEC_KEY_NAME] isEqualToString:@""] == FALSE) {
        NSString *str = shortOpts ? @"-a" : @"--name";
        appNameArg = [NSString stringWithFormat: @" %@ '%@' ", str,  self[APPSPEC_KEY_NAME]];
    }
    
    // only add identifier argument if it varies from default
    NSString *identifierArg = @"";
    NSString *standardIdentifier = [PlatypusAppSpec bundleIdentifierForAppName:self[APPSPEC_KEY_NAME] authorName:nil usingDefaults: NO];
    if ([self[APPSPEC_KEY_IDENTIFIER] isEqualToString:standardIdentifier] == FALSE) {
        NSString *str = shortOpts ? @"-I" : @"--bundle-identifier";
        identifierArg = [NSString stringWithFormat: @" %@ %@ ", str, self[APPSPEC_KEY_IDENTIFIER]];
    }
    
    // output type
    NSString *str = shortOpts ? @"-o" : @"--output-type";
    NSString *outputArg = [NSString stringWithFormat:@" %@ '%@' ", str, self[APPSPEC_KEY_INTERFACE_TYPE]];
    
    // interpreter
    str = shortOpts ? @"-p" : @"--interpreter";
    NSString *interpreterArg = [NSString stringWithFormat:@" %@ '%@' ", str, self[APPSPEC_KEY_INTERPRETER]];
    
    
    // finally, generate the command
    NSString *commandStr = [NSString stringWithFormat:
                            @"%@ %@%@%@%@%@%@ %@%@%@%@%@%@%@%@%@%@ '%@'",
                            CMDLINE_TOOL_PATH,
                            checkboxParamStr,
                            iconParamStr,
                            appNameArg,
                            outputArg,
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
                            textOutputString,
                            statusMenuOptionsString,
                            self[APPSPEC_KEY_SCRIPT_PATH],
                            nil];
    
    return commandStr;
}

#pragma mark - Class Methods

/*******************************************************************
 - Return the bundle identifier for the application to be generated
 - based on username etc. e.g. org.username.AppName
 ******************************************************************/

+ (NSString *)bundleIdentifierForAppName:(NSString *)appName authorName:(NSString *)authorName usingDefaults:(BOOL)def {
    
    NSString *defaults = def ? [DEFAULTS stringForKey:@"DefaultBundleIdentifierPrefix"] : nil;
    NSString *author = authorName ? [authorName stringByReplacingOccurrencesOfString:@" " withString:@""] : NSUserName();
    NSString *pre = defaults == nil ? [NSString stringWithFormat:@"org.%@.", author] : defaults;
    NSString *identifierString = [NSString stringWithFormat:@"%@%@", pre, appName];
    identifierString = [identifierString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
//    NSData *asciiData = [identifierString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//    identifierString = [[NSString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding];

    return identifierString;
}

+ (void)optimizeNibFile:(NSString *)nibPath {
    NSTask *ibToolTask = [[NSTask alloc] init];
    [ibToolTask setLaunchPath:IBTOOL_PATH];
    [ibToolTask setArguments:@[@"--strip", nibPath, nibPath]];
    [ibToolTask launch];
    [ibToolTask waitUntilExit];
#if !__has_feature(objc_arc)
    [ibToolTask release];
#endif
}

@end
