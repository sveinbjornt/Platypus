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

/* This is the source code to the main controller for the binary
 bundled into Platypus-generated applications */

#import "ScriptExecController.h"
#import "Alerts.h"
#import "ScriptExecJob.h"

@implementation ScriptExecController

- (id)init {
    if ((self = [super init])) {
        arguments = [[NSMutableArray alloc] initWithCapacity:ARG_MAX];
        textEncoding = DEFAULT_OUTPUT_TXT_ENCODING;
        isTaskRunning = NO;
        outputEmpty = YES;
        jobQueue = [[NSMutableArray alloc] initWithCapacity:PLATYPUS_MAX_QUEUE_JOBS];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (arguments != nil) {
        [arguments release];
    }
    if (droppableSuffixes != nil) {
        [droppableSuffixes release];
    }
    if (interpreterArgs != nil) {
        [interpreterArgs release];
    }
    if (scriptArgs != nil) {
        [scriptArgs release];
    }
    if (commandLineArguments != nil) {
        [commandLineArguments release];
    }
    if (statusItemIcon != nil) {
        [statusItemIcon release];
    }
    if (scriptText != nil) {
        [scriptText release];
    }
    if (statusItem != nil) {
        [statusItem release];
    }
    if (statusItemMenu != nil) {
        [statusItemMenu release];
    }
    if (appName != nil) {
        [appName release];
    }
    
    [jobQueue release];
    [super dealloc];
}

- (void)awakeFromNib {
    // load settings from AppSettings.plist in app bundle
    [self loadAppSettings];
    
    // prepare UI
    [self initialiseInterface];
    
    // we listen to different kind of notification depending on whether we're running
    // an NSTask or an STPrivilegedTask
    NSString *notificationName = (execStyle == PLATYPUS_EXECSTYLE_PRIVILEGED) ? STPrivilegedTaskDidTerminateNotification : NSTaskDidTerminateNotification;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskFinished:)
                                                 name:notificationName
                                               object:nil];
}

#pragma mark - App Settings

/**************************************************
 Load configuration file AppSettings.plist from
 application bundle, sanitize it, prepare it
 **************************************************/

