/*
 platypus - command line counterpart to the Mac OS X Platypus application
 - create application wrappers around scripts
 
 Copyright (C) 2003-2015 Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 
 */

/*
 Support files required for this program are defined in Common.h
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "Common.h"
#import "PlatypusAppSpec.h"

#import <stdio.h>
#import <unistd.h>
#import <errno.h>
#import <sys/stat.h>
#import <limits.h>
#import <string.h>
#import <fcntl.h>
#import <errno.h>
#import <getopt.h>

#define OPT_STRING "P:f:a:o:i:u:p:V:I:Q:ASOZDBRFNydlvhxX:G:C:b:g:n:E:K:Y:L:H:U:"

int verbose_flag;

static struct option long_options[] =
{
    /* These options set a flag. */
    {"verbose", no_argument,       &verbose_flag, 1},
    {"brief",   no_argument,       &verbose_flag, 0},
    /* These options don't set a flag.
     We distinguish them by their indices. */
    {"add",     no_argument,       0, 'a'},
    {"append",  no_argument,       0, 'b'},
    {"delete",  required_argument, 0, 'd'},
    {"create",  required_argument, 0, 'c'},
    {"file",    required_argument, 0, 'f'},
    {0, 0, 0, 0}
};

static NSString *MakeAbsolutePath(NSString *path);
static void PrintVersion(void);
static void PrintUsage(void);
static void PrintHelp(void);
static void NSPrintErr(NSString *format, ...);
static void NSPrint(NSString *format, ...);

