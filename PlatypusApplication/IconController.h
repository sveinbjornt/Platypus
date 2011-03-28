/*
    Platypus - program for creating Mac OS X application wrappers around scripts
    Copyright (C) 2003-2010 Sveinbjorn Thordarson <sveinbjornt@simnet.is>

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

#import <Cocoa/Cocoa.h>

@interface IconController : NSObject
{
    IBOutlet id iconImageView;
    IBOutlet id window;
	IBOutlet id iconToggleButton;
	IBOutlet id iconNameTextField;
	IBOutlet id	platypusControl;
	NSString	*icnsFilePath;
}
- (IBAction)copyIcon:(id)sender;
- (IBAction)pasteIcon:(id)sender;
- (void)updateIcnsStatus;
- (IBAction)contentsWereAltered:(id)sender;
- (IBAction)nextIcon:(id)sender;
- (IBAction)previousIcon:(id)sender;
- (void)setAppIconForType: (int)type;
- (NSDictionary *)getIconInfoForType: (int)type;
- (void)setDefaultIcon;
- (IBAction)switchIcons:(id)sender;
- (void)writeIconToPath: (NSString *)path;
- (NSData *)imageData;
- (BOOL)hasIcns;
- (NSString *)icnsFilePath;
- (UInt64)iconSize;
- (BOOL)validateMenuItem:(NSMenuItem*)anItem; 
- (IBAction) selectIcon:(id)sender;
- (void)selectIconDidEnd:(NSOpenPanel *)oPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (IBAction)selectIcnsFile:(id)sender;
- (void)selectIcnsFileDidEnd:(NSOpenPanel *)oPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (BOOL)loadIcnsFile: (NSString *)filePath;
- (BOOL)loadImageFile: (NSString *)filePath;
- (BOOL)loadImageWithData: (NSData *)imgData;
- (BOOL)loadImageFromPasteboard;
- (BOOL)loadPresetIcon: (NSDictionary *)iconInfo;
- (void)updateForCustomIcon;
@end