- (void)loadAppSettings {
    
    NSBundle *appBundle = [NSBundle mainBundle];
    NSString *appSettingsPath = [appBundle pathForResource:@"AppSettings.plist" ofType:nil];
    
    //make sure all the config files are present -- if not, we quit
    if (![FILEMGR fileExistsAtPath:appSettingsPath]) {
        [Alerts fatalAlert:@"Corrupt app bundle" subText:@"AppSettings.plist missing from the application bundle."];
    }
    
    // get app name
    // first, try to get CFBundleDisplayName from Info.plist
    NSDictionary *infoPlist = [appBundle infoDictionary];
    if ([infoPlist objectForKey:@"CFBundleDisplayName"] != nil) {
        appName = [[NSString alloc] initWithString:[infoPlist objectForKey:@"CFBundleDisplayName"]];
    } else {
        // if that doesn't work, use name of executable file
        appName = [[NSString alloc] initWithString:[[appBundle executablePath] lastPathComponent]];
    }
    
    //load dictionary containing app settings from property list
    NSDictionary *appSettingsDict = [NSDictionary dictionaryWithContentsOfFile:appSettingsPath];
    if (appSettingsDict == nil) {
        [Alerts fatalAlert:@"Corrupt app settings" subText:@"Unable to load AppSettings.plist"];
    }
    
    //determine output type
    NSString *outputTypeStr = [appSettingsDict objectForKey:@"OutputType"];
    if ([PLATYPUS_OUTPUT_TYPES containsObject:outputTypeStr] == FALSE) {
        [Alerts fatalAlert:@"Corrupt app settings" subText:@"Invalid Output Mode."];
    }
    outputType = [PLATYPUS_OUTPUT_TYPES indexOfObject:outputTypeStr];
    
    // we need some additional info from AppSettings.plist if we are presenting textual output
    if (outputType == PLATYPUS_OUTPUT_PROGRESSBAR ||
        outputType == PLATYPUS_OUTPUT_TEXTWINDOW ||
        outputType == PLATYPUS_OUTPUT_STATUSMENU) {
        
        //make sure all this data is sane, revert to defaults if not
        
        // font and size
        NSNumber *userFontSizeNum = [DEFAULTS objectForKey:@"UserFontSize"];
        CGFloat fontSize = userFontSizeNum ? [userFontSizeNum floatValue] : [[appSettingsDict objectForKey:@"TextSize"] floatValue];
        fontSize = fontSize ? fontSize : DEFAULT_OUTPUT_FONTSIZE;
        if ([appSettingsDict objectForKey:@"TextFont"]) {
            textFont = [NSFont fontWithName:[appSettingsDict objectForKey:@"TextFont"] size:fontSize];
        }
        if (!textFont) {
            textFont = [NSFont fontWithName:DEFAULT_OUTPUT_FONT size:DEFAULT_OUTPUT_FONTSIZE];
        }
        
        // foreground color
        if ([appSettingsDict objectForKey:@"TextForeground"]) {
            textForeground = [NSColor colorFromHex:[appSettingsDict objectForKey:@"TextForeground"]];
        }
        if (textForeground == nil) {
            textForeground = [NSColor colorFromHex:DEFAULT_OUTPUT_FG_COLOR];
        }
        
        // background color
        if ([appSettingsDict objectForKey:@"TextBackground"] != nil) {
            textBackground = [NSColor colorFromHex:[appSettingsDict objectForKey:@"TextBackground"]];
        }
        if (textBackground == nil) {
            textBackground = [NSColor colorFromHex:DEFAULT_OUTPUT_BG_COLOR];
        }
        
        // encoding
        textEncoding = DEFAULT_OUTPUT_TXT_ENCODING;
        if ([appSettingsDict objectForKey:@"TextEncoding"] != nil) {
            textEncoding = (int)[[appSettingsDict objectForKey:@"TextEncoding"] intValue];
        }
        
        [textFont retain];
        [textForeground retain];
        [textBackground retain];
    }
    
    // likewise, status menu output has some additional parameters
    if (outputType == PLATYPUS_OUTPUT_STATUSMENU) {
        NSString *statusItemDisplayType = [appSettingsDict objectForKey:@"StatusItemDisplayType"];
        
        // we load text label if status menu is not only an icon
        if ([statusItemDisplayType isEqualToString:@"Text"] || [statusItemDisplayType isEqualToString:@"Icon and Text"]) {
            statusItemTitle = [[appSettingsDict objectForKey:@"StatusItemTitle"] retain];
            if (statusItemTitle == nil) {
                [Alerts fatalAlert:@"Error getting title" subText:@"Failed to get Status Item title."];
            }
        }
        
        // we load icon if status menu is not only a text label
        if ([statusItemDisplayType isEqualToString:@"Icon"] || [statusItemDisplayType isEqualToString:@"Icon and Text"]) {
            statusItemIcon = [[NSImage alloc] initWithData:[appSettingsDict objectForKey:@"StatusItemIcon"]];
            if (statusItemIcon == nil) {
                [Alerts fatalAlert:@"Error loading icon" subText:@"Failed to load Status Item icon."];
            }
        }
        
        // Fallback if no title or icon is specified
        if (statusItemIcon == nil && statusItemTitle == nil) {
            statusItemTitle = @"Title";
        }
        
        statusItemUsesSystemFont = [[appSettingsDict objectForKey:@"StatusItemUseSystemFont"] boolValue];
    }
    
    // load these vars from plist
    interpreterArgs     = [[NSArray arrayWithArray:[appSettingsDict objectForKey:@"InterpreterArgs"]] retain];
    scriptArgs          = [[NSArray arrayWithArray:[appSettingsDict objectForKey:@"ScriptArgs"]] retain];
    execStyle           = [[appSettingsDict objectForKey:@"RequiresAdminPrivileges"] boolValue];
    remainRunning       = [[appSettingsDict objectForKey:@"RemainRunningAfterCompletion"] boolValue];
    secureScript        = [[appSettingsDict objectForKey:@"Secure"] boolValue];
    isDroppable         = [[appSettingsDict objectForKey:@"Droppable"] boolValue];
    promptForFileOnLaunch = [[appSettingsDict objectForKey:@"PromptForFileOnLaunch"] boolValue];
    
    // read and store command line arguments to the application
    NSMutableArray *processArgs = [NSMutableArray arrayWithArray:[[NSProcessInfo processInfo] arguments]];

    if ([processArgs count]) {
        // the first argument is always the path to the binary, so we remove that
        [processArgs removeObjectAtIndex:0];
        // hack to remove XCode CLI flags. Really just here to make debugging easier.
        if ([processArgs count] > 1 && [[processArgs objectAtIndex:0] isEqualToString:@"-NSDocumentRevisionsDebugMode"]) {
            [processArgs removeObjectAtIndex:0];
            [processArgs removeObjectAtIndex:0];
        }
    }
    
    commandLineArguments = [[NSMutableArray alloc] init];
    for (NSString *arg in processArgs) {
        // On older versions of Mac OS X, apps opened from the Finder
        // are passed a process number argument of the form -psn_0_*******
        // We don't hand these over to the script
        if ([arg hasPrefix:@"-psn_"] == FALSE) {
            [commandLineArguments addObject:arg];
        }
    }
    
    // we never have privileged execution or droppable with status menu apps
    if (outputType == PLATYPUS_OUTPUT_STATUSMENU) {
        remainRunning = YES;
        execStyle = PLATYPUS_EXECSTYLE_NORMAL;
        isDroppable = NO;
    }
    
    // load settings for drop acceptance, default is to accept files and not text snippets
    acceptsFiles = ([appSettingsDict objectForKey:@"AcceptsFiles"] != nil) ? [[appSettingsDict objectForKey:@"AcceptsFiles"] boolValue] : YES;
    acceptsText = ([appSettingsDict objectForKey:@"AcceptsText"] != nil) ? [[appSettingsDict objectForKey:@"AcceptsText"] boolValue] : NO;
    
    // equivalent to not being droppable
    if (!acceptsFiles && !acceptsText) {
        isDroppable = FALSE;
    }
    
    // initialize this to NO, then check the droppableSuffixes for 'fold'
    acceptDroppedFolders = NO;
    // initialize this to NO, then check the droppableSuffixes for *, and droppableFileTypes for ****
    acceptAnyDroppedItem = NO;
    
    // if app is droppable, the AppSettings.plist contains list of accepted file types / suffixes
    // we use them later as a criterion for in-code drop acceptance
    if (isDroppable && acceptsFiles) {
        // get list of accepted suffixes
        if ([appSettingsDict objectForKey:@"DropSuffixes"]) {
            droppableSuffixes = [[NSArray alloc] initWithArray:[appSettingsDict objectForKey:@"DropSuffixes"]];
        } else {
            droppableSuffixes = [[NSArray alloc] initWithArray:[NSArray array]];
        }
        
        // see if we accept any dropped item, * suffix indicates if that is the case
        for (NSString *suffix in droppableSuffixes) {
            if ([suffix isEqualToString:@"*"]) {
                acceptAnyDroppedItem = YES;
            }
        }
    }
    
    //get interpreter
    NSString *scriptInterpreter = [appSettingsDict objectForKey:@"ScriptInterpreter"];
    if (scriptInterpreter == nil || ![FILEMGR fileExistsAtPath:scriptInterpreter]) {
        [Alerts fatalAlert:@"Missing interpreter" subText:[NSString stringWithFormat:@"This application cannot run because the interpreter '%@' does not exist on this system.", scriptInterpreter]];
    }
    interpreter = [[NSString alloc] initWithString:scriptInterpreter];

    //if the script is not "secure" then we need a script file, otherwise we need data in AppSettings.plist
    if ((!secureScript && ![FILEMGR fileExistsAtPath:[appBundle pathForResource:@"script" ofType:nil]]) ||
        (secureScript && [appSettingsDict objectForKey:@"TextSettings"] == nil)) {
        [Alerts fatalAlert:@"Corrupt app bundle" subText:@"Script missing from application bundle."];
    }
    
    //get path to script within app bundle
    if (!secureScript) {
        scriptPath = [[NSString alloc] initWithString:[appBundle pathForResource:@"script" ofType:nil]];
        
        // make sure we can read the script file
        if ([FILEMGR isReadableFileAtPath:scriptPath] == NO) {
            // chmod 774
            chmod([scriptPath cStringUsingEncoding:NSUTF8StringEncoding], S_IRWXU | S_IRWXG | S_IROTH);
        }
        if ([FILEMGR isReadableFileAtPath:scriptPath] == NO) {
            [Alerts fatalAlert:@"Corrupt app bundle" subText:@"Script file is not readable."];
        }
    }
    //if we have a "secure" script, there is no path to get. We write script to temp location on execution
    else {
        NSData *b_str = [NSKeyedUnarchiver unarchiveObjectWithData:[appSettingsDict objectForKey:@"TextSettings"]];
        if (b_str == nil) {
            [Alerts fatalAlert:@"Corrupt app bundle" subText:@"Script missing from application bundle."];
        }
        // we create string with the script based on the decoded data
        scriptText = [[NSString alloc] initWithData:b_str encoding:textEncoding];
    }
}

