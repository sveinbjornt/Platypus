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

// General program information
#define PROGRAM_NAME                @"Platypus"
#define PROGRAM_VERSION             @"5.1"
#define PROGRAM_CREATOR_STAMP       [NSString stringWithFormat:@"%@-%@", PROGRAM_NAME, PROGRAM_VERSION]
#define PROGRAM_MIN_SYS_VERSION     @"10.7.0"
#define PROGRAM_BUNDLE_IDENTIFIER   [NSString stringWithFormat:@"org.sveinbjorn.%@", PROGRAM_NAME]
#define PROGRAM_AUTHOR              @"Sveinbjorn Thordarson"
#define PROGRAM_WEBSITE             @"http://sveinbjorn.org/platypus"
#define PROGRAM_GITHUB_WEBSITE      @"http://github.com/sveinbjornt/Platypus"
#define PROGRAM_DONATIONS           @"http://sveinbjorn.org/donations"
#define PROGRAM_PROFILE_UTI         @"org.sveinbjorn.platypus-profile"
#define PROGRAM_PROFILE_SUFFIX      @"platypus"
#define PROGRAM_README_FILE         @"Readme.html"
#define PROGRAM_MANPAGE             @"platypus.man.html"
#define PROGRAM_LICENSE_FILE        @"License.html"
#define PROGRAM_DOCUMENTATION       @"Documentation.html"
#define PROGRAM_MANPAGE_URL         @"http://sveinbjorn.org/files/manpages/platypus.man.html"
#define PROGRAM_DOCUMENTATION_URL   @"http://sveinbjorn.org/files/manpages/PlatypusDocumentation.html"
#define PROGRAM_DOCUMENTATION_DROP_SETTINGS_URL [NSString stringWithFormat:@"%@#41",PROGRAM_DOCUMENTATION_URL]
#define PROGRAM_DOCUMENTATION_ARGS_SETTINGS_URL [NSString stringWithFormat:@"%@#22",PROGRAM_DOCUMENTATION_URL]

// Folders
#define APP_SUPPORT_FOLDER          [@"~/Library/Application Support/Platypus/" stringByExpandingTildeInPath]
#define TEMP_FOLDER                 [NSString stringWithFormat:@"%@/", APP_SUPPORT_FOLDER]
#define PROFILES_FOLDER             [NSString stringWithFormat:@"%@/Profiles", APP_SUPPORT_FOLDER]
#define EXAMPLES_FOLDER             [NSString stringWithFormat:@"%@/Examples/", [[NSBundle mainBundle] resourcePath]]

#define NEW_SCRIPT_FILENAME         @"Script"

// Default text settings
#define DEFAULT_OUTPUT_FONT         @"Monaco"
#define DEFAULT_OUTPUT_FONTSIZE     13.0
#define DEFAULT_OUTPUT_FG_COLOR     @"#000000"
#define DEFAULT_OUTPUT_BG_COLOR     @"#ffffff"
#define DEFAULT_OUTPUT_TXT_ENCODING NSUTF8StringEncoding

// Command line tool seetings
#define CMDLINE_PROGNAME_IN_BUNDLE  @"platypus_clt"
#define CMDLINE_PROGNAME            @"platypus"
#define CMDLINE_SCRIPTEXEC_BIN_NAME @"ScriptExec"
#define CMDLINE_DEFAULT_ICON_NAME   @"PlatypusDefault.icns"
#define CMDLINE_NIB_NAME            @"MainMenu.nib"
#define CMDLINE_VERSION_ARG_FLAG    "version"
#define CMDLINE_BASE_INSTALL_PATH   @"/usr/local"
#define CMDLINE_BIN_PATH            [NSString stringWithFormat:@"%@/bin", CMDLINE_BASE_INSTALL_PATH]
#define CMDLINE_TOOL_PATH           [NSString stringWithFormat:@"%@/%@", CMDLINE_BIN_PATH, CMDLINE_PROGNAME]
#define CMDLINE_SHARE_PATH          [NSString stringWithFormat:@"%@/share/%@", CMDLINE_BASE_INSTALL_PATH, CMDLINE_PROGNAME]
#define CMDLINE_MANDIR_PATH         [NSString stringWithFormat:@"%@/share/man/man1", CMDLINE_BASE_INSTALL_PATH]
#define CMDLINE_MANPAGE_PATH        [NSString stringWithFormat:@"%@/%@.1", CMDLINE_MANDIR_PATH, CMDLINE_PROGNAME]
#define CMDLINE_EXEC_PATH           [NSString stringWithFormat:@"%@/%@", CMDLINE_SHARE_PATH, CMDLINE_SCRIPTEXEC_BIN_NAME]
#define CMDLINE_NIB_PATH            [NSString stringWithFormat:@"%@/%@", CMDLINE_SHARE_PATH, CMDLINE_NIB_NAME]
#define CMDLINE_SCRIPT_EXEC_PATH    [NSString stringWithFormat:@"%@/%@", CMDLINE_SHARE_PATH, CMDLINE_SCRIPTEXEC_BIN_NAME]
#define CMDLINE_ICON_PATH           [NSString stringWithFormat:@"%@/%@", CMDLINE_SHARE_PATH, CMDLINE_DEFAULT_ICON_NAME]
#define CMDLINE_ARG_SEPARATOR       @"|"

