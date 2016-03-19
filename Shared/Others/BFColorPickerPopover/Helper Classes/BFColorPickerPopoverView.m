//
//  BFColorPickerPopoverView.m
//  BFColorPickerPopover Demo
//
//  Created by Balázs Faludi on 07.08.12.
//  Copyright (c) 2012 Balázs Faludi. All rights reserved.
//

#import "BFColorPickerPopoverView.h"
#import "BFColorPickerPopover.h"
#import "BFColorPickerViewController.h"

#include <tgmath.h>

static inline CGFloat pow2(CGFloat x) {return x*x;}

@interface BFColorPickerViewController ()
@property (nonatomic, weak) NSView *colorPanelView;
@end

@interface BFColorPickerPopover ()
- (void)closeAndDeactivateColorWell:(BOOL)deactivate removeTarget:(BOOL)remove removeObserver:(BOOL)removeObserver;
@end


@interface BFColorPickerPopoverView ()
@property (nonatomic) CGPoint originalWindowOrigin;
@property (nonatomic) CGPoint originalMouseOffset;
@property (nonatomic) BOOL dragging;
@end


@implementation BFColorPickerPopoverView

- (void)mouseDown:(NSEvent *)event {
	self.originalWindowOrigin = self.window.frame.origin;
	self.originalMouseOffset = [event locationInWindow];
	self.dragging = YES;
}

- (void)mouseDragged:(NSEvent *)event {
	if (self.dragging) {
		// Calculate the new window position.
		CGPoint currentMouseOffset = [event locationInWindow];
		CGPoint difference = CGPointMake(currentMouseOffset.x - self.originalMouseOffset.x,
										 currentMouseOffset.y - self.originalMouseOffset.y);
		CGPoint currentWindowOrigin = self.window.frame.origin;
		CGPoint newWindowOrigin = CGPointMake(currentWindowOrigin.x + difference.x, currentWindowOrigin.y + difference.y);
		
//		[self.window setFrameOrigin:newWindowOrigin];	// Use this to make the anchor fixed, even when moving the popover ...
		[self.window setFrame:(CGRect){newWindowOrigin, self.window.frame.size} display:YES animate:NO];   // ... instead of this
		
		// Hide the anchor if the popover has been dragged far enough for detachment.
		CGFloat distance = sqrt(pow2(self.originalWindowOrigin.x - currentWindowOrigin.x) + pow2(self.originalWindowOrigin.y - currentWindowOrigin.y));
		BOOL isFarEnough = (distance < kBFColorPickerPopoverMinimumDragDistance);
		[[BFColorPickerPopover sharedPopover] setValue:isFarEnough ? @0 : @1 forKey:@"shouldHideAnchor"];

	}
}

- (void)mouseUp:(NSEvent *)event {

	if (self.dragging) {
		CGPoint currentWindowOrigin = self.window.frame.origin;
		CGFloat distance = sqrt(pow2(self.originalWindowOrigin.x - currentWindowOrigin.x) + pow2(self.originalWindowOrigin.y - currentWindowOrigin.y));
		
		if (distance < kBFColorPickerPopoverMinimumDragDistance) {
			// If the popover isn't far enough for detachment, animate it back to it's original position.
			[self.window setFrame:(CGRect){self.originalWindowOrigin, self.window.frame.size} display:YES animate:YES];
		} else {
			// Otherwise calculate the right frame for the color panel (the content views' frames should be the same as in the popover) ...
			NSColorPanel *panel = [NSColorPanel sharedColorPanel];
			NSView *popoverView = [((BFColorPickerViewController *)[[BFColorPickerPopover sharedPopover] contentViewController]) colorPanelView];
			NSRect popoverViewFrameRelativeToWindow = [popoverView convertRect:popoverView.bounds toView:nil];
			NSRect popoverViewFrameRelativeToScreen = [popoverView.window convertRectToScreen:popoverViewFrameRelativeToWindow];
			
			// ... and switch from popover to panel.
			CGRect panelFrame = [panel frameRectForContentRect:popoverViewFrameRelativeToScreen];
			[panel setFrame:panelFrame display:YES];
			
			
//			[self.window orderOut:self];
			
			[[BFColorPickerPopover sharedPopover] closeAndDeactivateColorWell:NO removeTarget:NO removeObserver:NO];
//			[self.window orderOut:self];
			[panel orderFront:nil];
			
//			panel.color = [BFColorPickerPopover sharedPopover].color;
		}
		
		[[BFColorPickerPopover sharedPopover] setValue:@0 forKey:@"shouldHideAnchor"];
		self.dragging = NO;
	}

}

@end
