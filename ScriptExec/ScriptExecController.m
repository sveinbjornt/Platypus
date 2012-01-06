/*
    ScriptExec - binary bundled into Platypus-created applications
    Copyright (C) 2003-2012 Sveinbjorn Thordarson <sveinbjornt@gmail.com>

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

#import "ScriptExecController.h"

@implementation ScriptExecController

- (id)init
{
	if (self = [super init]) 
	{
		task = NULL;
		privilegedTask = NULL;
		
		readHandle = NULL;
		arguments = [[NSMutableArray alloc] initWithCapacity: ARG_MAX];
		textEncoding = DEFAULT_OUTPUT_TXT_ENCODING;
		isTaskRunning = NO;
		outputEmpty = YES;
		jobQueue = [[NSMutableArray alloc] initWithCapacity: PLATYPUS_MAX_QUEUE_JOBS];
		
		statusItem = NULL;
		statusItemTitle = @"Title";
		statusItemIcon = NULL;
		statusItemMenu = NULL;
	}
    return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	if (arguments != NULL) { [arguments release]; }
	if (droppableSuffixes != NULL)	{[droppableSuffixes release];}
	if (droppableFileTypes != NULL)	{[droppableFileTypes release];}
	if (paramsArray != NULL) { [paramsArray release]; }
	[jobQueue release];
	if (statusItemIcon != NULL) { [statusItemIcon release]; }
	if (script != NULL) { [script release]; }
	if (statusItem != NULL) { [statusItem release]; }
	if (statusItemMenu != NULL) { [statusItemMenu release]; }
	[super dealloc];
}

-(void)awakeFromNib
{
	// load settings from AppSettings.plist in app bundle
	[self loadSettings];
	
    // prepare UI
	[self initialiseInterface];
	
	// we listen to different kind of notification depending on whether we're running
	// an NSTask or an STPrivilegedTask
	NSString *notificationName = (execStyle == PLATYPUS_PRIVILEGED_EXECUTION) ? STPrivilegedTaskDidTerminateNotification : NSTaskDidTerminateNotification;
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(taskFinished:)
												 name: notificationName
											   object: NULL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{	
    [NSApp setServicesProvider:self]; // register as text handling service
    
	// status menu apps just run when item is clicked
	// for all others, we run the script once app is up and running
	if (outputType != PLATYPUS_STATUSMENU_OUTPUT)
		[self executeScript];
}

#pragma mark -

/****************************************
 
 Set up any menu items, windows, controls
 at application launch time based on output mode
 
 ****************************************/

- (void)initialiseInterface
{
	//put application name into the relevant menu items
	[quitMenuItem setTitle: [NSString stringWithFormat: @"Quit %@", appName]];
	[aboutMenuItem setTitle: [NSString stringWithFormat: @"About %@", appName]];
	[hideMenuItem setTitle: [NSString stringWithFormat: @"Hide %@", appName]];
	
	// script output will be dumped in outputTextView, by default this is the Text Window text view
	outputTextView = textOutputTextView;
	
	// force us to be front process if we run in background
	// This is so that apps that are set to run in the background will still have their
	// window come to the front.  It is to my knowledge the only way to make an
	// application with LSUIElement set to true come to the front on launch
	ProcessSerialNumber process;
	GetCurrentProcess(&process);
	SetFrontProcess(&process);
	
	//prepare controls etc. for different output types
	switch (outputType)
	{
		case PLATYPUS_NONE_OUTPUT:
			break;
			
		case PLATYPUS_PROGRESSBAR_OUTPUT:
		{
			if (isDroppable)
				[progressBarWindow registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, NSStringPboardType, nil]];
			
			// add menu item for Show Details
			[[windowMenu insertItemWithTitle: @"Toggle Details" action: @selector(performClick:)  keyEquivalent:@"T" atIndex: 2] setTarget: progressBarDetailsTriangle];
			[windowMenu insertItem: [NSMenuItem separatorItem] atIndex: 2];
			
			// style the text field
			outputTextView = progressBarTextView;
			[outputTextView setFont: textFont];
			[outputTextView setTextColor: textForeground];
			[outputTextView setBackgroundColor: textBackground];
			
			// add drag instructions message if droplet
			if (isDroppable)
				[progressBarMessageTextField setStringValue: @"Drag files to process"];
			else
				[progressBarMessageTextField setStringValue: @"Running..."];
			
			[progressBarIndicator setUsesThreadedAnimation: YES];
			
			//preare window
			[progressBarWindow setTitle: appName];
			
			//center it if first time running the application
			if ([[progressBarWindow frameAutosaveName] isEqualToString: @""])
				[progressBarWindow center];
			
			// reveal it
			[progressBarWindow makeKeyAndOrderFront: self];
		}
		break;
			
		case PLATYPUS_TEXTWINDOW_OUTPUT:
		{
			if (isDroppable)
			{
				[textOutputWindow registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, NSStringPboardType, nil]];
				[textOutputMessageTextField setStringValue: @"Drag files on window to process them"];
			}
			
			// style the text field
			[outputTextView setFont: textFont];
			[outputTextView setTextColor: textForeground];
			[outputTextView setBackgroundColor: textBackground];				
			
			[textOutputProgressIndicator setUsesThreadedAnimation: YES];
			
			// prepare window
			[textOutputWindow setTitle: appName];
			[textOutputWindow center];
			[textOutputWindow makeKeyAndOrderFront: self];
		}
		break;
			
		case PLATYPUS_WEBVIEW_OUTPUT:
		{
			if (isDroppable)
			{
				[webOutputWindow registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, NSStringPboardType, nil]];
				[webOutputWebView registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, NSStringPboardType, nil]];
				[webOutputMessageTextField setStringValue: @"Drag files on window to process them"];
			}
			
			[webOutputProgressIndicator setUsesThreadedAnimation: YES];
			
			// prepare window
			[webOutputWindow setTitle: appName];
			[webOutputWindow center];
			[webOutputWindow makeKeyAndOrderFront: self];		
			
		}
		break;
			
		case PLATYPUS_STATUSMENU_OUTPUT:
		{
			// create and activate status item
			statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength: NSVariableStatusItemLength] retain];
			[statusItem setHighlightMode: YES];
			
			// set status item title and icon
			if (statusItemTitle != NULL)
				[statusItem setTitle: statusItemTitle];
			if (statusItemIcon != NULL)
				[statusItem setImage: statusItemIcon];
			
			// let's make sure it has at least either a title or an icon
			if (statusItemIcon == NULL && statusItemTitle == NULL)
				[self fatalAlert: @"Corrupt settings"  subText:@"Status Menu settings failed to specify title or icon."];
			
			// create menu for our status item
			statusItemMenu = [[NSMenu alloc] initWithTitle: @""];
			[statusItemMenu setDelegate: self];
			[statusItem setMenu: statusItemMenu];
			
			//create Quit menu item
			NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"Quit %@", appName] action: @selector(terminate:) keyEquivalent: @""] autorelease];
			[statusItemMenu insertItem: menuItem atIndex: 0];
			[statusItemMenu insertItem: [NSMenuItem separatorItem] atIndex: 0];
			
			// enable it
			[statusItem setEnabled: YES];
		}
		break;
			
		case PLATYPUS_DROPLET_OUTPUT:
		{			
			if (isDroppable)
				[dropletWindow registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, NSStringPboardType, nil]];
			
			[dropletProgressIndicator setUsesThreadedAnimation: YES];
			
			// prepare window
			[dropletWindow setTitle: appName];
			[dropletWindow center];
			[dropletWindow makeKeyAndOrderFront: self];
		}
		break;
	}
}

