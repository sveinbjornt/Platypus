/*
 Copyright (c) 2003-2015, Sveinbjorn Thordarson <sveinbjornt@gmail.com
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
 */

#import "PlatypusIconView.h"
#import "IconController.h"

@implementation PlatypusIconView

- (void)setDelegate: (id)theDelegate
{
	delegate = theDelegate;
}

- (id)delegate
{
	return delegate;
}

#pragma mark - Dragging

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if (delegate && [delegate respondsToSelector:@selector(draggingEntered:)]) 
		return [delegate draggingEntered:sender];
	else
		return [super draggingEntered:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender;
{
	if (delegate && [delegate respondsToSelector:@selector(draggingExited:)]) 
		return [delegate draggingExited:sender];
	else
		return [super draggingExited:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	if (delegate && [delegate respondsToSelector:@selector(draggingUpdated:)]) 
		return [delegate draggingUpdated:sender];
	else
		return [super draggingUpdated:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	if (delegate && [delegate respondsToSelector:@selector(prepareForDragOperation:)]) 
		return [delegate prepareForDragOperation:sender];
	else
		return [super prepareForDragOperation:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if (delegate && [delegate respondsToSelector:@selector(performDragOperation:)])
		return [delegate performDragOperation:sender];
	else
		return [super performDragOperation:sender];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	if (delegate && [delegate respondsToSelector:@selector(concludeDragOperation:)])
		[delegate concludeDragOperation:sender];
	else
		[super concludeDragOperation:sender];
}

#pragma mark - Drag source

- (void)mouseDown: (NSEvent*)event
{
    //get the Pasteboard used for drag and drop operations
    NSPasteboard *dragPasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];
		
    //create a new image for our semi-transparent drag image
    NSImage *dragImage = [[NSImage alloc] initWithSize: [[self image] size]];     
    if (dragImage == nil)
		return;
	
	//OK, let's see if we have an icns file behind this
	if ([(IconController *)delegate hasIcns])
	{
		[dragPasteboard declareTypes: [NSArray arrayWithObject: NSFilenamesPboardType] owner: self];
		[dragPasteboard setPropertyList: [NSArray arrayWithObject: [delegate icnsFilePath]] forType: NSFilenamesPboardType];
	}
	else
	{
		[dragPasteboard declareTypes: [NSArray arrayWithObject: NSTIFFPboardType] owner: self];
		[dragPasteboard setData: [delegate imageData] forType:NSTIFFPboardType];
	}	
	
    //draw our original image as 50% transparent
    [dragImage lockFocus];	
    [[self image] drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 0.5];
    
    [dragImage unlockFocus];//finished drawing
    [dragImage setScalesWhenResized:YES];//we want the image to resize
    [dragImage setSize: [self bounds].size];//change to the size we are displaying
	
    //execute the drag
    [self dragImage: dragImage					//image to be displayed under the mouse
				 at: [self bounds].origin		//point to start drawing drag image
			 offset: NSZeroSize					//no offset, drag starts at mousedown location
			  event: event						//mousedown event
		 pasteboard: dragPasteboard				//pasteboard to pass to receiver
			 source: self						//object where the image is coming from
		  slideBack: YES];						//if the drag fails slide the icon back
    
	[dragImage release];
}

- (NSDragOperation)draggingSourceOperationMaskForLocal: (BOOL)flag
{
	if (flag)
		return NSDragOperationNone;
	
    return NSDragOperationCopy;
}

- (BOOL)ignoreModifierKeysWhileDragging
{
	return YES;
}

- (BOOL)acceptsFirstMouse: (NSEvent *)event 
{
	//so source doesn't have to be the active window
    return YES;
}


@end