#pragma mark - App Delegate handlers

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [NSApp setServicesProvider:self]; // register as text handling service
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    // status menu apps just run when item is clicked
    // for all others, we run the script once app has been launched
    if (outputType == PLATYPUS_OUTPUT_STATUSMENU) {
        return;
    }
    
    if (promptForFileOnLaunch && isDroppable && ![jobQueue count]) {
        [self openFiles:self];
    } else {
        [self performSelector:@selector(executeScriptIfNothingDropped) withObject:nil afterDelay:0.1];
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}

- (void)application:(NSApplication *)theApplication openFiles:(NSArray *)filenames {

    // add the dropped files as a job for processing
    NSInteger ret = [self addDroppedFilesJob:filenames];
    
    // if no other job is running, we execute
    if (!isTaskRunning && ret) {
        [self executeScript];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // again, make absolutely sure we don't leave the clear-text script in temp directory
    if (secureScript && [FILEMGR fileExistsAtPath:scriptPath]) {
        [FILEMGR removeItemAtPath:scriptPath error:nil];
    }
    
    //terminate task
    if (task != nil) {
        if ([task isRunning]) {
            [task terminate];
        }
        [task release];
    }
    
    //terminate privileged task
    if (privilegedTask != nil) {
        if ([privilegedTask isRunning]) {
            [privilegedTask terminate];
        }
        [privilegedTask release];
    }
    
    // hide status item
    if (statusItem) {
        [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
    }
    
    // clean out the job queue since we're quitting
    [jobQueue removeAllObjects];
    
    return YES;
}

#pragma mark - Interface manipulation

/****************************************
 Set up any menu items, windows, controls
 at application launch time based on output mode
 ****************************************/

- (void)initialiseInterface {
    
    //put application name into the relevant menu items
    [quitMenuItem setTitle:[NSString stringWithFormat:@"Quit %@", appName]];
    [aboutMenuItem setTitle:[NSString stringWithFormat:@"About %@", appName]];
    [hideMenuItem setTitle:[NSString stringWithFormat:@"Hide %@", appName]];
    
    // script output will be dumped in outputTextView, by default this is the Text Window text view
    outputTextView = textOutputTextView;
    
    // force us to be front process if we run in background
    // This is so that apps that are set to run in the background will still have their
    // window come to the front.  It is to my knowledge the only way to make an
    // application with LSUIElement set to true come to the front on launch
    // We don't do this for applications with no user interface output
    if (outputType != PLATYPUS_OUTPUT_NONE) {
//        ProcessSerialNumber process;
//        GetCurrentProcess(&process);
//        SetFrontProcess(&process);
        // Old Carbon SetFrontProcess call replaced with Cocoa
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    }
    
    //prepare controls etc. for different output types
    switch (outputType) {
        case PLATYPUS_OUTPUT_NONE:
        {
            // nothing to do
        }
            break;
            
        case PLATYPUS_OUTPUT_PROGRESSBAR:
        {
            if (isDroppable) {
                [progressBarWindow registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, nil]];
            }
            
            // add menu item for Show Details
            [[windowMenu insertItemWithTitle:@"Toggle Details" action:@selector(performClick:) keyEquivalent:@"T" atIndex:2] setTarget:progressBarDetailsTriangle];
            [windowMenu insertItem:[NSMenuItem separatorItem] atIndex:2];
            
            // style the text field
            outputTextView = progressBarTextView;
            [outputTextView setFont:textFont];
            [outputTextView setTextColor:textForeground];
            [outputTextView setBackgroundColor:textBackground];
            
            // add drag instructions message if droplet
            NSString *progBarMsg = isDroppable ? @"Drag files to process" : @"Running...";
            [progressBarMessageTextField setStringValue:progBarMsg];
            [progressBarIndicator setUsesThreadedAnimation:YES];
            
            //preare window
            [progressBarWindow setTitle:appName];
            
            //center it if first time running the application
            if ([[progressBarWindow frameAutosaveName] isEqualToString:@""]) {
                [progressBarWindow center];
            }
            
            // reveal it
            [progressBarWindow makeKeyAndOrderFront:self];
        }
            break;
            
        case PLATYPUS_OUTPUT_TEXTWINDOW:
        {
            if (isDroppable) {
                [textOutputWindow registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, nil]];
                [textOutputMessageTextField setStringValue:@"Drag files on window to process them"];
            }
            
            // style the text field
            [outputTextView setString:@"\n"];
            [outputTextView setFont:textFont];
            [outputTextView setTextColor:textForeground];
            [outputTextView setBackgroundColor:textBackground];
            
            [textOutputProgressIndicator setUsesThreadedAnimation:YES];
            
            // prepare window
            [textOutputWindow setTitle:appName];
            if ([[textOutputWindow frameAutosaveName] isEqualToString:@""]) {
                [textOutputWindow center];
            }
            [textOutputWindow makeKeyAndOrderFront:self];
        }
            break;
            
        case PLATYPUS_OUTPUT_WEBVIEW:
        {
            if (isDroppable) {
                [webOutputWindow registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, nil]];
                [webOutputWebView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, nil]];
                [webOutputMessageTextField setStringValue:@"Drag files on window to process them"];
            }
            
            [webOutputProgressIndicator setUsesThreadedAnimation:YES];
            
            // prepare window
            [webOutputWindow setTitle:appName];
            [webOutputWindow center];
            if ([[webOutputWindow frameAutosaveName] isEqualToString:@""]) {
                [webOutputWindow center];
            }
            [webOutputWindow makeKeyAndOrderFront:self];
        }
            break;
            
        case PLATYPUS_OUTPUT_STATUSMENU:
        {
            // create and activate status item
            statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
            [statusItem setHighlightMode:YES];
            
            // set status item title and icon
            [statusItem setTitle:statusItemTitle];
            NSImage *icon = statusItemIcon;
            [icon setSize:NSMakeSize(18, 18)];
            [statusItem setImage:icon];
            
            // create menu for our status item
            statusItemMenu = [[NSMenu alloc] initWithTitle:@""];
            [statusItemMenu setDelegate:self];
            [statusItem setMenu:statusItemMenu];
            
            //create Quit menu item
            NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Quit %@", appName] action:@selector(terminate:) keyEquivalent:@""] autorelease];
            [statusItemMenu insertItem:menuItem atIndex:0];
            [statusItemMenu insertItem:[NSMenuItem separatorItem] atIndex:0];
            
            // enable it
            [statusItem setEnabled:YES];
        }
            break;
            
        case PLATYPUS_OUTPUT_DROPLET:
        {
            if (isDroppable) {
                [dropletWindow registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, nil]];
            }
            [dropletProgressIndicator setUsesThreadedAnimation:YES];
            
            // prepare window
            [dropletWindow setTitle:appName];
            if ([[dropletWindow frameAutosaveName] isEqualToString:@""]) {
                [dropletWindow center];
            }
            [dropletWindow makeKeyAndOrderFront:self];
        }
            break;
    }
}

