//
//  ColorWellWithPopover.m
//  ColorPickerPopup
//
//  Created by Balázs Faludi on 06.08.12.
//  Copyright (c) 2012 Balázs Faludi. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  - Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  - Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//  - Neither the name of the copyright holders nor the
//    names of its contributors may be used to endorse or promote products
//    derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL BALÁZS FALUDI BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "BFPopoverColorWell.h"
#import "BFColorPickerPopover.h"
#import "NSColorPanel+BFColorPickerPopover.h"
#import "NSColorWell+BFColorPickerPopover.h"

@interface BFColorPickerPopover ()
@property (nonatomic) NSColorPanel *colorPanel;
@property (nonatomic, weak) NSColorWell *colorWell;
@end

@interface BFPopoverColorWell ()
@property (nonatomic, weak) BFColorPickerPopover *popover;
@property (nonatomic, readwrite) BOOL isActive;
@end

@implementation BFPopoverColorWell

- (void)setup {
	self.preferredEdgeForPopover = NSMaxXEdge;
	self.useColorPanelIfAvailable = YES;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)activateWithPopover {
	if (self.isActive) return;
	
	// Setup and show the popover.
	self.popover = [BFColorPickerPopover sharedPopover];
    self.popover.delegate = self;
	self.popover.color = self.color;
	[self.popover showRelativeToRect:self.frame ofView:self.superview preferredEdge:self.preferredEdgeForPopover];
	self.popover.colorWell = self;
	
	// Disable the shared color panel, while the NSColorWell implementation is executed.
	// This is done by overriding the orderFront: method of NSColorPanel in a category.
	[[NSColorPanel sharedColorPanel] disablePanel];
	[super activate:YES];
	[[NSColorPanel sharedColorPanel] enablePanel];
	
	self.isActive = YES;
}

- (void)activate:(BOOL)exclusive {
	if (self.isActive) return;
	
	if (self.useColorPanelIfAvailable && [NSColorPanel sharedColorPanelExists] && [[NSColorPanel sharedColorPanel] isVisible]) {
		[super activate:exclusive];
		self.isActive = YES;
	} else {
		[self activateWithPopover];
	}
}

- (void)deactivate {
	if (!self.isActive) return;
	[super deactivate];
	self.popover.colorWell = nil;
    self.popover.delegate = nil;
	self.popover = nil;
	self.isActive = NO;
}

// Force using a popover (even if useColorPanelIfAvailable = YES), when the user double clicks the well.
- (void)mouseDown:(NSEvent *)theEvent {
	if([theEvent clickCount] == 2 && [NSColorPanel sharedColorPanelExists] && [[NSColorPanel sharedColorPanel] isVisible]) {
		[self deactivate];
		[self activateWithPopover];
	} else {
		[super mouseDown:theEvent];
	}
	
}

- (void)popoverDidClose:(NSNotification *)notification
{
    [self deactivate];
}

@end
