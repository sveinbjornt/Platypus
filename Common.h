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

// General program information
#define PROGRAM_NAME                @"Platypus"
#define PROGRAM_VERSION             @"5.3"
#define PROGRAM_CREATOR_STAMP       [NSString stringWithFormat:@"%@-%@", PROGRAM_NAME, PROGRAM_VERSION]
#define PROGRAM_MIN_SYS_VERSION     @"10.8.0"
#define PROGRAM_BUNDLE_IDENTIFIER   [NSString stringWithFormat:@"org.sveinbjorn.%@", PROGRAM_NAME]
#define PROGRAM_AUTHOR              @"Sveinbjorn Thordarson"
#define PROGRAM_WEBSITE             @"http://sveinbjorn.org/platypus"
#define PROGRAM_GITHUB_WEBSITE      @"http://github.com/sveinbjornt/Platypus"
#define PROGRAM_DONATIONS           @"http://sveinbjorn.org/donations"
#define PROGRAM_PROFILE_UTI         @"org.sveinbjorn.platypus.profile"
#define PROGRAM_PROFILE_SUFFIX      @"platypus"
#define PROGRAM_MANPAGE             @"platypus.man.html"
#define PROGRAM_LICENSE_FILE        @"License.html"
#define PROGRAM_DOCUMENTATION       @"Documentation.html"
#define PROGRAM_MANPAGE_URL         @"http://sveinbjorn.org/files/manpages/platypus.man.html"
#define PROGRAM_DOCUMENTATION_URL   @"http://sveinbjorn.org/files/manpages/PlatypusDocumentation.html"
#define PROGRAM_UTI_INFORMATION_URL @"https://en.wikipedia.org/wiki/Uniform_Type_Identifier"

// Folders
#define PROGRAM_APP_SUPPORT_PATH    [[NSString stringWithFormat:@"~/Library/Application Support/%@/", PROGRAM_NAME] stringByExpandingTildeInPath]
#define PROGRAM_TEMPDIR_PATH        [NSString stringWithFormat:@"%@/", PROGRAM_APP_SUPPORT_PATH]
#define PROGRAM_PROFILES_PATH       [NSString stringWithFormat:@"%@/Profiles", PROGRAM_APP_SUPPORT_PATH]
#define PROGRAM_EXAMPLES_PATH       [NSString stringWithFormat:@"%@/Examples/", [[NSBundle mainBundle] resourcePath]]

#define NEW_SCRIPT_FILENAME         @"Script"

// Command line tool seetings
#define CMDLINE_PROGNAME_BUNDLE     @"platypus_clt.gz"
#define CMDLINE_PROGNAME            @"platypus"
#define CMDLINE_SCRIPTEXEC_BIN_NAME @"ScriptExec"
#define CMDLINE_SCRIPTEXEC_GZIP_NAME @"ScriptExec.gz"
#define CMDLINE_MANPAGE_GZIP_NAME   @"platypus.1.gz"
#define CMDLINE_DEFAULT_ICON_NAME   @"PlatypusDefault.icns"
#define CMDLINE_NIB_NAME            @"MainMenu.nib"
#define CMDLINE_VERSION_ARG_FLAG    @"--version"
#define CMDLINE_BASE_INSTALL_PATH   @"/usr/local"
#define CMDLINE_BIN_PATH            @"/usr/local/bin"
#define CMDLINE_TOOL_PATH           @"/usr/local/bin/platypus"
#define CMDLINE_SHARE_PATH          @"/usr/local/share/platypus"
#define CMDLINE_MANDIR_PATH         @"/usr/local/share/man/man1"
#define CMDLINE_MANPAGE_PATH        @"/usr/local/share/man/man1/platypus.1.gz"
#define CMDLINE_EXEC_PATH           @"/usr/local/share/platypus/ScriptExec"
#define CMDLINE_NIB_PATH            @"/usr/local/share/platypus/MainMenu.nib"
#define CMDLINE_SCRIPT_EXEC_PATH    @"/usr/local/share/platypus/ScriptExec"
#define CMDLINE_ICON_PATH           @"/usr/local/share/platypus/PlatypusDefault.icns"
#define CMDLINE_ARG_SEPARATOR       @"|"

#define IBTOOL_PATH                 [NSString stringWithFormat:@"%@/Contents/Developer/usr/bin/ibtool", [WORKSPACE fullPathForApplication:@"Xcode"]]
#define PERL_INTERPRETER_PATH       @"/usr/bin/perl"

