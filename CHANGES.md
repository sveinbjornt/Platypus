# TODO for future versions

* Use NSDictionaryController and bindings for all controls in main window and sub-controllers
* http://stackoverflow.com/questions/1276029/non-blocking-stdio
* Terminal output mode? https://github.com/migueldeicaza/SwiftTerm
* Use pseudo-ttys for line buffered output: http://stackoverflow.com/questions/12586555/controlling-an-interactive-command-line-utility-from-a-cocoa-app-trouble-with  --- Look at PseudoTTY class
* Refactor ScriptExec for clean view controller/task controller decoupling. It's currently a mess.
* Refactor status menu item menu generation from output to share code between ScriptExec and Platypus.app
* Find a way to support authenticated task termination
* New button-based interface type
* New OnChange Text Filter interface type
* Implement new Table View interface (CSV output?)
* Create Platypus tutorial videos, make them available online
* Overhaul the Services feature
* Embed MainMenu.nib in platypus CLT Mach-O binary instead of storing in /usr/local/share
* Fix issue with multiple AEOpen events for many opened files
* Async Status Menu script execution to prevent interface locking on main thread
* Fix broken file watching of script path
* Add syntax for Status Menu output mode that suppresses menu entirely
* Update FAQ to answer question wrt relative interpreter path / bundling own interpreter
* Update Applescript input example to Python, instead of Perl
* Create more automated tests for command line tool and document existing tests
* Harden CI testing for this old project
* Fix selection change when item is deleted from the Bundled Files List
* Make Status Menu from script generation non-blocking
* Upgrade Sparkle version
* Performance optimization in the app build process (precompiled nib)

## Version history

### For 5.4.2 - 24/04/2024

* Fixed bug where the argument settings window would lock up
* Better support for Dark Mode
* Platypus now requires macOS 10.13 or later

### For 5.4.1 - 22/10/2022

* Fixed signing issues

### For 5.4 - 03/09/2022

* Added native support for arm64 CPU architecture. Both Platypus and the apps it generates are now Universal ARM/Intel 64-bit binaries
* New application icon
* Status Menu submenu items can now be disabled with the DISABLED syntax
* Support relative interpreter path (i.e. relative to Resources directory)
* Support dark mode for text fields (inverts colors, changes dynamically when user switches interface modes)
* Command line tool no longer defaults to stripping nib file (requires explicit -y option)
* Enabled close button on windows, which now quit the app(s)
* Added standard Help Menu to ScriptExec apps (support for bundled help bundles)
* Added support for dynamically changing status item title and icon via STATUSTITLE and STATUSICON syntax
* Warn when non-existent file in bundled files list
* Command line tool now defaults to creating apps with no application icon
* Support for notifications is now an option, to prevent permission popups on Catalina and later
* Added Python 3 and Dart interpreter presets
* Platypus apps now hide (instead of disabling) Open and Open Recent menu items if they don't accept files
* Fixed issue with signing generated apps due to missing "APPL" CFBundleType
* Fixed nasty empty newline parsing bug
* Switched over to AGIconFamily for icon generation, reducing dependence on deprecated Carbon calls
* Resolved issue with text selection and dark mode in generated apps
* Improved drag and drop handling on Platypus main window
* Platypus now requires macOS 10.11 or later

### 5.3 - 25/11/2018

* First facelift in a decade: New application icons created by Drífa Líftóra
* Updated to support Mojave Dark Mode
* Added AWK, JavaScript and Node interpreter presets
* Added "REFRESH" command that clears text output buffer
* Added "DISABLED" menu item syntax for status menu interface
* Platypus and its command line tool binary are now code-signed. Generated applications remain unsigned, for obvious reasons
* Windows of generated applications are now larger, and centered on first launch
* Apps now try to make script executable (+x) on launch This may resolve certain issues with launching generated apps stored on network-mounted volumes
* Added Open With menu for items in Bundled Files list
* Fixed bug where Platypus would generate broken custom icns files from images
* Fixed buggy Uniform Type Identifier validation in command line tool
* Platypus now validates default bundle identifier in Preferences
* Removed broken System Profiler example
* Removed XML plist format feature
* Documentation overhauled, partially rewritten and moved to Markdown format
* An assortment of minor bug fixes
* Various minor interface improvements
* Reduced size of generated app binaries2
* Now requires macOS 10.8 or later


