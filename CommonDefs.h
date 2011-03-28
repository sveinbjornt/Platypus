/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C) 2003-2010 Sveinbjorn Thordarson <sveinbjornt@simnet.is>

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

// General definitions file with various application-wide settings/information

// General program information
#define	PROGRAM_STAMP				@"Platypus-4.5"
#define PROGRAM_NAME				@"Platypus"
#define PROGRAM_VERSION				@"4.5"
#define PROGRAM_MIN_SYS_VERSION		@"10.4"
#define PROGRAM_AUTHOR				@"Sveinbjorn Thordarson"
#define PROGRAM_WEBSITE				@"http://sveinbjorn.org/platypus"
#define PROGRAM_DONATIONS			@"http://sveinbjorn.org/donations"

// Application support folder info
#define	APP_SUPPORT_FOLDER			@"~/Library/Application Support/Platypus/"
#define TEMP_FOLDER					@"~/Library/Application Support/Platypus/Temp"
#define PROFILES_FOLDER				@"~/Library/Application Support/Platypus/Profiles"
#define PROFILES_SUFFIX				@"platypus"

// default output text settings
#define DEFAULT_OUTPUT_FONT			@"Monaco"
#define DEFAULT_OUTPUT_FONTSIZE		10.0
#define DEFAULT_OUTPUT_FG_COLOR		@"#000000"
#define DEFAULT_OUTPUT_BG_COLOR		@"#ffffff"
#define DEFAULT_OUTPUT_TXT_ENCODING	NSUTF8StringEncoding

#define PROGRAM_MAX_LIST_ITEMS		255


// documentation
#define PROGRAM_README_FILE			@"Readme.html"
#define PROGRAM_MANPAGE				@"platypus.man.pdf"
#define PROGRAM_DOCUMENTATION		@"PlatypusDocumentation.html"
#define PROGRAM_LICENSE_FILE		@"License.txt"

// command line tool seetings
#define CMDLINE_PROGNAME			@"platypus"
#define CMDLINE_TOOL_PATH			@"/usr/local/bin/platypus"
#define CMDLINE_SHARE_PATH			@"/usr/local/share/platypus/"
#define CMDLINE_VERSION_PATH		@"/usr/local/share/platypus/Version"
#define CMDLINE_MANPAGE_PATH		@"/usr/local/share/man/man1/platypus.1"
#define	CMDLINE_EXEC_PATH			@"/usr/local/share/platypus/ScriptExec"
#define CMDLINE_NIB_PATH			@"/usr/local/share/platypus/MainMenu.nib"
#define CMDLINE_ICON_PATH			@"/usr/local/share/platypus/PlatypusDefault.icns"


#define TMP_DRAGGED_ICON_PATH		@"/tmp/PlatypusIcon.icns"
#define IBTOOL_PATH					@"/Developer/usr/bin/ibtool"
#define LIPO_TOOL_PATH				@"/usr/bin/lipo"

#define DEFAULT_EDITOR				@"Built-In"
#define DEFAULT_DESTINATION_PATH	@"~/Desktop/MyApp.app"
#define DEFAULT_OUTPUT_TYPE			@"Progress Bar"
#define DEFAULT_ARCHITECTURE		@"Universal"

// output modes
#define	PLATYPUS_NONE_OUTPUT				1
#define	PLATYPUS_PROGRESSBAR_OUTPUT			2
#define	PLATYPUS_TEXTWINDOW_OUTPUT			3
#define PLATYPUS_WEBVIEW_OUTPUT				4
#define PLATYPUS_STATUSMENU_OUTPUT			5
#define PLATYPUS_DROPLET_OUTPUT				6

// execution style
#define PLATYPUS_NORMAL_EXECUTION			0
#define PLATYPUS_PRIVILEGED_EXECUTION		1

// path to temp script file
#define TMP_SCRIPT_TEMPLATE					@".plx_tmp.XXXXXX"

// this is surely enough
#define PLATYPUS_MAX_QUEUE_JOBS				256

