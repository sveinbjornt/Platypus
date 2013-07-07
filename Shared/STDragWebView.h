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

#import <WebKit/WebKit.h>

@interface STDragWebView : WebView
{
    id delegate;
}
@end

@interface NSObject (STDragWebViewDragDelegate)
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo> )sender;
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo> )sender;
- (void)draggingExited:(id <NSDraggingInfo> )sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo> )sender;
//- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (void)concludeDragOperation:(id <NSDraggingInfo> )sender;
@end