/****************************************
 
 Prepare all the controls, windows, etc.
 prior to the execution of the script
 
 ****************************************/

- (void)prepareInterfaceForExecution {
    switch (outputType) {
        case PLATYPUS_OUTPUT_NONE:
        {
            
        }
            break;
            
        case PLATYPUS_OUTPUT_PROGRESSBAR:
        {
            [progressBarIndicator setIndeterminate:YES];
            [progressBarIndicator startAnimation:self];
            [progressBarMessageTextField setStringValue:@"Running..."];
            [outputTextView setString:@"\n"];
            [progressBarCancelButton setTitle:@"Cancel"];
            if (execStyle == PLATYPUS_EXECSTYLE_PRIVILEGED) {
                [progressBarCancelButton setEnabled:NO];
            }
        }
            break;
            
        case PLATYPUS_OUTPUT_TEXTWINDOW:
        {
            [outputTextView setString:@"\n"];
            [textOutputCancelButton setTitle:@"Cancel"];
            if (execStyle == PLATYPUS_EXECSTYLE_PRIVILEGED) {
                [textOutputCancelButton setEnabled:NO];
            }
            [textOutputProgressIndicator startAnimation:self];
        }
            break;
            
        case PLATYPUS_OUTPUT_WEBVIEW:
        {
            [outputTextView setString:@"\n"];
            [webOutputCancelButton setTitle:@"Cancel"];
            if (execStyle == PLATYPUS_EXECSTYLE_PRIVILEGED) {
                [webOutputCancelButton setEnabled:NO];
            }
            [webOutputProgressIndicator startAnimation:self];
        }
            break;
            
        case PLATYPUS_OUTPUT_STATUSMENU:
        {
            [outputTextView setString:@"\n"];
        }
            break;
            
        case PLATYPUS_OUTPUT_DROPLET:
        {
            [dropletProgressIndicator setIndeterminate:YES];
            [dropletProgressIndicator startAnimation:self];
            [dropletDropFilesLabel setHidden:YES];
            [dropletMessageTextField setHidden:NO];
            [dropletMessageTextField setStringValue:@"Processing..."];
            [outputTextView setString:@"\n"];
        }
            break;
            
    }
}

/****************************************
 
 Adjust controls, windows, etc. once script
 is done executing

 ****************************************/

- (void)cleanupInterface {
    switch (outputType) {
            
        case PLATYPUS_OUTPUT_NONE:
        case PLATYPUS_OUTPUT_STATUSMENU:
        {
            
        }
            break;

        case PLATYPUS_OUTPUT_TEXTWINDOW:
        {
            //update controls for text output window
            [textOutputCancelButton setTitle:@"Quit"];
            [textOutputCancelButton setEnabled:YES];
            [textOutputProgressIndicator stopAnimation:self];
        }
            break;
            
        case PLATYPUS_OUTPUT_PROGRESSBAR:
        {
            // if there are any remnants, we append them to output
            if (remnants != nil) {
                NSTextStorage *text = [outputTextView textStorage];
                [text replaceCharactersInRange:NSMakeRange([text length], 0) withString:remnants];
                [remnants release];
                remnants = nil;
            }
            
            if (isDroppable) {
                [progressBarMessageTextField setStringValue:@"Drag files to process"];
                [progressBarIndicator setIndeterminate:YES];
            } else {
                // cleanup - if the script didn't give us a proper status message, then we set one
                if ([[progressBarMessageTextField stringValue] isEqualToString:@""] ||
                    [[progressBarMessageTextField stringValue] isEqualToString:@"\n"] ||
                    [[progressBarMessageTextField stringValue] isEqualToString:@"Running..."]) {
                    [progressBarMessageTextField setStringValue:@"Task completed"];
                }
                [progressBarIndicator setIndeterminate:NO];
                [progressBarIndicator setDoubleValue:100];
            }
            
            //update controls for progress bar output
            [progressBarIndicator stopAnimation:self];
            
            // change button
            [progressBarCancelButton setTitle:@"Quit"];
            [progressBarCancelButton setEnabled:YES];
        }
            break;
            
        case PLATYPUS_OUTPUT_WEBVIEW:
        {
            //update controls for web output window
            [webOutputCancelButton setTitle:@"Quit"];
            [webOutputCancelButton setEnabled:YES];
            [webOutputProgressIndicator stopAnimation:self];
        }
            break;
            
        case PLATYPUS_OUTPUT_DROPLET:
        {
            [dropletProgressIndicator stopAnimation:self];
            [dropletDropFilesLabel setHidden:NO];
            [dropletMessageTextField setHidden:YES];
        }
            break;
    }
}

#pragma mark - Task

// construct arguments list etc. before actually running the script
- (void)prepareForExecution {
    // if it is a "secure" script, we decode and write it to a temp directory
    if (secureScript) {
        
        NSString *tempScriptPath = [WORKSPACE createTempFileWithContents:scriptText usingTextEncoding:textEncoding];
        if (!tempScriptPath) {
            [Alerts fatalAlert:@"Failed to write script file" subText:[NSString stringWithFormat:@"Could not create the temp file '%@'", tempScriptPath]];
        }
        // chmod 774 - make file executable
        chmod([tempScriptPath cStringUsingEncoding:NSUTF8StringEncoding], S_IRWXU | S_IRWXG | S_IROTH);
        scriptPath = [NSString stringWithString:tempScriptPath];
    }
    
    //clear arguments list and reconstruct it
    [arguments removeAllObjects];
    
    // first, add all specified arguments for interpreter
    [arguments addObjectsFromArray:interpreterArgs];
    
    // add script as argument to interpreter, if it exists
    if (![FILEMGR fileExistsAtPath:scriptPath]) {
        [Alerts fatalAlert:@"Missing script" subText:@"Script missing at execution path"];
    }
    [arguments addObject:scriptPath];
    
    // add arguments for script
    [arguments addObjectsFromArray:scriptArgs];
    
    // if initial run of app, add any arguments passed in via the command line (argv)
    // this is pretty obscure (why CLI args for GUI app typically launched from Finder?)
    // but apparently helpful for certain use cases such as Firefox protocol handlers etc.
    if (commandLineArguments && [commandLineArguments count]) {
        [arguments addObjectsFromArray:commandLineArguments];
        commandLineArguments = nil;
    }
    
    //finally, dequeue job and add arguments 
    if ([jobQueue count] > 0) {
        ScriptExecJob *job = [jobQueue objectAtIndex:0];

        // we have files in the queue, to append as arguments
        // we take the first job's arguments and put them into the arg list
        if ([job arguments]) {
            [arguments addObjectsFromArray:[job arguments]];
        }
        stdinString = [[job standardInputString] copy];
        
        [jobQueue removeObjectAtIndex:0];
    }
}

