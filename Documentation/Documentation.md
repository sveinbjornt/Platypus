# Documentation for Platypus 5.3

Last updated on November 17th, 2018. The latest version of this document can be found [here](http://sveinbjorn.org/platypus_documentation).


## Introduction


### What is Platypus?

<img style="float: right; margin-left: 30px; margin-bottom: 20px;" width="94" src="images/platypus.png">

Platypus is a developer tool that creates native macOS application wrappers around scripts. Scripts are thus transformed into regular applications that can be launched from the window environment – e.g. the Finder or the Dock – without requiring use of the command line interface.

Platypus was first conceived in 2003 and has since gone through many significant updates. It is written in Objective-C/Cocoa and is free, open-source software distributed under a BSD license. This means the source code is freely available and you are free to modify and distribute it as you see fit.

<form action="https://www.paypal.com/cgi-bin/webscr" method="post" style="float: right; margin-left: 40px;">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="hidden" name="hosted_button_id" value="BDT58J7HYKAEE">
<input type="image" src="https://www.paypalobjects.com/WEBSCR-640-20110306-1/en_US/i/btn/btn_donate_LG.gif" border="0" name="submit" alt="PayPal" width="92" height="26">
<img alt="" border="0" src="https://www.paypalobjects.com/WEBSCR-640-20110306-1/en_US/i/scr/pixel.gif" width="1" height="1">
</form>

While Platypus is free, it is the product of countless hours of work spanning well over a decade. **If Platypus makes your life easier, please [make a donation](http://sveinbjorn.org/donations) to support further development.**

I am happy to respond to feature requests, bug reports and questions concerning Platypus which are not addressed in this document, but I cannot answer queries about the particulars of individual scripting languages. Productive use of Platypus assumes that you are competent in your scripting language of choice and understand the UNIX shell environment.


### How does Platypus work?

Regular macOS applications are [bundles](https://en.wikipedia.org/wiki/Bundle_%28OS_X%29) – special folders with a specific directory structure. An executable binary is stored in the bundle along with resources and configuration files. This binary is run when the bundle is opened in the graphical user interface.

Platypus creates application bundles with a special executable binary that launches a script and captures its output. The binary can be configured to present the script's text output in various ways, for example by showing a progress bar, a text view, a Status Item menu or a WebKit-based web view.


### What Platypus is NOT

Platypus is **not** a set of bindings between the native macOS APIs and scripting languages. It is not a full GUI development environment and is not intended for creating substantial applications with complex and dynamic user interaction. If you want to create advanced macOS applications, you should learn to program using the Cocoa APIs. Platypus is not and never will be a substitute for learning to use the (mostly excellent) native application programming interfaces.

That being said, you may be able to add some interactive GUI elements using [CocoaDialog](User interaction with CocoaDialog), [Pashua](https://www.bluem.net/en/projects/pashua/) or even [AppleScript](#prompting-for-input-via-osascript-applescript).


### System Requirements

Both Platypus and the applications it generates require **macOS 10.8** or later and are provided as **64-bit Intel** binaries. If you want to target 10.6 and/or 32-bit systems, [version 4.9](http://sveinbjorn.org/files/software/platypus/platypus4.9.zip) continues to work just fine. If you want to target 10.4 and the PowerPC users of yore, you can use version [4.4](http://sveinbjorn.org/files/software/platypus/platypus4.4.zip).


### Credits

Platypus was conceived and created by me, [Sveinbjorn Thordarson](mailto:sveinbjorn@sveinbjorn.org). The Platypus application icon – [Hexley](http://www.hexley.com/), the Darwin mascot – was created by Jon Hooper, who was kind enough to grant me permission to use it.

Thanks go to Troy Stephens, the original author of the [IconFamily](http://iconfamily.sourceforge.net/) class used for icon handling in Platypus, Bryan D K Jones, author of [VDKQueue](https://github.com/bdkjones/VDKQueue), Gianni Ceccarelli for contributing code on authenticated script execution, Matt Gallagher for secure temp file code, and Andy Matuschak for the [Sparkle](http://sparkle-project.org) update framework. [Stack Overflow](http://stackoverflow.com) and the [OmniGroup](https://www.omnigroup.com) Mac development mailing list and have also been invaluable over the years.

Finally, I am much indebted to [Wilfredo Sanchez](http://www.wsanchez.net), author of [DropScript](http://www.wsanchez.net/software), the proof-of-concept project which inspired me to create Platypus in the first place.



## The Basics


### Basic Interface

The basic Platypus interface is relatively straightforward. As soon as you launch the Platypus application, you see a window that looks like this:

<img src="images/basic_interface.png" width="657" alt="Platypus window">

**App Name**

The name of your application.

**Script Path**

Path to the script you want to create an app from. Either use the **Select** button to select a script, or drag a script file on the Platypus window. You can also type in a path  manually (the text field supports supports shell-style tab autocompletion).

<img src="images/script_path.png" width="492" alt="Platypus Script Path">
    
Once you have selected a script, you can press the **Edit** button to open it in your default text editor. Platypus defaults to using a very basic built-in text editor. You can change this in the **Preferences** if you want to use a more capable external editor.

The **New** button creates a script file in the Platypus Application Support folder and opens it in the default editor. The **Reveal** button reveals the script file in the Finder.



### Interpreter

<img src="images/script_type.png" style="float: right; margin-left:20px; margin-bottom:20px;" width="135">

Use **Script Type** to specify an interpreter for your script. Either select one of the predefined scripting languages from the the pop-up menu or type in the path to an interpreter binary.

Most of the time, you do not need to specify this manually. Whenever you open a script file, Platypus automatically tries to determine its type based on the file suffix and shebang line (`#!`). If you have specified this meta-data in the script file itself, Platypus is usually smart enough to figure it out.

Please note that the interpreter must exist on the system where the application is run. All the preset scripting language interpreters (e.g. Python, Perl, Ruby, PHP, Tcl, etc.) are a standard part of all macOS installations.

**Args** let you add arguments to the script and/or its interpreter.

<img src="images/args.png" width="500">



### Interface

<img src="images/interface_type.png" style="float: right; margin-left: 20px; margin-bottom:20px;" width="159">

**Interface** sets the user interface for the application. Platypus offers six different interface types:

#### None

Windowless application that provides no graphical feedback. All script output is redirected to `STDERR`.

#### Progress Bar

A small window with an indeterminate progress bar and a "Cancel" button appears during the execution of the script. Script output is fed line by line into the text field above the progress bar. The "Show details" button reveals a small text view containing full script output.

<img src="images/interface_progressbar.png" width="438">

#### Text Window

Shows a window with a text view containing script output. Please note that this text view is *not* a full, interactive terminal session, and cannot be used to prompt for user input via STDIN. It does not support any of the standard terminal commands and cannot be used to display ncurses-based interfaces.

The styling of the text view can configured under **Text Settings**.

<img src="images/interface_textwindow.png" width="469">

#### Web View

Output from the script is rendered as HTML in a WebView window. This allows you to use HTML formatting and other web technologies to present script output to the user.

The base directory for the browser instance is the application bundle's Resources directory, so you can include images and other support files by adding them to the **Bundled Files** list and referencing them relative to the directory.

<img src="images/interface_webview.png" width="508">

#### Status Menu

Creates a Status Item in the menu bar when the app is launched. Every time the status item is clicked, the script is executed and its text output shown line for line in a menu. If a menu item is selected, the script is executed again with the title of the selected item passed as an argument to the script.

The properties of the Status Item (icon, title, etc.) can be configured under **Status Item Settings** button.

<img src="images/interface_statusmenu.png" width="369">

#### Droplet

Creates a square window instructing the user to drop files on it for processing. While processing, script output is displayed line for line along with an indeterminate circular progress indicator.

<img src="images/interface_droplet.png" width="294">



### Setting the Icon

<img src="images/setting_icon.png" width="207" style="float: right; margin-left: 20px; margin-bottom:20px;">

Platypus lets you set an icon for your application. You can pick from the icon presets, paste your own image or select an image or `icns` file.

Please note that having Platypus create the icon from an ordinary image file will typically not result in an icon that looks good in smaller sizes. For best results, use professional icon-editing software and import a carefully crafted `.icns` file using the **Select .icns file** option.



### Identifier, Author and Version

The **Identifier** text field specifies the unique identifier for the application. If you have already set an application name, this will default to something in the form of "org.yourusername.YourAppName".

Every macOS application has a unique string called a bundle identifier, which takes the form of a reverse DNS name (e.g. "com.apple.iTunes" or "org.sveinbjorn.Platypus"). Platypus automatically formats the bundle identifier using the application name and default user name, but you can set it to whatever you want. The default bundle identifier prefix can be configured in **Preferences**.

<img src="images/author_identifier.png" width="427">

You can also set **Author** and **Version** metadata. This information will appear in the Finder "Get Info" window for your application and in the About window accessible through the application menu.



### Special Options

<img src="images/special_options.png" style="float: right; margin-left: 20px; margin-bottom:20px;" width="260">

**Run with root privileges:**  If selected, the application prompts for an Administrator password and executes the script with escalated (root) privileges using Apple's Security Framework. This is not strictly equivalent to running the script *as the root user*. For details, see the [documentation for the Mac OS Security Framework](http://developer.apple.com/mac/library/documentation/Security/Reference/authorization_ref/Reference/reference.html#//apple_ref/c/func/AuthorizationExecuteWithPrivileges).

*Platypus scripts must not use the 'sudo' command*. This causes the script to prompt for input via `STDIN`, and since no input is forthcoming, the application will hang indefinitely.

Please note that if this option is selected, `STDERR` output cannot be captured due to limitations in the Security APIs. This can be circumvented by using a shell script to execute another script while piping `STDERR` into `STDOUT` (e.g. `perl myScript.pl 2>&amp;1`).

**Runs in background:** If selected, the application registers itself as a User Interface Element (LSUIElement) and will not appear in the Dock when launched.

**Remain running after completion**: This option tells the application to remain open after the script has executed.




### Bundled Files

**Bundled Files** contains files that should be copied into the Resources folder of the application bundle. These files can then be used by your script, which is run from the same directory.

<img src="images/bundled_files.png" width="658">

See also [How do I get the path to my application / bundled files within the script?](#how-do-i-get-the-path-to-my-application-and-or-bundled-files-from-within-the-script-) in the FAQ.



## Advanced Options



### Accepting files and dragged items

Checking **Accept dropped items** makes the application bundle accept dragged and dropped files, or dragged text snippets. You can specify which file types and draggable data the application should accept under **Drop Settings**.

<img src="images/drop_settings.png" width="537">

**Accept Dropped Files** means the paths of dropped or opened files are passed to the script as arguments. You can specify which file types to accept either using [UTIs](https://en.wikipedia.org/wiki/Uniform_Type_Identifier) (recommended) or filename suffixes.

To accept dragged folders, add the UTI `public.folder`. HINT: You can drag files from the Finder into the suffix or UTI list to add their respective suffix/UTI.

Optionally, select a document icon (.icns file) for the files "owned" by your app.

Selecting **Accept Dropped Text** makes the app accept dragged snippets of text. The text string is passed to the script via `stdin`.

**Provide macOS Service** makes the app register as a text-processing [Dynamic Service](http://www.computerworld.com/article/2476298/mac-os-x/os-x-a-quick-guide-to-services-on-your-mac.html), accessible from the **Services** submenu of application menus. You also need to enable this if you want your app to accept text snippets or URLs dropped on its Dock/Finder icon.

**Register as URI scheme handler** makes the app register as a handler for [URI schemes](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier). These can be either standard URI schemes such as http or a custom URI schemes of your choice (e.g. `myscheme://`). If your app is the default handler for a URI scheme, it will launch open every time a URL matching the scheme is opened. The URL is then passed to the script as an argument.



### Build-Time Options

Platypus allows you to **create development versions** of your script application. Ordinarily, the script and any bundled files are copied into the resulting application. If **Development Version** is selected in the **Create app** dialog, a symlink to the original script and bundled files is created instead. This allows you to edit your script file while simultaneously testing it as a Platypus app.

<img src="images/create_options.png" width="424">

**Optimize Application**: Strip and compile the nib file in the application in order to reduce its size. This makes the nib uneditable. Only works if Xcode is installed.



### Built-In Editor

Platypus includes a very basic built-in text editor for editing scripts. Press the **Edit** button to bring it up.

<img src="images/built-in_editor.png" width="600">

A more capable external editor can be set in **Preferences.**



### Syntax Checking

The **Check Script Syntax** menu verifies the syntax of the script by running it through the interpreter's syntax checker.

This feature only works for interpreters that support syntax checking (bash, Perl, Python, Ruby, PHP and Swift).

<img src="images/syntax_checker.png" width="473">



### Show Shell Command

Platypus includes a **command line tool** counterpart to the Platypus.app application, `platypus`,which can be installed into `/usr/local/bin/` via **Preferences**. The man page for this tool is available from the Help menu, and via the command line. There is also an [online version available](http://sveinbjorn.org/files/manpages/platypus.man.html)</a>.

The command line tool does not in any way depend on the Platypus application once it has been installed.

<img src="images/shell_command.png" width="472">

**Show Shell Command** in the **Action** menu displays the command required to execute the platypus command line tool using all the options selected in the graphical interface. This can be helpful if you have the command line tool installed and want to automate the creation of script apps within a larger build process.



## Preferences

The Platypus Preferences should be pretty self-explanatory. You can select an editor of choice, set the default author and bundle identifier settings, set the behaviour of Platypus on app creation, and install/uninstall the `platypus` command line tool.

<img src="images/preferences.png" width="313">





## Profiles



### Saving and Loading

Profiles let you save Platypus application configuration settings. These can then be loaded by Platypus or the `platypus` command line tool. The Profiles menu is used to save and access profiles. Profiles are stored as files, typically in the **Profiles** folder of the Platypus Application Support folder (`~/Library/Application Support/Platypus/Profiles`).

You can load a profile by selecting it from the menu, which lists all profiles in the Profiles folder. To reveal a profile in the Finder, hold down the Command key and select the profile. Profiles have a `.platypus` filename suffix.

<img src="images/profiles.png" width="212">




### Using Profiles with the Command Line Tool

Profiles can be used with the `platypus` command line tool. This allows you to set all the settings for your application within the graphical user interface, save them as a profile and then load the settings with the command line app. This makes automation more convenient. The following command would load a profile with the command line tool and create an app from it named MyApp.app:

```
/usr/local/bin/platypus -P myProfile.platypus MyApp.app
```

See the command line tool man page for further details. An HTML version of the man page is [available here](http://sveinbjorn.org/files/manpages/platypus.man.html).




### Platypus Profile Format

Platypus Profiles are standard macOS [property lists](http://en.wikipedia.org/wiki/Property_list) in XML format. They can be edited using either a plain text editor or Xcode.

As of version 5.2, Platypus understands and resolves relative paths in Profiles. However, neither the Platypus app nor the command line tool *generate* relative paths, so if you want to use them in a Profile, you will have to edit it manually.





## Controlling the GUI with script output

### Showing an Alert

Platypus application wrappers can be made to show an alert if your script prints out a line using the following syntax:

```
ALERT:Title|Text\n
```

Thus, to show an alert with the title "Hello" and the informative text "World", you would do as follows:

```
ALERT:Hello|World\n
```



### Showing a Notification

Platypus application wrappers can be made to show a notification in the User Notification Center if your script prints out a line using the following syntax:

```
NOTIFICATION:My notification text\n
```



### Controlling the Progress Bar

Script apps with the interface type **Progress Bar** can communicate with the progress bar by notifying it of script progress. All lines of script output in the format "PROGRESS:\d+\n" (e.g. PROGRESS:75) are parsed and used to set the completion percentage of the progress bar. Similarly, DETAILS:SHOW and DETAILS:HIDE can be used to change the visibility of the Details text field during the execution of the script.



### Terminating Application

If your script prints the string "QUITAPP\n" to STDOUT, the application will quit.


### Clearing Output

If your script prints the string "REFRESH\n" to STDOUT, the text output buffer will be cleared. This can, for example, be used to clear a Web View in preparation for new HTML output.

### Loading a Website into a Web View

If interface type was set to **Web View** and your script prints "Location:http://some.url.com\n", the Web View will load the URL in question.



### User interaction with CocoaDialog

Platypus apps may be able to use [CocoaDialog](https://cocoadialog.com) to construct scripts that prompt for user input with dialogs. As of writing, the CocoaDialog project seems to be dead and so the following instructions may be obsolete:

* Download CocoaDialog
* Add CocoaDialog.app to the list of Bundled Files.

The following script shows of how to query for input using this bundled copy of CocoaDialog:

```
#!/bin/bash

CD="CocoaDialog.app/Contents/MacOS/CocoaDialog"

rv=`$CD yesno-msgbox --string-output`
$CD ok-msgbox --no-cancel --text "You pressed $rv"
```

This application will present the user with an alert and several buttons. When the user presses one of the buttons, a feedback dialog is generated notifying the user which button he pressed. While this particular script accomplishes nothing, it serves as a basic example of how to add interactive elements to the script.



### Creating a Status Menu app

<img src="images/interface_statusmenu2.png" width="315" style="float: right; margin: 20px;">

Platypus-generated apps with **Interface** set to **Status Menu** show a Status Item in the menu bar when launched. When the item is pressed, a menu is opened, the script is executed and each line of output is shown as a menu item in the menu.

When the user selects a menu item, the script is executed again, but this time it receives the menu title as an argument. Based on whether it receives an argument, the script can thus determine whether it is being invoked to list the menu items or in order to perform some action for a selected menu item.

If this seems unclear, check out the following script, which is part of the MacbethMenu Example:

```
#!/usr/bin/perl

# If 0 arguments, we show menu
if (!scalar(@ARGV)) {
    print "Life's but a walking shadow, a poor player\n";
    print "That struts and frets his hour upon the stage\n";
    print "And then is heard no more.\n";
} else {
    # We get the menu title as an argument
    system("/usr/bin/say \"$ARGV[0]\"");
}
```

This script creates a Status Menu app which shows a few lines from Shakespeare's Macbeth as menu items. When selected, the title of the menu item in question is fed into the macOS speech synthesizer via `/usr/bin/say`.

Status Menu apps can also create submenus and menu separators by printing out lines with the following syntax:

**Set icon for menu item**

```
MENUITEMICON|my_bundled_file.png|Bundled file example\n
MENUITEMICON|/path/to/icon.png|Absolute path example\n
MENUITEMICON|http://sveinbjorn.org/images/andlat.png|Remote URL example\n
```

**Creating a menu separator**

```
----\n
```

**Creating a submenu named "Title" with three menu items:**

```
SUBMENU|Title|Item1|Item2|Item3\n
```

### Prompting for input via osascript/AppleScript

Scripts can also prompt for input by running AppleScript code via the `/usr/bin/osascript` program. See an example in Perl below:

```
#!/usr/bin/perl

use strict;

sub osascript($) { system 'osascript', map { ('-e', $_) } split(/\n/, $_[0]); }

sub dialog {
    my ($text, $default) = @_;
    osascript(qq{
    tell app "System Events"
    text returned of (display dialog "$text" default answer "$default" buttons {"OK"} default button 1 with title "Riddle")
    end tell
    });
}

my $result = dialog("Answer to life, the universe and everything?", "42");
```

[Source.](http://stackoverflow.com/questions/33601580/using-platypus-to-create-mac-os-x-applications-from-a-perl-script/33603239#33603239)





## Examples

### Built-In Examples

Platypus includes many built-in examples. These can be opened via the **Examples** submenu of the **Profiles** menu. Brief explanation of each of the examples:

* **AdminPrivilegesDemo**: Demonstrates running a script with root privileges by creating a file in /etc/ and testing for its existence.
    
* **AlertMe**: Demonstrates ALERT: and PROGRESS: syntax in action by showing alerts while manipulating the progress bar.
    
* **DataURLifier**: Drop a file on a window to get its [Data URI](https://en.wikipedia.org/wiki/Data_URI_scheme).
    
* **FastDMGMounter**: Creates a replacement for DiskImageMounter. Uses the `hdiutil` command line tool to quickly mount `.dmg` disk images, skipping verification and auto-accepting any EULAs. See [this page](http://sveinbjorn.org/macosx_hack_faster_dmg_image_mounting) for details.
    
* **IcnsToIconset**: Converts Apple `.icns` files to `.iconset` folders with PNGs for the various representations.
    
* **ImageResizer**: Shows how to use the built-in macOS Scriptable Image Processing System (see `man sips`) to resize dropped images to 512x512 dimensions.
    
* **MacbethMenu**: Simple interactive status menu app that shows lines by Shakespeare and feeds them to the speech synthesizer when selected.
    
* **PostToNotificationCenter**: Creates notifications in the macOS Notification Center via script output using the custom NOTIFICATION: syntax.
    
* **ProcessMenu**: Creates a status menu which displays the output of `ps cax` when clicked.
    
* **ProgressBar**: Demonstrates how a progress bar can be controlled with script output.
    
* **SayURLSchemeHandler**: A handler for the custom URI scheme `say://`. Try creating the app and opening a URL such as `say://hello-world` in your browser.
    
* **SpeakDroplet**: Uses the macOS speech synthesiser to read all opened text files.
    
* **SpotlightInfo**: Drag a file on a window to see its Spotlight metadata.
    
* **StatusMenuDemo**: Shows how to set menu item icons and create submenus in a Status Menu interface.
    
* **SysLoadMenu**: Status menu app which displays the output of `w`.
    
* **TarGzipper**: Creates a gzipped tar archive of any dropped files.
    
* **WordCountService**: Dynamic Service app which does a word count of received text and shows results in an alert.

If you come up with a particularly nifty use of Platypus and think it might make a suitable addition to this list, by all means [let me know](mailto:sveinbjorn@sveinbjorn.org).




## Updates

### Updating Platypus

Platypus uses <a href="https://sparkle-project.org">Sparkle</a> for updates. You can update to the latest version by selecting **Check for updates...** in the application menu. Future releases may or may not break your saved profiles. Consult the version change log for details.

An Appcast RSS XML file is available [here](http://sveinbjorn.org/files/appcasts/PlatypusAppcast.xml).

To get the absolutely latest development version of Platypus, you can check out the source repository on [GitHub](http://github.com/sveinbjornt/Platypus).


## Frequently Asked Questions

### Can I use Platypus to create proprietary software?

Yes. Platypus is distributed under the terms and conditions of the three-clause [BSD License](http://www.sveinbjorn.org/files/software/platypus/documentation/License.html).



### Help, text output isn't being shown until the script is done!

You need to autoflush the output buffer. In Perl, this is done with the following command at the start of your script:

```
$| = 1;
```

In Python, you can pass the `-u` parameter to the interpreter to get unbuffered output, or alternately flush the output buffer in code:

```
import sys
sys.stdout.flush()
```

For help with other scripting languages, [Stack Overflow](http://stackoverflow.com) is your friend.



### Does Platypus support localizations?

No. But if you uncheck "Optimize nib file" in the save dialog when creating an app, the resulting nib in the application bundle can be edited using Xcode. You can thus localize your app manually if you want to. Support for localization is not on the feature roadmap.



### How does my script access the user's environment (e.g. PATH)?

Assuming that you're using `bash`, you can set the interpreter to `/bin/bash` and add the `-l` flag as an argument under "Args". This makes `bash` act as if it had been invoked as a login shell. See `man bash` for details.



### How can I pass specific arguments to my script?

You can edit arguments to both the script interpreter and the script itself by pressing the **Args** button next to the **Interpreter** controls.



### How do I uninstall Platypus?

Platypus only uses about 5MB of disk space, but if you want to remove it entirely, along with support files, profiles, etc., you can select **Uninstall Platypus** from the Platypus application menu. This will uninstall the command line tool (if previously installed), and move Platypus.app and all its supporting files –  including saved Profiles – to the Trash.



### How do I get the source code to Platypus and Platypus-generated app binaries?

The Platypus source repository can be found [on GitHub](https://github.com/sveinbjornt/Platypus).

The source code to the binary used in Platypus-generated apps is [ScriptExecController.m](https://github.com/sveinbjornt/Platypus/blob/master/ScriptExec/ScriptExecController).

Please let me know if you make any improvements or fix any bugs, so I can incorporate them into the official release.


### How do I get the path to my application and/or bundled files from within the script?

The script executed by Platypus-generated applications runs from the Resources directory of the application bundle (e.g. `MyApp.app/Contents/Resources`). Any bundled files are thus accessible from the script's current working directory.

For example, if you have added `file.txt` as a bundled file and want to copy it over to the user's home directory using a shell script, you would run the following command:

```
cp file.txt ~/
```

To get the path to the application bundle itself, or its containing directory, you can use `../..` (application bundle) or `../../..` (application bundle's containing directory).


### How do Platypus-generated applications work?

Platypus-generated applications are macOS application (.app) [bundles](https://en.wikipedia.org/wiki/Bundle_(OS_X)#OS_X_application_bundles), and have the following directory structure:

```
MyApp.app/                                      Application bundle folder
MyApp.app/Contents
MyApp.app/Contents/Info.plist                   Info property list for app
MyApp.app/Contents/MacOS
MyApp.app/Contents/MacOS/MyApp                  Application binary
MyApp.app/Contents/Resources                    Resources folder
MyApp.app/Contents/Resources/AppIcon.icns       Application icon
MyApp.app/Contents/Resources/AppSettings.plist  Application settings
MyApp.app/Contents/Resources/MainMenu.nib       Nib file, stores interface layout
MyApp.app/Contents/Resources/script             Script executed by application binary
```

The application binary reads settings from AppSettings.plist and then runs the script, making use of the user interface assets in the nib file to display the script's output.

The source code to the binary is [here](https://github.com/sveinbjornt/Platypus/blob/master/ScriptExec/ScriptExecController.m). Skimming it should give you a fairly thorough understanding of what the executable does. It's relatively straightforward.


### Can I change the dimensions of my app's window?

Yes, but only by altering the application manually after it has been created. When you press Create, you need to uncheck the "Optimize Application (strip nib file)" option in the dialog. You can then edit the user interface assets in the nib file using Xcode. The nib file is stored at the following path within your application bundle.

```
Contents/Resources/MainMenu.nib
```

If you want to keep your own modified nib for repeated use, you can simply save a copy, edit it and add it to **Bundled Files** when you create an app. It will then overwrite the default MainMenu.nib file:

The Platypus command line tool also allows you to specify an alternate nib file using the `-H` flag. See the [man page](http://sveinbjorn.org/files/manpages/platypus.man.html) for details.


### Can I prompt for user input (STDIN) in my Platypus-wrapped scripts?

No. Platypus applications do not present the user with an interactive shell, and therefore no bidirectional communication can take place using standard input. Platypus apps can only capture and display the text output of your script. They cannot prompt for input via STDIN, and will not be able to do so in the foreseeable future. This means that any script commands that require input via STDIN, such as `sudo`, will not work from within a Platypus application.


### Is there a way to sign Platypus-generated apps so they don't require GateKeeper approval?

Neither Platypus nor Platypus-generated apps are signed. Due to GateKeeper, this means they will not run on macOS without prompting the user for approval. There are no plans to change this in the future. Apple developer accounts cost money and I have no intention of paying Apple for the privilege of developing free software for their operating system.

You could always sign the Platypus binaries yourself, but it's a pain in the ass and beyond the scope of this document.


### Can I pass arguments to a Platypus-generated app via the command line?

Yes. You can execute a Platypus-generated binary via the command line. Any arguments you provide will be passed on to your script. Take the following example:

```
# ./MyApp.app/Contents/MacOS/MyApp -arg1 -arg2
```

In this case, both `-arg1` and `-arg2` will be passed on as arguments to your script. This feature makes it possible to create protocol handlers for Firefox and other programs that invoke macOS application binaries directly.


### Where is the command line tool installed?

The Platypus command line tool install script creates the following files on your system:

```
/usr/local/bin/platypus                         Program binary
/usr/local/share/platypus/ScriptExec            Executable binary
/usr/local/share/platypus/MainMenu.nib          Nib file for app
/usr/local/share/platypus/PlatypusDefault.icns  Default icon
/usr/local/share/man/man1/platypus.1            Man page
```

These files are all removed by **Uninstall Platypus** in the Platypus application menu.



### Can I customize the About window of a Platypus-generated app?

If you add a file named **Credits.rtf** or **Credits.html** to the bundled files list, it will appear in the About window of your application.

----

Copyright &copy; 2003-2018 [Sveinbjorn Thordarson](mailto:sveinbjorn@sveinbjorn.org)