### 5.2 - 03/03/2017

* Platypus apps can now register as URI scheme handlers and receive opened URLs as arguments to script
* Platypus apps can now accept dragged URLs
* Platypus apps that accept dropped files now have an Open Recent menu
* New syntax to create submenus in Status Menu interface type
* Relative paths are now supported in Platypus Profiles, but only through manual editing. Platypus app and CLT still generate Profiles with absolute paths.
* Platypus now warns about about identical file names in bundled files
* Droplet apps now quit when their window is closed
* Updated and improved example profiles demonstrating new features
* Text in Platypus apps now has a minimum font size
* The Platypus Profile format has changed slightly in this version, but old formats can still be read
* Fixed annoying issue where status menu would render before receiving all script output
* Fixed performance issue with printing many lines to text window. It is now very fast again.
* Fixed issue where loading certain Example profiles would cause Platypus to crash
* Fixed bug where "Use as template" was shown when Status Item mode was "Text"
* Fixed bug where command line tool failed to infer app name from script filename, resulting in "(null).app"
* Fixed bug where files that had been moved were not colored red in Bundled Files list
* Fixed bug where valid menu items were disabled in Action menu
* Fixed issue with console spamming due to missing CFBundleTypeRole. Now always "Viewer".
* Fixed bug where text settings were not properly loaded by the GUI
* Fixed bug where bundling files with the -f flag didn't work in the command line tool
* Fixed issue where status menu settings would not be restored to defaults on clear
* Fixed bug where the command line tool would erroneously try to validate whole argument strings instead of individual UTI strings
* Fixed bug where suffix editing buttons remained enabled when they shouldn't be
* Got rid of text encoding settings. Platypus now uses UTF8 for everything, and you should too.
* Got rid of "Secure bundled script" option, which was useless bullshit anyway
* Fixed issue where main application window would not remember its last position
* Updated documentation & man page
* Various minor interface refinements


### 5.1 - 06/02/2016

* New Build All Examples feature
* ScriptExec windows now remember window size and position between launches
* Fixed issue where MainMenu.nib was stripped and thus not editable using XCode
* Smarter handling of dropped files via more intelligent methods to determine if a file is a script
* Fixed issue with window behaviour during resizing in Progress Bar interface
* Added new WebViewDroplet example which lists dropped files using HTML output
* Fixed critical issue with Web View interface type
* Automatic app name generation from script name now respects camelCase and strips whitespace
* Using NSString constants for NSUserDefault string keys
* clearAllFields method uses default spec to set controls
* Give image names for interface type and interpreter a filename prefix indicating family
* Added build script for cat2html
* Added support for multiple arguments to --bundled-file in command line tool via "|" separator
* Various minor UI improvements (button status in args & drop settings window)
* Now treating drop into STPathTextField like any other drop on window
* Editable type lists in drop settings are now click-editable like those in Args controller
* Output string "----\n" in Status Menu mode now creates menu separator item
* Uniform Type Identifiers and Application Bundle Identifiers are now validated
* New template processing option for Status Item icon
* Build script now generates sparkle hash
* More robust command line tool version checking
* Fixed issue where showing the Preferences window lagged due to icon fetching on main thread
* Args button title now shows the number of custom arguments that have been set
* UTIs are now used for default file types in Drop Settings (public.item and public.folder)
* Moved project over to ARC


### 5.0 - 29/11/2015