/****************************************
 
 Prepare all the controls, windows, etc.
 prior to the execution of the script
 
 ****************************************/

- (void)prepareInterfaceForExecution
{
	switch(outputType)
	{
		case PLATYPUS_PROGRESSBAR_OUTPUT:
		{
			[progressBarIndicator setIndeterminate: YES];
			[progressBarIndicator startAnimation: self];
			[progressBarMessageTextField setStringValue: @"Running..."];
			[outputTextView setString: @"\n"];
			[progressBarCancelButton setTitle: @"Cancel"];
			if (execStyle == PLATYPUS_PRIVILEGED_EXECUTION) { [progressBarCancelButton setEnabled: NO]; }
		}
		break;
			
		case PLATYPUS_TEXTWINDOW_OUTPUT:
		{   
			[outputTextView setString: @"\n"];
			[textOutputCancelButton setTitle: @"Cancel"];
			if (execStyle == PLATYPUS_PRIVILEGED_EXECUTION) { [textOutputCancelButton setEnabled: NO]; }
			[textOutputProgressIndicator startAnimation: self];
		}
		break;
			
		case PLATYPUS_WEBVIEW_OUTPUT:
		{
			[outputTextView setString: @"\n"];
			[webOutputCancelButton setTitle: @"Cancel"];
			if (execStyle == PLATYPUS_PRIVILEGED_EXECUTION) { [webOutputCancelButton setEnabled: NO]; }
			[webOutputProgressIndicator startAnimation: self];
		}
		break;
			
		case PLATYPUS_STATUSMENU_OUTPUT:
		{
			[outputTextView setString: @""];
		}
		break;
			
		case PLATYPUS_DROPLET_OUTPUT:
		{
			[dropletProgressIndicator setIndeterminate: YES];
			[dropletProgressIndicator startAnimation: self];
			[dropletDropFilesLabel setHidden: YES];
			[dropletMessageTextField setHidden: NO];
			[dropletMessageTextField setStringValue: @"Processing..."];
			[outputTextView setString: @"\n"];
		}
		break;
	}
}

/****************************************
 
 Adjust controls, windows, etc. once script
 is done executing
 
 ****************************************/

