/*
 Copyright (c) 2003-2015, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
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

#pragma mark - Delegate

- (void)setDelegate: (id)theDelegate {
	delegate = theDelegate;
}

- (id)delegate {
	return delegate;
}

#pragma mark - Dragging

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if (delegate && [delegate respondsToSelector:@selector(draggingEntered:)]) {
		return [delegate draggingEntered:sender];
    } else {
		return [super draggingEntered:sender];
    }
}

- (void)draggingExited:(id <NSDraggingInfo>)sender;
{
	if (delegate && [delegate respondsToSelector:@selector(draggingExited:)]) {
        [delegate draggingExited:sender];
	} else {
        [super draggingExited:sender];
    }
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	if (delegate && [delegate respondsToSelector:@selector(draggingUpdated:)]) {
		return [delegate draggingUpdated:sender];
	} else {
		return [super draggingUpdated:sender];
    }
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	if (delegate && [delegate respondsToSelector:@selector(prepareForDragOperation:)]) {
		return [delegate prepareForDragOperation:sender];
	} else {
		return [super prepareForDragOperation:sender];
    }
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if (delegate && [delegate respondsToSelector:@selector(performDragOperation:)]) {
		return [delegate performDragOperation:sender];
	} else {
		return [super performDragOperation:sender];
    }
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	if (delegate && [delegate respondsToSelector:@selector(concludeDragOperation:)]) {
		[delegate concludeDragOperation:sender];
    } else {
		[super concludeDragOperation:sender];
    }
}

#pragma mark - Drag source

- (void)mouseDown:(NSEvent*)event
{
    /*------------------------------------------------------
     catch mouse down events in order to start drag
     --------------------------------------------------------*/
    
    /* Dragging operation occur within the context of a special pasteboard (NSDragPboard).
     * All items written or read from a pasteboard must conform to NSPasteboardWriting or
     * NSPasteboardReading respectively.  NSPasteboardItem implements both these protocols
     * and is as a container for any object that can be serialized to NSData. */
    
    NSPasteboardItem *pbItem = [NSPasteboardItem new];
    /* Our pasteboard item will support public.tiff, public.pdf, and our custom UTI (see comment in -draggingEntered)
     * representations of our data (the image).  Rather than compute both of these representations now, promise that
     * we will provide either of these representations when asked.  When a receiver wants our data in one of the above
     * representations, we'll get a call to  the NSPasteboardItemDataProvider protocol method –pasteboard:item:provideDataForType:. */
    [pbItem setDataProvider:self forTypes:[NSArray arrayWithObjects:NSPasteboardTypeTIFF, nil]];
    
    //create a new NSDraggingItem with our pasteboard item.
    NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
    [pbItem release];
    
    /* The coordinates of the dragging frame are relative to our view.  Setting them to our view's bounds will cause the drag image
     * to be the same size as our view.  Alternatively, you can set the draggingFrame to an NSRect that is the size of the image in
     * the view but this can cause the dragged image to not line up with the mouse if the actual image is smaller than the size of the
     * our view. */
    NSRect draggingRect = self.bounds;
    
    /* While our dragging item is represented by an image, this image can be made up of multiple images which
     * are automatically composited together in painting order.  However, since we are only dragging a single
     * item composed of a single image, we can use the convince method below. For a more complex example
     * please see the MultiPhotoFrame sample. */
    [dragItem setDraggingFrame:draggingRect contents:[self image]];
    
    //create a dragging session with our drag item and ourself as the source.
    NSDraggingSession *draggingSession = [self beginDraggingSessionWithItems:[NSArray arrayWithObject:[dragItem autorelease]] event:event source:self];
    //causes the dragging item to slide back to the source if the drag fails.
    draggingSession.animatesToStartingPositionsOnCancelOrFail = YES;
    
    draggingSession.draggingFormation = NSDraggingFormationNone;
}

- (void)pasteboard:(NSPasteboard *)sender item:(NSPasteboardItem *)item provideDataForType:(NSString *)type
{
    /*------------------------------------------------------
     method called by pasteboard to support promised
     drag types.
     --------------------------------------------------------*/
    //sender has accepted the drag and now we need to send the data for the type we promised
    if ([type compare: NSPasteboardTypeTIFF] == NSOrderedSame) {
        
        //set data for TIFF type on the pasteboard as requested
        [sender setData:[[self image] TIFFRepresentation] forType:NSPasteboardTypeTIFF];
    }
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    return (context == NSDraggingContextOutsideApplication) ? NSDragOperationCopy : NSDragOperationNone;
}

- (BOOL)ignoreModifierKeysForDraggingSession:(NSDraggingSession *)session {
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event  {
	//so source doesn't have to be the active window
    return YES;
}

@end
