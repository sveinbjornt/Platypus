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
    
    // these are explicitly alloc'd in the program
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
    if (script != nil) {
        [script release];
    }
    if (statusItem != nil) {
        [statusItem release];
    }
    if (statusItemMenu != nil) {
        [statusItemMenu release];
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
    NSString *notificationName = (execStyle == PLATYPUS_PRIVILEGED_EXECUTION) ? STPrivilegedTaskDidTerminateNotification : NSTaskDidTerminateNotification;
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
    
    NSDictionary *appSettingsPlist;
    NSBundle *appBundle = [NSBundle mainBundle];
    NSString *appSettingsPath = [appBundle pathForResource:@"AppSettings.plist" ofType:nil];
    
    //make sure all the config files are present -- if not, we quit
    if (![FILEMGR fileExistsAtPath:appSettingsPath]) {
        [self fatalAlert:@"Corrupt app bundle" subText:@"AppSettings.plist missing from the application bundle."];
    }
    
    // get app name
    // first, try to get CFBundleDisplayName from Info.plist
    NSDictionary *infoPlist = [appBundle infoDictionary];
    if ([infoPlist objectForKey:@"CFBundleDisplayName"] != nil) {
        appName = [[NSString alloc] initWithString:[infoPlist objectForKey:@"CFBundleDisplayName"]];
    } else {
        // if that doesn't work, use name of executable file
        appName = [[[appBundle executablePath] lastPathComponent] retain];
    }
    
    //get dictionary with app settings
    appSettingsPlist = [NSDictionary dictionaryWithContentsOfFile:appSettingsPath];
    if (appSettingsPlist == nil) {
        [self fatalAlert:@"Corrupt app settings" subText:@"Unable to load AppSettings.plist"];
    }
    
    //determine output type
    NSString *outputTypeStr = [appSettingsPlist objectForKey:@"OutputType"];
    if ([outputTypeStr isEqualToString:@"Progress Bar"]) {
        outputType = PLATYPUS_PROGRESSBAR_OUTPUT;
    } else if ([outputTypeStr isEqualToString:@"Text Window"]) {
        outputType = PLATYPUS_TEXTWINDOW_OUTPUT;
    } else if ([outputTypeStr isEqualToString:@"Web View"]) {
        outputType = PLATYPUS_WEBVIEW_OUTPUT;
    } else if ([outputTypeStr isEqualToString:@"Status Menu"]) {
        outputType = PLATYPUS_STATUSMENU_OUTPUT;
    } else if ([outputTypeStr isEqualToString:@"Droplet"]) {
        outputType = PLATYPUS_DROPLET_OUTPUT;
    } else if ([outputTypeStr isEqualToString:@"None"]) {
        outputType = PLATYPUS_NONE_OUTPUT;
    } else {
        [self fatalAlert:@"Corrupt app settings" subText:@"Invalid Output Mode."];
    }
    
    // we need some additional info from AppSettings.plist if we are presenting textual output
    if (outputType == PLATYPUS_PROGRESSBAR_OUTPUT ||
        outputType == PLATYPUS_TEXTWINDOW_OUTPUT ||
        outputType == PLATYPUS_STATUSMENU_OUTPUT) {
        //make sure all this data is sane, revert to defaults if not
        
        // font and size
        NSNumber *userFontSizeNum = [DEFAULTS objectForKey:@"UserFontSize"];
        CGFloat fontSize = userFontSizeNum ? [userFontSizeNum floatValue] : [[appSettingsPlist objectForKey:@"TextSize"] floatValue];
        fontSize = fontSize ? fontSize : DEFAULT_OUTPUT_FONTSIZE;
        if ([appSettingsPlist objectForKey:@"TextFont"]) {
            textFont = [NSFont fontWithName:[appSettingsPlist objectForKey:@"TextFont"] size:fontSize];
        }
        if (!textFont) {
            textFont = [NSFont fontWithName:DEFAULT_OUTPUT_FONT size:DEFAULT_OUTPUT_FONTSIZE];
        }
        
        // foreground
        if ([appSettingsPlist objectForKey:@"TextForeground"]) {
            textForeground = [NSColor colorFromHex:[appSettingsPlist objectForKey:@"TextForeground"]];
        }
        if (!textForeground) {
            textForeground = [NSColor colorFromHex:DEFAULT_OUTPUT_FG_COLOR];
        }
        
        // background
        if ([appSettingsPlist objectForKey:@"TextBackground"] != nil) {
            textBackground    = [NSColor colorFromHex:[appSettingsPlist objectForKey:@"TextBackground"]];
        }
        if (!textBackground) {
            textBackground = [NSColor colorFromHex:DEFAULT_OUTPUT_BG_COLOR];
        }
        
        // encoding
        if ([appSettingsPlist objectForKey:@"TextEncoding"]) {
            textEncoding = (int)[[appSettingsPlist objectForKey:@"TextEncoding"] intValue];
        } else {
            textEncoding = DEFAULT_OUTPUT_TXT_ENCODING;
        }
        
        [textFont retain];
        [textForeground retain];
        [textBackground retain];
    }
    
    // likewise, status menu output has some additional parameters
    if (outputType == PLATYPUS_STATUSMENU_OUTPUT) {
        NSString *statusItemDisplayType = [appSettingsPlist objectForKey:@"StatusItemDisplayType"];
        
        // we load text label if status menu is not only an icon
        if ([statusItemDisplayType isEqualToString:@"Text"] || [statusItemDisplayType isEqualToString:@"Icon and Text"]) {
            statusItemTitle = [[appSettingsPlist objectForKey:@"StatusItemTitle"] retain];
            if (statusItemTitle == nil) {
                [self fatalAlert:@"Error getting title" subText:@"Failed to get Status Item title."];
            }
        }
        
        // we load icon if status menu is not only a text label
        if ([statusItemDisplayType isEqualToString:@"Icon"] || [statusItemDisplayType isEqualToString:@"Icon and Text"]) {
            statusItemIcon = [[NSImage alloc] initWithData:[appSettingsPlist objectForKey:@"StatusItemIcon"]];
            if (statusItemIcon == nil) {
                [self fatalAlert:@"Error loading icon" subText:@"Failed to load Status Item icon."];
            }
        }
        
        // Fallback if no title or icon is specified
        if (statusItemIcon == nil && statusItemTitle == nil) {
            statusItemTitle = @"Title";
        }
    }
    
    // load these vars from plist
    interpreterArgs     = [[NSArray arrayWithArray:[appSettingsPlist objectForKey:@"InterpreterArgs"]] retain];
    scriptArgs          = [[NSArray arrayWithArray:[appSettingsPlist objectForKey:@"ScriptArgs"]] retain];
    execStyle           = [[appSettingsPlist objectForKey:@"RequiresAdminPrivileges"] boolValue];
    remainRunning       = [[appSettingsPlist objectForKey:@"RemainRunningAfterCompletion"] boolValue];
    secureScript        = [[appSettingsPlist objectForKey:@"Secure"] boolValue];
    isDroppable         = [[appSettingsPlist objectForKey:@"Droppable"] boolValue];
    promptForFileOnLaunch = [[appSettingsPlist objectForKey:@"PromptForFileOnLaunch"] boolValue];
    
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
        if (![arg hasPrefix:@"-psn_"]) {
            [commandLineArguments addObject:arg];
        }
    }
    
    // we never have privileged execution or droppable with status menu apps
    if (outputType == PLATYPUS_STATUSMENU_OUTPUT) {
        remainRunning = YES;
        execStyle = PLATYPUS_NORMAL_EXECUTION;
        isDroppable = NO;
    }
    
    // load settings for drop acceptance, default is to accept files and not text snippets
    acceptsFiles = ([appSettingsPlist objectForKey:@"AcceptsFiles"] != nil) ? [[appSettingsPlist objectForKey:@"AcceptsFiles"] boolValue] : YES;
    acceptsText = ([appSettingsPlist objectForKey:@"AcceptsText"] != nil) ? [[appSettingsPlist objectForKey:@"AcceptsText"] boolValue] : NO;
    
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
        if ([appSettingsPlist objectForKey:@"DropSuffixes"]) {
            droppableSuffixes = [[NSArray alloc] initWithArray:[appSettingsPlist objectForKey:@"DropSuffixes"]];
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
    NSString *scriptInterpreter = [appSettingsPlist objectForKey:@"ScriptInterpreter"];
    if (scriptInterpreter == nil || ![FILEMGR fileExistsAtPath:scriptInterpreter]) {
        [self fatalAlert:@"Missing interpreter" subText:[NSString stringWithFormat:@"This application could not run because the interpreter '%@' does not exist on this system.", scriptInterpreter]];
    }
    interpreter = [[NSString alloc] initWithString:scriptInterpreter];

    //if the script is not "secure" then we need a script file, otherwise we need data in AppSettings.plist
    if ((!secureScript && ![FILEMGR fileExistsAtPath:[appBundle pathForResource:@"script" ofType:nil]]) ||
        (secureScript && [appSettingsPlist objectForKey:@"TextSettings"] == nil)) {
        [self fatalAlert:@"Corrupt app bundle" subText:@"Script missing from application bundle."];
    }
    
    //get path to script within app bundle
    if (!secureScript) {
        scriptPath = [[NSString alloc] initWithString:[appBundle pathForResource:@"script" ofType:nil]];
        
        // make sure we can read the script file
        if ([FILEMGR isReadableFileAtPath:scriptPath] == NO) {
            // chmod 774
            chmod([scriptPath cStringUsingEncoding:NSUTF8StringEncoding], S_IRWXU | S_IRWXG | S_IROTH);
        }
        if ([FILEMGR isReadableFileAtPath:scriptPath] == NO) { // if still unreadable
            [self fatalAlert:@"Corrupt app bundle" subText:@"Script file is not readable."];
        }
    }
    //if we have a "secure" script, there is no path to get, we write script to temp location on execution
    else {
        NSData *b_str = [NSKeyedUnarchiver unarchiveObjectWithData:[appSettingsPlist objectForKey:@"TextSettings"]];
        if (b_str == nil) {
            [self fatalAlert:@"Corrupt app bundle" subText:@"Script missing from application bundle."];
        }
        // we create string with the script based on the decoded data
        script = [[NSString alloc] initWithData:b_str encoding:textEncoding];
    }
}