int main(int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];  //set up autorelease pool
    NSApplication *app = [NSApplication sharedApplication];
    app = app; //establish connection to Window Server
    NSFileManager *fm = FILEMGR;
    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:ARG_MAX];
    BOOL createProfile = FALSE;
    BOOL loadedProfile = FALSE;
    int optch;
    static char optstring[] = OPT_STRING;
    
    while ((optch = getopt(argc, (char *const *)argv, optstring)) != -1) {
        switch (optch) {
                // tells the command line app to create a profile from its data rather than an app
            case 'O':
            {
                createProfile = TRUE;
            }
                break;
                
                // Load Profile
            case 'P':
            {
                NSString *profilePath = MakeAbsolutePath([NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING]);
                
                // error if profile doesn't exists, warn if w/o profile suffix
                if (![fm fileExistsAtPath:profilePath]) {
                    NSPrintErr(@"Error: Profile '%@' is invalid.  No file at path.", profilePath, PROGRAM_NAME);
                    exit(1);
                }
                if (![profilePath hasSuffix:PROFILES_SUFFIX])
                    NSPrintErr(@"Warning: Profile '%@' does not have profile suffix.  Trying anyway...");
                
                // read profile dictionary from file
                NSDictionary *profileDict = [NSDictionary dictionaryWithContentsOfFile:profilePath];
                if (profileDict == nil) {
                    NSPrintErr(@"Error loading %@ profile '%@'.", PROGRAM_NAME, profilePath);
                    exit(1);
                }
                
                // warn about diff versions
                if (![[profileDict objectForKey:@"Creator"] isEqualToString:PROGRAM_STAMP])
                    NSPrint(@"Warning: Profile created with different version of %@.", PROGRAM_NAME);
                
                // add entries in profile to app properties, overwriting any former values
                [properties addEntriesFromDictionary:profileDict];
                loadedProfile = TRUE;
            }
                break;
                
                // App Name
            case 'a':
                [properties setObject:[NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING] forKey:@"Name"];
                break;
                
                // A bundled file.  This flag can be passed multiple times to include more than one bundled file
            case 'f':
            {
                NSString *filePath = MakeAbsolutePath([NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING]);
                
                // make sure file exists
                if (![fm fileExistsAtPath:filePath]) {
                    NSPrintErr(@"Error: No file exists at path '%@'", filePath);
                    exit(1);
                }
                
                // create bundled files array entry in properties if it doesn't already exist
                if ([properties objectForKey:@"BundledFiles"] == nil)
                    [properties setObject:[NSMutableArray array] forKey:@"BundledFiles"];
                
                // add file argument to it
                [[properties objectForKey:@"BundledFiles"] addObject:filePath];
            }
                break;
                
                // Output Type
            case 'o':
            {
                NSString *outputType = [NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING];
                if (![PLATYPUS_OUTPUT_TYPES containsObject:outputType]) {
                    NSPrintErr(@"Error: Invalid output type '%@'.  Valid types are:", outputType);
                    NSPrintErr([PLATYPUS_OUTPUT_TYPES description]);
                    exit(1);
                }
                [properties setObject:[NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING] forKey:@"Output"];
            }
                break;
                
                // background color of text output
            case 'b':
            {
                NSString *hexColorStr = [NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING];
                if ([hexColorStr length] != 7 || [hexColorStr characterAtIndex:0] != '#') {
                    NSPrintErr(@"Error: '%@' is not a valid color spec.  Must be 6 digit hexadecimal, e.g. #aabbcc", hexColorStr);
                    exit(1);
                }
                [properties setObject:[NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING] forKey:@"TextBackground"];
            }
                break;
                
                // foreground color of text output
            case 'g':
            {
                NSString *hexColorStr = [NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING];
                if ([hexColorStr length] != 7 || [hexColorStr characterAtIndex:0] != '#') {
                    NSPrintErr(@"Error: '%@' is not a valid color spec.  Must be 6 digit hexadecimal, e.g. #aabbcc", hexColorStr);
                    exit(1);
                }
                [properties setObject:[NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING] forKey:@"TextForeground"];
            }
                break;
                
                // font and size of text output
            case 'n':
            {
                NSString *fontStr = [NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING];
                NSMutableArray *words = [NSMutableArray arrayWithArray:[fontStr componentsSeparatedByString:@" "]];
                if ([words count] < 2) {
                    NSPrintErr(@"Error: '%@' is not a valid font.  Must be fontname followed by size, e.g. 'Monaco 10'", fontStr);
                    exit(1);
                }
                // parse string for font name and size, and set it in properties
                float fontSize = [[words lastObject] floatValue];
                [words removeLastObject];
                NSString *fontName = [words componentsJoinedByString:@" "];
                [properties setObject:fontName forKey:@"TextFont"];
                [properties setObject:[NSNumber numberWithFloat:fontSize] forKey:@"TextSize"];
            }
                break;
                
                // text encoding to use
            case 'E':
            {
                NSString *encNumStr = [NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING];
                int textEncoding = [encNumStr intValue];
                if (textEncoding <= 0) {
                    NSPrintErr(@"Error: Invalid text encoding specified");
                    exit(1);
                }
                [properties setObject:[NSNumber numberWithInt:textEncoding] forKey:@"TextEncoding"];
            }
                break;
                
                // Author
            case 'u':
                [properties setObject:[NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING] forKey:@"Author"];
                break;
                
                // Icon
            case 'i':
            {
                NSString *iconPath = [NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING];
                
                // empty icon path means just default app icon, otherwise a path to an icns file
                if (![iconPath isEqualTo:@""]) {
                    iconPath = MakeAbsolutePath(iconPath);
                    // if we have proper arg, make sure file exists
                    if (![fm fileExistsAtPath:iconPath]) {
                        NSPrintErr(@"Error: No icon file exists at path '%@'", iconPath);
                        exit(1);
                    }
                    
                    // warn if file doesn't have icns suffix
                    if (![iconPath hasSuffix:@"icns"])
                        NSPrintErr(@"Warning: '%@' not identified as an Apple .icns file", iconPath);
                }
                [properties setObject:iconPath forKey:@"IconPath"];
            }
                break;
                
                // Document icon
            case 'Q':
            {
                NSString *iconPath = [NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING];
                
                // empty icon path means just default app icon, otherwise a path to an icns file
                if (![iconPath isEqualTo:@""]) {
                    iconPath = MakeAbsolutePath(iconPath);
                    // if we have proper arg, make sure file exists
                    if (![fm fileExistsAtPath:iconPath]) {
                        NSPrintErr(@"Error: No icon file exists at path '%@'", iconPath);
                        exit(1);
                    }
                    
                    // warn if file doesn't have icns suffix
                    if (![iconPath hasSuffix:@"icns"])
                        NSPrintErr(@"Warning: '%@' not identified as an Apple .icns file", iconPath);
                }
                [properties setObject:iconPath forKey:@"DocIcon"];
            }
                break;
                
                // Interpreter
            case 'p':
            {
                NSString *interpreterPath = MakeAbsolutePath([NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING]);
                if (![fm fileExistsAtPath:interpreterPath])
                    NSPrintErr(@"Warning: Interpreter path '%@' invalid - no file at path.", interpreterPath);
                
                [properties setObject:interpreterPath forKey:@"Interpreter"];
            }
                break;
                
                // Version
            case 'V':
                [properties setObject:[NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING] forKey:@"Version"];
                break;
                
                // Identifier
            case 'I':
                [properties setObject:[NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING] forKey:@"Identifier"];
                break;
                
                // The checkbox options
            case 'A':
                [properties setObject:[NSNumber numberWithBool:YES] forKey:@"Authentication"];
                break;
                
            case 'S':
                [properties setObject:[NSNumber numberWithBool:YES] forKey:@"Secure"];
                break;
                
            case 'D':
                [properties setObject:[NSNumber numberWithBool:YES] forKey:@"Droppable"];
                [properties setObject:[NSNumber numberWithBool:YES] forKey:@"AcceptsFiles"];
                break;
                
            case 'F':
                [properties setObject:[NSNumber numberWithBool:YES] forKey:@"Droppable"];
                [properties setObject:[NSNumber numberWithBool:YES] forKey:@"AcceptsText"];
                break;
                
            case 'N':
                [properties setObject:[NSNumber numberWithBool:YES] forKey:@"DeclareService"];
                break;
                
            case 'B':
                [properties setObject:[NSNumber numberWithBool:YES] forKey:@"ShowInDock"];
                break;
                
            case 'R':
                [properties setObject:[NSNumber numberWithBool:NO] forKey:@"RemainRunning"];
                break;
                
            case 'x':
                [properties setObject:[NSNumber numberWithBool:YES] forKey:@"UseXMLPlistFormat"];
                break;
                
                // Suffixes
            case 'X':
            {
                NSString *suffixesStr = [NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING];
                NSArray *suffixes = [suffixesStr componentsSeparatedByString:@"|"];
                [properties setObject:suffixes forKey:@"Suffixes"];
            }
                break;
                
                // File Types
            case 'T':
            {
                // obsolete option
            }
                break;
            
                // Prompt for file on startup
            case 'Z':
                [properties setObject:[NSNumber numberWithBool:YES] forKey:@"PromptForFileOnLaunch"];
                break;
                
                // Arguments for interpreter
            case 'G':
            {
                NSString *parametersString = [NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING];
                NSArray *parametersArray = [parametersString componentsSeparatedByString:@"|"];
                [properties setObject:parametersArray forKey:@"InterpreterArgs"];
            }
                break;
                
                // Arguments for script
            case 'C':
            {
                NSString *parametersString = [NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING];
                NSArray *parametersArray = [parametersString componentsSeparatedByString:@"|"];
                [properties setObject:parametersArray forKey:@"ScriptArgs"];
            }
                break;
                
                // force overwrite mode
            case 'y':
                [properties setObject:[NSNumber numberWithBool:YES] forKey:@"DestinationOverride"];
                break;
                
                // development version, symlink to script
            case 'd':
                [properties setObject:[NSNumber numberWithBool:YES] forKey:@"DevelopmentVersion"];
                break;
                
                // don't optimize application by stripping/compiling nib files
            case 'l':
                [properties setObject:[NSNumber numberWithBool:NO] forKey:@"OptimizeApplication"];
                break;
                
                // custom nib path
            case 'H':
            {
                NSString *nibPath = MakeAbsolutePath([NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING]);
                // make sure we have a nib file that exists at this path
                if (![fm fileExistsAtPath:nibPath] || ![nibPath hasSuffix:@"nib"]) {
                    NSPrintErr(@"Error: No nib file exists at path '%@'", nibPath);
                    exit(1);
                }
                [properties setObject:nibPath forKey:@"NibPath"];
            }
                break;
                
                // set display kind for Status Menu output
            case 'K':
            {
                NSString *kind = [NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING];
                if (![kind isEqualToString:@"Text"] && ![kind isEqualToString:@"Icon"] && ![kind isEqualToString:@"Icon and Text"]) {
                    NSPrintErr(@"Error: Invalid status item kind '%@'", kind);
                    exit(1);
                }
                [properties setObject:kind forKey:@"StatusItemDisplayType"];
            }
                break;
                
                // set title of status item for Status Menu output
            case 'Y':
            {
                NSString *title = [NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING];
                if ([title isEqualToString:@""] || title == NULL) {
                    NSPrintErr(@"Error: Empty status item title");
                    exit(1);
                }
                [properties setObject:title forKey:@"StatusItemTitle"];
            }
                break;
                
                // set icon image of status item for Status Menu output
            case 'L':
            {
                NSString *iconPath = MakeAbsolutePath([NSString stringWithCString:optarg encoding:DEFAULT_OUTPUT_TXT_ENCODING]);
                if (![fm fileExistsAtPath:iconPath]) {
                    NSPrintErr(@"Error: No image file exists at path '%@'", iconPath);
                    exit(1);
                }
                
                // read image from file
                NSImage *iconImage = [[[NSImage alloc] initWithContentsOfFile:iconPath] autorelease];
                if (iconImage == NULL) {
                    NSPrintErr(@"Error: Unable to get image from file '%@'", iconPath);
                    exit(1);
                }
                
                // make sure it's 16x16 pixels
                NSSize imgSize = [iconImage size];
                if (imgSize.width != 16 || imgSize.height != 16) {
                    NSPrintErr(@"Error: Dimensions of image '%@' is not 16x16", iconPath);
                    exit(1);
                }
                [properties setObject:[iconImage TIFFRepresentation] forKey:@"StatusItemIcon"];
            }
                break;
                
                // print version
            case 'v':
                PrintVersion();
                exit(0);
                break;
                
                // print help with list of options
            case 'h':
                PrintHelp();
                return 0;
                break;
                
                // default to printing usage string
            default:
                PrintUsage();
                return 0;
                break;
        }
    }
    
    // we always need one more argument, either script file path or app name
    if (argc - optind < 1) {
        NSPrintErr(@"Error: Missing argument");
        PrintUsage();
        exit(1);
    }
    
    PlatypusAppSpec *appSpec = nil;
    NSString *scriptPath = nil;
    NSString *destPath = nil;
    
    // read remaining args as paths
    NSMutableArray *remainingArgs = [NSMutableArray arrayWithCapacity:ARG_MAX];
    while (optind < argc) {
        NSString *argStr = [NSString stringWithCString:argv[optind] encoding:DEFAULT_OUTPUT_TXT_ENCODING];
        if (![argStr isEqualToString:@"-"])
            argStr = MakeAbsolutePath(argStr);
        [remainingArgs addObject:argStr];
        optind += 1;
    }
    
    if (createProfile) {
        BOOL printStdout = FALSE;
        destPath = [remainingArgs objectAtIndex:0];
        
        // append .platypus suffix to destination file if not user-specified
        if ([destPath hasSuffix:@"-"])
            printStdout = TRUE;
        else if (![destPath hasSuffix:@".platypus"]) {
            NSPrintErr(@"Warning: Appending .platypus extension");
            destPath = [destPath stringByAppendingString:@".platypus"];
        }
        // we then dump the profile dictionary to path and exit
        appSpec = [PlatypusAppSpec specWithDefaults];
        [appSpec addProperties:properties];
        
        if (printStdout)
            [appSpec dump];
        else
            [appSpec dumpToFile:destPath];
        
        exit(0);
    }
    // if we loaded a profile, the first remaining arg is destination path, others ignored
    else if (loadedProfile) {
        destPath = [remainingArgs objectAtIndex:0];
        if (![destPath hasSuffix:@".app"])
            destPath = [destPath stringByAppendingString:@".app"];
        
        appSpec = [PlatypusAppSpec specWithDefaults];
        [appSpec addProperties:properties];
        [appSpec setProperty:destPath forKey:@"Destination"];
    }
    // if we're creating an app, first argument must be script path, second (optional) argument is destination
    else {
        // get script path, generate default app name
        scriptPath = [remainingArgs objectAtIndex:0];
        if ([scriptPath isEqualToString:@"-"]) {
            // read data
            NSData *inData = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
            if (!inData) {
                NSPrintErr(@"Empty buffer, aborting.");
                exit(1);
            }
            
            // convert to string
            NSString *inStr = [[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding];
            if (!inStr) {
                NSPrintErr(@"Cannot handle non-text data.");
                exit(1);
            }
            
            // write to temp file
            [inStr writeToFile:TMP_STDIN_PATH atomically:YES encoding:DEFAULT_OUTPUT_TXT_ENCODING error:nil];
            [inStr release];
            
            // set temp file as script path
            scriptPath = TMP_STDIN_PATH;
        }
        else if ([fm fileExistsAtPath:scriptPath] == NO) {
            NSPrintErr(@"Error: No script file exists at path '%@'", scriptPath);
            exit(1);
        }
        
        appSpec = [PlatypusAppSpec specWithDefaultsFromScript:scriptPath];
        if ([properties objectForKey:@"Name"] != nil) {
            NSString *appBundleName = [NSString stringWithFormat:@"%@.app", [properties objectForKey:@"Name"]];
            NSString *scriptFolder = [scriptPath stringByDeletingLastPathComponent];
            destPath = [scriptFolder stringByAppendingPathComponent:appBundleName];
            [appSpec setProperty:destPath forKey:@"Destination"];
        }
        [appSpec addProperties:properties];
        
        // if there's another argument after the script path, it means a destination path has been specified
        if ([remainingArgs count] > 1) {
            destPath = [remainingArgs objectAtIndex:1];
            [appSpec setProperty:destPath forKey:@"Destination"];
        }
    }
    
    if (![appSpec propertyForKey:@"ScriptPath"] || [[appSpec propertyForKey:@"ScriptPath"] isEqualToString:@""]) {
        NSPrintErr(@"Error: Missing script path.");
        exit(1);
    }
    
    // create the app from spec
    if (![appSpec verify] || ![appSpec create]) {
        NSPrintErr(@"Error: %@", [appSpec error]);
        exit(1);
    }
    
    [pool drain];
    
    return 0;
}

