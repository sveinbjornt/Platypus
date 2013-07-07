/*
 * STDragWebView
 * This is a modified version of Adium's ESWebView used to enable ordinary drag and drop on WebViews
 *
 * Changes are copyright (C) 2010 Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 *
 * Adium source code is protected by the copyright of its respective developers.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "STDragWebView.h"

@implementation STDragWebView

- (id)initWithFrame:(NSRect)frameRect frameName:(NSString *)frameName groupName:(NSString *)groupName {
	if ((self = [super initWithFrame:frameRect frameName:frameName groupName:groupName]))
		delegate = NULL;
    
	return self;
}

//Accepting Drags ------------------------------------------------------------------------------------------------------
#pragma mark Accepting Drags

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo> )sender {
	return [delegate draggingEntered:sender];
}

- (void)draggingExited:(id <NSDraggingInfo> )sender;
{
	return [delegate draggingExited:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo> )sender {
	return [delegate draggingUpdated:sender];
}

/*- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return [delegate prepareForDragOperation:sender];
}*/

- (BOOL)performDragOperation:(id <NSDraggingInfo> )sender {
	return [delegate performDragOperation:sender];
}

- (void)concludeDragOperation:(id <NSDraggingInfo> )sender {
	return [delegate concludeDragOperation:sender];
}

@end