#pragma mark - App Delegate handlers

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [NSApp setServicesProvider:self]; // register as text handling service
    
    // status menu apps just run when item is clicked
    // for all others, we run the script once app has been launched
    if (outputType == PLATYPUS_STATUSMENU_OUTPUT) {
        return;
    }
    
    if (promptForFileOnLaunch && isDroppable && ![jobQueue count]) {
        [self openFiles:self];
    } else {
        [self executeScript];
    }
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
    
    // hide status item, if on
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
    if (outputType != PLATYPUS_NONE_OUTPUT) {
        ProcessSerialNumber process;
        GetCurrentProcess(&process);
        SetFrontProcess(&process);
    }
    
    //prepare controls etc. for different output types
    switch (outputType) {
        case PLATYPUS_NONE_OUTPUT:
        {
            // nothing to do
        }
            break;
            
        case PLATYPUS_PROGRESSBAR_OUTPUT:
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
            
        case PLATYPUS_TEXTWINDOW_OUTPUT:
        {
            if (isDroppable) {
                [textOutputWindow registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, nil]];
                [textOutputMessageTextField setStringValue:@"Drag files on window to process them"];
            }
            
            // style the text field
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
            
        case PLATYPUS_WEBVIEW_OUTPUT:
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
            
        case PLATYPUS_STATUSMENU_OUTPUT:
        {
            // create and activate status item
            statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
            [statusItem setHighlightMode:YES];
            
            // set status item title and icon
            [statusItem setTitle:statusItemTitle];
            [statusItem setImage:statusItemIcon];
            
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
            
        case PLATYPUS_DROPLET_OUTPUT:
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
        case PLATYPUS_PROGRESSBAR_OUTPUT:
        {
            [progressBarIndicator setIndeterminate:YES];
            [progressBarIndicator startAnimation:self];
            [progressBarMessageTextField setStringValue:@"Running..."];
            [outputTextView setString:@"\n"];
            [progressBarCancelButton setTitle:@"Cancel"];
            if (execStyle == PLATYPUS_PRIVILEGED_EXECUTION) {
                [progressBarCancelButton setEnabled:NO];
            }
        }
            break;
            
        case PLATYPUS_TEXTWINDOW_OUTPUT:
        {
            [outputTextView setString:@"\n"];
            [textOutputCancelButton setTitle:@"Cancel"];
            if (execStyle == PLATYPUS_PRIVILEGED_EXECUTION) {
                [textOutputCancelButton setEnabled:NO];
            }
            [textOutputProgressIndicator startAnimation:self];
        }
            break;
            
        case PLATYPUS_WEBVIEW_OUTPUT:
        {
            [outputTextView setString:@"\n"];
            [webOutputCancelButton setTitle:@"Cancel"];
            if (execStyle == PLATYPUS_PRIVILEGED_EXECUTION) {
                [webOutputCancelButton setEnabled:NO];
            }
            [webOutputProgressIndicator startAnimation:self];
        }
            break;
            
        case PLATYPUS_STATUSMENU_OUTPUT:
        {
            [outputTextView setString:@""];
        }
            break;
            
        case PLATYPUS_DROPLET_OUTPUT:
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
        case PLATYPUS_TEXTWINDOW_OUTPUT:
        {
            //update controls for text output window
            [textOutputCancelButton setTitle:@"Quit"];
            [textOutputCancelButton setEnabled:YES];
            [textOutputProgressIndicator stopAnimation:self];
        }
            break;
            
        case PLATYPUS_PROGRESSBAR_OUTPUT:
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
            
        case PLATYPUS_WEBVIEW_OUTPUT:
        {
            //update controls for web output window
            [webOutputCancelButton setTitle:@"Quit"];
            [webOutputCancelButton setEnabled:YES];
            [webOutputProgressIndicator stopAnimation:self];
        }
            break;
            
        case PLATYPUS_DROPLET_OUTPUT:
        {
            [dropletProgressIndicator stopAnimation:self];
            [dropletDropFilesLabel setHidden:NO];
            [dropletMessageTextField setHidden:YES];
        }
            break;
    }
}