#pragma mark -

static NSString *MakeAbsolutePath(NSString *path) {
    path = [path stringByExpandingTildeInPath];
    if ([path isAbsolutePath] == NO)
        path = [[FILEMGR currentDirectoryPath] stringByAppendingPathComponent:path];
    return [path stringByStandardizingPath];
}

#pragma mark -

////////////////////////////////////////
// Print version and author to stdout
///////////////////////////////////////

static void PrintVersion(void) {
    NSPrint(@"%@ version %@ by %@", CMDLINE_PROGNAME, PROGRAM_VERSION, PROGRAM_AUTHOR);
}

////////////////////////////////////////
// Print usage string to stdout
///////////////////////////////////////

static void PrintUsage(void) {
    NSPrint(@"usage: %@ [-vh] [-O profile] [-FASDNBRZ] [-ydlHx] [-KYL] [-P profile] [-a appName] [-o outputType] [-i icon] [-Q docIcon] [-p interpreter] [-V version] [-u author] [-I identifier] [-f bundledFile] [-X suffixes] [-C scriptArgs] [-G interpreterArgs] scriptFile [appPath]", CMDLINE_PROGNAME);
}

////////////////////////////////////////
// Print help string to stdout
///////////////////////////////////////

static void PrintHelp(void) {
    NSPrint(@"%@ - command line application wrapper generator for scripts", CMDLINE_PROGNAME);
    PrintVersion();
    PrintUsage();
    printf("\n\
       Options:\n\
       -O                   Generate a profile instead of an app\n\
       \n\
       -P [profilePath]     Load settings from profile file\n\
       -a [name]            Set name of application bundle\n\
       -o [type]            Set output type.  See man page for accepted types\n\
       -p [interpreterPath] Set interpreter for script\n\
       \n\
       -i [iconPath]        Set icon for application\n\
       -u [author]          Set name of application author\n\
       -Q [iconPath]        Set icon for documents\n\
       -V [version]         Set version of application\n\
       -I [identifier]      Set bundle identifier (i.e. org.yourname.appname)\n\
       \n\
       -A                   App runs with Administrator privileges\n\
       -S                   Secure bundled script\n\
       -D                   App accepts dropped files as argument to script\n\
       -F                   App accepts dropped text as argument to script\n\
       -Z                   App presents Open file dialog once launched\n\
       -N                   App registers as a Mac OS X Service\n\
       -B                   App runs in background (LSUI Element)\n\
       -R                   App quits after executing script\n\
       \n\
       -b [hexColor]        Set background color of text output (e.g. #ffffff)\n\
       -g [hexColor]        Set foreground color of text output (e.g. #000000)\n\
       -n [fontName]        Set font for text output field (e.g. 'Monaco 10')\n\
       -E [encoding]        Set text encoding for script output (see man page)\n\
       -X [suffixes]        Set suffixes handled by application\n\
       -G [arguments]       Set arguments for script interpreter, separated by |\n\
       -C [arguments]       Set arguments for script, separated by |\n\
       \n\
       -K [kind]            Set Status Item kind ('Icon','Text', 'Icon and Text')\n\
       -Y [title]           Set title of Status Item\n\
       -L [imagePath]       Set icon of Status Item\n\
       \n\
       -f [filePath]        Add a bundled file\n\
       \n\
       -x                   Create XML property lists instead of binary\n\
       -y                   Force mode.  Overwrite any files/folders in path\n\
       -d                   Development version.  Symlink to script instead of copying\n\
       -l                   Optimize application.  Strip and compile bundled nib file\n\
       -H [xibPath]         Specify alternate xib file to bundle with app\n\n\
       -h                   Prints help\n\
       -v                   Prints program name, version and author\n\n");
}

#pragma mark -

// print to stdout
static void NSPrint(NSString *format, ...) {
    va_list args;
    
    va_start(args, format);
    
    NSString *string;
    
    string = [[NSString alloc] initWithFormat:format arguments:args];
    
    va_end(args);
    
    fprintf(stdout, "%s\n", [string UTF8String]);
    
    [string release];
}

// print to stderr
static void NSPrintErr(NSString *format, ...) {
    va_list args;
    
    va_start(args, format);
    
    NSString *string;
    
    string = [[NSString alloc] initWithFormat:format arguments:args];
    
    va_end(args);
    
    fprintf(stderr, "%s\n", [string UTF8String]);
    
    [string release];
}