- (void)executeScriptIfNothingDropped {
    if (hasTaskRun == FALSE) {
        [self executeScript];
    }
}

- (void)executeScript {
    hasTaskRun = YES;
    
    // we never execute script if there is one running
    if (isTaskRunning) {
        return;
    }
    if (outputType != PLATYPUS_OUTPUT_NONE) {
        outputEmpty = NO;
    }
    
    [self prepareForExecution];
    [self prepareInterfaceForExecution];
    
    isTaskRunning = YES;
    
    // run the task
    if (execStyle == PLATYPUS_EXECSTYLE_PRIVILEGED) {
        [self executeScriptWithPrivileges];
    } else {
        [self executeScriptWithoutPrivileges];
    }
}

//launch regular user-privileged process using NSTask
- (void)executeScriptWithoutPrivileges {

    //create task and apply settings
    task = [[NSTask alloc] init];
    [task setLaunchPath:interpreter];
    [task setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    [task setArguments:arguments];
    
    // direct output to file handle and start monitoring it if script provides feedback
    if (outputType != PLATYPUS_OUTPUT_NONE) {
        outputPipe = [NSPipe pipe];
        [task setStandardOutput:outputPipe];
        [task setStandardError:outputPipe];
        outputReadFileHandle = [outputPipe fileHandleForReading];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOutputData:) name:NSFileHandleReadCompletionNotification object:outputReadFileHandle];
        [outputReadFileHandle readInBackgroundAndNotify];
    }
    
    // set up stdin for writing
    inputPipe = [NSPipe pipe];
    [task setStandardInput:inputPipe];
    inputWriteFileHandle = [[task standardInput] fileHandleForWriting];
    
    //set it off
    [task launch];
    
    // write input, if any, to stdin, and then close
    if (stdinString) {
        [inputWriteFileHandle writeData:[stdinString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [inputWriteFileHandle closeFile];
    stdinString = nil;
    
    // we wait until task exits if this is triggered by a status item menu
    if (outputType == PLATYPUS_OUTPUT_STATUSMENU) {
        [task waitUntilExit];
    }
}

//launch task with admin privileges using Authentication Manager
- (void)executeScriptWithPrivileges {
    //initalize task
    privilegedTask = [[STPrivilegedTask alloc] init];
    
    //apply settings for task
    [privilegedTask setLaunchPath:interpreter];
    [privilegedTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    [privilegedTask setArguments:arguments];
    
    //set it off
    OSStatus err = [privilegedTask launch];
    if (err != errAuthorizationSuccess) {
        if (err == errAuthorizationCanceled) {
            outputEmpty = YES;
            [self taskFinished:nil];
            return;
        }  else {
            // something went wrong
            [Alerts fatalAlert:@"Failed to execute script" subText:[NSString stringWithFormat:@"Error %d occurred while executing script with privileges.", (int)err]];
        }
    }
    
    if (outputType != PLATYPUS_OUTPUT_NONE) {
        // Success!  Now, start monitoring output file handle for data
        outputReadFileHandle = [privilegedTask outputFileHandle];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOutputData:) name:NSFileHandleReadCompletionNotification object:outputReadFileHandle];
        [outputReadFileHandle readInBackgroundAndNotify];
    }
}

#pragma mark - Task completion

// OK, called when we receive notification that task is finished
// Some cleaning up to do, controls need to be adjusted, etc.
- (void)taskFinished:(NSNotification *)aNotification {
    // if task already quit, we return
    if (!isTaskRunning) {
        return;
    }
    isTaskRunning = NO;
    
    // make sure task is dead.  Ideally we'd like to do the same for privileged tasks, but that's just not possible w/o process id
    if (execStyle == PLATYPUS_EXECSTYLE_NORMAL && task != nil && [task isRunning]) {
        [task terminate];
    }
    
    // did we receive all the data?
    if (outputEmpty) { // if no data left we do the clean up
        [self cleanup];
    }
    
    // if we're using the "secure" script, we must remove the temporary clear-text one in temp directory if there is one
    if (secureScript && [FILEMGR fileExistsAtPath:scriptPath]) {
        [FILEMGR removeItemAtPath:scriptPath error:nil];
    }
    
    // if there are more jobs waiting for us, execute
    if ([jobQueue count] > 0) {
        [self executeScript];
    }
    
    // we quit now if the app isn't set to continue running
    if (!remainRunning) {
        [[NSApplication sharedApplication] terminate:self];
    }
}

- (void)cleanup {
    // we never do cleanup if the task is running
    if (isTaskRunning) {
        return;
    }
    // stop observing the filehandle for data since task is done
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:outputReadFileHandle];
    
    // we make sure to clear the filehandle of any remaining data
    if (outputReadFileHandle != nil) {
        NSData *data;
        while ((data = [outputReadFileHandle availableData]) && [data length]) {
            [self appendOutput:data];
        }
    }
    
    // now, reset all controls etc., general cleanup since task is done
    [self cleanupInterface];
}

#pragma mark - Output

// read from the file handle and append it to the text window
- (void)getOutputData:(NSNotification *)aNotification {
    // get the data from notification
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    
    // make sure there's actual data
    if ([data length]) {
        outputEmpty = NO;
        
        // append the output to the text field
        [self appendOutput:data];
        
        // we schedule the file handle to go and read more data in the background again.
        [[aNotification object] readInBackgroundAndNotify];
    }
    else {
        outputEmpty = YES;
        if (!isTaskRunning) {
            [self cleanup];
        }
    }
}