#pragma mark - Task

//
// construct arguments list etc.
// before actually running the script
//
- (void)prepareForExecution {
    // if it is a "secure" script, we decode and write it to a temp directory
    if (secureScript) {
        
        NSString *tempScriptPath = [FILEMGR createTempFileWithContents:script usingTextEncoding:textEncoding];
        if (!tempScriptPath) {
            [self fatalAlert:@"Failed to write script file" subText:[NSString stringWithFormat:@"Could not create the temp file '%@'", tempScriptPath]];
        }
        chmod([tempScriptPath cStringUsingEncoding:NSUTF8StringEncoding], S_IRWXU | S_IRWXG | S_IROTH);  // chmod 774 - make file executable

        scriptPath = [NSString stringWithString:tempScriptPath];
    }
    
    //clear arguments list and reconstruct it
    [arguments removeAllObjects];
    
    // first, add all specified arguments for interpreter
    [arguments addObjectsFromArray:interpreterArgs];
    
    // add script as argument to interpreter, if it exists
    if (![FILEMGR fileExistsAtPath:scriptPath]) {
        [self fatalAlert:@"Missing script" subText:@"Script missing at execution path"];
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
    
    //finally, add any file arguments we may have received as dropped/opened
    if ([jobQueue count] > 0) {
        // we have files in the queue, to append as arguments
        // we take the first job's arguments and put them into the arg list
        [arguments addObjectsFromArray:[jobQueue objectAtIndex:0]];
        
        // then we remove the job from the queue
        //[[jobQueue objectAtIndex: 0] release]; // release
        [jobQueue removeObjectAtIndex:0];
    }
}

- (void)executeScript {
    // we never execute script if there is one running
    if (isTaskRunning) {
        return;
    }
    if (outputType != PLATYPUS_NONE_OUTPUT) {
        outputEmpty = NO;
    }
    
    [self prepareForExecution];
    [self prepareInterfaceForExecution];
    
    isTaskRunning = YES;
    
    // run the task
    if (execStyle == PLATYPUS_PRIVILEGED_EXECUTION) { //authenticated task
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
    if (outputType != PLATYPUS_NONE_OUTPUT) {
        outputPipe = [NSPipe pipe];
        [task setStandardOutput:outputPipe];
        [task setStandardError:outputPipe];
        readHandle = [outputPipe fileHandleForReading];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOutputData:) name:NSFileHandleReadCompletionNotification object:readHandle];
        [readHandle readInBackgroundAndNotify];
    }
    
    //set it off
    [task launch];
    
    // we wait until task exits if this is triggered by a status item menu
    if (outputType == PLATYPUS_STATUSMENU_OUTPUT) {
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
            [self fatalAlert:@"Failed to execute script" subText:[NSString stringWithFormat:@"Error %d occurred while executing script with privileges.", (int)err]];
        }
    }
    
    if (outputType != PLATYPUS_NONE_OUTPUT) {
        // Success!  Now, start monitoring output file handle for data
        readHandle = [privilegedTask outputFileHandle];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOutputData:) name:NSFileHandleReadCompletionNotification object:readHandle];
        [readHandle readInBackgroundAndNotify];
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
    if (execStyle == PLATYPUS_NORMAL_EXECUTION && task != nil && [task isRunning]) {
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
    
    // we quit now if the app isn't set to continue running
    if (!remainRunning) {
        [[NSApplication sharedApplication] terminate:self];
        return;
    }
    
    // if there are more jobs waiting for us, execute
    if ([jobQueue count] > 0) {
        [self executeScript];
    }
}

