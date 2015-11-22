#IconFamily class

by Troy Stephens, Thomas Schnitzer, David Remahl, Nathan Day, Ben Haller, Sven Janssen, Peter Hosey, Conor Dearden, Elliot Glaysher, and Dave MacLachlan

##Modifications

This fork of IconFamily from Alex Zielenski's fork adds the following:

* Fixed broken alpha channel when writing icons to icns file
* Fixed issues where empty icns files were being generated on Retina macs

This fork of IconFamily by **Alex Zielenski** adds the following:

* Usage of ```kIconServices[size]PixelDataARGB``` types
* Correct encoding of image data under Lion
* Removal of deprecated APIs and replacement of equivalent up to date ones
* Lossless encoding using the Accelerate APIs for 32 bit and 24 bit types
* Implementation of ```NSPasteboardReading``` and ```NSPasteboardWriting```

##Purpose

"IconFamily" is a Cocoa/Objective-C wrapper for Mac OS X Icon Services' "IconFamily" data type. Its main purpose is to enable Cocoa applications to easily assign custom file icons from NSImage instances. Using the IconFamily class you can:

* create a multi-representation icon family from any arbitrary NSImage
* assign an icon family as a file's custom icon resource, so it will appear in Finder views
* read and write .icns files
* copy icon data to and from the scrap (pasteboard)
* get and set the elements of an icon family in convenient, Cocoa-compatible NSBitmapImageRep form

The IconFamily code started out as a small experiment that yielded a modest bit of code that has since found its way into a gratifying number of applications. It's extensively commented, so extending it further and fixing problems should be pretty easy. I welcome contributions, suggestions, and feedback that will help to improve it further.

##License

The IconFamily source code is released under The MIT License, which permits commercial as well as non-commercial use.

##Download

Get the latest complete source code at sourceforge.

There is reference documentation for the IconFamily class on the sourceforge project page.

##Credits/Contributors

I'm grateful to a number of talented and generous people for enhancements, bug fixes, and feedback that have helped improve the IconFamily code over the years. Thanks, guys!

Thomas Schnitzer provided contributions to the icon family element extraction code, and valuable help in understanding the related Carbon APIs, that made the initial releases possible.

David Remahl, author of Can Combine Icons, generously donated his own extensions to the IconFamily class for the 0.3 and 0.4.x releases. Nathan Day has likewise helped fix bugs and has contributed useful extensions, in the course of using the IconFamily code to build Popup Dock. Ben Haller, proprietor of Stick Software, pitched in his own contributions and dedication to get the 0.4 release of IconFamily out the door.

Sven Janssen, Peter Hosey, Conor Dearden, and Elliot Glaysher reported bugs and contributed patches to modernize the IconFamily code and keep the project going in the 0.9.x releases.

Dave MacLachlan of Google has contributed support for 256x256 and 512x512 icon family elements that I've rolled into a 0.9.3 release.

Mike Margolis, author of Sugar Cube Software's Pic2Icon tool, has contributed support for creating shadowed, dog-eared document-like thumbnail icons that I've been meaning for a good long while now to fold into a future release. (Sorry, Mike!)