// this function receives all new data dumped out by the script and appends it to text field
// it is *relatively* memory efficient (given the nature of NSTextView)
- (void)appendOutput:(NSData *)data {
    // we decode the script output according to specified character encoding
    NSMutableString *outputString = [[NSMutableString alloc] initWithData:data encoding:textEncoding];
    
    if (!outputString || [outputString length] == 0) {
        if (outputString) {
            [outputString release];
        }
        return;
    }
    
    if (remnants != nil && [remnants length] > 0) {
        [outputString insertString:remnants atIndex:0];
    }
    
    // parse
    NSMutableArray *lines = [NSMutableArray arrayWithArray:[outputString componentsSeparatedByString:@"\n"]];
        
    // if the line did not end with a newline, it wasn't a complete line of output
    // Thus, we store the last line and then delete it from the outputstring
    // It'll be appended next time we get output
    if ([(NSString *)[lines lastObject] length] > 0) {
        if (remnants != nil) {
            [remnants release];
            remnants = nil;
        }
        remnants = [[NSString alloc] initWithString:[lines lastObject]];
        [outputString deleteCharactersInRange:NSMakeRange([outputString length] - [remnants length], [remnants length])];
    } else {
        remnants = nil;
    }
    
    [lines removeLastObject];
    
    // parse output looking for commands; if none, add line to output text field
    for (NSString *theLine in lines) {
        
        // if the line is empty, we ignore it
        if ([theLine isEqualToString:@""]) {
            continue;
        }
        
        if ([theLine hasPrefix:@"QUITAPP"]) {
            [[NSApplication sharedApplication] terminate:self];
            break;
        }
        
        if ([theLine hasPrefix:@"NOTIFICATION:"]) {
            NSString *notificationString = [theLine substringFromIndex:13];
            [self showNotification:notificationString];
            continue;
        }
        
        if ([theLine hasPrefix:@"ALERT:"]) {
            NSString *alertString = [theLine substringFromIndex:6];
            NSArray *components = [alertString componentsSeparatedByString:@"|"];
            [Alerts alert:[components objectAtIndex:0]
                  subText:[components count] > 1 ? [components objectAtIndex:1] : [components objectAtIndex:0]];
            continue;
        }
        
        // special commands to control progress bar output window
        if (outputType == PLATYPUS_OUTPUT_PROGRESSBAR) {
            
            // set progress bar status
            // lines starting with PROGRESS:\d+ are interpreted as percentage to set progress bar
            if ([theLine hasPrefix:@"PROGRESS:"]) {
                NSString *progressPercentString = [theLine substringFromIndex:9];
                
                // Parse percentage using number formatter
                NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
                numFormatter.numberStyle = NSNumberFormatterDecimalStyle;
                NSNumber *percentageNumber = [numFormatter numberFromString:progressPercentString];
                
                if (percentageNumber != nil) {
                    [progressBarIndicator setIndeterminate:NO];
                    [progressBarIndicator setDoubleValue:[percentageNumber doubleValue]];
                }
                [numFormatter release];
                continue;
            }
            // set visibility of details text field
            else if ([theLine hasPrefix:@"DETAILS:SHOW"]) {
                [self showDetails];
                continue;
            }
            else if ([theLine hasPrefix:@"DETAILS:HIDE"]) {
                [self hideDetails];
                continue;
            }
        }
        
        // ok, line wasn't a command understood by the wrapper
        // show it in GUI text field if appropriate
        if (outputType == PLATYPUS_OUTPUT_DROPLET) {
            [dropletMessageTextField setStringValue:theLine];
        }
        if (outputType == PLATYPUS_OUTPUT_PROGRESSBAR) {
            [progressBarMessageTextField setStringValue:theLine];
        }
    }
    
    // append the ouput to the text in the text field
    NSTextStorage *textStorage = [outputTextView textStorage];
    int textReplacementIndex = [textStorage length];
    
    NSRange appendRange = NSMakeRange(textReplacementIndex, 0);
    // this is a hack to fix the bug where NSTextView loses all font attributes
    // if the text storage is empty. We set contents to a newline earlier, now
    // we remove it and font attributes remain
    if (textReplacementIndex == 1 && [[outputTextView string] isEqualToString:@"\n"]) {
        appendRange = NSMakeRange(0, 1);
    }
    
    [textStorage replaceCharactersInRange:appendRange withString:outputString];
    
    // if web output, we continually re-render to accomodate incoming data, else we scroll down
    if (outputType == PLATYPUS_OUTPUT_WEBVIEW) {

        NSArray *htmlLines = [[textStorage string] componentsSeparatedByString: @"\n"];

        // Check for 'Location: *URL*' In that case, we load the URL in the web view
        if ([htmlLines count] > 0 && [[htmlLines objectAtIndex:1] hasPrefix:@"Location:"]) {
            NSString *url = [[htmlLines objectAtIndex: 1] substringFromIndex:9];
            url = [url stringByReplacingOccurrencesOfString:@" " withString:@""];
            [[webOutputWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] ];
        } else {
            // otherwise, just load script output as HTML string
            NSURL *resourcePathURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]];
            [[webOutputWebView mainFrame] loadHTMLString:[outputTextView string] baseURL:resourcePathURL];
        }
    } else if (outputType == PLATYPUS_OUTPUT_TEXTWINDOW || outputType == PLATYPUS_OUTPUT_PROGRESSBAR) {
        [outputTextView scrollRangeToVisible:NSMakeRange([textStorage length], 0)];
    }
    
    [outputString release];
}

#pragma mark - Interface actions

//run open panel, made available to apps that are droppable
- (IBAction)openFiles:(id)sender {
    
    //create open panel
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setPrompt:@"Open"];
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setCanChooseFiles:YES];
    [oPanel setCanChooseDirectories:acceptDroppedFolders];
    
    // set acceptable file types - default allows all
    if (!acceptAnyDroppedItem) {
        [oPanel setAllowedFileTypes:droppableSuffixes];
    }
    
    if ([oPanel runModal] == NSFileHandlingPanelOKButton) {
        // Convert URLs to paths
        NSMutableArray *files = [NSMutableArray arrayWithArray:[oPanel URLs]];
        for (NSInteger i = 0; i < [files count]; i++) {
            [files replaceObjectAtIndex:i withObject:[(NSURL *)[files objectAtIndex:i] path]];
        }
        
        NSInteger ret = [self addDroppedFilesJob:files];
        if (!isTaskRunning && ret) {
            [self executeScript];
        }
    }
}

// show / hide the details text field in progress bar output
- (IBAction)toggleDetails:(id)sender {
    NSRect winRect = [progressBarWindow frame];
    
    if ([sender state] == NSOffState) {
        [progressBarWindow setShowsResizeIndicator:NO];
        winRect.origin.y += 224;
        winRect.size.height -= 224;
        [progressBarWindow setFrame:winRect display:TRUE animate:TRUE];
    }
    else {
        [progressBarWindow setShowsResizeIndicator:YES];
        winRect.origin.y -= 224;
        winRect.size.height += 224;
        [progressBarWindow setFrame:winRect display:TRUE animate:TRUE];
    }
}

