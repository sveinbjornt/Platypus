/*
Copyright (c) 2003-2015, Sveinbjorn Thordarson <sveinbjornt@gmail.com
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of the FreeBSD Project.
 */

// General definitions file with various application-wide settings/information

// General program information
#define PROGRAM_NAME                @ "Platypus"
#define PROGRAM_VERSION             @ "4.9.1"
#define PROGRAM_STAMP               [NSString stringWithFormat:@"%@-%@", PROGRAM_NAME, PROGRAM_VERSION]
#define PROGRAM_MIN_SYS_VERSION     @ "10.6.0"
#define PROGRAM_BUNDLE_IDENTIFIER   [NSString stringWithFormat:@"org.sveinbjorn.%@", PROGRAM_NAME]
#define PROGRAM_AUTHOR              @ "Sveinbjorn Thordarson"
#define PROGRAM_WEBSITE             @ "http://sveinbjorn.org/platypus"
#define PROGRAM_DONATIONS           @ "http://sveinbjorn.org/donations"

// Application support folder info
#define APP_SUPPORT_FOLDER          [@ "~/Library/Application Support/Platypus/" stringByExpandingTildeInPath]
#define TEMP_FOLDER                 [@ "~/Library/Application Support/Platypus/Temp" stringByExpandingTildeInPath]
#define PROFILES_FOLDER             [@ "~/Library/Application Support/Platypus/Profiles" stringByExpandingTildeInPath]
#define EXAMPLES_FOLDER             "./Examples/"
#define PROFILES_SUFFIX             @ "platypus"
#define TEMP_ICON_PATH              [NSString stringWithFormat : @ "%@/TmpIcon.icns", APP_SUPPORT_FOLDER]

// default output text settings
#define DEFAULT_OUTPUT_FONT         @ "Monaco"
#define DEFAULT_OUTPUT_FONTSIZE     13.0
#define DEFAULT_OUTPUT_FG_COLOR     @ "#000000"
#define DEFAULT_OUTPUT_BG_COLOR     @ "#ffffff"
#define DEFAULT_OUTPUT_TXT_ENCODING NSUTF8StringEncoding

#define PROGRAM_MAX_LIST_ITEMS      65535

// documentation
#define PROGRAM_README_FILE         @ "Readme.html"
#define PROGRAM_MANPAGE             @ "platypus.man.html"
#define PROGRAM_DOCUMENTATION       @ "Documentation.html"
#define PROGRAM_LICENSE_FILE        @ "License.html"
#define PROGRAM_EXAMPLES_FOLDER     @ "/Examples/"

// command line tool seetings
#define CMDLINE_PROGNAME_IN_BUNDLE  @ "platypus_clt"
#define CMDLINE_PROGNAME            @ "platypus"
#define CMDLINE_SCRIPTEXEC_BIN_NAME @ "ScriptExec"
#define CMDLINE_DEFAULT_ICON_NAME   @ "PlatypusDefault.icns"
#define CMDLINE_NIB_NAME            @ "MainMenu.nib"
#define CMDLINE_BASE_INSTALL_PATH   @ "/usr/local"
#define CMDLINE_BIN_PATH            [NSString stringWithFormat:@"%@/bin", CMDLINE_BASE_INSTALL_PATH]
#define CMDLINE_TOOL_PATH           [NSString stringWithFormat:@"%@/%@", CMDLINE_BIN_PATH, CMDLINE_PROGNAME]
#define CMDLINE_SHARE_PATH          [NSString stringWithFormat:@"%@/share/%@", CMDLINE_BASE_INSTALL_PATH, CMDLINE_PROGNAME]
#define CMDLINE_VERSION_PATH        [NSString stringWithFormat:@"%@/Version", CMDLINE_SHARE_PATH]
#define CMDLINE_MANDIR_PATH         [NSString stringWithFormat:@"%@/share/man/man1", CMDLINE_BASE_INSTALL_PATH]
#define CMDLINE_MANPAGE_PATH        [NSString stringWithFormat:@"%@/%@.1", CMDLINE_MANDIR_PATH, CMDLINE_PROGNAME]
#define CMDLINE_EXEC_PATH           [NSString stringWithFormat:@"%@/%@", CMDLINE_SHARE_PATH, CMDLINE_SCRIPTEXEC_BIN_NAME]
#define CMDLINE_NIB_PATH            [NSString stringWithFormat:@"%@/%@", CMDLINE_SHARE_PATH, CMDLINE_NIB_NAME]
#define CMDLINE_SCRIPT_EXEC_PATH    [NSString stringWithFormat:@"%@/%@", CMDLINE_SHARE_PATH, CMDLINE_SCRIPTEXEC_BIN_NAME]
#define CMDLINE_ICON_PATH           [NSString stringWithFormat:@"%@/%@", CMDLINE_SHARE_PATH, CMDLINE_DEFAULT_ICON_NAME]

#define IBTOOL_PATH                 @ "/Developer/usr/bin/ibtool"
#define IBTOOL_PATH_2               @ "/Applications/Xcode.app/Contents/Developer/usr/bin/ibtool"
#define LIPO_PATH                   @ "/usr/bin/lipo"

#define DEFAULT_EDITOR              @ "Built-In"
#define DEFAULT_INTERPRETER         @ "/bin/sh"
#define DEFAULT_VERSION             @ "1.0"
#define DEFAULT_ROLE                @ "Viewer"
#define DEFAULT_STATUSITEM_DTYPE    @ "Text"
#define DEFAULT_APP_NAME            @ "MyPlatypusApp"
#define DEFAULT_DESTINATION_PATH    [[NSString stringWithFormat : @ "~/Desktop/%@.app", DEFAULT_APP_NAME] stringByExpandingTildeInPath]
#define DEFAULT_OUTPUT_TYPE         @ "Progress Bar"
#define DEFAULT_BUNDLE_ID           [PlatypusAppSpec standardBundleIdForAppName:DEFAULT_APP_NAME usingDefaults:NO]

// output modes
#define PLATYPUS_NONE_OUTPUT                1
#define PLATYPUS_PROGRESSBAR_OUTPUT         2
#define PLATYPUS_TEXTWINDOW_OUTPUT          3
#define PLATYPUS_WEBVIEW_OUTPUT             4
#define PLATYPUS_STATUSMENU_OUTPUT          5
#define PLATYPUS_DROPLET_OUTPUT             6

// execution style
#define PLATYPUS_NORMAL_EXECUTION           0
#define PLATYPUS_PRIVILEGED_EXECUTION       1

// path to temp script file
#define TMP_STDIN_PATH                      @ "/tmp/.plstdin.XXXXXX"
#define TMP_ICON_PATH                       @ "/tmp/PlatypusIcon.icns"

// this is surely enough
#define PLATYPUS_MAX_QUEUE_JOBS             255

// array of output types, used for validation
#define PLATYPUS_OUTPUT_TYPES       [NSArray arrayWithObjects:\
@ "None", \
@ "Progress Bar", \
@ "Text Window", \
@ "Web View", \
@ "Droplet", \
@ "Status Menu", \
nil]

#pragma mark -

// code abbreviations, Obj-C is a tediously verbose language
#define FILEMGR                     [NSFileManager defaultManager]
#define DEFAULTS                    [NSUserDefaults standardUserDefaults]

#ifdef DEBUG
    #define DLog(...) NSLog(__VA_ARGS__)
#endif