- (void)cleanupInterface
{
	switch (outputType)
	{
		case PLATYPUS_TEXTWINDOW_OUTPUT:
		{
			//update controls for text output window
			[textOutputCancelButton setTitle: @"Quit"];
			[textOutputCancelButton setEnabled: YES];
			[textOutputProgressIndicator stopAnimation: self];
		}
		break;
			
		case PLATYPUS_PROGRESSBAR_OUTPUT:
		{
			// if there are any remnants, we append them to output
			if (remnants != NULL) 
			{ 
				NSTextStorage *text = [outputTextView textStorage];
				[text replaceCharactersInRange: NSMakeRange([text length], 0) withString: remnants];
				[remnants release]; 
				remnants = NULL; 
			}
			
			//update controls for progress bar output
			[progressBarIndicator stopAnimation: self];
			
			if (isDroppable)
			{
				[progressBarMessageTextField setStringValue: @"Drag files to process"];
				[progressBarIndicator setIndeterminate: YES];
			}
			else 
			{				
				// cleanup - if the script didn't give us a proper status message, then we set one
				if ([[progressBarMessageTextField stringValue] isEqualToString: @""] || 
					[[progressBarMessageTextField stringValue] isEqualToString: @"\n"] || 
					[[progressBarMessageTextField stringValue] isEqualToString: @"Running..."])
					[progressBarMessageTextField setStringValue: @"Task completed"];
				
				[progressBarIndicator setIndeterminate: NO];
				[progressBarIndicator setDoubleValue: 100];
			}
			
			// change button
			[progressBarCancelButton setTitle: @"Quit"];
			[progressBarCancelButton setEnabled: YES];
		}
		break;
			
		case PLATYPUS_WEBVIEW_OUTPUT:
		{
			//update controls for web output window
			[webOutputCancelButton setTitle: @"Quit"];
			[webOutputCancelButton setEnabled: YES];
			[webOutputProgressIndicator stopAnimation: self];
		}
		break;
			
		case PLATYPUS_DROPLET_OUTPUT:
		{
			[dropletProgressIndicator stopAnimation: self];
			[dropletDropFilesLabel setHidden: NO];
			[dropletMessageTextField setHidden: YES];
		}
		break;
	}
}

#pragma mark -

//
// construct arguments list etc.
// before actually running the script
//
- (void)prepareForExecution
{
	// if it is a "secure" script, we decode and write it to a temp directory
	// This used to be done by just writing to /tmp, but this method is more secure
	// and will result in the script file being created at a path that looks something
	// like this:  /var/folders/yV/yV8nyB47G-WRvC76fZ3Be++++TI/-Tmp-/
	// Kind of ugly, but it's the Apple/Cocoa-approved way of doing things
	// Thanks to Matt Gallagher for this technique:
	// http://cocoawithlove.com/2009/07/temporary-files-and-folders-in-cocoa.html
	
	if (secureScript)
	{
		// create full path w. template
		NSString *tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent: TMP_SCRIPT_TEMPLATE];
		const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
		char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
		strcpy(tempFileNameCString, tempFileTemplateCString);
		
		// use mkstemp to expand template
		int fileDescriptor = mkstemp(tempFileNameCString);
		if (fileDescriptor == -1)
			[self fatalAlert: @"Unable to create temporary file" subText: [NSString stringWithFormat: @"Error %d in mkstemp()", errno]];
		
		// create nsstring from the c-string temp path
		NSString *tempScriptPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
		
		// write script to the temporary path
		[script writeToFile: tempScriptPath atomically: YES encoding: textEncoding error: NULL];
		
		// get rid of these
		free(tempFileNameCString);
		close(fileDescriptor);
		
		// make sure writing it was successful
		if (![[NSFileManager defaultManager] fileExistsAtPath: tempScriptPath])
			[self fatalAlert: @"Failed to write script file" subText: [NSString stringWithFormat: @"Could not create the temp file '%@'", tempScriptPath]]; 		
		
		scriptPath = [NSString stringWithString: tempScriptPath];
	}
	
	//clear arguments list and reconstruct it
	[arguments removeAllObjects];
	
	// first, add all specified arguments for interpreter
	if ([paramsArray count] > 0)
		[arguments addObjectsFromArray: paramsArray];

	// add script as argument to interpreter, if it exists
	if (![[NSFileManager defaultManager] fileExistsAtPath: scriptPath])
		[self fatalAlert: @"Missing script" subText: @"Script missing at execution path"];
	[arguments addObject: scriptPath];
	
	//set $1 as path of application bundle if that option is set
	if (appPathAsFirstArg)
		[arguments addObject: [[NSBundle mainBundle] bundlePath]]; 
	
	//finally, add any file arguments we may have received as dropped/opened
	if ([jobQueue count] > 0) // we have files in the queue, to append as arguments
	{
        NSLog(@"%d in job queue", [jobQueue count]);
		// we take the first job's arguments and put them into the arg list
		[arguments addObjectsFromArray: [jobQueue objectAtIndex: 0]];
		
		// then we remove the job from the queue
        NSLog(@"Releasing object at 0 in job queue");
        //[[jobQueue objectAtIndex: 0] release]; // release
        NSLog(@"Removing object at 0 from job queue array");
		[jobQueue removeObjectAtIndex: 0]; // remove it from the queue
	}
}

- (void)executeScript
{	
	// we never execute script if there is one running
	if (isTaskRunning)
		return;
	
	if (outputType != PLATYPUS_NONE_OUTPUT)
		outputEmpty = NO;
	
	[self prepareForExecution];
	[self prepareInterfaceForExecution];
	
	isTaskRunning = YES;
	
	// run the task
	if (execStyle == PLATYPUS_PRIVILEGED_EXECUTION) //authenticated task
		[self executeScriptWithPrivileges];
	else //plain old nstask
		[self executeScriptWithoutPrivileges];
}

#pragma mark -