* Long GNU named params for command line tool, e.g. --some-option
* Fixed issue where ScriptExec quit before script output was parsed
* Add new examples Icns2Iconset, ImageResizer
* Integrated CFBundleVersion increment script into build process
* Updated keys in information property lists
* Added ALERT: example
* Added authenticated execution example
* Optimize Location: parsing for Web Interface
* Parsed commands are now removed from script text output
* Fixed bug where Status Item menu intermittently showed empty output
* New high res images for documentation
* Added example showing STATUSMENUICON: syntax in action
* Migrated source to modern Objective-C syntax (literals, properties etc.)
* Now using bindings for defaults
* Implemented UI stuff making clear that UTIs exclude suffixes
* Fixed issue where a status menu could display an empty menu if clicked repeatedly
* Use UTI methods instead of deprecated imageFileTypes
* Fixed issue where dropping text on an app wouldn't work with “Remain running after initial execution” off
* Symlinks now resolved when adding files to Bundled Files list
* Folder sizes are now calculated much faster (and asynchronously) when added to Bundled Files list
* Arguments window now highlights arguments and argument groups in command preview field
* New high resolution (1024x1024) icons
* Added ALERT:\.+ syntax, which triggers a modal alert dialog
* Author name argument is now used to generate default bundle identifier in command line tool
* Dropped text input (NSPboardText) is now passed to script via STDIN, not as an argument. This allows differentiation between dropped text snippets and dropped files in applications that are made to handle both.
* Fixed issue with generating icon from images on retina macs (IconFamily)
* Fixed issue with broken icon image alpha channels (IconFamily)
* Finder now refreshes display of overwritten applications
* Better error handling in file operations
* New retina icons in script type popup button
* No longer linking to Carbon framework
* CFBundleDevelopmentRegion in generated apps now declared using ISO code
* New default "Use system font" option for Status Menu interface
* New MENUITEMICON: syntax to set menu item icon in Status Menu interface type
* The built-in editor has been much enhanced, with line numbering, configurable text size, word wrap and other improvements
* Migrated from UKKqueue to VDKQueue and got all file system watching working properly again
* Uniform Type Identifiers (UTIs) are now supported in Drop Settings
* More examples
* Scripts can now send notifications to User Notification Center via the NOTIFICATION:* syntax
* New help buttons in main window and drop settings
* Previewing status item menu now shows actual script output instead of placeholder text
* Status menu items can now only have a title or an icon, not both, due to changes in Mac OS X
* Show Shell Command window now shows install status of command line tool
* Got rid of old, low-resolution preset icons
* New release build script
* Built with XCode 7 and now requires Mac OS X 10.7 or later and a 64-bit Intel system. Older versions continue to work just fine on 32-bit 10.6 systems, and version 4.4 still works on PowerPC. But it's time to leave the past behind. It's been 9 years since the last 32-bit Mac was released.
* Syntax checker window now shows the command invoked when checking script syntax
* App size estimation is now more accurate
* New contexual menu button for icon view
* "Copy icon path" option in icon contextual menu
* Modernization of user interface elements
* Proper icon temp file handling
* New retina-quality default status menu icon
* Fixed issue with Open... menu item and file types in ScriptExec
* Font size in web views can now also be increased/reduced
* Revised and updated documentation
* Dynamic (in code) install path for command line tool scripts
* Platypus-generated apps now remember font size set by user
* Auto-focus on app name text field on app launch
* Process number arguments in the format -psn_0_******* used by old version of the Finder are no longer passed to script


### 4.9 - 09/03/2015

* Users can now manually increase/decrease the font size in Platypus-generated apps
* Status menu items can now be selected. This will run the script again with the menu title as an argument.
* Arguments can now be passed to Platypus-generated apps via the command line
* In Progress Bar interface, it is now possible to use DETAILS:SHOW and DETAILS:HIDE to toggle details field visibility
* New feature: If script prints "QUITAPP" to STDOUT, the wrapper application will quit.
* Platypus now remembers app creation dialog settings such as "Optimize Nib"
* Platypus now remembers opened Profiles in the Open Recent menu
* It is now possible to add a custom MainMenu.nib to bundled files which overwrites default
* Extended and improved documentation
* Built with XCode 6, now requires Mac OS X 10.6 or later
* Fixed a bug where "Provide as a Service" failed to be read from saved profiles
* Fixed bug where a custom bundle identifier in a saved Profile would not be loaded
* Fixed bug where the Create button would remain greyed out even though all requirements were satisfied
* Fixed bug where progress indicator would keep animating after execution in Progress Bar interface type
* Fixed bug where command line tool complained about valid .icns filenames
* Fixed bug where command line tool would always create XML property lists instead of binary ones
* Refactored all deprecated method calls
* Various minor interface refinements
* Fixed row height in bundled file list
* Updated version of IconFamily class
* Improved documentation


