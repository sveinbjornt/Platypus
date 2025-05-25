/*
    Copyright (c) 2003-2025, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
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

@import Cocoa;

#import <stdio.h>
#import <unistd.h>
#import <stdlib.h>
#import <errno.h>
#import <sys/stat.h>
#import <limits.h>
#import <string.h>
#import <fcntl.h>
#import <errno.h>
#import <getopt.h>
#import <mach-o/getsect.h>

#import "Common.h"
#import "PlatypusAppSpec.h"
#import "NSFileManager+TempFiles.h"

static NSString *ReadStandardInputToFile(void);
static NSString *MakeAbsolutePath(NSString *path);
static NSArray *FindDuplicateFileNames(NSArray *paths);
static void PrintVersion(void);
static void PrintHelp(void);
static void NSPrintErr(NSString *format, ...);
static void NSPrint(NSString *format, ...);

static const char optstring[] = "P:f:a:o:i:u:p:V:I:Q:AOZDBWRFNydlvhxX:T:G:C:b:g:n:K:Y:L:cqU:";

static struct option long_options[] = {

    {"generate-profile",          no_argument,        0, 'O'},

    {"load-profile",              required_argument,  0, 'P'},
    {"name",                      required_argument,  0, 'a'},
    {"output-type",               required_argument,  0, 'o'}, // Backwards compatibility!
    {"interface-type",            required_argument,  0, 'o'},
    {"interpreter",               required_argument,  0, 'p'},

    {"app-icon",                  required_argument,  0, 'i'},
    {"author",                    required_argument,  0, 'u'},
    {"document-icon",             required_argument,  0, 'Q'},
    {"app-version",               required_argument,  0, 'V'},
    {"bundle-identifier",         required_argument,  0, 'I'},

    {"admin-privileges",          no_argument,        0, 'A'},
    {"droppable",                 no_argument,        0, 'D'},
    {"text-droppable",            no_argument,        0, 'F'},
    {"file-prompt",               no_argument,        0, 'Z'},
    {"service",                   no_argument,        0, 'N'},
    {"background",                no_argument,        0, 'B'},
    {"notifications",             no_argument,        0, 'W'},
    {"quit-after-execution",      no_argument,        0, 'R'},

    {"text-background-color",     required_argument,  0, 'b'},
    {"text-foreground-color",     required_argument,  0, 'g'},
    {"text-font",                 required_argument,  0, 'n'},
    {"suffixes",                  required_argument,  0, 'X'},
    {"uniform-type-identifiers",  required_argument,  0, 'T'},
    {"uri-schemes",               required_argument,  0, 'U'},
    {"interpreter-args",          required_argument,  0, 'G'},
    {"script-args",               required_argument,  0, 'C'},

    {"status-item-kind",          required_argument,  0, 'K'},
    {"status-item-title",         required_argument,  0, 'Y'},
    {"status-item-icon",          required_argument,  0, 'L'},
    {"status-item-sysfont",       no_argument,        0, 'c'},
    {"status-item-template-icon", no_argument,        0, 'q'},
    
    {"bundled-file",              required_argument,  0, 'f'},

    {"xml-property-lists",        no_argument,        0, 'x'}, // Deprecated
    {"overwrite",                 no_argument,        0, 'y'},
    {"force",                     no_argument,        0, 'y'}, // Backwards compatibility!
    {"symlink",                   no_argument,        0, 'd'},
    {"development-version",       no_argument,        0, 'd'}, // Backwards compatibility!
    {"optimize-nib",              no_argument,        0, 'l'},
    {"help",                      no_argument,        0, 'h'},
    {"version",                   no_argument,        0, 'v'},
    
    {0,                           0,                  0,  0 }
};

int main(int argc, const char *argv[]) {
    NSFileManager *fm = FILEMGR;
    NSWorkspace *ws = WORKSPACE;
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    
    BOOL createProfile = FALSE;
    BOOL loadedProfile = FALSE;
    BOOL deleteScript = FALSE;
    
    int optch;
    int long_index = 0;
    while ((optch = getopt_long(argc, (char *const *)argv, optstring, long_options, &long_index)) != -1) {
        switch (optch) {
            
            // Create a profile instead of an app
            case 'O':
            {
                createProfile = TRUE;
            }
                break;
            
            // Load profile
            case 'P':
            {
                NSString *profilePath = MakeAbsolutePath(@(optarg));
                
                // Error if profile doesn't exists, warn if w/o profile suffix
                if (![fm fileExistsAtPath:profilePath]) {
                    NSPrintErr(@"Error: No profile found at path '%@'.", profilePath);
                    exit(EXIT_FAILURE);
                }
                
                // Read profile dictionary from file
                NSDictionary *profileDict = [NSDictionary dictionaryWithContentsOfFile:profilePath];
                if (profileDict == nil) {
                    NSPrintErr(@"Error loading profile '%@'.", profilePath);
                    exit(EXIT_FAILURE);
                }
                
                // Warn if created by different version
                if (![profileDict[AppSpecKey_Creator] isEqualToString:PROGRAM_CREATOR_STAMP]) {
                    NSPrintErr(@"Warning: Profile created with different version of %@.", PROGRAM_NAME);
                }
                
                // Add entries in profile to app properties, overwriting any former values
                [properties addEntriesFromDictionary:profileDict];
                loadedProfile = TRUE;
            }
                break;
            
            // App name
            case 'a':
                properties[AppSpecKey_Name] = @(optarg);
                break;
            
            // Bundled file -- flag can be passed multiple times to include more than one bundled file
            // or alternately, multiple |-separated paths can be passed in a single argument
            case 'f':
            {
                NSString *argStr = @(optarg);
                NSArray <NSString *> *paths = [argStr componentsSeparatedByString:CMDLINE_ARG_SEPARATOR];
                
                for (NSString *filePath in paths) {
                    NSString *fp = MakeAbsolutePath(filePath);
                    
                    // Make sure file exists
                    if ([fm fileExistsAtPath:fp] == NO) {
                        NSPrintErr(@"Error: No file exists at path '%@'.", fp);
                        exit(EXIT_FAILURE);
                    }

                    // Add to bundled files array in spec
                    if (properties[AppSpecKey_BundledFiles] == nil) {
                        properties[AppSpecKey_BundledFiles] = [NSMutableArray array];
                    }
                    [properties[AppSpecKey_BundledFiles] addObject:fp];
                }
            }
                break;
            
            // Interface type
            case 'o':
            {
                NSString *interfaceType = @(optarg);
                if (IsValidInterfaceTypeString(interfaceType) == NO) {
                    NSPrintErr(@"Error: Invalid interface type '%@'. Valid types are: %@.",
                               interfaceType, [PLATYPUS_INTERFACE_TYPE_NAMES description]);
                    exit(EXIT_FAILURE);
                }
                properties[AppSpecKey_InterfaceType] = @(optarg);
            }
                break;
            
            // Background color of text
            case 'b':
            {
                NSString *hexColorStr = @(optarg);
                if ([hexColorStr length] != 7 || [hexColorStr characterAtIndex:0] != '#') {
                    NSPrintErr(@"Error: '%@' is not a valid color hex value. Should be hash-prefixed 6 digit hexadecimal, e.g. '#aabbcc'.", hexColorStr);
                    exit(EXIT_FAILURE);
                }
                properties[AppSpecKey_TextBackgroundColor] = @(optarg);
            }
                break;
            
            // Foreground color of text
            case 'g':
            {
                NSString *hexColorStr = @(optarg);
                if ([hexColorStr length] != 7 || [hexColorStr characterAtIndex:0] != '#') {
                    NSPrintErr(@"Error: '%@' is not a valid color hex value. Should be hash-prefixed 6 digit hexadecimal, e.g. '#aabbcc'.", hexColorStr);
                    exit(EXIT_FAILURE);
                }
                properties[AppSpecKey_TextColor] = @(optarg);
            }
                break;
            
            // Font and size of text
            case 'n':
            {
                NSString *fontStr = @(optarg);
                NSMutableArray *words = [[fontStr componentsSeparatedByString:@" "] mutableCopy];
                if ([words count] < 2) {
                    NSPrintErr(@"Error: '%@' is not a valid font. Must be font name followed by size, e.g. 'Monaco 10'.", fontStr);
                    exit(EXIT_FAILURE);
                }
                // Parse string for font name and size, and set it in properties
                float fontSize = [[words lastObject] floatValue];
                [words removeLastObject];
                NSString *fontName = [words componentsJoinedByString:@" "];
                properties[AppSpecKey_TextFont] = fontName;
                properties[AppSpecKey_TextSize] = @(fontSize);
            }
                break;
            
            // Author
            case 'u':
                properties[AppSpecKey_Author] = @(optarg);
                break;
            
            // Icon
            case 'i':
            {
                NSString *iconPath = @(optarg);
                
                // empty icon path means just default app icon, otherwise a path to an icns file
                if (iconPath && [iconPath isEqualTo:@""] == NO) {
                    iconPath = [MakeAbsolutePath(iconPath) stringByResolvingSymlinksInPath];
                    // if we have proper arg, make sure file exists
                    if ([fm fileExistsAtPath:iconPath] == NO) {
                        NSPrintErr(@"Error: No icon file exists at path '%@'", iconPath);
                        exit(EXIT_FAILURE);
                    }
                    
                    // warn if file doesn't seem to be icns
                    NSString *fileType = [ws typeOfFile:iconPath error:nil];
                    if ([ws type:fileType conformsToType:(NSString *)kUTTypeAppleICNS] == FALSE) {
                        NSPrintErr(@"Warning: '%@' does not appear to be an Apple .icns file.", iconPath);
                    }
                }
                properties[AppSpecKey_IconPath] = iconPath;
            }
                break;
            
            // Document icon
            case 'Q':
            {
                NSString *iconPath = @(optarg);
                
                // empty icon path means just default app icon, otherwise a path to an icns file
                if (![iconPath isEqualTo:@""]) {
                    iconPath = [MakeAbsolutePath(iconPath) stringByResolvingSymlinksInPath];
                    // if we have proper arg, make sure file exists
                    if (![fm fileExistsAtPath:iconPath]) {
                        NSPrintErr(@"Error: No icon file at path '%@'.", iconPath);
                        exit(EXIT_FAILURE);
                    }
                    
                    // warn if file doesn't seem to be icns
                    NSString *fileType = [ws typeOfFile:iconPath error:nil];
                    if ([ws type:fileType conformsToType:(NSString *)kUTTypeAppleICNS] == FALSE) {
                        NSPrintErr(@"Warning: '%@' is not an .icns file.", iconPath);
                    }
                }
                properties[AppSpecKey_DocIconPath] = iconPath;
            }
                break;
            
            // Interpreter
            case 'p':
            {
                NSString *path = @(optarg);
                BOOL relative = ![path hasPrefix:@"/"];
                if (!relative) {
                    path = MakeAbsolutePath(path);
                    if (![fm fileExistsAtPath:path]) {
                        NSPrintErr(@"Warning: Interpreter path '%@' invalid - no file at path.", path);
                    }
                }
                properties[AppSpecKey_InterpreterPath] = path;
            }
                break;
            
            // Version
            case 'V':
                properties[AppSpecKey_Version] = @(optarg);
                break;
            
            // Bundle identifier
            case 'I':
            {
                NSString *identifier = @(optarg);
                if (!BundleIdentifierIsValid(identifier)) {
                    NSPrintErr(@"Warning: '%@' is not a valid bundle identifier.", identifier);
                }
                properties[AppSpecKey_Identifier] = @(optarg);
            }
                break;
            
            // Run with root privileges
            case 'A':
                properties[AppSpecKey_Authenticate] = @YES;
                break;
            
            // Accept files
            case 'D':
                properties[AppSpecKey_Droppable] = @YES;
                properties[AppSpecKey_AcceptFiles] = @YES;
                break;
            
            // Accept text
            case 'F':
                properties[AppSpecKey_Droppable] = @YES;
                properties[AppSpecKey_AcceptText] = @YES;
                break;
            
            // Provide service
            case 'N':
                properties[AppSpecKey_Service] = @YES;
                break;
            
            // Run in background
            case 'B':
                properties[AppSpecKey_RunInBackground] = @YES;
                break;
            
            // Send notifications
            case 'W':
                properties[AppSpecKey_SendNotifications] = @YES;
                break;
                
            // Remain running
            case 'R':
                properties[AppSpecKey_RemainRunning] = @NO;
                break;
            
            // Write plists in XML format (DEPRECATED)
            case 'x':
                break;
            
            // Suffixes
            case 'X':
            {
                NSString *suffixesStr = @(optarg);
                properties[AppSpecKey_Suffixes] = [suffixesStr componentsSeparatedByString:CMDLINE_ARG_SEPARATOR];
            }
                break;
            
            // Uniform Type Identifiers
            case 'T':
            {
                NSString *utisStr = @(optarg);
                NSArray *utis = [utisStr componentsSeparatedByString:CMDLINE_ARG_SEPARATOR];
                properties[AppSpecKey_Utis] = utis;
            }
                break;
            
            // URI schemes
            case 'U':
            {
                NSString *uriSchemes = @(optarg);
                properties[AppSpecKey_URISchemes] = [uriSchemes componentsSeparatedByString:CMDLINE_ARG_SEPARATOR];
            }
                break;
            
            // Prompt for file on startup
            case 'Z':
                properties[AppSpecKey_PromptForFile] = @YES;
                break;
            
            // Arguments for interpreter
            case 'G':
            {
                NSString *parametersString = @(optarg);
                NSArray *parametersArray = [parametersString componentsSeparatedByString:CMDLINE_ARG_SEPARATOR];
                properties[AppSpecKey_InterpreterArgs] = parametersArray;
            }
                break;
            
            // Arguments for script
            case 'C':
            {
                NSString *parametersString = @(optarg);
                NSArray *parametersArray = [parametersString componentsSeparatedByString:CMDLINE_ARG_SEPARATOR];
                properties[AppSpecKey_ScriptArgs] = parametersArray;
            }
                break;
            
            // Overwrite mode
            case 'y':
                properties[AppSpecKey_Overwrite] = @YES;
                break;
            
            // Development version, symlink to script
            case 'd':
                properties[AppSpecKey_SymlinkFiles] = @YES;
                break;
            
            // Optimize nib files by stripping/compiling
            case 'l':
                properties[AppSpecKey_StripNib] = @YES;
                break;
            
            // Set display kind for Status Menu interface
            case 'K':
            {
                NSString *kind = @(optarg);
                // validate -- refactor!
                if (![kind isEqualToString:PLATYPUS_STATUSITEM_DISPLAY_TYPE_TEXT] && ![kind isEqualToString:PLATYPUS_STATUSITEM_DISPLAY_TYPE_ICON]) {
                    NSPrintErr(@"Error: Invalid status item kind '%@'.", kind);
                    exit(EXIT_FAILURE);
                }
                properties[AppSpecKey_StatusItemDisplayType] = kind;
            }
                break;
            
            // Set title of status item for Status Menu interface
            case 'Y':
            {
                NSString *title = @(optarg);
                if ([title isEqualToString:@""] || title == nil) {
                    NSPrintErr(@"Error: Empty status item title.");
                    exit(EXIT_FAILURE);
                }
                properties[AppSpecKey_StatusItemTitle] = title;
            }
                break;
            
            // Set if Status Menu uses system font
            case 'c':
                properties[AppSpecKey_StatusItemUseSysfont] = @YES;
                break;
            
            // Icon is template: process Status Menu item icon with AppKit
            case 'q':
                properties[AppSpecKey_StatusItemIconIsTemplate] = @YES;
                break;
            
            // Set icon image of status item for Status Menu interface
            case 'L':
            {
                NSString *iconPath = MakeAbsolutePath(@(optarg));
                if (![fm fileExistsAtPath:iconPath]) {
                    NSPrintErr(@"Error: No image file exists at path '%@'.", iconPath);
                    exit(EXIT_FAILURE);
                }
                
                // Read image from file
                NSImage *iconImage = [[NSImage alloc] initWithContentsOfFile:iconPath];
                if (iconImage == nil) {
                    NSPrintErr(@"Error: Unable to get image from file '%@'.", iconPath);
                    exit(EXIT_FAILURE);
                }
                properties[AppSpecKey_StatusItemIcon] = [iconImage TIFFRepresentation];
            }
                break;
            
            // Print version
            case 'v':
            {
                PrintVersion();
                exit(EXIT_SUCCESS);
            }
                break;
            
            // Print help with list of options
            case 'h':
            default:
            {
                PrintHelp();
                exit(EXIT_SUCCESS);
            }
                break;
        }
    }
    
    // We always need one more argument, either script file path or app name
    if (argc - optind < 1) {
        NSPrintErr(@"Error: Missing argument.");
        PrintHelp();
        exit(EXIT_FAILURE);
    }
    
    // Check if there are any duplicate filenames in bundled files
    NSArray *duplicateFileNames = FindDuplicateFileNames(properties[AppSpecKey_BundledFiles]);
    if ([duplicateFileNames count]) {
        NSPrintErr(@"Warning: Duplicate file names in bundled files. These may be overwritten: %@", [duplicateFileNames description]);
    }
    
    PlatypusAppSpec *appSpec = nil;
    NSString *scriptPath = nil;
    NSString *destPath = nil;
    
    // Read remaining args as paths
    NSMutableArray *remainingArgs = [NSMutableArray array];
    while (optind < argc) {
        NSString *argStr = @(argv[optind]);
        if (![argStr isEqualToString:@"-"]) {
            argStr = MakeAbsolutePath(argStr);
        }
        [remainingArgs addObject:argStr];
        optind += 1;
    }
    
    if (createProfile) {
        BOOL printStdout = FALSE;
        destPath = remainingArgs[0];
        
        // Append .platypus suffix to destination file if not user-specified
        if ([destPath isEqualToString:@"-"] ) {
            printStdout = TRUE;
        } else if (![destPath hasSuffix:@".platypus"]) {
            NSPrintErr(@"Warning: Appending .platypus extension");
            destPath = [destPath stringByAppendingString:@".platypus"];
        }
        
        // We then dump the profile dictionary to path and exit
        appSpec = [PlatypusAppSpec specWithDefaults];
        [appSpec addEntriesFromDictionary:properties];
        
        printStdout ? [appSpec dump] : [appSpec writeToFile:destPath];
        
        exit(EXIT_SUCCESS);
    }
    
    // If we loaded a profile, the first remaining arg is destination path, others ignored
    if (loadedProfile) {
        destPath = remainingArgs[0];
        if (![destPath hasSuffix:APPBUNDLE_SUFFIX]) {
            destPath = [destPath stringByAppendingString:APPBUNDLE_SUFFIX];
        }
        appSpec = [PlatypusAppSpec specWithDefaults];
        [appSpec addEntriesFromDictionary:properties];
        appSpec[AppSpecKey_DestinationPath] = destPath;
        
        if (appSpec[AppSpecKey_IsExample]) {
            NSString *scriptText = appSpec[AppSpecKey_ScriptText];
            scriptPath = [FILEMGR createTempFileNamed:nil withContents:scriptText usingTextEncoding:NSUTF8StringEncoding];
            appSpec[AppSpecKey_ScriptPath] = scriptPath;
            deleteScript = YES;
        }
    }
    // If we're creating an app, first argument must be script path, second (optional) argument is destination
    else {
        // Get script path, generate default app name
        scriptPath = remainingArgs[0];
        
        // A script path of "-" means read from STDIN
        if ([scriptPath isEqualToString:@"-"]) {
            // Read stdin, dump to temp file, set it as script path
            scriptPath = ReadStandardInputToFile();
            deleteScript = YES; // we get rid of it once the app has been created
        }
        else if ([fm fileExistsAtPath:scriptPath] == NO) {
            NSPrintErr(@"Error: No script file exists at path '%@'", scriptPath);
            exit(EXIT_FAILURE);
        }
        
        appSpec = [PlatypusAppSpec specWithDefaultsFromScript:scriptPath];
        NSString *appName = properties[AppSpecKey_Name] ? properties[AppSpecKey_Name] : appSpec[AppSpecKey_Name];
        NSString *appBundleName = [NSString stringWithFormat:@"%@.app", appName];
        NSString *scriptFolder = [scriptPath stringByDeletingLastPathComponent];
        destPath = [scriptFolder stringByAppendingPathComponent:appBundleName];
        
        appSpec[AppSpecKey_DestinationPath] = destPath;
        [appSpec addEntriesFromDictionary:properties];
        
        // If author name is supplied but no identifier, we create a default identifier with author name as clue
        if (properties[AppSpecKey_Author] && properties[AppSpecKey_Identifier] == nil) {
            NSString *identifier = [PlatypusAppSpec bundleIdentifierForAppName:appSpec[AppSpecKey_Name]
                                                                    authorName:properties[AppSpecKey_Author]
                                                                 usingDefaults:NO];
            if (identifier) {
                appSpec[AppSpecKey_Identifier] = identifier;
            }
        }
        
        // If there's another argument after the script path, it means a destination path has been specified
        if ([remainingArgs count] > 1) {
            destPath = remainingArgs[1];
            // Insist on .app suffix
            if (![destPath hasSuffix:APPBUNDLE_SUFFIX]) {
                destPath = [destPath stringByAppendingString:APPBUNDLE_SUFFIX];
            }
            appSpec[AppSpecKey_DestinationPath] = destPath;
        }
    }
    
    NSString *path = appSpec[AppSpecKey_ScriptPath];
    if (path == nil || [path isEqualToString:@""]) {
        NSPrintErr(@"Error: Missing script path.");
        exit(EXIT_FAILURE);
    }
    
    // Create the app from spec
    if ([appSpec verify] == NO || [appSpec create] == NO) {
        NSPrintErr(@"Error: %@", [appSpec error]);
        exit(EXIT_FAILURE);
    }
    
    // If script was a temporary file created from stdin, we remove it
    if (deleteScript) {
        [FILEMGR removeItemAtPath:scriptPath error:nil];
    }
    
    return EXIT_SUCCESS;
}

#pragma mark -

static NSString *ReadStandardInputToFile(void) {
    // Read data
    NSData *inData = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
    if (inData == nil) {
        NSPrintErr(@"Empty buffer, aborting.");
        exit(EXIT_FAILURE);
    }
    
    // Convert to string
    NSString *inStr = [[NSString alloc] initWithData:inData encoding:DEFAULT_TEXT_ENCODING];
    if (inStr == nil) {
        NSPrintErr(@"Cannot handle non-text data.");
        exit(EXIT_FAILURE);
    }
    
    // Write to temp file
    NSString *tmpFilePath = [FILEMGR createTempFileNamed:nil withContents:inStr usingTextEncoding:NSUTF8StringEncoding];
    return tmpFilePath;
}

static NSString *MakeAbsolutePath(NSString *path) {
    NSString *absPath = [path stringByExpandingTildeInPath];
    if ([absPath isAbsolutePath] == NO) {
        absPath = [[FILEMGR currentDirectoryPath] stringByAppendingPathComponent:path];
    }
    return [absPath stringByStandardizingPath];
}

static NSArray *FindDuplicateFileNames(NSArray *paths) {
    NSMutableSet *fileNameSet = [NSMutableSet set];
    NSMutableArray *duplicateFileNames = [NSMutableArray array];
    for (NSString *p in paths) {
        NSString *fn = [p lastPathComponent];
        if ([fileNameSet containsObject:fn]) {
            [duplicateFileNames addObject:fn];
        } else {
            [fileNameSet addObject:fn];
        }
    }
    return [duplicateFileNames copy];
}

#pragma mark -

static void PrintVersion(void) {
    NSPrint(@"%@ version %@", CMDLINE_PROGNAME, PROGRAM_VERSION);
}

static void PrintHelp(void) {
    PrintVersion();
    
    NSPrint(@"\n\
platypus [OPTIONS] scriptPath [destinationPath]\n\
\n\
Options:\n\
\n\
    -O --generate-profile              Generate a profile instead of an app\n\
\n\
    -P --load-profile [profilePath]    Load settings from profile document\n\
    -a --name [name]                   Set name of application bundle\n\
    -o --interface-type [type]         Set interface type. See man page for accepted types\n\
    -p --interpreter [interpreterPath] Set interpreter for script\n\
\n\
    -i --app-icon [iconPath]           Set icon for application\n\
    -u --author [author]               Set name of application author\n\
    -Q --document-icon [iconPath]      Set icon for documents\n\
    -V --app-version [version]         Set version of application\n\
    -I --bundle-identifier [idstr]     Set bundle identifier (e.g. org.yourname.appname)\n\
\n\
    -A --admin-privileges              App runs with Administrator privileges\n\
    -D --droppable                     App accepts dropped files as arguments to script\n\
    -F --text-droppable                App accepts dropped text passed to script via STDIN\n\
    -Z --file-prompt                   App presents an open file dialog when launched\n\
    -N --service                       App registers as a Mac OS X Service\n\
    -B --background                    App runs in background (LSUIElement)\n\
    -R --quit-after-execution          App quits after executing script\n\
\n\
    -b --text-background-color [color] Set background color of text view (e.g. '#ffffff')\n\
    -g --text-foreground-color [color] Set foreground color of text view (e.g. '#000000')\n\
    -n --text-font [fontName]          Set font for text view (e.g. 'Monaco 10')\n\
    -X --suffixes [suffixes]           Set suffixes handled by app, separated by |\n\
    -T --uniform-type-identifiers      Set uniform type identifiers handled by app, separated by |\n\
    -U --uri-schemes                   Set URI schemes handled by app, separated by |\n\
    -G --interpreter-args [arguments]  Set arguments for script interpreter, separated by |\n\
    -C --script-args [arguments]       Set arguments for script, separated by |\n\
\n\
    -K --status-item-kind [kind]       Set Status Item kind ('Icon' or 'Text')\n\
    -Y --status-item-title [title]     Set title of Status Item\n\
    -L --status-item-icon [imagePath]  Set icon of Status Item\n\
    -c --status-item-sysfont           Status Item should use the system font for menu item text\n\
    -q --status-item-template-icon     Status Item icon should be treated as a template by AppKit\n\
\n\
    -f --bundled-file [filePath]       Add a bundled file or files (paths separated by \"|\")\n\
    \n\
    -y --overwrite                     Overwrite any file/folder at destination path\n\
    -d --symlink                       Symlink to script and bundled files instead of copying\n\
    -l --optimize-nib                  Strip and compile bundled nib file to reduce size\n\
    -h --help                          Prints help\n\
    -v --version                       Prints program name and version\n\
\n\
See 'man platypus' or %@ for details.", PROGRAM_MANPAGE_URL);
}

#pragma mark -

// Print to stdout
static void NSPrint(NSString *format, ...) {
    va_list args;
    
    va_start(args, format);
    NSString *string  = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    fprintf(stdout, "%s\n", [string UTF8String]);
}

// Print to stderr
static void NSPrintErr(NSString *format, ...) {
    va_list args;
    
    va_start(args, format);
    NSString *string  = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    fprintf(stderr, "%s\n", [string UTF8String]);
}
