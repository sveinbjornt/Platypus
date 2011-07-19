//
//  ScriptAnalyser.m
//  Platypus
//
//  Created by Sveinbjorn Thordarson on 8/30/10.
//  Copyright 2010 Sveinbjorn Thordarson. All rights reserved.
//
//
//  This is a class with convenience and analytical methods for the 
//  script file types handled by Platypus.
//
#import "ScriptAnalyser.h"

@implementation ScriptAnalyser

+(NSArray *)interpreters
{
	return [NSArray arrayWithObjects:			
	 @"/bin/sh",
	 @"/usr/bin/perl",
	 @"/usr/bin/python",
	 @"/usr/bin/ruby",
	 @"/usr/bin/osascript",
	 @"/usr/bin/tclsh",
	 @"/usr/bin/expect",
	 @"/usr/bin/php", 
	 @"",
	 nil];
}

+(NSArray *)interpreterDisplayNames
{
	return [NSArray arrayWithObjects:			
	@"Shell",
	@"Perl",
	@"Python",
	@"Ruby",
	@"AppleScript",
	@"Tcl",
	@"Expect",
	@"PHP", 
	@"Other...",
	nil];
}

+(NSString *)displayNameForInterpreter: (NSString *)theInterpreter
{
	NSArray *interpreters = [self interpreters];
	NSArray *interpreterDisplayNames = [self interpreterDisplayNames];
	
	for (int i = 0; i < [interpreters count]; i++)
		if ([theInterpreter isEqualToString: [interpreters objectAtIndex: i]])
			return [interpreterDisplayNames objectAtIndex: i];
	
	return @"Other...";
}

+ (NSString *)interpreterBasedOnDisplayName: (NSString *)name
{
	NSArray *interpreters = [self interpreters];
	NSArray *interpreterDisplayNames = [self interpreterDisplayNames];
	
	int i;
	for (i = 0; i < [interpreterDisplayNames count]; i++)
		if ([name isEqualToString: [interpreterDisplayNames objectAtIndex: i]])
			return [interpreters objectAtIndex: i];
	
	return @"";
}

/*****************************************
 - Determine script type based on a file's suffix
 *****************************************/

+ (NSString *)interpreterFromSuffix: (NSString *)fileName
{
	NSArray *interpreters = [self interpreters];
	
	if ([fileName hasSuffix: @".sh"])
		return [interpreters objectAtIndex: 0];
	else if ([fileName hasSuffix: @".pl"])
		return [interpreters objectAtIndex: 1];
	else if ([fileName hasSuffix: @".py"])
		return [interpreters objectAtIndex: 2];
	else if ([fileName hasSuffix: @".rb"] || [fileName hasSuffix: @".rbx"])
		return [interpreters objectAtIndex: 3];
	else if ([fileName hasSuffix: @".scpt"] || [fileName hasSuffix: @".applescript"])
		return [interpreters objectAtIndex: 4];
	else if ([fileName hasSuffix: @".tcl"])
		return [interpreters objectAtIndex: 5];
	else if ([fileName hasSuffix: @".exp"] || [fileName hasSuffix: @".expect"])
		return [interpreters objectAtIndex: 6];
	else if ([fileName hasSuffix: @".php"])
		return [interpreters objectAtIndex: 7];
	
	return @"";
}

/********************************************************************
 - Parse the Shebang line (#!) to get the interpreter for the script
 **********************************************************************/

+ (NSArray *)getInterpreterFromShebang: (NSString *)path
{	
	// get the first line of the script
	NSString *script = [NSString stringWithContentsOfFile: path encoding: DEFAULT_OUTPUT_TXT_ENCODING error: nil];
	NSArray *lines = [script componentsSeparatedByString: @"\n"];
	NSString *firstLine = [lines objectAtIndex: 0];
	
	// if the first line of the script is shorter than 2 chars, it can't possibly be a shebang line
	if ([firstLine length] <= 2)
		return [NSArray arrayWithObject: @""];
	
	// get first two characters of first line
	NSString *shebang = [firstLine substringToIndex: 2]; // first two characters should be #!
	if (![shebang isEqualToString: @"#!"])
		return [NSArray arrayWithObject: @""];
	
	// get everything that follows after the #!
	// seperate it by whitespaces, in order not to get also the params to the interpreter
	NSString *interpreterCmd = [firstLine substringFromIndex: 2];
	NSArray *words = [interpreterCmd componentsSeparatedByString: @" "];
	return ([[words retain] autorelease]);
}

/*****************************************
 - Try to determine the interpreter of the script, return path to it
 *****************************************/

+ (NSString *)determineInterpreterForScriptFile: (NSString *)path
{
	NSString *interpreter = [[self getInterpreterFromShebang: path] objectAtIndex: 0];
	if (![interpreter isEqualToString: @""])
		return interpreter;
	
	return [self interpreterFromSuffix: path];
}

/*****************************************
 - Report on syntax of script
 *****************************************/

+ (NSString *)checkSyntaxOfFile: (NSString *)scriptPath withInterpreter: (NSString *)suggestedInterpreter
{
	NSTask			*task;
	NSString		*interpreter = suggestedInterpreter;
	NSPipe			*outputPipe = [NSPipe pipe];
	NSFileHandle	*readHandle;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath: scriptPath ])//make sure it exists
		return nil;
	
	if (interpreter == nil)
		interpreter = [self determineInterpreterForScriptFile: scriptPath];
	
	if ([interpreter isEqualToString:@""])
		return nil;
	
	task = [[NSTask alloc] init];
	
	 //let's see if the script type is supported for syntax checking
	 //if so, we set up the task's launch path as the script interpreter and set the relevant flags and arguments

	if ([interpreter isEqualToString: @"/bin/sh"])
	{
		[task setArguments: [NSArray arrayWithObjects: @"-n", scriptPath, nil]];
	}
	else if ([interpreter isEqualToString: @"/usr/bin/perl"])
	{
		[task setArguments: [NSArray arrayWithObjects: @"-c", scriptPath, nil]];
	}
	else if ([interpreter isEqualToString: @"/usr/bin/ruby"])
	{
		 [task setArguments: [NSArray arrayWithObjects: @"-c", scriptPath, nil]];
	}
	else if ([interpreter isEqualToString: @"/usr/bin/php"])
	{
		[task setArguments: [NSArray arrayWithObjects: @"-l", scriptPath, nil]];
	}
	else
	{
		[task release];
		return [NSString stringWithFormat: @"Syntax Checking is not supported by interpreter %@", interpreter];
	}
	
	// OK, so interpreter supports syntax checking
	[task setLaunchPath: interpreter];
	
	 //direct the output of the task into a file handle for reading
	 [task setStandardOutput: outputPipe];
	 [task setStandardError: outputPipe];
	 readHandle = [outputPipe fileHandleForReading];
	 
	 //launch task
	 [task launch];
	 [task waitUntilExit];
	
	 //get output in string
	 NSString *outputStr = [[[NSString alloc] initWithData: [readHandle readDataToEndOfFile] encoding: DEFAULT_OUTPUT_TXT_ENCODING] autorelease];
	 
	 if ([outputStr length] == 0) //if the syntax report string is empty, we report syntax as OK
		 outputStr = [NSString stringWithString: @"Syntax OK"];
	
	[task release];
	
	 return outputStr;
}

@end