### 4.8 - 07/07/2013

* New "Prompt for file on launch" option
* Redesigned, user-friendlier Drop Settings sheet
* Fixed issue where version of generated apps would not appear in Get Info in Finder (missing CFBundleShortVersionString)
* Generated apps have NSHumanReadableCopyright defined again
* Extensive updates to documentation
* "Provide as a Mac OS X Service" no longer enabled by default
* Removed all support for file types.  They are ancient crust now mostly ignored by Mac OS X and should no longer be used.
* Improved uninstall script
* Fixed issue where a generated icon file referenced in a Profile could be overwritten
* Documentation files now open in default browser, not in default .html handling app
* Fixed broken nib optimization. Platypus now correctly detects XCode 4 installs. 


### 4.7 - 27/02/2012

* New "Uninstall" menu option, which removes all traces of Platypus on a system
* New update mechanism using the Sparkle framework and appcasting
* Command line tool now supports reading script from STDIN
* Command line tool now supports XML plist option 
* Migrated away from all deprecated Mac OS X API calls
* Minor interface tweaks
* Fixed bug where script permissions could be erroneously set, resulting in execution failure
* Fixed bug which caused Platypus to crash when creating Droplets
* Fixed bug with icon missing on "New Script" if CLI tool wasn't installed
* Fixed bug with enabled empty menu item when no profiles were in Profiles list


### 4.6 - 26/01/2012

* "Open" and "Save" menu item option for Platypus-created apps
* Applications can now be set as Services for text or file handling via Services menu
* Configurable document icon for Platypus apps
* New option to set custom arguments for script, not just interpreter, under "Args" (previously "Params")
* Command line tool now supports dumping profile property lists to stdout (see man page)
* Additional interpreter presets: zsh and tcsh
* Extended documentation and FAQ
* New "Edit" button and contextual menu item for Bundled Files List.
* New FastDMGMounter example
* Platypus now defaults to using binary-format property lists.  This can be set to XML in create panel.
* Status Bar apps now gracefully remove status bar item before exiting
* Removed app path as first arg option, it's unnecessary and confusing. App path == $CWD/../..
* Various interface refinements
* Migrated all images to optimized PNGs for smaller file sizes
* Now using LLVM for builds instead of GCC, which makes for smaller code size
* Changed "New Script" preset contents to be a "Hello, World" example in the selected language
* Fixed bug with script path text field tab autocomplete
* Fixed bug in shell command generator which erronously inversed the logic of the -R flag
* Fixed bug which caused crash when editing file in Bundled Files list using built-in editor.
* Fixed bug where text font settings would not be applied
* Fixed bug with contextual menus in Arguments window
* Fixed bug where custom image data application icons failed to be created
* Fixed bug where "Icon" display mode status item would erroneously display a default title
* "Run in background" applications no longer set themselves as front process with interface type "None"


### 4.5 - 11/12/2011