#define APPBUNDLE_SUFFIX            @".app"
#define GZIP_SUFFIX                 @".gz"

#define DEFAULT_TEXT_FONT_NAME      @"Monaco"
#define DEFAULT_TEXT_FONT_SIZE      13.0
#define DEFAULT_TEXT_FG_COLOR       @"#000000"
#define DEFAULT_TEXT_BG_COLOR       @"#ffffff"
#define DEFAULT_TEXT_ENCODING       NSUTF8StringEncoding

#define DEFAULT_EDITOR              @"Built-In"
#define DEFAULT_INTERPRETER_PATH    @"/bin/sh"
#define DEFAULT_VERSION             @"1.0"
#define DEFAULT_APP_NAME            @"Application"
#define DEFAULT_DESTINATION_PATH    [[NSString stringWithFormat:@"~/Desktop/%@.app", DEFAULT_APP_NAME] stringByExpandingTildeInPath]
#define DEFAULT_SCRIPT_TYPE         @"Shell"
#define DEFAULT_SUFFIXES            @[]
#define DEFAULT_UTIS                @[(NSString *)kUTTypeItem, (NSString *)kUTTypeFolder]
#define DEFAULT_URI_PROTOCOLS       @[]
#define DEFAULT_STATUS_ITEM_TITLE   @"Title"

#define SHELL_COMMAND_STRING_FONT   [NSFont userFixedPitchFontOfSize:11.0]

// Notifications
#define PLATYPUS_APP_SPEC_CREATION_NOTIFICATION     @"PlatypusAppSpecCreationNotification"
#define PLATYPUS_APP_SIZE_CHANGED_NOTIFICATION      @"PlatypusAppSizeChangedNotification"

// Status Item display types
#define PLATYPUS_STATUSITEM_DISPLAY_TYPE_TEXT       @"Text"
#define PLATYPUS_STATUSITEM_DISPLAY_TYPE_ICON       @"Icon"
#define PLATYPUS_STATUSITEM_DISPLAY_TYPE_DEFAULT    PLATYPUS_STATUSITEM_DISPLAY_TYPE_TEXT

// Execution style
typedef enum PlatypusExecStyle {
    PlatypusExecStyle_Normal = 0,
    PlatypusExecStyle_Authenticated = 1
} PlatypusExecStyle;

// Status item style
typedef enum PlatypusStatusItemStyle {
    PlatypusStatusItemStyle_Title = 0,
    PlatypusStatusItemStyle_Icon = 1
} PlatypusStatusItemStyle;

// Interface type
typedef enum PlatypusInterfaceType {
    PlatypusInterfaceType_None = 0,
    PlatypusInterfaceType_ProgressBar = 1,
    PlatypusInterfaceType_TextWindow = 2,
    PlatypusInterfaceType_WebView = 3,
    PlatypusInterfaceType_StatusMenu = 4,
    PlatypusInterfaceType_Droplet = 5
} PlatypusInterfaceType;


// Array of interface type name strings
// mapped to PlatypusInterfaceType enum
#define PLATYPUS_INTERFACE_TYPE_NAMES   @[\
    @"None", \
    @"Progress Bar", \
    @"Text Window", \
    @"Web View", \
    @"Status Menu", \
    @"Droplet" \
]

#define DEFAULT_INTERFACE_TYPE          PlatypusInterfaceType_TextWindow

#define DEFAULT_INTERFACE_TYPE_STRING   PLATYPUS_INTERFACE_TYPE_NAMES[DEFAULT_INTERFACE_TYPE]

#define IsValidInterfaceType(X)         ( (X) >= 0 && (X) < [PLATYPUS_INTERFACE_TYPE_NAMES count] )

#define IsValidInterfaceTypeString(X)   [PLATYPUS_INTERFACE_TYPE_NAMES containsObject:(X)]

#define InterfaceTypeForString(X)       (PlatypusInterfaceType)[PLATYPUS_INTERFACE_TYPE_NAMES indexOfObject:(X)]

#define IsTextStyledInterfaceType(X)    (   (X) == PlatypusInterfaceType_ProgressBar || \
                                            (X) == PlatypusInterfaceType_TextWindow || \
                                            (X) == PlatypusInterfaceType_StatusMenu  )

#define IsTextStyledInterfaceTypeString(X)  IsTextStyledInterfaceType(InterfaceTypeForString(X))

#define IsTextSizableInterfaceType(X)   (   (X) == PlatypusInterfaceType_ProgressBar || \
                                            (X) == PlatypusInterfaceType_TextWindow || \
                                            (X) == PlatypusInterfaceType_WebView  )