//launch regular user task with NSTask
- (void)executeScriptWithoutPrivileges
{	
	//initalize task
	task = [[NSTask alloc] init];
	
	//apply settings for task
	[task setLaunchPath: interpreter];
	[task setCurrentDirectoryPath: [[NSBundle mainBundle] resourcePath]];
	[task setArguments: arguments];
	
	// set output to file handle and start monitoring it if script provides feedback
	if (outputType != PLATYPUS_NONE_OUTPUT)
	{
		outputPipe = [NSPipe pipe];
		[task setStandardOutput: outputPipe];
		[task setStandardError: outputPipe];
		readHandle = [outputPipe fileHandleForReading];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOutputData:) name: NSFileHandleReadCompletionNotification object:readHandle];
		[readHandle readInBackgroundAndNotify];
	}
	
	//set it off
	[task launch];

	// we wait until task exits if this is for the menu
	if (outputType == PLATYPUS_STATUSMENU_OUTPUT)
		[task waitUntilExit];
}

//launch task with admin privileges using Authentication Manager
- (void)executeScriptWithPrivileges
{	
	//initalize task
	privilegedTask = [[STPrivilegedTask alloc] init];
	
	//apply settings for task
	[privilegedTask setLaunchPath: interpreter];
	[privilegedTask setCurrentDirectoryPath: [[NSBundle mainBundle] resourcePath]];
	[privilegedTask setArguments: arguments];
	
	//set it off
	OSStatus err = [privilegedTask launch];
	if (err != errAuthorizationSuccess)
	{
		if (err == errAuthorizationCanceled)
		{
			outputEmpty = YES;
			[self taskFinished: NULL];
			return;
		}
		else // something went wrong
			[self fatalAlert: @"Failed to execute script" subText: [NSString stringWithFormat: @"Error %d occurred while executing script with privileges.", err]];
	}
	
	if (outputType != PLATYPUS_NONE_OUTPUT)
	{
		// Success!  Now, start monitoring output file handle for data
		readHandle = [privilegedTask outputFileHandle];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(getOutputData:) name: NSFileHandleReadCompletionNotification object: readHandle];
		[readHandle readInBackgroundAndNotify];
	}
}

#pragma mark -

// OK, called when we receive notification that task is finished
// Some cleaning up to do, controls need to be adjusted, etc.
- (void)taskFinished: (NSNotification *)aNotification
{		
	// if task already quit, we return
	if (!isTaskRunning) 
		return;
	
	isTaskRunning = NO;
	
	// make sure task is dead.  Ideally we'd like to do the same for privileged tasks, but that's just not possible w/o process id
	if (execStyle == PLATYPUS_NORMAL_EXECUTION && task != NULL && [task isRunning])
		[task terminate];
	
	// did we receive all the data?
	if (outputEmpty) // if no data left we do the clean up 
		[self cleanup];

	//if we're using the "secure" script, we must remove the temporary clear-text one in temp directory if there is one
	if (secureScript && [[NSFileManager defaultManager] fileExistsAtPath: scriptPath])
		[[NSFileManager defaultManager] removeFileAtPath: scriptPath handler: nil];
	
	// we quit now if the app isn't set to continue running
	if (!remainRunning)
		[[NSApplication sharedApplication] terminate: self];
	
	// if there are more jobs waiting for us, execute
	if ([jobQueue count] > 0)
		[self executeScript];
}

- (void) cleanup
{	
	// we never do cleanup if the task is running
	if (isTaskRunning) 
		return;
	
	// Stop observing the filehandle for data since task is done
	[[NSNotificationCenter defaultCenter] removeObserver: self name: NSFileHandleReadCompletionNotification object: readHandle];
		
	// We make sure to clear the filehandle of any remaining data
	if (readHandle != NULL)
	{
		NSData *data;
		while ((data = [readHandle availableData]) && [data length])
			[self appendOutput: data];
	}
	
	// now, reset all controls etc., general cleanup since task is done	
	[self cleanupInterface];	
}

#pragma mark -

//  read from the file handle and append it to the text window
- (void) getOutputData: (NSNotification *)aNotification
{
	//get the data from notification
	NSData *data = [[aNotification userInfo] objectForKey: NSFileHandleNotificationDataItem];
	
	//make sure there's actual data
	if ([data length]) 
	{
		outputEmpty = NO;
		
		//append the output to the text field		
		[self appendOutput: data];
		
		// we schedule the file handle to go and read more data in the background again.
		[[aNotification object] readInBackgroundAndNotify];
	}
	else
	{
		outputEmpty = YES;
		if (!isTaskRunning)
			[self cleanup];
	}
}