* Upgraded to XCode 4 for builds.  Platypus and generated applications now require Mac OS X 10.5 or later
* Dropped PowerPC support. All binaries are now 32-bit/64-bit Intel only
* New Examples menu with a number example profiles, scripts and presets demonstrating Platypus features
* Support for accepting dragged text snippets as arguments to script
* Platypus now displays a progress bar with status messages while creating applications
* New "Create app on script file change" option, which automatically creates and launches a Platypus application when you save changes to script.
* Due to popular demand, "droppable" apps now run script on launch, not just when files are dropped
* "Open in Editor" option for bundled files
* Interface refactored to be always in what was previously "Advanced mode"
* Better handling of icons for apps
* More accurate estimated final app size
* New "Launch app on creation" option in Platypus, to facilitate development workflow
* "Runs in background" windows now come to the front on launch
* Improved application icon and preset icons (512x512px representations)
* Updated man page for command line tool
* Open Recent menu uses Apple's API
* Main window no longer accepts locally dragged and dropped icon files
* Icon view no longer erroneously recognizes locally originating drags as valid
* Revised and extended documentation
* Fixed a text encoding bug with "Secure" scripts
* Fixed text encoding bug in built-in text editor
* Fixed bug in drag and drop handling in Platypus application
* Removed environment editing and signature settings [redundant and obsolete, respectively]
* Removed English.lproj from created apps.  It's not need with current lack of localization support.
* Fixed bug in drag and drop on Web View
* Updated to IconFamily 0.9.4
* New FAQ section in the documentation which addresses common questions and issues
* Fixed a bug where droplet apps would lock up on cancelled authentication
* Fixed bug in command line tool where nib parameter was ignored
* Platypus no longer embeds icon data in profiles, which results in smaller file sizes
* A variety of other small bug fixes all over the codebase
* Platypus now identifies .command files as shell scripts
* Additional interpreter pre-set options (/usr/bin/env and /bin/bash)
* Command line tool now no longer requires destination path parameter, defaulting to [name-of-script].app as destination package
* Platypus now recognises more script type suffix variants (e.g. rbx, objpy, osacript, etc.)
* Command line tool now defaults to compiling nib file (can be disabled with -l flag)
* Command line tool is now more intelligent about automatically detecting script type, interpreter, autogenerating bundle identifier, etc.
 Command line tool parameters change from '-c scriptPath [appName]' to 'scriptPath [appName]'
* More intelligent automatic app name generation based on script filename  


### 4.4 - 17/08/2010

* New interface type: "Droplet"
* Development mode now also creates symlinks to bundled files, not just the script
* New high-resolution 512x512 icon presets
* New "Default Text Encoding" option in Preferences
* STDOUT and STDERR are no longer captured in interface type "None"
* Platypus apps now use the Apple-recommended, more secure temporary location for secure scripts
* More text encoding options
* Show Shell Command option is now more intelligent about creating a terse, efficient shell command without superfluous parameters
* Various small bug fixes and optimizations in Platypus app binaries
* Updated and improved code for executing script with privileges
* Updated and improved output parsing in Progress Bar interface type
* Fixed documentation so that it uses external images instead of data URLs
* Fixed bug where Platypus would incorrectly claim to be unable to create Platypus application support folder
* Fixed bug where background color from text settings would not be applied to the text view in Progress Bar interface type
* Fixed bug where syntax checking would work incorrectly with Perl scripts
* Fixed bug when interface in a Platypus app would lock up when dropping files in authenticated execution mode
* Fixed various bugs in Progress Bar interface type
* Fixed bug in interface type "None" where app would fail to quit on script termination
* Fixed small memory leak when applications were created


### 4.3 - 25/07/2010

* Platypus text output now defaults to UTF8 instead of ASCII
* Refactored execution code running w. administrator privileges
* Fixed text-encoding bug with secure bundled scripts
* Fixed bug in secure bundled script w. droppable option
* Some changes to the interface of Platypus apps
* Current working directory is now set to .app/Contents/Resources in scripts running with Admin privileges
* Drag and drop now works properly in Web View windows
* Auto-scrolling with output in Web View interface type
* Fixed bug where apps would fail to register dropped files on launch
* Fixed bug in command line tool install script
* Fixed bug with suffix and file type validation
* Fixed bug where command-line generated apps would have black background and foreground in text window interface
* Generated apps now have editable nib files
* Updated to latest IconFamily code (0.9.3)
* Drag and drop works in more places in the Platypus application
* Updated sample scripts
* Updated documentation and command line tool man page
* Better icon handling when creating applications
* New icon presets
* New high resolution app icon and improved document icons
* New interface type:  Status Menu
* Fixed bug where command-line tool generated apps would default to black background in text interface types
* Fixed bug where apps would default to interface type "None" on invalid interface settings
* Now warns when attempting to load a profile generated by an older version of Platypus
* New "Optimize Application" mode which strips/compiles nibs and removes unnecessary files from generated application bundle
* Command line tool has new option to specify alternate nib file
* Fixed some bugs in "Show Shell Command" window


### 4.2 - 18/05/2009