#define IsTextViewScrollableInterfaceType(X) (  (X) == PlatypusInterfaceType_ProgressBar || \
                                                (X) == PlatypusInterfaceType_TextWindow )

// App Spec keys
extern NSString * const AppSpecKey_Creator;
extern NSString * const AppSpecKey_ExecutablePath;
extern NSString * const AppSpecKey_NibPath;
extern NSString * const AppSpecKey_DestinationPath;
extern NSString * const AppSpecKey_Overwrite;
extern NSString * const AppSpecKey_SymlinkFiles;
extern NSString * const AppSpecKey_StripNib;
extern NSString * const AppSpecKey_Name;
extern NSString * const AppSpecKey_ScriptPath;
extern NSString * const AppSpecKey_InterfaceType;
extern NSString * const AppSpecKey_IconPath;
extern NSString * const AppSpecKey_InterpreterPath;
extern NSString * const AppSpecKey_InterpreterArgs;
extern NSString * const AppSpecKey_ScriptArgs;
extern NSString * const AppSpecKey_Version;
extern NSString * const AppSpecKey_Identifier;
extern NSString * const AppSpecKey_Author;

extern NSString * const AppSpecKey_Droppable;
extern NSString * const AppSpecKey_Authenticate;
extern NSString * const AppSpecKey_RemainRunning;
extern NSString * const AppSpecKey_RunInBackground;

extern NSString * const AppSpecKey_BundledFiles;

extern NSString * const AppSpecKey_Suffixes;
extern NSString * const AppSpecKey_Utis;
extern NSString * const AppSpecKey_URISchemes;
extern NSString * const AppSpecKey_AcceptText;
extern NSString * const AppSpecKey_AcceptFiles;
extern NSString * const AppSpecKey_Service;
extern NSString * const AppSpecKey_PromptForFile;
extern NSString * const AppSpecKey_DocIconPath;

extern NSString * const AppSpecKey_TextFont;
extern NSString * const AppSpecKey_TextSize;
extern NSString * const AppSpecKey_TextColor;
extern NSString * const AppSpecKey_TextBackgroundColor;

extern NSString * const AppSpecKey_StatusItemDisplayType;
extern NSString * const AppSpecKey_StatusItemTitle;
extern NSString * const AppSpecKey_StatusItemIcon;
extern NSString * const AppSpecKey_StatusItemUseSysfont;
extern NSString * const AppSpecKey_StatusItemIconIsTemplate;

extern NSString * const AppSpecKey_IsExample; // examples only
extern NSString * const AppSpecKey_ScriptText; // examples only
extern NSString * const AppSpecKey_ScriptName; // examples only

extern NSString * const AppSpecKey_DocIconPath_Legacy; // legacy
extern NSString * const AppSpecKey_InterpreterPath_Legacy; // legacy
extern NSString * const AppSpecKey_InterfaceType_Legacy; // legacy
extern NSString * const AppSpecKey_RunInBackground_Legacy; // legacy

// NSUserDefaults keys for Platypus app
extern NSString * const DefaultsKey_BundleIdentifierPrefix;
extern NSString * const DefaultsKey_DefaultEditor;
extern NSString * const DefaultsKey_RevealApplicationWhenCreated;
extern NSString * const DefaultsKey_OpenApplicationWhenCreated;
extern NSString * const DefaultsKey_DefaultAuthor;
extern NSString * const DefaultsKey_SymlinkFiles;
extern NSString * const DefaultsKey_StripNib;
extern NSString * const DefaultsKey_EditorFontSize;
extern NSString * const DefaultsKey_EditorWordWrap;
extern NSString * const DefaultsKey_Launched;

// NSUserDefaults keys for ScriptExec app
extern NSString * const ScriptExecDefaultsKey_UserFontSize;
extern NSString * const ScriptExecDefaultsKey_ShowDetails;

// Abbreviations. Objective-C is often tediously verbose
#define FILEMGR     [NSFileManager defaultManager]
#define DEFAULTS    [NSUserDefaults standardUserDefaults]
#define WORKSPACE   [NSWorkspace sharedWorkspace]

// Logging
#ifdef DEBUG
    #define PLog(...) NSLog(__VA_ARGS__)
#else
    #define PLog(...)
#endif

// Prototypes
extern BOOL UTTypeIsValid(NSString *inUTI);
extern BOOL BundleIdentifierIsValid(NSString *bundleIdentifier);