// show the details text field in progress bar output
- (IBAction)showDetails {
    if ([progressBarDetailsTriangle state] == NSOffState) {
        [progressBarDetailsTriangle performClick:progressBarDetailsTriangle];
    }
}

// hide the details text field in progress bar output
- (IBAction)hideDetails {
    if ([progressBarDetailsTriangle state] != NSOffState) {
        [progressBarDetailsTriangle performClick:progressBarDetailsTriangle];
    }
}

// save output in text field to file when Save to File menu item is invoked
- (IBAction)saveToFile:(id)sender {
    if (outputType != PLATYPUS_OUTPUT_TEXTWINDOW &&
        outputType != PLATYPUS_OUTPUT_WEBVIEW &&
        outputType != PLATYPUS_OUTPUT_PROGRESSBAR) {
        return;
    }
    NSString *outSuffix = (outputType == PLATYPUS_OUTPUT_WEBVIEW) ? @"html" : @"txt";
    NSString *fileName = [NSString stringWithFormat:@"%@-Output.%@", appName, outSuffix];
    
    NSSavePanel *sPanel = [NSSavePanel savePanel];
    [sPanel setPrompt:@"Save"];
    [sPanel setNameFieldStringValue:fileName];
    
    if ([sPanel runModal] == NSFileHandlingPanelOKButton) {
        NSError *err;
        BOOL success = [[outputTextView string] writeToFile:[[sPanel URL] path] atomically:YES encoding:textEncoding error:&err];
        if (!success) {
            [Alerts alert:@"Error writing file" subText:[err localizedDescription]];
        }
    }
}

// save only works for text window, web view output types
// and open only works for droppable apps that accept files as script args
- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    if (outputType == PLATYPUS_OUTPUT_STATUSMENU) {
        return YES;
    }
    
    //save to file item
    if ([[anItem title] isEqualToString:@"Save to File…"] &&
        (outputType != PLATYPUS_OUTPUT_TEXTWINDOW && outputType != PLATYPUS_OUTPUT_WEBVIEW  && outputType != PLATYPUS_OUTPUT_PROGRESSBAR)) {
        return NO;
    }
    //open should only work if it's a droppable app
    if ([[anItem title] isEqualToString:@"Open…"] &&
        (!isDroppable || !acceptsFiles || [jobQueue count] >= PLATYPUS_MAX_QUEUE_JOBS)) {
        return NO;
    }
    // Make text bigger stuff
    if (outputType != PLATYPUS_OUTPUT_TEXTWINDOW && outputType != PLATYPUS_OUTPUT_PROGRESSBAR &&outputType != PLATYPUS_OUTPUT_WEBVIEW) {
        return NO;
    }
    
    return YES;
}

- (IBAction)cancel:(id)sender {
    
    if (task != nil) {
        [task terminate];
    }
    
    if ([[sender title] isEqualToString:@"Quit"]) {
        [[NSApplication sharedApplication] terminate:self];
    }
}

#pragma mark - Text resizing

- (void)changeFontSize:(CGFloat)delta {
    
    if (outputType == PLATYPUS_OUTPUT_WEBVIEW) {
        // web view
        if (delta > 0) {
            [webOutputWebView makeTextLarger:self];
        } else {
            [webOutputWebView makeTextSmaller:self];
        }
    } else {
        // text field
        NSTextView *textView = outputTextView;
        NSFont *font = [textView font];
        CGFloat newFontSize = [font pointSize] + delta;
        font = [[NSFontManager sharedFontManager] convertFont:font toSize:newFontSize];
        [textView setFont:font];
        [DEFAULTS setObject:[NSNumber numberWithFloat:(float)newFontSize] forKey:@"UserFontSize"];
        [textView didChangeText];
    }
}

- (IBAction)makeTextBigger:(id)sender {
    [self changeFontSize:1];
}

- (IBAction)makeTextSmaller:(id)sender {
    [self changeFontSize:-1];
}

#pragma mark - Service handling

- (void)dropService:(NSPasteboard *)pb userData:(NSString *)userData error:(NSString **)err {
    NSArray *types = [pb types];
    BOOL ret = 0;
    id data = nil;
    
    if (acceptsFiles && [types containsObject:NSFilenamesPboardType] && (data = [pb propertyListForType:NSFilenamesPboardType])) {
        ret = [self addDroppedFilesJob:data];  // files
    } else if (acceptsText && [types containsObject:NSStringPboardType] && (data = [pb stringForType:NSStringPboardType])) {
        ret = [self addDroppedTextJob:data];  // text
    } else {
        // unknown
        *err = @"Data type in pasteboard cannot be handled by this application.";
        return;
    }
    
    if (!isTaskRunning && ret) {
        [self executeScript];
    }
}

#pragma mark - Text snippet drag handling

- (void)doString:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
    if (!isDroppable || !acceptsText || [jobQueue count] >= PLATYPUS_MAX_QUEUE_JOBS) {
        return;
    }
    NSString *pboardString = [pboard stringForType:NSStringPboardType];
    NSInteger ret = [self addDroppedTextJob:pboardString];
    
    if (!isTaskRunning && ret) {
        [self executeScript];
    }
}

#pragma mark - Create drop job

- (BOOL)addTextJob:(NSString *)text {
    if ([text length] <= 0) { // ignore empty strings
        return NO;
    }
    
    // add job with text as argument for script
    ScriptExecJob *job = [ScriptExecJob jobWithArguments:nil andStandardInput:text];
    [jobQueue addObject:job];
    return YES;
}

- (BOOL)addDroppedTextJob:(NSString *)text {
    if (!isDroppable || [jobQueue count] >= PLATYPUS_MAX_QUEUE_JOBS) {
        return NO;
    }
    return [self addTextJob:text];
}

// processing dropped files
- (BOOL)addDroppedFilesJob:(NSArray *)files {
    if (!isDroppable || !acceptsFiles || [jobQueue count] >= PLATYPUS_MAX_QUEUE_JOBS) {
        return NO;
    }
    
    // we only accept the drag if at least one of the files meets the required types
    NSMutableArray *acceptedFiles = [NSMutableArray array];
    for (NSString *file in files) {
        if ([self isAcceptableFileType:file]) {
            [acceptedFiles addObject:file];
        }
    }
    
    // if at this point there are no accepted files, we refuse drop
    if ([acceptedFiles count] == 0) {
        return NO;
    }
    
    // we create a processing job and add the files as arguments
    NSMutableArray *args = [NSMutableArray array];
    [args addObjectsFromArray:acceptedFiles];
    ScriptExecJob *job = [ScriptExecJob jobWithArguments:args andStandardInput:nil];
    [jobQueue addObject:job];
    
    // accept drop
    return YES;
}