* Droppable Platypus apps can now execute script repeatedly when new files are dropped
* Text settings now available for Progress Bar interface type
* Command line tool now supports setting text properties such as font, color and encoding
* Command line tool has achieved feature parity with GUI application
* Command line tool now correctly handles relative paths
* Change in profile format to make it more transparent and human-readable/editable
* "Show Shell Command" now shows all parameters for command line app
* Platypus apps now default to remaining open after execution
* Secure bundled script option now correctly excludes Development Version save option
* Fixed bug from 4.1 where text settings failed to be applied
* Fixed memory leak and bugs in privileged execution mode
* Fixed bug in path text field autocompletion
* Minor interface tweaks and fixes


### 4.1 - 15/05/2009

* New "Development Mode" option makes Platypus create symlink to script instead of copying it to the application bundle
* Platypus now tracks and warns of location change of bundled files and script
* Profiles menu now updates profile list when displayed
* Path autocomplete feature in script path text field
* Now parses entire shebang line for arguments to interpreter
* Script text output is now directed line by line to the status text field in Progress Bar interface type
* Progress Bar interface type now has a little arrow that shows details (i.e. script output) in a text field
* Tooltips for many more controls
* Additional default external editor presets
* Minor user interface tweaks and fixes
* Minor optimizations in app size
* Command line program can now create profiles
* Command line program can now operate in "Force" mode, overwriting files
* Fixed bug where secure bundled scripts failed to work on PowerPC-based machines
* Fixed memory leak in text interface type
* Fixed bug where command line program failed to create icons from images
* Fixed bug where command line program failed to parse arguments correctly
* Fixed bug where script type was not identified when a script was dropped on Platypus to launch the program
* Fixed bug which prevented File Types and App Role from being set in Info.plist
* Fixed bug where Platypus would insist on at least one File Type being set in file types and suffixes settings


### 4.0 - 22/6/2008

* Now both Platypus and Platypus-generated apps require Mac OS X 10.4 or later.
* Interface streamlined and improved
* Overhauled entire source code backend.
* Optimized binaries of Platypus and Platypus-generated apps.  Both are now leaner, meaner and slimmer than ever before.
* New file-based Profiles feature
* New application icon and new icon presets for generated apps
* New "Web View" interface type.  Scripts can generate HTML which is rendered in a WebKit view in the Platypus-generated application
* New option to configure text size, font and color for Text Window interface type
* New option to send arguments to script interpreter
* New option to disable passing path to app as first argument to script
* New "Secure script" encryption method
* Command line tool now has complete feature parity with the Platypus app
* Command line tool can now load Platypus profiles
* Command line tool now installed/uninstalled through Platypus Preferences
* New "Estimated final app size" reporting feature
* "Show Shell Command" option now correctly adds icon parameters
* Fixed bug where "Run Script in Terminal" option failed to escape script path
* Fixed bug with reversed LSMinimumSystemVersion property in Info.plist of generated applications
* Fixed bug where the same file could be added multiple times to Bundled Files list
* Fixed memory leak in Platypus-generated apps where a large amount of text output would cause the application to crash
* New and better man page for command line tool
* Updated and improved documentation
* Updated to latest IconFamily class code for icon generation


### 3.4 - 25/07/2006

* Fixed problem where Platypus refused to launch on certain Mac OS X 10.3.x  systems
* Platypus-generated apps are now Universal Binaries and require Mac OS X 10.3.9 or later
* Various bug fixes, error checks and minor improvements


### 3.3 - 24/02/2006

* Platypus and Platypus-generated apps are now Universal binaries that run natively on both PowerPC and x86 processors
* Fixed bug which made the Platypus command line utility generate non-functioning applications


### 3.2 - 06/05/2005

 * Fixed two memory leaks
 * Info.plists now contain LSHasLocalizedDisplayName, NSAppleScriptEnabled,CFBundleDisplayName, NSHumanReadableCopyright
 * Property List code is now much cleaner
 * Python syntax checking incorporated
 * Editing of environmental variables via an interface pane
 * English.lproj is en.lproj in accordance with Apple's specifications
 * Sliding animation when advanced options are revealed


### 3.1 - 06/05/2005