#define IBTOOL_PATH                 @"/Applications/Xcode.app/Contents/Developer/usr/bin/ibtool"

#define DEFAULT_EDITOR              @"Built-In"
#define DEFAULT_INTERPRETER         @"/bin/sh"
#define DEFAULT_VERSION             @"1.0"
#define DEFAULT_APP_NAME            @"PlatypusApp"
#define DEFAULT_DESTINATION_PATH    [[NSString stringWithFormat:@"~/Desktop/%@.app", DEFAULT_APP_NAME] stringByExpandingTildeInPath]
#define DEFAULT_SCRIPT_TYPE         @"Shell"
#define DEFAULT_SUFFIXES            @[]
#define DEFAULT_UTIS                @[(NSString *)kUTTypeItem, (NSString *)kUTTypeFolder]
#define DEFAULT_STATUS_ITEM_TITLE   @"Title"

#define EDITOR_FONT                 [NSFont userFixedPitchFontOfSize:13.0]
#define SHELL_COMMAND_STRING_FONT   [NSFont userFixedPitchFontOfSize:11.0]

// notifications
#define PLATYPUS_APP_SPEC_CREATION_NOTIFICATION     @"PlatypusAppSpecCreationNotification"
#define PLATYPUS_APP_SIZE_CHANGED_NOTIFICATION      @"PlatypusAppSizeChangedNotification"

// path to temp script file
#define TMP_STDIN_PATH              @"/tmp/.platypus_stdin.XXXXXX"

// status item display types
#define PLATYPUS_STATUSITEM_DISPLAY_TYPE_TEXT @"Text"
#define PLATYPUS_STATUSITEM_DISPLAY_TYPE_ICON @"Icon"
#define PLATYPUS_STATUSITEM_DISPLAY_TYPE_DEFAULT PLATYPUS_STATUSITEM_DISPLAY_TYPE_TEXT

// execution style
typedef enum PlatypusExecStyle {
    PLATYPUS_EXECSTYLE_NORMAL = 0,
    PLATYPUS_EXECSTYLE_PRIVILEGED = 1
} PlatypusExecStyle;

// output modes
typedef enum PlatypusOutputType {
    PLATYPUS_OUTPUT_NONE = 0,
    PLATYPUS_OUTPUT_PROGRESSBAR = 1,
    PLATYPUS_OUTPUT_TEXTWINDOW = 2,
    PLATYPUS_OUTPUT_WEBVIEW = 3,
    PLATYPUS_OUTPUT_STATUSMENU = 4,
    PLATYPUS_OUTPUT_DROPLET = 5
} PlatypusOutputType;

// execution style
typedef enum PlatypusStatusItemStyle {
    PLATYPUS_STATUS_ITEM_STYLE_TITLE = 0,
    PLATYPUS_STATUS_ITEM_STYLE_ICON = 1
} PlatypusStatusItemStyle;

#define PLATYPUS_OUTPUT_STRING_NONE             @"None"
#define PLATYPUS_OUTPUT_STRING_PROGRESS_BAR     @"Progress Bar"
#define PLATYPUS_OUTPUT_STRING_TEXT_WINDOW      @"Text Window"
#define PLATYPUS_OUTPUT_STRING_WEB_VIEW         @"Web View"
#define PLATYPUS_OUTPUT_STRING_STATUS_MENU      @"Status Menu"
#define PLATYPUS_OUTPUT_STRING_DROPLET          @"Droplet"

#define DEFAULT_OUTPUT_TYPE                     PLATYPUS_OUTPUT_STRING_TEXT_WINDOW

// array of output types, used for validation
#define PLATYPUS_OUTPUT_TYPE_NAMES   @[\
    PLATYPUS_OUTPUT_STRING_NONE, \
    PLATYPUS_OUTPUT_STRING_PROGRESS_BAR, \
    PLATYPUS_OUTPUT_STRING_TEXT_WINDOW, \
    PLATYPUS_OUTPUT_STRING_WEB_VIEW, \
    PLATYPUS_OUTPUT_STRING_STATUS_MENU, \
    PLATYPUS_OUTPUT_STRING_DROPLET, \
]

#pragma mark - Output type macros

#define IsTextStyledOutputType(X) ( X == PLATYPUS_OUTPUT_PROGRESSBAR || \
                                    X == PLATYPUS_OUTPUT_TEXTWINDOW || \
                                    X == PLATYPUS_OUTPUT_STATUSMENU  )