//
// this function receives all new data dumped out by the script and appends it to text field
// it is *relatively* memory efficient (given the nature of NSTextView) and doesn't leak, as far as I can tell...
//
- (void)appendOutput: (NSData *)data
{	
	// we decode the script output according to specified character encoding
	NSMutableString *outputString = [[NSMutableString alloc] initWithData: data encoding: textEncoding];

	if (!outputString)
		return;
	
	// we parse output if output type is progress bar, to get progress indicator values and display string
	if (outputType == PLATYPUS_PROGRESSBAR_OUTPUT || outputType == PLATYPUS_DROPLET_OUTPUT )
	{
		if (remnants != NULL && [remnants length] > 0)
		{
			[outputString insertString: remnants atIndex: 0];
		}
		
		// parse the data just dumped out
		NSMutableArray *lines = [NSMutableArray arrayWithArray: [outputString componentsSeparatedByString: @"\n"]];
		
		// if the line did not end with a newline, it wasn't a complete line of output
		// Thus, we store the last line and then delete it from the outputstring
		// It'll be appended next time we get output
		if ([(NSString *)[lines lastObject] length] > 0)
		{
			if (remnants != NULL) { [remnants release]; remnants = NULL; }
			remnants = [[NSString alloc] initWithString: [lines lastObject]];
			[outputString deleteCharactersInRange: NSMakeRange([outputString length]-[remnants length], [remnants length])];
		}
		else
			remnants = NULL;

		[lines removeLastObject];
		
		int i;
		for (i = 0; i < [lines count]; i++)
		{
			NSString *theLine = [lines objectAtIndex: i];
			
			// if the line is empty, we ignore it
			if ([theLine caseInsensitiveCompare: @""] == NSOrderedSame)
				continue;
			
			if ([theLine hasPrefix: @"PROGRESS:"])
			{			
				NSString *progressPercent = [theLine substringFromIndex: 9];
				[progressBarIndicator setIndeterminate: NO];
				[progressBarIndicator setDoubleValue: [progressPercent doubleValue]];
			}
			else
			{
				[dropletMessageTextField setStringValue: theLine];
				[progressBarMessageTextField setStringValue: theLine];
			}
		}
	}
		
	// append the ouput to the text in the text field
	NSTextStorage *text = [outputTextView textStorage];
	[text replaceCharactersInRange: NSMakeRange([text length], 0) withString: outputString];
	
	// if web output, we continually re-render to accomodate incoming data, else we scroll down
	if (outputType == PLATYPUS_WEBVIEW_OUTPUT)
		[[webOutputWebView mainFrame] loadHTMLString: [outputTextView string] baseURL: [NSURL fileURLWithPath: [[NSBundle mainBundle] resourcePath]] ];
	else if (outputType == PLATYPUS_TEXTWINDOW_OUTPUT || outputType == PLATYPUS_PROGRESSBAR_OUTPUT)
		[outputTextView scrollRangeToVisible: NSMakeRange([text length], 0)];
	
	[outputString release];
}

#pragma mark -

- (void)application:(NSApplication *)theApplication openFiles:(NSArray *)filenames
{
	// add the dropped files as a job for processing
	int ret = [self addDroppedFilesJob: filenames];
	
	// if no other job is running, we execute
	if (!isTaskRunning && ret)
		[self executeScript];
}
	 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{	
    // again, make absolutely sure we don't leave the clear-text script in temp directory
	if (secureScript && [[NSFileManager defaultManager] fileExistsAtPath: scriptPath])
		[[NSFileManager defaultManager] removeFileAtPath: scriptPath handler: nil];

	//terminate task
	if (task != NULL)
	{
		if ([task isRunning])
			[task terminate];
		[task release];
	}
	
	if (privilegedTask != NULL)
		[privilegedTask release];
	
	// clean out the job queue since we're quitting
	[jobQueue removeAllObjects];
		
	return YES;
}

#pragma mark -

/***************************************************************************
 
 Receives a list of files, filters out those that the application can handle
 based on application settings, then creates an array of arguments, appends
 it as a drop job for processing.  If no files are accepted it returns false.
 
***************************************************************************/

-(void)doString:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error 
{
    NSString *pboardString = [pboard stringForType:NSStringPboardType];
    
    int ret = [self addDroppedTextJob: pboardString];
    
    if (!isTaskRunning && ret)
		[self executeScript];
}

- (BOOL) addDroppedFilesJob: (NSArray *)files
{
	// if this isn't a droppable application, we never add a drop job.  Likewise, if too many jobs already, we ignore.
	if (!isDroppable || [jobQueue count] >= PLATYPUS_MAX_QUEUE_JOBS)
		return NO;
	
	// Let's see what we have
	int i;
	NSMutableArray *acceptedFiles = [[[NSMutableArray alloc] init] autorelease];
	
	// Only accept the drag if at least one of the files meets the required types
	for (i = 0; i < [files count]; i++)
	{			
		// if we accept this item, add it to list of accepted files
		if ([self acceptableFileType: [files objectAtIndex: i]])
			[acceptedFiles addObject: [files objectAtIndex: i]];
	}
	
	// if at this point there are no accepted files, we refuse drop
	if ([acceptedFiles count] == 0)
		return NO;
	
	// we create a processing job and add the files as arguments, accept drop
	NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity: ARG_MAX];//this object is released in -prepareForExecution function
	[args addObjectsFromArray: acceptedFiles];
    NSLog(@"Adding to job queue");
	[jobQueue addObject: args];
    [args release];
	return YES;
}

- (BOOL)addDroppedTextJob: (NSString *)text
{
	// if this isn't a droppable application, we never add a drop job.  Likewise, if too many jobs already, we ignore.
	if (!isDroppable || [jobQueue count] >= PLATYPUS_MAX_QUEUE_JOBS)
		return NO;
	
	if ([text length] <= 0) // ignore empty strings
		return NO;
	
	// add job with text as argument for script
	NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity: ARG_MAX];
	[args addObject: text];
	[jobQueue addObject: args];

	return YES;
}


