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


### Some notes on the code

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

With these caveats in mind, here is the BSD-licensed 
source code to Platypus. At least it's meticulously commented.

### License 

Copyright (c) Sveinbjorn Thordarson <sveinbjornt@gmail.com>
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