/*****************************************************************
 Returns whether a given file is accepted by the suffix/types
 criterion specified in AppSettings.plist
 *****************************************************************/

- (BOOL)isAcceptableFileType:(NSString *)file {
    BOOL isDir;
    
    // Check if it's a folder. If so, we only accept it if folders are accepted
    if ([FILEMGR fileExistsAtPath:file isDirectory:&isDir] && isDir && acceptDroppedFolders) {
        return YES;
    }
    
    if (acceptAnyDroppedItem) {
        return YES;
    }
    
    // see if file has accepted suffix
    for (NSString *suffix in droppableSuffixes) {
        if ([file hasSuffix:suffix]) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Drag and drop handling

// check file types against acceptable drop types here before accepting them
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo> )sender {
    BOOL acceptDrag = NO;
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    // if this is a file being dragged
    if ([[pboard types] containsObject:NSFilenamesPboardType] && acceptsFiles) {
        // loop through files, see if any of the dragged files are acceptable
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        
        for (NSString *file in files) {
            if ([self isAcceptableFileType:file]) {
                acceptDrag = YES;
            }
        }
    }
    // if this is a string being dragged
    else if ([[pboard types] containsObject:NSStringPboardType] && acceptsText) {
        acceptDrag = YES;
    }
    
    if (acceptDrag) {
        // we shade the window if output is droplet mode
        if (outputType == PLATYPUS_OUTPUT_DROPLET) {
            [dropletShader setAlphaValue:0.3];
            [dropletShader setHidden:NO];
        }
        return NSDragOperationLink;
    }
    
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo> )sender;
{
    // remove the droplet shading on drag exit
    if (outputType == PLATYPUS_OUTPUT_DROPLET) {
        [dropletShader setHidden:YES];
    }
}

- (BOOL)performDragOperation:(id <NSDraggingInfo> )sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    // determine drag data type and dispatch to job queue
    if ([[pboard types] containsObject:NSStringPboardType]) {
        return [self addDroppedTextJob:[pboard stringForType:NSStringPboardType]];
    } else if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        return [self addDroppedFilesJob:[pboard propertyListForType:NSFilenamesPboardType]];
    }
    return NO;
}

// once the drag is over, we immediately execute w. files as arguments if not already processing
- (void)concludeDragOperation:(id <NSDraggingInfo> )sender {
    
    // shade droplet
    if (outputType == PLATYPUS_OUTPUT_DROPLET) {
        [dropletShader setHidden:YES];
    }
    // fire off the job queue if nothing is running
    if (!isTaskRunning && [jobQueue count] > 0) {
        [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(executeScript) userInfo:nil repeats:NO];
    }
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo> )sender {
    // this is needed to keep link instead of the green plus sign on web view
    // also required to reject non-acceptable dragged items
    return [self draggingEntered:sender];
}

#pragma mark - Web View Output updating

/**************************************************
 Called whenever web view re-renders.  We scroll to
 the bottom on each re-rendering.
 **************************************************/

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    NSScrollView *scrollView = [[[[webOutputWebView mainFrame] frameView] documentView] enclosingScrollView];
    NSRect bounds = [[[[webOutputWebView mainFrame] frameView] documentView] bounds];
    [[scrollView documentView] scrollPoint:NSMakePoint(0, bounds.size.height)];
}

#pragma mark - Status Menu

/**************************************************
 Called whenever status item is clicked.  We run
 script, get output and generate menu with the ouput
 **************************************************/

- (void)menuNeedsUpdate:(NSMenu *)menu {
    
    // run script and wait until we've received all the script output
    [self executeScript];
    while (isTaskRunning) {
        usleep(100000); // microseconds
    }
    
    // create an array of lines by separating output by newline
    NSMutableArray *lines = [NSMutableArray arrayWithArray:[[outputTextView string] componentsSeparatedByString:@"\n"]];
    
    // clean out any trailing newlines
    while ([[lines lastObject] isEqualToString:@""]) {
        [lines removeLastObject];
    }
    
    // remove all items of previous output
    while ([statusItemMenu numberOfItems] > 2) {
        [statusItemMenu removeItemAtIndex:0];
    }
    
    //populate menu with output from task
    for (int i = [lines count] - 1; i >= 0; i--) {
        NSString *line = [lines objectAtIndex:i];
        NSImage *icon = nil;
        
        if ([line hasPrefix:@"MENUITEMICON|"]) {
            NSArray *tokens = [line componentsSeparatedByString:@"|"];
            if ([tokens count] < 3) {
                continue;
            }
            NSString *imageToken = [tokens objectAtIndex:1];
            // is it a bundled image?
            icon = [NSImage imageNamed:imageToken];
            
            // if not, it could be a URL
            if (icon == nil) {
                // or a file system path
                BOOL isDir;
                if ([FILEMGR fileExistsAtPath:imageToken isDirectory:&isDir] && !isDir) {
                    icon = [[[NSImage alloc] initByReferencingFile:imageToken] autorelease];
                } else {
                    NSURL *url = [NSURL URLWithString:imageToken];
                    if (url != nil) {
                        icon = [[[NSImage alloc] initWithContentsOfURL:url] autorelease];
                    }
                }
            }
            
            [icon setSize:NSMakeSize(16, 16)];
            line = [tokens objectAtIndex:2];
        }
        
        // create the menu item
        NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:line action:@selector(menuItemSelected:) keyEquivalent:@""] autorelease];
        
        // set the formatted menu item string
        if (statusItemUsesSystemFont) {
            [menuItem setTitle:line];
        } else {
            // create a dict of text attributes based on settings
            NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                            //textBackground, NSBackgroundColorAttributeName,
                                            textForeground, NSForegroundColorAttributeName,
                                            textFont, NSFontAttributeName,
                                            nil];
            
            NSAttributedString *attStr = [[[NSAttributedString alloc] initWithString:line attributes:textAttributes] autorelease];
            [menuItem setAttributedTitle:attStr];
        }
        
        if (icon != nil) {
            [menuItem setImage:icon];
        }
        
        [menu insertItem:menuItem atIndex:0];
    }
}

- (IBAction)menuItemSelected:(id)sender {
    [self addTextJob:[sender title]];
    if (!isTaskRunning && [jobQueue count] > 0) {
        [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(executeScript) userInfo:nil repeats:NO];
    }
}

#pragma mark - Utility methods

- (void)showNotification:(NSString *)notificationText {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = appName;
    notification.informativeText = notificationText;
    notification.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    [notification release];
}

@end
