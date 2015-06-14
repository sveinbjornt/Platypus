# Platypus

Platypus is a developer tool for the Mac OS X operating system. 

It can be used to create native Mac OS X applications from interpreted 
scripts such as shell scripts or Perl and Python programs. This is done 
by wrapping the script in an application bundle directory structure 
along with an executable binary that runs the script.

Platypus makes it easy for you to share your scripts and programs 
with those unfamiliar with the command line interface, without any 
knowledge of the native Mac OS X APIs -- a few clicks and you will have 
your own Mac OS X graphical program. Creating installers, maintenance 
applications, login items, launchers, automations and droplets is 
very easy using Platypus.


# Some notes on the code

The Platypus source code is in a somewhat sorry state.  
It's very old software, dating back to the early days 
of Mac OS X.  It was originally written in C using the 
Carbon APIs, but later transitioned to Cocoa during the 
time I was learning to use Objective-C and the Cocoa 
APIs. I made many beginner mistakes, some of which 
remain in the code.  The software has gone through over 
three dozen significant versions. It has been patched,
bugfixed, streamlined to include new features and 
partially refactored.  Much crust remains.  I once tried 
to create a new version which was supposed to leave
much of the old codebase behind it, but the task grew 
daunting in size and I was unable to find the time.

That being said, with these caveats being kept in mind, 
here is the GPL'd source code to Platypus.  At least it's 
meticulously commented.  Enjoy.