/*****************************************************************
 
  Returns whether a given file is accepted by the suffix/types 
  criterion specified in AppSettings.plist
 
*****************************************************************/

- (BOOL)acceptableFileType: (NSString *)file
{
	int i;
	BOOL isDir;
	
	// Check if it's a folder. If so, we only accept it if 'fold' is specified as accepted file type
	if ([[NSFileManager defaultManager] fileExistsAtPath: file isDirectory: &isDir] && isDir)
	{
		for(i = 0; i < [droppableFileTypes count]; i++)
		{
			if([[droppableFileTypes objectAtIndex: i] isEqualToString: @"fold"])
				return YES;
		}
		return NO;
	}
	
	if (acceptAnyDroppedItem)
		return YES;
	
	// see if it has accepted suffix
	for (i = 0; i < [droppableSuffixes count]; i++)
		if ([file hasSuffix: [droppableSuffixes objectAtIndex: i]])
			return YES;
	
	// see if it has accepted file type
	NSString *fileType = NSHFSTypeOfFile(file);
	for(i = 0; i < [droppableFileTypes count]; i++)
		if([fileType isEqualToString: [droppableFileTypes objectAtIndex: i]])
			return YES;
	
	return NO;
}


// check file types against acceptable drop types here before accepting them

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender 
{ 
	BOOL acceptDrag = NO;
    NSPasteboard *pboard = [sender draggingPasteboard];
	
	// if this is a file being dragged
	if ([[pboard types] containsObject: NSFilenamesPboardType])
	{
		// loop through files, see if any of the dragged files are acceptable
		int i;
		NSArray *files = [pboard propertyListForType: NSFilenamesPboardType];
		
		for (i = 0; i < [files count]; i++)
			if ([self acceptableFileType: [files objectAtIndex: i]])
				acceptDrag = YES;
	}
	
	// if this is a string being dragged
	else if ([[pboard types] containsObject: NSStringPboardType])
		acceptDrag = YES;
	
	if (acceptDrag)
	{
		// we shade the window if output is droplet mode
		if (outputType == PLATYPUS_DROPLET_OUTPUT)
		{
			[dropletShader setAlphaValue: 0.3];
			[dropletShader setHidden: NO];
		}
		return NSDragOperationLink;
	}
	
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender;
{
	[dropletShader setHidden: YES];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{ 
	NSPasteboard *pboard = [sender draggingPasteboard];
	
	if ([[pboard types] containsObject: NSStringPboardType])
	{
		return [self addDroppedTextJob: [pboard stringForType: NSStringPboardType]];
	}
	else
		return [self addDroppedFilesJob: [pboard propertyListForType: NSFilenamesPboardType]];
	
	return NO;
	
}

// once the drag is over, we immediately execute w. files as arguments if not already processing
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	if (outputType == PLATYPUS_DROPLET_OUTPUT)
		[dropletShader setHidden: YES];
	
	if (!isTaskRunning && [jobQueue count] > 0)
		[NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector:@selector(executeScript) userInfo: nil repeats: NO];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	return [self draggingEntered: sender]; // this is needed to keep link instead of the green plus sign on web view
}

#pragma mark -

/**************************************************
 
 Called whenever web view re-renders.  We scroll to
 the bottom on each re-rendering.
 
 **************************************************/

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	NSScrollView *scrollView = [[[[webOutputWebView mainFrame] frameView] documentView] enclosingScrollView];	
	NSRect bounds = [[[[webOutputWebView mainFrame] frameView] documentView] bounds];
	[[scrollView documentView] scrollPoint: NSMakePoint(0, bounds.size.height)];
}

#pragma mark -

/**************************************************
 
 Called whenever status item is clicked.  We run 
 script, get output and generate menu with the ouput
 
 **************************************************/

- (void)menuNeedsUpdate:(NSMenu *)menu
{	
	int i;
	
	// run script and wait until we've received all the script output
	[self executeScript];
	while (isTaskRunning) {}
	
	// create an array of lines by separating output by newline
	NSMutableArray *lines = (NSMutableArray *)[[textOutputTextView string] componentsSeparatedByString: @"\n"];
	
	// clean out any trailing newlines
	while ([[lines lastObject] isEqualToString: @""])
		[lines removeLastObject];
	
	// create a dict of text attributes based on settings
	NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									//textBackground, NSBackgroundColorAttributeName, 
									textForeground, NSForegroundColorAttributeName, 
									textFont, NSFontAttributeName,
									NULL];
	
	// remove all items of previous output
	while ([statusItemMenu numberOfItems] > 2)
		[statusItemMenu removeItemAtIndex: 0];
	
	//populate menu with output from task
	for (i = [lines count]-1; i >= 0; i--)
	{		
		// create the menu item
		NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle: @"" action: NULL keyEquivalent: @""] autorelease];
		
		// set the formatted menu item string
		NSAttributedString *attStr = [[[NSAttributedString alloc] initWithString: [lines objectAtIndex: i] attributes: textAttributes] autorelease];
		[menuItem setAttributedTitle: attStr];
		[menu insertItem: menuItem atIndex: 0];
	}
}


#pragma mark -

