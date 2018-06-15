# Platypus

<img align="right" src="Documentation/images/platypus.png" style="float: right; margin-left: 30px;">

**Platypus** is a developer tool that creates native Mac applications
from interpreted scripts such as shell scripts or Perl and Python programs.
This is done by wrapping the script in an 
[application bundle](https://en.wikipedia.org/wiki/Bundle_(OS_X)#OS_X_application_bundles)
directory structure  along with an application binary that runs the script.

Platypus makes it easy to share scripts and programs with those 
unfamiliar with the command line interface. Native user-friendly
applications can be created with a few clicks. It is very easy to
create installers, administrative applications, login items, status menu items, 
launchers, automations and droplets using Platypus.

* **⇩ [Download Platypus 5.2](http://sveinbjorn.org/files/software/platypus.zip)** (Intel 64-bit, 10.7 or later, ~3.5 MB)

## Documentation & Links

* [Platypus Documentation](Documentation/Documentation.md)
* [Platypus Website](http://www.sveinbjorn.org/platypus)
* [Platypus Command Line Tool man Page](http://www.sveinbjorn.org/files/manpages/platypus.man.html)
* [Platypus Developer Mailing List](http://www.sveinbjorn.org/platypus_mailinglist)
* [AppCast XML Feed](http://www.sveinbjorn.org/files/appcasts/PlatypusAppcast.xml)


## Screenshots

### Platypus main window
<img src="Documentation/images/basic_interface.png" width="663">

### Interfaces

Platypus lets you select one of several different user interfaces for your script.

#### Progress Bar Interface
<img src="Documentation/images/interface_screenshot_progress_bar.png" width="550">

#### Text Window Interface
<img src="Documentation/images/interface_screenshot_text_window.png" width="581">

#### Web View Interface
<img src="Documentation/images/interface_screenshot_web_view.png" width="620">

#### Status Menu Interface
<img src="Documentation/images/interface_screenshot_status_menu.png" width="401">

#### Droplet Interface
<img src="Documentation/images/interface_screenshot_droplet.png" width="374">

## Some notes on the code

Platypus is very old software, dating back to the early days of Mac OS X, circa 2003.  It was originally written in C using the
Carbon APIs, but later transitioned to Cocoa during the time I was learning to use Objective-C and the Cocoa
APIs. I made many beginner mistakes, some of which remain in the code.  This software has  since gone through about
four dozen significant versions. It has been patched, bugfixed, streamlined to include new features and was
recently transitioned over to modern Objective C. It's not how I would write it today.

With these caveats in mind, here is the BSD-licensed source code to Platypus.

## License 

Copyright (c) Sveinbjorn Thordarson &lt;<a href="mailto:">sveinbjorn@sveinbjorn.org</a>&gt;
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

### Hexley Icon

Hexley DarwinOS Mascot Copyright (c) 2000 Jon Hooper. All Rights Reserved.