- (void)cleanup {
    // we never do cleanup if the task is running
    if (isTaskRunning) {
        return;
    }
    // stop observing the filehandle for data since task is done
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:readHandle];
    
    // we make sure to clear the filehandle of any remaining data
    if (readHandle != nil) {
        NSData *data;
        while ((data = [readHandle availableData]) && [data length]) {
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
        return;
    }
    
    // we parse output if output type is progress bar/droplet
    // in order to get progress indicator values and display string
    if (outputType == PLATYPUS_PROGRESSBAR_OUTPUT || outputType == PLATYPUS_DROPLET_OUTPUT) {
        if (remnants != nil && [remnants length] > 0) {
            [outputString insertString:remnants atIndex:0];
        }
        // parse the data just dumped out
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
            
            // lines starting with PROGRESS:\d+ are interpreted as percentage to set progress bar at
            if ([theLine hasPrefix:@"PROGRESS:"]) {
                NSString *progressPercent = [theLine substringFromIndex:9];
                [progressBarIndicator setIndeterminate:NO];
                [progressBarIndicator setDoubleValue:[progressPercent doubleValue]];
            } else if ([theLine hasPrefix:@"DETAILS:"]) {
                NSString *detailsCommand = [theLine substringFromIndex:8];
                if ([detailsCommand isEqualToString:@"SHOW"]) {
                    [self showDetails];
                } else if ([detailsCommand isEqualToString:@"HIDE"]) {
                    [self hideDetails];
                }
            } else if ([theLine hasPrefix:@"QUITAPP"]) {
                [[NSApplication sharedApplication] terminate:self];
            } else {
                [dropletMessageTextField setStringValue:theLine];
                [progressBarMessageTextField setStringValue:theLine];
            }
        }
    }
    
    // append the ouput to the text in the text field
    NSTextStorage *textStorage = [outputTextView textStorage];
    [textStorage replaceCharactersInRange:NSMakeRange([textStorage length], 0) withString:outputString];
    
    // if web output, we continually re-render to accomodate incoming data, else we scroll down
    if (outputType == PLATYPUS_WEBVIEW_OUTPUT) {

        NSArray *lines = [[textStorage string] componentsSeparatedByString: @"\n"];

        // Check for 'Location: *URL*' In that case, we load the URL in the web view
        if ([lines count] > 0 && [[lines objectAtIndex:1] hasPrefix:@"Location: "]) {
            NSString *url = [[lines objectAtIndex: 1] substringFromIndex:10];
            [[webOutputWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString: url]] ];
        } else {
            // otherwise, just load script output as HTML string
            NSURL *resourcePathURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]];
            [[webOutputWebView mainFrame] loadHTMLString:[outputTextView string] baseURL:resourcePathURL];
        }
    } else if (outputType == PLATYPUS_TEXTWINDOW_OUTPUT || outputType == PLATYPUS_PROGRESSBAR_OUTPUT) {
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
    if (outputType != PLATYPUS_TEXTWINDOW_OUTPUT &&
        outputType != PLATYPUS_WEBVIEW_OUTPUT &&
        outputType != PLATYPUS_PROGRESSBAR_OUTPUT) {
        return;
    }
    NSString *outSuffix = (outputType == PLATYPUS_WEBVIEW_OUTPUT) ? @"html" : @"txt";
    NSString *fileName = [NSString stringWithFormat:@"%@ Output.%@", appName, outSuffix];
    
    NSSavePanel *sPanel = [NSSavePanel savePanel];
    [sPanel setPrompt:@"Save"];
    [sPanel setNameFieldStringValue:fileName];
    
    if ([sPanel runModal] == NSFileHandlingPanelOKButton) {
        [[outputTextView string] writeToFile:[[sPanel URL] path] atomically:YES encoding:textEncoding error:nil];
    }
}