* New minimal, non-intrusive built-in text editor for those who prefer working in one application
* It is now possible to set app author name manually
* Invalid configuration fields now highlight red as you type
* New Dock menu
* New "Show Shell Command" menu item
* Fixed bug where "Secure" Platypus apps failed to work on read-only volumes
* New option to set default bundle identifier prefix in the preferences
* New option to set default author name in the preferences
* Profiles now correctly register bundle identifier and author name
* "Run script in Terminal" command now brings Terminal.app to the front
* Fixed bug where window title was not restored after a dialog
* Fixed a bug in the command line utility installer
* Updated man page for command line utility
* Updated Help documentation
* More sample scripts
* Platypus apps now register their creator in AppSettings.plist
* Help now opens with default app for http: protocol, not .html suffix


### 3.0 - 13/01/2005

* New "Secure bundled script" option, which checksums, encrypts and hides script
* New "Check Script Syntax" feature for shell, Perl, Ruby and PHP scripts
* New "Edit Profiles" window for easier Profiles management
* New "platypus" command line tool
* Fixed a bug where PkgInfo file would not contain application signature
* Scripts created with the "New" button list bundled file paths in comment
* More complete Info.plist property list in Platypus-generated apps
* Several user interface refinements
* Several minor speed optimizations
* Updated documentation, tutorials, sample scripts and source code comments


### 2.8 - 29/11/2004

* New "Import Custom Icon" menu item
* New contextual menus for app icon and file list
* It is now possible to manually edit an app's bundle signature
* Fixed bug where an authorized Platypus app could cause a logout
* Fixed bug with loading profiles created in older versions of Platypus


### 2.7 - 16/11/2004

* Now possible to create applications that run with privileges *and* have a text output interface
* Profiles now store custom application icons
* Fixed bug where buttons would not be enabled after a valid profile was loaded
* Custom application icons are now correctly labeled
* There is now a "Select Custom Icon" menu item
* Fixed bug where custom dragged icons would leave the icon image highlighted
* File Types and Suffixes list now displays the appropriate icons for entries
* File Types editor window is now a sheet
* Updated documentation and examples
* Various bug fixes and interface refinements
* All those that made Platypus possible are now rightly credited


### 2.6 - 11/10/2004

* Application configurations can now be saved as "Profiles"
* It is now possible to set application version and 4-character signature
* Updated documentation to reflect the changes introduced in version 2.5
* New "Clear" button for clearing all configuration fields
* New "Run script in Terminal" menu command
* All dialogs in Platypus are now sheets instead of navigation dialogs
* Fixed bug where a non-droppable app's bundle identifier would not be correctly set
* Several minor bugs and inconsistencies fixed
* Several interface tweaks


### 2.5 - 23/08/2004

* This is a major update with many important bug fixes and some powerful new features
* New interface type: "Text Window", making it very easy to create tool wrappers
* New application option: "Remain running after completion"
* New "Open Recent" menu
* New text fields that display the application bundle identifier and total number and size of bundled files
* It is now possible to register a droppable application as either an Editor or a Viewer in the Types List
* Platypus apps now have a "PkgInfo" file within the application, in accordance with Apple's guidelines
* Any application can now be selected as external editor
* Platypus now remembers "Show Advanced Options" status between launches
* Fixed a bug which caused Platypus apps to behave oddly with the Dock
* Fixed a silly bug where Platypus apps would sometimes crash on dual-processor machines
* Fixed major memory leak in Platypus apps which had been present from Platypus 2.1
* Fixed a minor memory leak introduced in Platypus 2.3


### 2.3 - 11/08/2004

* New "Runs in background" option, for creating applications that don't show up in the Dock
* Every Platypus app now has a unique bundle identifier (f.e. org.johnsmith.myscriptapp)
* New Edit Types window which allows you to set what kind of files your droppable app accepts
* New Help menu for instant access to Platypus documentation
* Platypus no longer accepts dragged folders as valid scripts
* The Bundled Files list is now drag-n-drop aware
* The same file can no longer be added many times to the Bundled Files list
* Bundled Files list buttons are now auto-enabled/disabled according to selection
* Platypus now prompts whether to overwrite when an app by the same name already exists


### 2.2 - 03/05/2004