/**************************************************

 Load configuration file AppSettings.plist from 
 application bundle, sanitize it, prepare it

**************************************************/

- (void)loadSettings
{
	int				i = 0;
	NSBundle		*appBundle = [NSBundle mainBundle];
	NSFileManager   *fmgr = [NSFileManager defaultManager];
	NSDictionary	*appSettingsPlist;
		
	//make sure all the config files are present -- if not, we quit
	if (![fmgr fileExistsAtPath: [appBundle pathForResource:@"AppSettings.plist" ofType:nil]])
		[self fatalAlert: @"Corrupt app bundle" subText: @"AppSettings.plist missing from the application bundle."];

	// get app name
	// first, try to get CFBundleDisplayName from Info.plist
	NSDictionary *infoPlist = [appBundle infoDictionary];
	if ([infoPlist objectForKey: @"CFBundleDisplayName"] != nil)
		appName = [[NSString alloc] initWithString: [infoPlist objectForKey: @"CFBundleDisplayName"]];
	else // if that doesn't work, use name of executable file
		appName = [[[appBundle executablePath] lastPathComponent] retain];

	//get dictionary with app settings
	appSettingsPlist = [NSDictionary dictionaryWithContentsOfFile: [appBundle pathForResource:@"AppSettings.plist" ofType:nil]];
	if (appSettingsPlist == NULL)
		[self fatalAlert: @"Corrupt app settings" subText: @"AppSettings.plist is corrupt."]; 
	
	//determine output type
	NSString *outputTypeStr = [appSettingsPlist objectForKey:@"OutputType"];
	if ([outputTypeStr isEqualToString: @"Progress Bar"])
		outputType = PLATYPUS_PROGRESSBAR_OUTPUT;
	else if ([outputTypeStr isEqualToString: @"Text Window"])
		outputType = PLATYPUS_TEXTWINDOW_OUTPUT;
	else if ([outputTypeStr isEqualToString: @"Web View"])
		outputType = PLATYPUS_WEBVIEW_OUTPUT;
	else if ([outputTypeStr isEqualToString: @"Status Menu"])
		outputType = PLATYPUS_STATUSMENU_OUTPUT;
	else if ([outputTypeStr isEqualToString: @"Droplet"])
		outputType = PLATYPUS_DROPLET_OUTPUT;
	else if ([outputTypeStr isEqualToString: @"None"])
		outputType = PLATYPUS_NONE_OUTPUT;
	else
		[self fatalAlert: @"Corrupt app settings" subText: @"Invalid Output Mode."];

	
	// we need some additional info from AppSettings.plist if we are presenting textual output
	if (outputType == PLATYPUS_PROGRESSBAR_OUTPUT || 
		outputType == PLATYPUS_TEXTWINDOW_OUTPUT ||
		outputType == PLATYPUS_STATUSMENU_OUTPUT )
	{
		//make sure all this data is sane 
		
		// font and size
		if ([appSettingsPlist objectForKey:@"TextFont"] != NULL || [appSettingsPlist objectForKey:@"TextSize"] != NULL)
			textFont = [NSFont fontWithName: DEFAULT_OUTPUT_FONT size: DEFAULT_OUTPUT_FONTSIZE];
		if (textFont == NULL)
			textFont = [NSFont fontWithName: [appSettingsPlist objectForKey:@"TextFont"] size: [[appSettingsPlist objectForKey:@"TextSize"] floatValue]];
			
		// foreground
		if ([appSettingsPlist objectForKey:@"TextForeground"] == NULL)
			textForeground = [NSColor colorFromHex: DEFAULT_OUTPUT_FG_COLOR];
		if (textForeground == NULL)
			textForeground = [NSColor colorFromHex: [appSettingsPlist objectForKey:@"TextForeground"]];
		
		// background
		if ([appSettingsPlist objectForKey:@"TextBackground"] == NULL)
			textBackground = [NSColor colorFromHex: DEFAULT_OUTPUT_BG_COLOR];
		if (textBackground == NULL)
			textBackground	= [NSColor colorFromHex: [appSettingsPlist objectForKey:@"TextBackground"]];
		
		// encoding
		if (textEncoding < 1)
			textEncoding = DEFAULT_OUTPUT_TXT_ENCODING;
		else
			textEncoding = (int)[[appSettingsPlist objectForKey:@"TextEncoding"] intValue];
		
		[textFont retain];
		[textForeground retain];
		[textBackground retain];
	}
	
	// likewise, status menu output has some additional parameters
	if (outputType == PLATYPUS_STATUSMENU_OUTPUT)
	{
		// we load text label if status menu is not only an icon
		if (![[appSettingsPlist objectForKey: @"StatusItemDisplayType"] isEqualToString: @"Icon"])
		{
			statusItemTitle = [[appSettingsPlist objectForKey: @"StatusItemTitle"] retain];
			if (statusItemTitle == NULL)
				[self fatalAlert: @"Error getting title" subText: @"Failed to get Status Item title."];
		}
		
		// we load icon if status menu is not only a text label
		if (![[appSettingsPlist objectForKey: @"StatusItemDisplayType"] isEqualToString: @"Text"])
		{
			statusItemIcon = [[NSImage alloc] initWithData: [appSettingsPlist objectForKey: @"StatusItemIcon"]];
			if (statusItemIcon == NULL)
				[self fatalAlert: @"Error loading icon" subText: @"Failed to load Status Item icon."];
		}
	}
	
	//arguments to interpreter
	paramsArray = [[NSArray arrayWithArray: [appSettingsPlist objectForKey:@"InterpreterParams"]] retain];
	
	//pass app path as first arg?
	appPathAsFirstArg = [[appSettingsPlist objectForKey:@"AppPathAsFirstArg"] boolValue];
	
	//determine execution style
	execStyle = [[appSettingsPlist objectForKey:@"RequiresAdminPrivileges"] boolValue];
	
	//remain running?
	remainRunning = [[appSettingsPlist objectForKey:@"RemainRunningAfterCompletion"] boolValue];
	
	//is script encrypted and checksummed?
	secureScript = [[appSettingsPlist objectForKey: @"Secure"] boolValue];
		
	//can the app receive dropped files as args?
	isDroppable = [[appSettingsPlist objectForKey: @"Droppable"] boolValue];
	
	// never privileged execution or droppable w. status menu
	if (outputType == PLATYPUS_STATUSMENU_OUTPUT) 
	{
		remainRunning = YES;
		execStyle = PLATYPUS_NORMAL_EXECUTION;
		isDroppable = NO;
	}
	
	//if app is droppable, the AppSettings.plist contains list of accepted file types / suffixes
	acceptAnyDroppedItem = NO; // initialize this to NO, then check the droppableSuffixes for *, and droppableFiles for ****
	if (isDroppable)
	{	
		// get list of accepted suffixes
		if([appSettingsPlist objectForKey: @"DropSuffixes"])
			droppableSuffixes = [[NSArray alloc] initWithArray:  [appSettingsPlist objectForKey:@"DropSuffixes"]];
		else
			droppableSuffixes = [[NSArray alloc] initWithArray: [NSArray array]];
		[droppableSuffixes retain];
		
		// get list of accepted file types
		if([appSettingsPlist objectForKey:@"DropTypes"])
			droppableFileTypes = [[NSArray alloc] initWithArray:  [appSettingsPlist objectForKey:@"DropTypes"]];
		else
			droppableFileTypes = [[NSArray alloc] initWithArray: [NSArray array]];
		[droppableFileTypes retain];
		
		// see if we accept any dropped item
		for (i = 0; i < [droppableSuffixes count]; i++)
			if ([[droppableSuffixes objectAtIndex:i] isEqualToString:@"*"]) //* suffix
				acceptAnyDroppedItem = YES;

		for (i = 0; i < [droppableFileTypes count]; i++)
			if([[droppableFileTypes objectAtIndex:i] isEqualToString:@"****"])//**** filetype
				acceptAnyDroppedItem = YES;
	}
	
	//get interpreter
	interpreter = [[NSString stringWithString: [appSettingsPlist objectForKey:@"ScriptInterpreter"]] retain];
	
	//if the script is not "secure" then we need a script file, otherwise we need data in AppSettings.plist
	if ((!secureScript && ![fmgr fileExistsAtPath: [appBundle pathForResource:@"script" ofType: NULL]]) || (secureScript && [appSettingsPlist objectForKey:@"TextSettings"] == NULL))
		[self fatalAlert: @"Corrupt app bundle" subText: @"Script missing from application bundle."];
	
	//get path to script
	if (!secureScript)
		scriptPath = [[NSString stringWithString: [appBundle pathForResource:@"script" ofType:nil]] retain];	
	else //if we have a "secure" script, no path to get
	{
		NSData *b_str = [NSKeyedUnarchiver unarchiveObjectWithData: [appSettingsPlist objectForKey:@"TextSettings"]];
		if (b_str == NULL)
			[self fatalAlert: @"Corrupt app bundle" subText: @"Script missing from application bundle."];
	
		// we create string with the script based on the decoded data
		script = [[NSString alloc] initWithData: b_str encoding: textEncoding];
	}
}

