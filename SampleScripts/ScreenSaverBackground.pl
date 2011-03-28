#!/usr/bin/perl
#
# An app created with this Perl script will toggle on / off the hidden
# screen saver background feature in Mac OS X and then exit.    
#
# Open with Platypus, select Output: None and make sure "Remain running" option
# is not set.
#
# *** Make sure not to run this if you have a screensaver password enabled ****
#

use Shell;

$matched = 0;

# Get list of processes and kill ScreenSaverEngine if it's running
@procs = `ps -cxa`;
for $proc (@procs )
{
	if ($proc =~ /ScreenSaverEngine/)
	{
		$matched = true;
		killall("ScreenSaverEngine");
	}
}

if (!$matched)
{
	system("/System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine -background &");
}