// save only works for text window, web view output types
// and open only works for droppable apps that accept files as script args
- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    if (outputType == PLATYPUS_STATUSMENU_OUTPUT) {
        return YES;
    }
    
    //save to file item
    if ([[anItem title] isEqualToString:@"Save to File…"] &&
        (outputType != PLATYPUS_TEXTWINDOW_OUTPUT && outputType != PLATYPUS_WEBVIEW_OUTPUT  && outputType != PLATYPUS_PROGRESSBAR_OUTPUT)) {
        return NO;
    }
    //open should only work if it's a droppable app
    if ([[anItem title] isEqualToString:@"Open…"] &&
        (!isDroppable || !acceptsFiles || [jobQueue count] >= PLATYPUS_MAX_QUEUE_JOBS)) {
        return NO;
    }
    // Make text bigger stuff
    if (outputType != PLATYPUS_TEXTWINDOW_OUTPUT && outputType != PLATYPUS_PROGRESSBAR_OUTPUT &&outputType != PLATYPUS_WEBVIEW_OUTPUT) {
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
    
    if (outputType == PLATYPUS_WEBVIEW_OUTPUT) {
        // web view
        if (delta > 0) {
            [webOutputWebView makeTextLarger:self];
        } else {
            [webOutputWebView makeTextSmaller:self];
        }
    } else {
        // text field
        NSTextView *textView = outputType == PLATYPUS_PROGRESSBAR_OUTPUT ? progressBarTextView : textOutputTextView;
        NSFont *font = [textView font];
        CGFloat newFontSize = [font pointSize] + delta;
        font = [[NSFontManager sharedFontManager] convertFont:font toSize:newFontSize];
        [textView setFont:font];
        [DEFAULTS setObject:[NSNumber numberWithFloat:newFontSize] forKey:@"UserFontSize"];
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
    NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity:ARG_MAX];
    [args addObject:text];
    [jobQueue addObject:args];
    [args release];
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
    NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity:ARG_MAX]; //this object is released in -prepareForExecution function
    [args addObjectsFromArray:acceptedFiles];
    [jobQueue addObject:args];
    [args release];
    
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
        if (outputType == PLATYPUS_DROPLET_OUTPUT) {
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
    if (outputType == PLATYPUS_DROPLET_OUTPUT) {
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
    if (outputType == PLATYPUS_DROPLET_OUTPUT) {
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
    NSInteger i;
    
    // run script and wait until we've received all the script output
    [self executeScript];
    while (isTaskRunning) {
        usleep(50000); // microseconds
    }
    
    // create an array of lines by separating output by newline
    NSMutableArray *lines = [NSMutableArray arrayWithArray:[[textOutputTextView string] componentsSeparatedByString:@"\n"]];
    
    // clean out any trailing newlines
    while ([[lines lastObject] isEqualToString:@""])
        [lines removeLastObject];
    
    // create a dict of text attributes based on settings
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    //textBackground, NSBackgroundColorAttributeName,
                                    textForeground, NSForegroundColorAttributeName,
                                    textFont, NSFontAttributeName,
                                    nil];
    
    // remove all items of previous output
    while ([statusItemMenu numberOfItems] > 2)
        [statusItemMenu removeItemAtIndex:0];
    
    //populate menu with output from task
    for (i = [lines count] - 1; i >= 0; i--) {
        // create the menu item
        NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:[lines objectAtIndex:i] action:@selector(menuItemSelected:) keyEquivalent:@""] autorelease];
        
        // set the formatted menu item string
        NSAttributedString *attStr = [[[NSAttributedString alloc] initWithString:[lines objectAtIndex:i] attributes:textAttributes] autorelease];
        [menuItem setAttributedTitle:attStr];
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

// show error alert and then exit application
- (void)fatalAlert:(NSString *)message subText:(NSString *)subtext {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:message];
    [alert setInformativeText:subtext];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert runModal];
    [alert release];
    [[NSApplication sharedApplication] terminate:self];
}

@end