* "New Script" button/menu item for creating and opening a script from within Platypus
* "Reveal Script" button/menu item for revealing script in the Finder
* Incorporated menu items (and keyboard shortcuts) for almost all Platypus actions/options
* Buttons and menu items correctly disabled when script path is invalid
* Fixed a bug where the last remaining file in the Bundled Files list could not be removed
* Files in the Bundled Files list now appear with their icon
* Tool Tip labels placed on all interface components
* Droplets now identify themselves as Editors instead of Viewers
* Fixed bug where files with file/creator types could not be dropped on Platypus droplets
* Some minor interface adjustments


### 2.1 - 27/04/2004

* Rewrote the ScriptExec executable that Platypus bundles into apps from scratch
* Fixed the dreaded "Is droppable" bug where Platypus would crash
* Platypus now (again) correctly creates droppable applications
* Scripts now properly receive the application bundle's path as first argument $1
* Droppable apps now also receive application bundle path as first argument
* Dropped files are now passed from $2-$*
* Preferences partially implemented - default editor can be changed to presets
* Apps that require authentication now also receive app bundle path and dropped files
* New menu and menu items for Platypus functions
* Two new icon presets, Platypus Plate and Platypus Droplet


### 2.0 - 17/02/2004

* Entire application rewritten from scratch in Objective C and Cocoa
* Images can now be dragged on "App Icon" to create custom icons for apps
* Added Expect and PHP to list of preset interpreters
* Added "Edit" button, to edit selected script in TextEdit
* An editable file list for bundling files with script into Resources folder of app bundle
* Some settings delegated to "Advanced Options", revealed by expanding window


### 1.8 - 21/11/2003

* Platypus applications that aren't marked 'Is Droppable' now get the path of the app's enclosing folder as first argument ($1, $ARGV[0] etc.). This can be very handy for installers or working with files relative to the app. A sample script that utilises this is included.


### 1.7 - 17/11/2003

* Platypus no longer has problems with spaces in certain paths
* Fixed an interface bug where Platypus window would close after Create, although cancelled
* Platypus apps with progress bar now really do have a functioning "Cancel" button
* Fixed bug where new platypus windows retained former Droppable setting
* Some cool sample scripts bundled with Platypus


### 1.6 - 14/08/2003

* New option to create droppable apps that pass files as arguments to script (like DropScript)
* Fixed a nasty bug where Platypus apps would freeze up after failed authentication
* Platypus apps with progress bar now have a "Cancel" button
* Minor user interface enhancements in both Platypus and Platypus-generated apps


## 1.5 - 29/07/2003

* Platypus apps now remain running while root-privileged scripts finish executing
* Invisible files and folders are now shown in Navigation dialogs
* Navigation dialogs use newer API calls, support app names longer than 31 characters and are non-modal
* Platypus apps can now be set to display a progress bar while running
* Platypus apps are now threaded, which means that the interface is responsive while they're running
* Some interface tweaks and bug fixes


### 1.4 - 18/06/2003

* It is now possible to create script applications that require root privileges
* Optimized performance and improved error handling for apps created with Platypus
* Platypus now launches faster
* Fixed bug where window proxy icon remained unchanged when a custom icon was set
* Fixed bug where apps with spaces in their names failed to function
* Platypus apps now remain running while script is executing


### 1.3 - 15/06/2003

* Script interpreter can now be defined
* Shebang line (#!) is now parsed for interpreter
* "Open" menu item now works
* New windows center correctly on screen
* Code optimized and trimmed
* Minor interface tweaks


### 1.2 - 13/06/2003

* Support for Ruby, AppleScript and Tcl
* Drag'n drop support for script path
* Now gracefully handles files dropped on Platypus application icon
* Better icons - specialized default icons for each script type
* Fixed bug where application placement name in Navigation dialog was ignored when creating app


### 1.1 - 11/06/2003

* Fixed issue with window redraws
* Text fields are now Unicode and displayed in correct font
* Support for Perl and Python scripts
* Drag'n drop support for script path
* Drag'n drop support for custom app icon
* Scripts can now be dragged on Platypus to automatically create an app in the same directory
* Now warns about inappropriate script suffixes


### 1.0 - 23/05/2003

* Initial release

