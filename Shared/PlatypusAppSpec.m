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
@end

@implementation PlatypusAppSpec

#pragma mark - Creation

- (PlatypusAppSpec *)init {
    if (self = [super init]) {
        properties = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [properties release];
    [super dealloc];
}

- (PlatypusAppSpec *)initWithDefaults {
    if (self = [self init]) {
        [self setDefaults];
    }
    return self;
}

- (PlatypusAppSpec *)initWithDefaultsFromScript:(NSString *)scriptPath {
    if (self = [self initWithDefaults]) {
        [self setDefaultsForScript:scriptPath];
    }
    return self;
}

- (PlatypusAppSpec *)initWithDictionary:(NSDictionary *)dict {
    if (self = [self init]) {
        [self setDefaults];
        [properties addEntriesFromDictionary:dict];
    }
    return self;
}

- (PlatypusAppSpec *)initWithProfile:(NSString *)profilePath {
    return [self initWithDictionary:[NSMutableDictionary dictionaryWithContentsOfFile:profilePath]];
}

+ (PlatypusAppSpec *)specWithDefaults {
    return [[[PlatypusAppSpec alloc] initWithDefaults] autorelease];
}

+ (PlatypusAppSpec *)specWithDictionary:(NSDictionary *)dict {
    return [[[PlatypusAppSpec alloc] initWithDictionary:dict] autorelease];
}

+ (PlatypusAppSpec *)specWithProfile:(NSString *)profilePath {
    return [[[PlatypusAppSpec alloc] initWithProfile:profilePath] autorelease];
}

+ (PlatypusAppSpec *)specWithDefaultsFromScript:(NSString *)scriptPath {
    return [[[PlatypusAppSpec alloc] initWithDefaultsFromScript:scriptPath] autorelease];
}

#pragma mark - Set default values

/**********************************
 init a spec with default values for everything
 **********************************/

- (void)setDefaults {
    // stamp the spec with the creator
    properties[@"Creator"] = PROGRAM_STAMP;
    
    //prior properties
    properties[@"ExecutablePath"] = CMDLINE_EXEC_PATH;
    properties[@"NibPath"] = CMDLINE_NIB_PATH;
    properties[@"Destination"] = DEFAULT_DESTINATION_PATH;
    
    [properties setValue:@NO forKey:@"DestinationOverride"];
    [properties setValue:@NO forKey:@"DevelopmentVersion"];
    [properties setValue:@YES forKey:@"OptimizeApplication"];
    [properties setValue:@NO forKey:@"UseXMLPlistFormat"];
    
    // primary attributes
    properties[@"Name"] = DEFAULT_APP_NAME;
    properties[@"ScriptPath"] = @"";
    properties[@"Output"] = DEFAULT_OUTPUT_TYPE;
    properties[@"IconPath"] = CMDLINE_ICON_PATH;
    
    // secondary attributes
    properties[@"Interpreter"] = DEFAULT_INTERPRETER;
    properties[@"InterpreterArgs"] = [NSMutableArray array];
    properties[@"ScriptArgs"] = [NSMutableArray array];
    properties[@"Version"] = DEFAULT_VERSION;
    properties[@"Identifier"] = [PlatypusAppSpec standardBundleIdForAppName:DEFAULT_APP_NAME authorName:nil usingDefaults:YES];
    properties[@"Author"] = NSFullUserName();
    
    [properties setValue:@NO forKey:@"Droppable"];
    [properties setValue:@NO forKey:@"Secure"];
    [properties setValue:@NO forKey:@"Authentication"];
    [properties setValue:@YES forKey:@"RemainRunning"];
    [properties setValue:@NO forKey:@"ShowInDock"];
    
    // bundled files
    properties[@"BundledFiles"] = [NSMutableArray array];
    
    // file/drag acceptance properties
    properties[@"Suffixes"] = [NSMutableArray arrayWithObject:@"*"];
    properties[@"UniformTypes"] = [NSMutableArray array];
    properties[@"Role"] = DEFAULT_ROLE;
    properties[@"AcceptsText"] = @NO;
    properties[@"AcceptsFiles"] = @YES;
    properties[@"DeclareService"] = @NO;
    properties[@"PromptForFileOnLaunch"] = @NO;
    properties[@"DocIcon"] = @"";
    
    // text output settings
    properties[@"TextEncoding"] = @(DEFAULT_OUTPUT_TXT_ENCODING);
    properties[@"TextFont"] = DEFAULT_OUTPUT_FONT;
    properties[@"TextSize"] = @(DEFAULT_OUTPUT_FONTSIZE);
    properties[@"TextForeground"] = DEFAULT_OUTPUT_FG_COLOR;
    properties[@"TextBackground"] = DEFAULT_OUTPUT_BG_COLOR;
    
    // status item settings
    properties[@"StatusItemDisplayType"] = DEFAULT_STATUSITEM_DTYPE;
    properties[@"StatusItemTitle"] = DEFAULT_APP_NAME;
    properties[@"StatusItemIcon"] = [NSData data];
    properties[@"StatusItemUseSystemFont"] = @YES;
}

/********************************************************
 inits with default values and then analyse script,
 load default values based on analysed script properties
 ********************************************************/

- (void)setDefaultsForScript:(NSString *)scriptPath {
    // start with a dict populated with defaults
    [self setDefaults];
    
    // set script path
    [self setProperty:scriptPath forKey:@"ScriptPath"];
    
    //determine app name based on script filename
    NSString *appName = [ScriptAnalyser appNameFromScriptFilePath:scriptPath];
    [self setProperty:appName forKey:@"Name"];
    
    //find an interpreter for it
    NSString *interpreter = [ScriptAnalyser determineInterpreterForScriptFile:scriptPath];
    if (interpreter == nil) {
        interpreter = DEFAULT_INTERPRETER;
    } else {
        // get parameters to interpreter
        NSMutableArray *shebangCmdComponents = [NSMutableArray arrayWithArray:[ScriptAnalyser parseInterpreterFromShebang:scriptPath]];
        [shebangCmdComponents removeObjectAtIndex:0];
        [self setProperty:shebangCmdComponents forKey:@"InterpreterArgs"];
    }
    [self setProperty:interpreter forKey:@"Interpreter"];
    
    // find parent folder wherefrom we create destination path of app bundle
    NSString *parentFolder = [scriptPath stringByDeletingLastPathComponent];
    NSString *destPath = [NSString stringWithFormat:@"%@/%@.app", parentFolder, appName];
    [self setProperty:destPath forKey:@"Destination"];
    [self setProperty:[PlatypusAppSpec standardBundleIdForAppName:appName authorName:nil usingDefaults:YES] forKey:@"Identifier"];
}

#pragma mark -

/****************************************
 This function creates the Platypus app
 based on the data contained in the spec.
 ****************************************/

- (BOOL)create {
    NSString *contentsPath, *macosPath, *resourcesPath;
    NSString *execDestinationPath, *infoPlistPath, *iconPath, *docIconPath, *nibDestPath;
    NSString *execPath, *nibPath;
    NSData *b_enc_script = [NSData data];
    
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
    
    //check if app already exists
    if ([FILEMGR fileExistsAtPath:properties[@"Destination"]]) {
        if ([properties[@"DestinationOverride"] boolValue] == FALSE) {
            _error = [NSString stringWithFormat:@"App already exists at path %@. Use -y flag to overwrite.", properties[@"Destination"]];
            return FALSE;
        } else {
            [self report:[NSString stringWithFormat:@"Overwriting app at path %@", properties[@"Destination"]]];
        }
    }
    
    // check if executable exists
    execPath = properties[@"ExecutablePath"];
    if (![FILEMGR fileExistsAtPath:execPath] || ![FILEMGR isReadableFileAtPath:execPath]) {
        [self report:[NSString stringWithFormat:@"Executable %@ does not exist. Aborting.", execPath, nil]];
        return NO;
    }
    
    // check if source nib exists
    nibPath = properties[@"NibPath"];
    if (![FILEMGR fileExistsAtPath:nibPath] || ![FILEMGR isReadableFileAtPath:nibPath]) {
        [self report:[NSString stringWithFormat:@"Nib file %@ does not exist. Aborting.", nibPath, nil]];
        return NO;
    }
    
    ////////////////////////// CREATE THE FOLDER HIERARCHY //////////////////////////
    
    // we begin by creating the application bundle at temp path
    [self report:@"Creating application bundle folder hierarchy"];
    
    //Application.app bundle
    tmpPath = [tmpPath stringByAppendingString:[properties[@"Destination"] lastPathComponent]];
    [FILEMGR createDirectoryAtPath:tmpPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    //.app/Contents
    contentsPath = [tmpPath stringByAppendingString:@"/Contents"];
    [FILEMGR createDirectoryAtPath:contentsPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    //.app/Contents/MacOS
    macosPath = [contentsPath stringByAppendingString:@"/MacOS"];
    [FILEMGR createDirectoryAtPath:macosPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    //.app/Contents/Resources
    resourcesPath = [contentsPath stringByAppendingString:@"/Resources"];
    [FILEMGR createDirectoryAtPath:resourcesPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    ////////////////////////// COPY FILES TO THE APP BUNDLE //////////////////////////////////
    
    [self report:@"Copying executable to bundle"];
    
    //copy exec file
    //.app/Contents/Resources/MacOS/ScriptExec
    execDestinationPath = [macosPath stringByAppendingString:@"/"];
    execDestinationPath = [execDestinationPath stringByAppendingString:properties[@"Name"]];
    [FILEMGR copyItemAtPath:execPath toPath:execDestinationPath error:nil];
    NSDictionary *execAttrDict = @{NSFilePosixPermissions: @0755UL};
    [FILEMGR setAttributes:execAttrDict ofItemAtPath:execDestinationPath error:nil];

    //copy nib file to app bundle
    //.app/Contents/Resources/MainMenu.nib
    [self report:@"Copying nib file to bundle"];
    nibDestPath = [resourcesPath stringByAppendingString:@"/MainMenu.nib"];
    [FILEMGR copyItemAtPath:nibPath toPath:nibDestPath error:nil];

    if ([properties[@"OptimizeApplication"] boolValue] == YES && [FILEMGR fileExistsAtPath:IBTOOL_PATH]) {
        [self report:@"Optimizing nib file"];
        [PlatypusAppSpec optimizeNibFile:nibDestPath];
    }
    
    // create script file in app bundle
    //.app/Contents/Resources/script
    [self report:@"Copying script"];
    
    if ([properties[@"Secure"] boolValue]) {
        NSString *path = properties[@"ScriptPath"];
        b_enc_script = [NSData dataWithContentsOfFile:path];
    } else {
        NSString *scriptFilePath = [resourcesPath stringByAppendingString:@"/script"];
        // make a symbolic link instead of copying script if this is a dev version
        if ([properties[@"DevelopmentVersion"] boolValue] == YES) {
            [FILEMGR createSymbolicLinkAtPath:scriptFilePath withDestinationPath:properties[@"ScriptPath"] error:nil];
        } else { // copy script over
            [FILEMGR copyItemAtPath:properties[@"ScriptPath"] toPath:scriptFilePath error:nil];
        }
        NSDictionary *fileAttrDict = @{NSFilePosixPermissions: @0755UL};
        [FILEMGR setAttributes:fileAttrDict ofItemAtPath:scriptFilePath error:nil];
    }
    
    //create AppSettings.plist file
    //.app/Contents/Resources/AppSettings.plist
    [self report:@"Creating AppSettings property list"];
    NSMutableDictionary *appSettingsPlist = [self appSettingsPlist];
    if ([properties[@"Secure"] boolValue]) {
        // if script is "secured" we encode it into AppSettings property list
        appSettingsPlist[@"TextSettings"] = [NSKeyedArchiver archivedDataWithRootObject:b_enc_script];
    }
    NSString *appSettingsPlistPath = [resourcesPath stringByAppendingString:@"/AppSettings.plist"];
    if ([properties[@"UseXMLPlistFormat"] boolValue] == FALSE) {
        NSData *binPlistData = [NSPropertyListSerialization dataFromPropertyList:appSettingsPlist
                                                                          format:NSPropertyListBinaryFormat_v1_0
                                                                errorDescription:nil];
        [binPlistData writeToFile:appSettingsPlistPath atomically:YES];
    } else {
        [appSettingsPlist writeToFile:appSettingsPlistPath atomically:YES];
    }
    
    //create icon
    //.app/Contents/Resources/appIcon.icns
    if (properties[@"IconPath"] && ![properties[@"IconPath"] isEqualToString:@""]) {
        [self report:@"Writing application icon"];
        iconPath = [resourcesPath stringByAppendingString:@"/appIcon.icns"];
        [FILEMGR copyItemAtPath:properties[@"IconPath"] toPath:iconPath error:nil];
    }
    
    //document icon
    //.app/Contents/Resources/docIcon.icns
    if (properties[@"DocIcon"] && ![properties[@"DocIcon"] isEqualToString:@""]) {
        [self report:@"Writing document icon"];
        docIconPath = [resourcesPath stringByAppendingString:@"/docIcon.icns"];
        [FILEMGR copyItemAtPath:properties[@"DocIcon"] toPath:docIconPath error:nil];
    }
    
    //create Info.plist file
    //.app/Contents/Info.plist
    [self report:@"Writing Info.plist"];
    NSDictionary *infoPlist = [self infoPlist];
    infoPlistPath = [contentsPath stringByAppendingString:@"/Info.plist"];
    if (![properties[@"UseXMLPlistFormat"] boolValue]) { // if binary
        NSData *binPlistData = [NSPropertyListSerialization dataFromPropertyList:infoPlist
                                                                          format:NSPropertyListBinaryFormat_v1_0
                                                                errorDescription:nil];
        [binPlistData writeToFile:infoPlistPath atomically:YES];
    }
    else {
        [infoPlist writeToFile:infoPlistPath atomically:YES];
    }
    
    //copy bundled files to Resources folder
    //.app/Contents/Resources/*
    [self report:@"Copying bundled files"];
    
    for (NSString *bundledFilePath in properties[@"BundledFiles"]) {
        NSString *fileName = [bundledFilePath lastPathComponent];
        NSString *bundledFileDestPath = [resourcesPath stringByAppendingString:@"/"];
        bundledFileDestPath = [bundledFileDestPath stringByAppendingString:fileName];
        
        [self report:[NSString stringWithFormat:@"Copying \"%@\" to bundle", fileName]];
        
        // if it's a development version, we just symlink it
        if ([properties[@"DevelopmentVersion"] boolValue] == YES) {
            [FILEMGR createSymbolicLinkAtPath:bundledFileDestPath withDestinationPath:bundledFilePath error:nil];
        } else {
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
    [self report:@"Moving app to destination directory"];
    
    NSString *destPath = properties[@"Destination"];
    
    // first, let's see if there's anything there.  If we have override set on, we just delete that stuff.
    if ([FILEMGR fileExistsAtPath:destPath] && [properties[@"DestinationOverride"] boolValue]) {
        [FILEMGR removeItemAtPath:destPath error:nil];
        [WORKSPACE notifyFinderFileChangedAtPath:destPath];
    }
    
    //if delete wasn't a success and there's still something there
    if ([FILEMGR fileExistsAtPath:destPath]) {
        _error = @"Could not remove pre-existing item at destination path";
        return FALSE;
    }
    
    // now, move the newly created app to the destination
    [FILEMGR moveItemAtPath:tmpPath toPath:destPath error:nil];    //move
    if (![FILEMGR fileExistsAtPath:destPath]) {
        //if move wasn't a success, clean up app in tmp dir
        [FILEMGR removeItemAtPath:tmpPath error:nil];
        _error = @"Failed to create application at the specified destination";
        return FALSE;
    }
    [WORKSPACE notifyFinderFileChangedAtPath:destPath];
    
    // Update Services
    if ([properties[@"DeclareService"] boolValue]) {
        [self report:@"Updating Dynamic Services"];
        // This call will refresh Services without user having to log out/in
        NSUpdateDynamicServices();
    }
    
    [self report:@"Done"];
    
    return TRUE;
}

// Generate AppSettings.plist dictionary
- (NSMutableDictionary *)appSettingsPlist {
    NSMutableDictionary *appSettingsPlist = [NSMutableDictionary dictionary];
    appSettingsPlist[@"RequiresAdminPrivileges"] = properties[@"Authentication"];
    appSettingsPlist[@"Droppable"] = properties[@"Droppable"];
    appSettingsPlist[@"RemainRunningAfterCompletion"] = properties[@"RemainRunning"];
    appSettingsPlist[@"Secure"] = properties[@"Secure"];
    appSettingsPlist[@"OutputType"] = properties[@"Output"];
    appSettingsPlist[@"ScriptInterpreter"] = properties[@"Interpreter"];
    appSettingsPlist[@"Creator"] = PROGRAM_STAMP;
    appSettingsPlist[@"InterpreterArgs"] = properties[@"InterpreterArgs"];
    appSettingsPlist[@"ScriptArgs"] = properties[@"ScriptArgs"];
    appSettingsPlist[@"PromptForFileOnLaunch"] = properties[@"PromptForFileOnLaunch"];
    
    // we need only set text settings for the output types that use this information
    if ([properties[@"Output"] isEqualToString:@"Progress Bar"] ||
        [properties[@"Output"] isEqualToString:@"Text Window"] ||
        [properties[@"Output"] isEqualToString:@"Status Menu"]) {
        appSettingsPlist[@"TextFont"] = properties[@"TextFont"];
        appSettingsPlist[@"TextSize"] = properties[@"TextSize"];
        appSettingsPlist[@"TextForeground"] = properties[@"TextForeground"];
        appSettingsPlist[@"TextBackground"] = properties[@"TextBackground"];
        appSettingsPlist[@"TextEncoding"] = properties[@"TextEncoding"];
    }
    
    // likewise, status menu settings are only written if that is the output type
    if ([properties[@"Output"] isEqualToString:@"Status Menu"] == YES) {
        appSettingsPlist[@"StatusItemDisplayType"] = properties[@"StatusItemDisplayType"];
        appSettingsPlist[@"StatusItemTitle"] = properties[@"StatusItemTitle"];
        appSettingsPlist[@"StatusItemIcon"] = properties[@"StatusItemIcon"];
        appSettingsPlist[@"StatusItemUseSystemFont"] = properties[@"StatusItemUseSystemFont"];
    }
    
    // we  set the suffixes/file types in the AppSettings.plist if app is droppable
    if ([properties[@"Droppable"] boolValue] == YES) {
        appSettingsPlist[@"DropSuffixes"] = properties[@"Suffixes"];
        appSettingsPlist[@"DropUniformTypes"] = properties[@"UniformTypes"];
    }
    appSettingsPlist[@"AcceptsFiles"] = properties[@"AcceptsFiles"];
    appSettingsPlist[@"AcceptsText"] = properties[@"AcceptsText"];
    
    return appSettingsPlist;
}

// Generate Info.plist dictionary
- (NSDictionary *)infoPlist {

    NSString *humanCopyright = [NSString stringWithFormat:@"© %d %@",
                                (int)[[NSCalendarDate calendarDate] yearOfCommonEra],
                                properties[@"Author"]];
    
    NSMutableDictionary *infoPlist = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      
          @"en",                                    @"CFBundleDevelopmentRegion",
          properties[@"Name"],                      @"CFBundleExecutable",
          properties[@"Name"],                      @"CFBundleName",
          properties[@"Name"],                      @"CFBundleDisplayName",
          humanCopyright,                           @"NSHumanReadableCopyright",
          properties[@"Version"],                   @"CFBundleVersion",
          properties[@"Version"],                   @"CFBundleShortVersionString",
          properties[@"Identifier"],                @"CFBundleIdentifier",
          properties[@"ShowInDock"],                @"LSUIElement",
          @"6.0",                                   @"CFBundleInfoDictionaryVersion",
          @"APPL",                                  @"CFBundlePackageType",
          @"MainMenu",                              @"NSMainNibFile",
          PROGRAM_MIN_SYS_VERSION,                  @"LSMinimumSystemVersion",
          @"NSApplication",                         @"NSPrincipalClass",
          @{@"NSAllowsArbitraryLoads": @YES},       @"NSAppTransportSecurity",
                                      
                                                    nil];
    
    if (properties[@"IconPath"] && [properties[@"IconPath"] isEqualToString:@""] == NO) {
        infoPlist[@"CFBundleIconFile"] = @"appIcon.icns";
    }
    
    // if droppable, we declare the accepted file types
    if ([properties[@"Droppable"] boolValue] == YES) {
        
        NSMutableDictionary *typesAndSuffixesDict = [NSMutableDictionary dictionary];
        
        typesAndSuffixesDict[@"CFBundleTypeExtensions"] = properties[@"Suffixes"];
        
        if (properties[@"UniformTypes"] != nil && [properties[@"UniformTypes"] count] > 0) {
            typesAndSuffixesDict[@"LSItemContentTypes"] = properties[@"UniformTypes"];
        }
        
        // document icon
        if (properties[@"DocIcon"] && [FILEMGR fileExistsAtPath:properties[@"DocIcon"]])
            typesAndSuffixesDict[@"CFBundleTypeIconFile"] = @"docIcon.icns";
        
        // set file types and suffixes
        infoPlist[@"CFBundleDocumentTypes"] = @[typesAndSuffixesDict];
        
        // add service settings to Info.plist
        if ([properties[@"DeclareService"] boolValue]) {
            // service data type handling
            NSMutableArray *sendTypes = [NSMutableArray arrayWithCapacity:2];
            if ([properties[@"AcceptsFiles"] boolValue])
                [sendTypes addObject:@"NSFilenamesPboardType"];
            if ([properties[@"AcceptsText"] boolValue])
                [sendTypes addObject:@"NSStringPboardType"];
            
            NSString *appName = properties[@"Name"];
            NSMutableDictionary *serviceDict = [NSMutableDictionary dictionaryWithCapacity:10];
            NSDictionary *menuItemDict = @{@"default": [NSString stringWithFormat:@"Process with %@", appName]};
            
            serviceDict[@"NSMenuItem"] = menuItemDict;
            serviceDict[@"NSMessage"] = @"dropService";
            serviceDict[@"NSPortName"] = appName;
            serviceDict[@"NSSendTypes"] = sendTypes;
            infoPlist[@"NSServices"] = @[serviceDict];
        }
    }
    return infoPlist;
}

- (void)report:(NSString *)str {
    fprintf(stderr, "%s\n", [str UTF8String]);
    [[NSNotificationCenter defaultCenter] postNotificationName:PLATYPUS_APP_SPEC_CREATED_NOTIFICATION object:str];
}

/****************************************
 Make sure the data in the spec is sane
 ****************************************/

- (BOOL)verify {
    BOOL isDir;
    
    if (![properties[@"Destination"] hasSuffix:@"app"]) {
        _error = @"Destination must end with .app";
        return NO;
    }
    
    // warn if font can't be instantiated
    if ([NSFont fontWithName:[self propertyForKey:@"TextFont"] size:13] == nil) {
        NSLog(@"Warning: Font \"%@\" cannot be instantiated.", [self propertyForKey:@"TextFont"]);
    }
    
    if ([properties[@"Name"] isEqualToString:@""]) {
        _error = @"Empty app name";
        return NO;
    }
    
    if (![FILEMGR fileExistsAtPath:properties[@"ScriptPath"] isDirectory:&isDir] || isDir) {
        _error = [NSString stringWithFormat:@"Script not found at path '%@'", properties[@"ScriptPath"], nil];
        return NO;
    }
    
    if (![FILEMGR fileExistsAtPath:properties[@"NibPath"] isDirectory:&isDir]) {
        _error = [NSString stringWithFormat:@"Nib not found at path '%@'", properties[@"NibPath"], nil];
        return NO;
    }
    
    if (![FILEMGR fileExistsAtPath:properties[@"ExecutablePath"] isDirectory:&isDir] || isDir) {
        _error = [NSString stringWithFormat:@"Executable not found at path '%@'", properties[@"ExecutablePath"], nil];
        return NO;
    }
    
    //make sure destination directory exists
    if (![FILEMGR fileExistsAtPath:[properties[@"Destination"] stringByDeletingLastPathComponent] isDirectory:&isDir] || !isDir) {
        _error = [NSString stringWithFormat:@"Destination directory '%@' does not exist.", [properties[@"Destination"] stringByDeletingLastPathComponent], nil];
        return NO;
    }
    
    //make sure we have write privileges for the destination directory
    if (![FILEMGR isWritableFileAtPath:[properties[@"Destination"] stringByDeletingLastPathComponent]]) {
        _error = [NSString stringWithFormat:@"Don't have permission to write to the destination directory '%@'", properties[@"Destination"]];
        return NO;
    }
    
    return YES;
}

#pragma mark -

- (void)writeToFile:(NSString *)filePath {
    [properties writeToFile:filePath atomically:YES];
}

- (void)dump {
    fprintf(stdout, "%s\n", [[properties description] UTF8String]);
}

- (NSString *)description {
    return [properties description];
}

#pragma mark - Command string generation

- (NSString *)commandString:(BOOL)shortOpts {
    BOOL longOpts = !shortOpts;
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
    if ([properties[@"Authentication"] boolValue]) {
        NSString *str = longOpts ? @"-A " : @"--admin-privileges ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([properties[@"Secure"] boolValue]) {
        NSString *str = longOpts ? @"-S " : @"--secure-script ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([properties[@"AcceptsFiles"] boolValue] && [properties[@"Droppable"] boolValue]) {
        NSString *str = longOpts ? @"-D " : @"--droppable ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([properties[@"AcceptsText"] boolValue] && [properties[@"Droppable"] boolValue]) {
        NSString *str = longOpts ? @"-F " : @"--text-droppable ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([properties[@"DeclareService"] boolValue] && [properties[@"Droppable"] boolValue]) {
        NSString *str = longOpts ? @"-N " : @"--service ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([properties[@"ShowInDock"] boolValue]) {
        NSString *str = longOpts ? @"-B " : @"--background ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([properties[@"RemainRunning"] boolValue] == FALSE) {
        NSString *str = longOpts ? @"-R " : @"--quit-after-execution ";
        checkboxParamStr = [checkboxParamStr stringByAppendingString:str];
    }
    
    if ([properties[@"Version"] isEqualToString:@"1.0"] == FALSE) {
        NSString *str = longOpts ? @"-V" : @"--app-version";
        versionString = [NSString stringWithFormat:@" %@ '%@' ", str, properties[@"Version"]];
    }
    
    if (![properties[@"Author"] isEqualToString:NSFullUserName()]) {
        NSString *str = longOpts ? @"-u" : @"--author";
        authorString = [NSString stringWithFormat:@" %@ '%@' ", str, properties[@"Author"]];
    }
    
    NSString *promptForFileString = @"";
    if ([properties[@"Droppable"] boolValue]) {
        //  suffixes param
        if ([properties[@"Suffixes"] count]) {
            NSString *str = longOpts ? @"-X" : @"--suffixes";
            suffixesString = [properties[@"Suffixes"] componentsJoinedByString:@"|"];
            suffixesString = [NSString stringWithFormat:@"%@ '%@' ", str, suffixesString];
        }
        // uniform type identifier params
        if ([properties[@"UniformTypes"] count]) {
            uniformTypesString = [properties[@"UniformTypes"] componentsJoinedByString:@"|"];
            uniformTypesString = [NSString stringWithFormat:@"-T '%@' ", uniformTypesString];
        }
        // file prompt
        if ([properties[@"PromptForFileOnLaunch"] boolValue]) {
            NSString *str = longOpts ? @"-Z" : @"--file-prompt";
            promptForFileString = [NSString stringWithFormat:@"%@ ", str];
        }
    }
    
    //create bundled files string
    NSString *bundledFilesCmdString = @"";
    NSArray *bundledFiles = (NSArray *)properties[@"BundledFiles"];
    for (int i = 0; i < [bundledFiles count]; i++) {
        NSString *str = longOpts ? @"-f" : @"--bundled-file";
        bundledFilesCmdString = [bundledFilesCmdString stringByAppendingString:[NSString stringWithFormat:@"%@ '%@' ", str, bundledFiles[i]]];
    }
    
    // create interpreter and script args flags
    if ([(NSArray *)properties[@"InterpreterArgs"] count]) {
        NSString *str = longOpts ? @"-G" : @"--interpreter-args";
        NSString *arg = [properties[@"InterpreterArgs"] componentsJoinedByString:@"|"];
        parametersString = [parametersString stringByAppendingString:[NSString stringWithFormat:@"%@ '%@' ", str, arg]];
    }
    if ([(NSArray *)properties[@"ScriptArgs"] count]) {
        NSString *str = longOpts ? @"-C" : @"--script-args";
        NSString *arg = [properties[@"ScriptArgs"] componentsJoinedByString:@"|"];
        parametersString = [parametersString stringByAppendingString:[NSString stringWithFormat:@"%@ '%@' ", str, arg]];
    }
    
    //  create args for text settings if progress bar/text window or status menu
    if (([properties[@"Output"] isEqualToString:@"Text Window"] ||
         [properties[@"Output"] isEqualToString:@"Progress Bar"] ||
         [properties[@"Output"] isEqualToString:@"Status Menu"])) {
        
        NSString *textFgString = @"", *textBgString = @"", *textFontString = @"";
        if (![properties[@"TextForeground"] isEqualToString:DEFAULT_OUTPUT_FG_COLOR]) {
            NSString *str = longOpts ? @"-g" : @"--text-foreground-color";
            textFgString = [NSString stringWithFormat:@" %@ '%@' ", str, properties[@"TextForeground"]];
        }
        
        if (![properties[@"TextBackground"] isEqualToString:DEFAULT_OUTPUT_BG_COLOR]) {
            NSString *str = longOpts ? @"-b" : @"--text-background-color";
            textBgString = [NSString stringWithFormat:@" %@ '%@' ", str, properties[@"TextForeground"]];
        }
        
        if ([properties[@"TextSize"] floatValue] != DEFAULT_OUTPUT_FONTSIZE ||
            ![properties[@"TextFont"] isEqualToString:DEFAULT_OUTPUT_FONT]) {
            NSString *str = longOpts ? @"-n" : @"--text-font";
            textFontString = [NSString stringWithFormat:@" %@ '%@ %2.f' ", str, properties[@"TextFont"], [properties[@"TextSize"] floatValue]];
        }
        
        textOutputString = [NSString stringWithFormat:@"%@%@%@", textFgString, textBgString, textFontString];
    }
    
    //text encoding
    if ([properties[@"TextEncoding"] intValue] != DEFAULT_OUTPUT_TXT_ENCODING) {
        NSString *str = longOpts ? @"-E" : @"--text-encoding";
        textEncodingString = [NSString stringWithFormat:@" %@ %d ", str, [properties[@"TextEncoding"] intValue]];
    }
    
    //create custom icon string
    if (![properties[@"IconPath"] isEqualToString:CMDLINE_ICON_PATH] && ![properties[@"IconPath"] isEqualToString:@""]) {
        NSString *str = longOpts ? @"-i" : @"--app-icon";
        iconParamStr = [NSString stringWithFormat:@"%@ '%@' ", str, properties[@"IconPath"]];
    }
    
    //create custom icon string
    if (properties[@"DocIcon"] && ![properties[@"DocIcon"] isEqualToString:@""]) {
        NSString *str = longOpts ? @"-Q" : @"--document-icon";
        iconParamStr = [iconParamStr stringByAppendingFormat:@" %@ '%@' ", str, properties[@"DocIcon"]];
    }
    
    //status menu settings, if output mode is status menu
    if ([properties[@"Output"] isEqualToString:@"Status Menu"]) {
        // -K kind
        NSString *str = longOpts ? @"-K" : @"--status-item-kind";
        statusMenuOptionsString = [statusMenuOptionsString stringByAppendingFormat:@"%@ '%@' ", str, properties[@"StatusItemDisplayType"]];
        
        // -L /path/to/image
        if (![properties[@"StatusItemDisplayType"] isEqualToString:@"Text"]) {
            str = longOpts ? @"-L" : @"--status-item-icon";
            statusMenuOptionsString = [statusMenuOptionsString stringByAppendingFormat:@"%@ '/path/to/image' ", str];
        }
        
        // -Y 'Title'
        if (![properties[@"StatusItemDisplayType"] isEqualToString:@"Icon"]) {
            str = longOpts ? @"-Y" : @"--status-item-title";
            statusMenuOptionsString = [statusMenuOptionsString stringByAppendingFormat:@"%@ '%@' ", str, properties[@"StatusItemTitle"]];
        }
        
        // -c
        if (![properties[@"StatusItemUseSystemFont"] boolValue]) {
            str = longOpts ? @"-c" : @"--status-item-sysfont";
            statusMenuOptionsString = [statusMenuOptionsString stringByAppendingFormat:@"%@ ", str];
        }
    }
    
    // only set app name arg if we have a proper value
    NSString *appNameArg = @"";
    if ([properties[@"Name"] isEqualToString:@""] == FALSE) {
        NSString *str = longOpts ? @"-a" : @"--name";
        appNameArg = [NSString stringWithFormat: @" %@ '%@' ", str,  properties[@"Name"]];
    }
    
    // only add identifier argument if it varies from default
    NSString *identifierArg = @"";
    NSString *standardIdentifier = [PlatypusAppSpec standardBundleIdForAppName:properties[@"Name"] authorName:nil usingDefaults: NO];
    if ([properties[@"Identifier"] isEqualToString:standardIdentifier] == FALSE) {
        NSString *str = longOpts ? @"-I" : @"--bundle-identifier";
        identifierArg = [NSString stringWithFormat: @" %@ %@ ", str, properties[@"Identifier"]];
    }
    
    // output type
    NSString *str = longOpts ? @"-o" : @"--output-type";
    NSString *outputArg = [NSString stringWithFormat:@" %@ '%@' ", str, properties[@"Output"]];

    // interpreter
    str = longOpts ? @"-p" : @"--interpreter";
    NSString *interpreterArg = [NSString stringWithFormat:@" %@ '%@' ", str, properties[@"Interpreter"]];


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
                            properties[@"ScriptPath"],
                            nil];
    
    return commandStr;
}

#pragma mark - Get/Set Properties

- (void)setProperty:(id)property forKey:(NSString *)theKey {
    properties[theKey] = property;
}

- (id)propertyForKey:(NSString *)theKey {
    return properties[theKey];
}

- (void)addProperties:(NSDictionary *)dict {
    [properties addEntriesFromDictionary:dict];
}

- (NSDictionary *)properties {
    return properties;
}

#pragma mark - Class Methods

/*******************************************************************
 - Return the bundle identifier for the application to be generated
 - based on username etc. e.g. org.username.AppName
 ******************************************************************/

+ (NSString *)standardBundleIdForAppName:(NSString *)appName authorName:(NSString *)authorName usingDefaults:(BOOL)def {
    
    NSString *defaults = def ? [DEFAULTS stringForKey:@"DefaultBundleIdentifierPrefix"] : nil;
    NSString *author = authorName ? [authorName stringByReplacingOccurrencesOfString:@" " withString:@""] : NSUserName();
    NSString *pre = defaults == nil ? [NSString stringWithFormat:@"org.%@.", author] : defaults;
    NSString *bundleId = [NSString stringWithFormat:@"%@%@", pre, appName];
    bundleId = [bundleId stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    return bundleId;
}

+ (void)optimizeNibFile:(NSString *)nibPath {
    NSTask *ibToolTask = [[NSTask alloc] init];
    [ibToolTask setLaunchPath:IBTOOL_PATH];
    [ibToolTask setArguments:@[@"--strip", nibPath, nibPath]];
    [ibToolTask launch];
    [ibToolTask waitUntilExit];
    [ibToolTask release];
}

@end
