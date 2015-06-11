/*
 ScriptExec - binary bundled into Platypus-generated applications
 Copyright (C) 2003-2015 Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 
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

#ifdef DEBUG
    void exceptionHandler(NSException *exception);

    void exceptionHandler(NSException *exception) {
        NSLog(@"%@", [exception reason]);
        NSLog(@"%@", [exception userInfo]);
        NSLog(@"%@", [exception callStackReturnAddresses]);
        NSLog(@"%@", [exception callStackSymbols]);
    }
#endif

int main(int argc, char *argv[]) {
#ifdef DEBUG
    NSSetUncaughtExceptionHandler(&exceptionHandler);
#endif
    return NSApplicationMain(argc,  (const char **)argv);
}
