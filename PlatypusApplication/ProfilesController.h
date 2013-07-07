/*
 Platypus - program for creating Mac OS X application wrappers around scripts
 Copyright (C) 2003-2013 Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 
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
#import "PlatypusController.h"
#import "Common.h"

#define EXAMPLES_TAG    7

@interface ProfilesController : NSObject
{
    IBOutlet id profilesMenu;
    IBOutlet id platypusControl;
    IBOutlet id examplesMenuItem;
}
- (IBAction)loadProfile:(id)sender;
- (void)loadProfileFile:(NSString *)file;
- (IBAction)saveProfile:(id)sender;
- (IBAction)saveProfileToLocation:(id)sender;
- (void)writeProfile:(NSDictionary *)dict toFile:(NSString *)profileDestPath;
- (void)profileMenuItemSelected:(id)sender;
- (IBAction)clearAllProfiles:(id)sender;
- (IBAction)constructMenus:(id)sender;
- (NSArray *)getProfilesList;
- (NSArray *)getExamplesList;
@end