#define IsTextStyledOutputTypeString(X)  (  [X isEqualToString:PLATYPUS_OUTPUT_STRING_PROGRESS_BAR] || \
                                            [X isEqualToString:PLATYPUS_OUTPUT_STRING_TEXT_WINDOW] || \
                                            [X isEqualToString:PLATYPUS_OUTPUT_STRING_STATUS_MENU]  )

#define IsTextSizableOutputType(X) (X == PLATYPUS_OUTPUT_PROGRESSBAR || \
                                    X == PLATYPUS_OUTPUT_TEXTWINDOW || \
                                    X == PLATYPUS_OUTPUT_WEBVIEW  )

#define IsTextViewScrollableOutputType(X) ( X == PLATYPUS_OUTPUT_PROGRESSBAR || \
                                            X == PLATYPUS_OUTPUT_TEXTWINDOW )

#pragma mark - App Spec keys

#define APPSPEC_KEY_CREATOR                 @"Creator"
#define APPSPEC_KEY_EXECUTABLE_PATH         @"ExecutablePath"
#define APPSPEC_KEY_NIB_PATH                @"NibPath"
#define APPSPEC_KEY_DESTINATION_PATH        @"Destination"
#define APPSPEC_KEY_OVERWRITE               @"DestinationOverride"
#define APPSPEC_KEY_SYMLINK_FILES           @"DevelopmentVersion"
#define APPSPEC_KEY_STRIP_NIB               @"OptimizeApplication"
#define APPSPEC_KEY_XML_PLIST_FORMAT        @"UseXMLPlistFormat"
#define APPSPEC_KEY_NAME                    @"Name"
#define APPSPEC_KEY_SCRIPT_PATH             @"ScriptPath"
#define APPSPEC_KEY_INTERFACE_TYPE          @"Output"
#define APPSPEC_KEY_ICON_PATH               @"IconPath"
#define APPSPEC_KEY_INTERPRETER             @"Interpreter" // ATH
#define APPSPEC_KEY_INTERPRETER_ARGS        @"InterpreterArgs"
#define APPSPEC_KEY_SCRIPT_ARGS             @"ScriptArgs"
#define APPSPEC_KEY_VERSION                 @"Version"
#define APPSPEC_KEY_IDENTIFIER              @"Identifier"
#define APPSPEC_KEY_AUTHOR                  @"Author"

#define APPSPEC_KEY_DROPPABLE               @"Droppable"
#define APPSPEC_KEY_SECURE                  @"Secure"
#define APPSPEC_KEY_AUTHENTICATE            @"Authentication"
#define APPSPEC_KEY_REMAIN_RUNNING          @"RemainRunning"  // ATH
#define APPSPEC_KEY_RUN_IN_BACKGROUND       @"ShowInDock"

#define APPSPEC_KEY_BUNDLED_FILES           @"BundledFiles"

#define APPSPEC_KEY_SUFFIXES                @"Suffixes"
#define APPSPEC_KEY_UTIS                    @"UniformTypes"
#define APPSPEC_KEY_ACCEPT_TEXT             @"AcceptsText"
#define APPSPEC_KEY_ACCEPT_FILES            @"AcceptsFiles"
#define APPSPEC_KEY_SERVICE                 @"DeclareService"
#define APPSPEC_KEY_PROMPT_FOR_FILE         @"PromptForFileOnLaunch"
#define APPSPEC_KEY_DOC_ICON_PATH           @"DocIcon"

#define APPSPEC_KEY_TEXT_ENCODING           @"TextEncoding"
#define APPSPEC_KEY_TEXT_FONT               @"TextFont"
#define APPSPEC_KEY_TEXT_SIZE               @"TextSize"
#define APPSPEC_KEY_TEXT_COLOR              @"TextForeground"
#define APPSPEC_KEY_TEXT_BGCOLOR            @"TextBackground"

#define APPSPEC_KEY_STATUSITEM_DISPLAY_TYPE @"StatusItemDisplayType"
#define APPSPEC_KEY_STATUSITEM_TITLE        @"StatusItemTitle"
#define APPSPEC_KEY_STATUSITEM_ICON         @"StatusItemIcon"
#define APPSPEC_KEY_STATUSITEM_USE_SYSFONT  @"StatusItemUseSystemFont" // ATH

// examples only
#define APPSPEC_KEY_IS_EXAMPLE              @"Example"
#define APPSPEC_KEY_SCRIPT_TEXT             @"Script"
#define APPSPEC_KEY_SCRIPT_NAME             @"ScriptName"

#pragma mark - Abbreviations

// abbreviations, Obj-C is sometimes tediously verbose
#define FILEMGR     [NSFileManager defaultManager]
#define DEFAULTS    [NSUserDefaults standardUserDefaults]
#define WORKSPACE   [NSWorkspace sharedWorkspace]

#pragma mark - Logging

#ifdef DEBUG
    #define PLog(...) NSLog(__VA_ARGS__)
#else
    #define PLog(...)
#endif
