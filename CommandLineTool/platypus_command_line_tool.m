/*
    platypus - command line counterpart to the Mac OS X Platypus application
			 - create application wrappers around scripts
			 
    Copyright (C) 2006-2010 Sveinbjorn Thordarson <sveinbjornt@simnet.is>

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
	Support files required for this program are defined in CommonDefs.h
*/

///////////// IMPORTS/INCLUDES ////////////////

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "CommonDefs.h"
#import "PlatypusAppSpec.h"

#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>

///////////// DEFINITIONS ////////////////

#define		OPT_STRING			"P:c:f:a:o:i:u:p:V:I:ASODBRFydlvhX:T:G:b:g:n:E:K:Y:L:H:U:" 

///////////// PROTOTYPES ////////////////

static void PrintVersion (void);
static void PrintUsage (void);
static void PrintHelp (void);
static void NSPrintErr (NSString *format, ...);
static void NSPrint (NSString *format, ...);

int main (int argc, const char * argv[]) 
{
    NSAutoreleasePool	*pool				= [[NSAutoreleasePool alloc] init];//set up autorelease pool
	NSApplication		*app				= [NSApplication sharedApplication];//establish connection to Window Server
	NSFileManager		*fm					= [NSFileManager defaultManager];
		
	// we start with an application spec set to all the default settings
	// command line params can fill in the settings user wants
	PlatypusAppSpec		*appSpec			= [[[PlatypusAppSpec alloc] initWithDefaults] autorelease];	
	BOOL				createProfile		= FALSE;
	
	int					optch;
    static char			optstring[] = OPT_STRING;
	
    while ( (optch = getopt(argc, (char * const *)argv, optstring)) != -1)
    {
        switch(optch)
        {
			// tells the command line app to CREATE a profile from its data
			case 'O':
			{
				createProfile = TRUE;	
			}
			break;
				
			// Load Profile
			case 'P':
			{
				NSString *profilePath = [[NSString stringWithCString: optarg] stringByExpandingTildeInPath];

				if (![fm fileExistsAtPath: profilePath] || ![profilePath hasSuffix: PROFILES_SUFFIX])
				{
					NSPrintErr(@"Error: Profile path '%@' invalid.  No %@ profile at this path.", profilePath, PROGRAM_NAME);
					exit(1);
				}
				
				appSpec = [[PlatypusAppSpec alloc] initWithProfile: profilePath];
				if (appSpec == nil)
				{
					NSPrintErr(@"Error loading %@ profile '%@'.", PROGRAM_NAME, profilePath);
					exit(1);
				}
				if (![[appSpec propertyForKey:@"Creator"] isEqualToString: PROGRAM_STAMP])
					NSPrint(@"Warning:  Profile created with different version of %@.", PROGRAM_NAME);
				
			}
			break;
		
			// App Name
			case 'a':				
				[appSpec setProperty: [NSString stringWithCString: optarg] forKey: @"Name"];
				break;
			
			// A bundled file
			case 'f':
			{
				NSString *filePath = [[NSString stringWithCString: optarg] stringByExpandingTildeInPath];
				if (![fm fileExistsAtPath: filePath])
				{
					NSPrintErr(@"Error: No file exists at path '%@'", filePath);
					exit(1);
				}
				[[appSpec propertyForKey: @"BundledFiles"] addObject: filePath];
			}
			break;
			
			// Script path
			case 'c':
			{
				NSString *scriptPath = [[NSString stringWithCString: optarg] stringByExpandingTildeInPath];
				if (![fm fileExistsAtPath: scriptPath])
				{
					NSPrintErr(@"Error: No script file exists at path '%@'", scriptPath);
					exit(1);
				}
				[appSpec setProperty: scriptPath forKey: @"ScriptPath"];
			}
			break;
		
			// Output Type
            case 'o':
			{
				NSString *outputType = [NSString stringWithCString: optarg];
				if ([outputType caseInsensitiveCompare: @"None"] != NSOrderedSame &&
					[outputType caseInsensitiveCompare: @"Progress Bar"] != NSOrderedSame &&
					[outputType caseInsensitiveCompare: @"Text Window"] != NSOrderedSame &&
					[outputType caseInsensitiveCompare: @"Web View"] != NSOrderedSame &&
					[outputType caseInsensitiveCompare: @"Droplet"] != NSOrderedSame &&
					[outputType caseInsensitiveCompare: @"Status Menu"])
				{
						NSPrintErr(@"Error: Invalid output type '%@'.", outputType);
						exit(1);
				}
				[appSpec setProperty: [NSString stringWithCString: optarg] forKey: @"Output"];
			}
			break;
				
			// background color of text output
			case 'b':
			{
				NSString *hexColorStr = [NSString stringWithCString: optarg];
				if ([hexColorStr length] != 7 || [hexColorStr characterAtIndex: 0] != '#')
				{
					NSPrintErr(@"Error: '%@' is not a valid color spec.  Must be 6 digit hexadecimal, e.g. #aabbcc", hexColorStr);
					exit(1);
				}
				[appSpec setProperty: [NSString stringWithCString: optarg] forKey: @"TextBackground"];
			}
			break;
			
			// foreground color of text output
			case 'g':
			{
				NSString *hexColorStr = [NSString stringWithCString: optarg];
				if ([hexColorStr length] != 7 || [hexColorStr characterAtIndex: 0] != '#')
				{
					NSPrintErr(@"Error: '%@' is not a valid color spec.  Must be 6 digit hexadecimal, e.g. #aabbcc", hexColorStr);
					exit(1);
				}
				[appSpec setProperty: [NSString stringWithCString: optarg] forKey: @"TextForeground"];
			}
			break;
			
			// font and size of text output
			case 'n':
			{
				NSString *fontStr = [NSString stringWithCString: optarg];
				NSMutableArray *words = [NSMutableArray arrayWithArray: [fontStr componentsSeparatedByString:@" "]];
				if ([words count] < 2)
				{
					NSPrintErr(@"Error: '%@' is not a valid font.  Must be fontname followed by size, e.g. 'Monaco 10'", fontStr);
					exit(1);
				}
				// parse string for font name and size
				float fontSize = [[words lastObject] floatValue];
				[words removeLastObject];
				NSString *fontName = [words componentsJoinedByString: @" "];
				// set
				[appSpec setProperty: fontName forKey: @"TextFont"];
				[appSpec setProperty: [NSNumber numberWithFloat: fontSize] forKey: @"TextSize"];
			}
			break;
			
			// text encoding to use
			case 'E':
			{
				NSString *encNumStr = [NSString stringWithCString: optarg];
				int textEncoding = [encNumStr intValue];
				if (textEncoding <= 0)
				{
					NSPrintErr(@"Error: Invalid text encoding specified");
					exit(1);
				}
				[appSpec setProperty: [NSNumber numberWithInt: textEncoding] forKey: @"TextEncoding"];
			}
			break;
				
			// Author
			case 'u':
				[appSpec setProperty: [NSString stringWithCString: optarg] forKey: @"Author"];
				break;
			
			// Icon
			case 'i':
			{
				NSString *iconPath = [[NSString stringWithCString: optarg] stringByExpandingTildeInPath];
				if (![fm fileExistsAtPath: iconPath])
				{
					NSPrintErr(@"Error: No icon file exists at path '%@'", iconPath);
					exit(1);
				}
				
				 // specifying an icns file, that means we just use the file
				if ([iconPath hasSuffix: @"icns"])
				{
					NSPrintErr(@"Error: '%@' not an .icns file", iconPath);
					exit(1);
				}
				[appSpec setProperty: [NSString stringWithCString: optarg] forKey: @"IconPath"];
			}
			break;
			
			// Interpreter
			case 'p':
			{
				NSString *interpreterPath = [[NSString stringWithCString: optarg] stringByExpandingTildeInPath];;
				if (![fm fileExistsAtPath: interpreterPath])
					NSPrintErr(@"Warning: Interpreter path '%@' invalid - no such file.", interpreterPath);

				[appSpec setProperty: interpreterPath forKey: @"Interpreter"];
			}
			break;
			
			// Version
			case 'V':
				[appSpec setProperty: [NSString stringWithCString: optarg] forKey: @"Version"];
				break;
			
			case 'I':
				[appSpec setProperty: [NSString stringWithCString: optarg] forKey: @"Identifier"];
				break;
			
			// The checkbox options
            case 'A':
				[appSpec setProperty: [NSNumber numberWithBool: YES] forKey: @"Authentication"];
				break;
			case 'S':
				[appSpec setProperty: [NSNumber numberWithBool: YES] forKey: @"Secure"];
				break;
			case 'D':
				[appSpec setProperty: [NSNumber numberWithBool: YES] forKey: @"Droppable"];
				break;
			case 'F':
				[appSpec setProperty: [NSNumber numberWithBool: YES] forKey: @"AppPathAsFirstArg"];
				break;
			case 'B':
				[appSpec setProperty: [NSNumber numberWithBool: YES] forKey: @"ShowInDock"];				
				break;
			case 'R':
				[appSpec setProperty: [NSNumber numberWithBool: YES] forKey: @"RemainRunning"];
				break;
				
			// Suffixes
			case 'X':
			{
				NSString *suffixesStr = [NSString stringWithCString: optarg];
				NSArray *suffixes = [suffixesStr componentsSeparatedByString: @"|"];
				[appSpec setProperty: suffixes forKey:  @"Suffixes"];
			}
			break;
			
			// File Types
			case 'T':
			{
				NSString *filetypesStr = [NSString stringWithCString: optarg];
				NSArray *fileTypes = [filetypesStr componentsSeparatedByString: @"|"];
				[appSpec setProperty: fileTypes forKey: @"FileTypes"];
			}
			break;
			
			// Parameters for interpreter
			case 'G':
			{
				NSString *parametersString = [NSString stringWithCString: optarg];
				NSArray *parametersArray = [parametersString componentsSeparatedByString: @"|"];
				[appSpec setProperty: parametersArray forKey: @"Parameters"];
			}
			break;
			
			// force overwrite mode
			case 'y':
				[appSpec setProperty: [NSNumber numberWithBool: YES] forKey: @"DestinationOverride"];
				break;
				
			// development version, symlink to script
			case 'd':
				[appSpec setProperty: [NSNumber numberWithBool: YES] forKey: @"DevelopmentVersion"];
				break;
			
			// optimize application, strip/compile nib files
			case 'l':
				[appSpec setProperty: [NSNumber numberWithBool: YES] forKey: @"OptimizeApplication"];
				break;
			
			case 'U':
				[appSpec setProperty: [NSString stringWithCString: optarg] forKey: @"Architecture"];
				break;
			
			case 'H':
			{
				NSString *nibPath = [[NSString stringWithCString: optarg] stringByExpandingTildeInPath];
				// make sure we have a nib file that exists at this path
				if (![fm fileExistsAtPath: nibPath] || ![nibPath hasSuffix: @"nib"])
				{
					NSPrintErr(@"Error: No nib file exists at path '%@'", nibPath);
					exit(1);
				}
				[appSpec setProperty: nibPath forKey: @"NibPath"];
			}
			break;
			
			// set display kind for Status Menu output
			case 'K':
			{
				NSString *kind = [NSString stringWithCString: optarg];
				if (![kind isEqualToString: @"Text"] && ![kind isEqualToString: @"Icon"] && ![kind isEqualToString: @"Icon and Text"])
				{
					NSPrintErr(@"Error: Invalid status item kind '%@'", kind);
					exit(1);
				}
				[appSpec setProperty: kind forKey: @"StatusItemDisplayType"];
			}
			break;
			
			// set title of status item for Status Menu output
			case 'Y':
			{
				NSString *title = [NSString stringWithCString: optarg];
				if ([title isEqualToString:@""] || title == NULL)
				{
					NSPrintErr(@"Error: Empty status item title");
					exit(1);
				}
				[appSpec setProperty: title forKey: @"StatusItemTitle"];
			}
			break;
			
			// set icon image of status item for Status Menu output
			case 'L':
			{
				NSString *iconPath = [[NSString stringWithCString: optarg] stringByExpandingTildeInPath];
				if (![fm fileExistsAtPath: iconPath])
				{
					NSPrintErr(@"Error: No image file exists at path '%@'", iconPath);
					exit(1);
				}
				
				// read image from file
				NSImage *iconImage = [[[NSImage alloc] initWithContentsOfFile: iconPath] autorelease];
				if (iconImage == NULL)
				{
					NSPrintErr(@"Error: Unable to get image from file '%@'", iconPath);
					exit(1);
				}
				// make sure it's 16x16 pixels
				NSSize imgSize = [iconImage size];
				if (imgSize.width != 16 || imgSize.height != 16)
				{
					NSPrintErr(@"Error: Dimensions of image '%@' is not 16x16", iconPath);
					exit(1);
				}
				[appSpec setProperty: [iconImage TIFFRepresentation] forKey: @"StatusItemIcon"];
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
	
	if (argc - optind < 1) //  application/profile destination must follow
    {
        NSPrintErr(@"Error: Too few arguments.");
        PrintUsage();
        exit(1);
    }
			
	//get application destination parameter and make it an absolute path
	NSString *destPath = [[NSString stringWithCString: argv[optind]] stringByStandardizingPath];
	if (destPath == NULL)
	{
		NSPrintErr(@"Error: Missing parameter: Destination Path");
		PrintUsage();
		exit(1);
	}
	
	if ([destPath isAbsolutePath] == NO)
		destPath = [[fm currentDirectoryPath] stringByAppendingPathComponent: destPath];
	
	// at this stage we're either creating an app or a profile
	if (createProfile)
	{
		// since it's a profile, we dump the profile dictionary
		if (![destPath hasSuffix: PROFILES_SUFFIX])
		{
			NSPrintErr(@"Error: Profile destination filename must have '%@' suffix", PROFILES_SUFFIX);
			exit(1);
		}
		[appSpec dump: destPath];
	}
	else
	{
		// insert the app destination path into spec
		[appSpec setProperty: destPath forKey: @"Destination"];
			
		// create the app from spec
		if (![appSpec verify] || ![appSpec create])
		{
			NSPrintErr(@"Error: %@", [appSpec error]);
			exit(1);
		}
	}
			
    [pool release];
	
	return 0;
}

#pragma mark -

////////////////////////////////////////
// Print version and author to stdout
///////////////////////////////////////

static void PrintVersion (void)
{
    NSPrint(@"%@ version %@ by %@", CMDLINE_PROGNAME, PROGRAM_VERSION, PROGRAM_AUTHOR);
}

////////////////////////////////////////
// Print usage string to stdout
///////////////////////////////////////

static void PrintUsage (void)
{
    NSPrint(@"usage: %@ [-vh] [-O profile] [-FASDBR] [-ydlH] [-KYL] [-P profile] [-a appName] [-c scriptPath] [-o outputType] [-i icon] [-p interpreter] [-V version] [-u author] [-I identifier] [-f bundledFile] [-X suffixes] [-T filetypes] [-G interpreterArgs] [-U arch] destinationPath", CMDLINE_PROGNAME);
}

////////////////////////////////////////
// Print help string to stdout
///////////////////////////////////////

static void PrintHelp (void)
{
	NSPrint(@"%@ - command line application wrapper generator for scripts", CMDLINE_PROGNAME);
	PrintVersion();
    PrintUsage();
	printf("\n\
Options:\n\
	-O			Generate a profile instead of an app\n\
\n\
	-P [profile]		Load settings from profile file\n\
	-a [name]		Set name of application bundle\n\
	-o [type]		Set output type.  See man page for accepted types\n\
	-c [script]		Set script for application\n\
	-p [interpreter]	Set interpreter for script\n\
\n\
	-i [icon]		Set icon for application\n\
	-u [author]		Set name of application author\n\
	-V [version]		Set version of application\n\
	-I [identifier]		Set bundle identifier (i.e. org.yourname.appname)\n\
\n\
	-F			Script receives path to app as first argument\n\
	-A			App runs with Administrator privileges\n\
	-S			Secure bundled script\n\
	-D			App accepts dropped files as argument to script\n\
	-B			App runs in background (LSUI Element)\n\
	-R			App remains running after executing script\n\
\n\
	-b [hexColor]		Set background color of text output (e.g. #ffffff)\n\
	-g [hexColor]		Set foreground color of text output (e.g. #000000)\n\
	-n [fontName]		Set font for text output field (e.g. 'Monaco 10')\n\
	-E [encoding]		Set text encoding for script output (see man page)\n\
	-X [suffixes]		Set suffixes handled by application\n\
	-T [filetypes]		Set file type codes handled by application\n\
	-G [arguments]		Set arguments for script interpreter\n\
\n\
	-K [kind]		Set Status Item kind ('Icon','Text', 'Icon and Text')\n\
	-Y [title]		Set title of Status Item\n\
	-L [image]		Set icon of Status Item\n\
\n\
	-f [file]		Add a bundled file\n\
\n\
	-y			Force mode.  Overwrite any files/folders in path\n\
	-d			Development version.  Symlink to script instead of copying\n\
	-l			Optimize application.  Strip and compile bundled nib file\n\
	-H [nib]		Specify alternate nib file to bundle with app\n\
	-U [arch]		Specify architecture of app (i.e. 'i386' or 'ppc')\n\
\n\
	-h			Prints help\n\
	-v			Prints program name, version and author\n\
\n");
}

#pragma mark -

void NSPrint (NSString *format, ...)
{
    va_list args;
	
    va_start (args, format);
	
    NSString *string;
	
    string = [[NSString alloc] initWithFormat: format  arguments: args];
	
    va_end (args);
	
	fprintf(stdout, "%s\n", [string UTF8String]);
	
    [string release];	
}

void NSPrintErr (NSString *format, ...)
{
    va_list args;
	
    va_start (args, format);
	
    NSString *string;
	
    string = [[NSString alloc] initWithFormat: format  arguments: args];
	
    va_end (args);
	
    fprintf(stderr, "%s\n", [string UTF8String]);
	
    [string release];
	
} 