- (IBAction)cancel:(id)sender
{
	if ([[sender title] isEqualToString: @"Quit"])
		[[NSApplication sharedApplication] terminate: self];
	else if (task != NULL)
		[task terminate];
}

// show / hide the details text field in progress bar output
- (IBAction)toggleDetails: (id)sender
{
	NSRect winRect = [progressBarWindow frame];
	
	if ([sender state] == NSOffState)
	{
		[progressBarWindow setShowsResizeIndicator: NO];
		winRect.origin.y += 224;
		winRect.size.height -= 224;		
		[progressBarWindow setFrame: winRect display: TRUE animate: TRUE];
	}
	else if ([sender state] == NSOnState)
	{
		[progressBarWindow setShowsResizeIndicator: YES];
		winRect.origin.y -= 224;
		winRect.size.height += 224;
		[progressBarWindow setFrame: winRect display: TRUE animate: TRUE];
	}
}

#pragma mark -

- (void)fatalAlert: (NSString *)message subText: (NSString *)subtext
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText: message];
	[alert setInformativeText: subtext];
	[alert setAlertStyle: NSCriticalAlertStyle];
	
	if ([alert runModal] == NSAlertFirstButtonReturn) 
	{
		[alert release];
		[[NSApplication sharedApplication] terminate: self];
		return;
	}
	[alert release];
}


@end
