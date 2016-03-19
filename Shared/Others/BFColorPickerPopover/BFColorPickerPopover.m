//
//  ColorPickerPopover.m
//  ColorPickerPopup
//
//  Created by Balázs Faludi on 05.08.12.
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

#import "BFColorPickerPopover.h"
#import "BFColorPickerViewController.h"

@interface NSPopover (ColorPickerPopover)
- (BOOL)_delegatePopoverShouldClose:(id)sender;
@end


@interface BFColorPickerPopover ()
@property (nonatomic) NSColorPanel *colorPanel;
@property (nonatomic, weak) NSColorWell *colorWell;
@property (nonatomic) BOOL observingColor;
@end


@implementation BFColorPickerPopover {
	NSColor *_color;
}

@synthesize observingColor = _observingColor;

- (void)setObservingColor:(BOOL)observingColor {
	if (_observingColor == observingColor) {
		return;
	}

	if (!self.colorPanel) {
		observingColor = NO;
	}

	_observingColor = observingColor;

	void *context = (__bridge void *)self;
	if (_observingColor) {
		[self.colorPanel addObserver:self forKeyPath:@"color" options:NSKeyValueObservingOptionNew context:context];
	} else {
		[self.colorPanel removeObserver:self forKeyPath:@"color" context:context];
	}
}

#pragma mark -
#pragma mark Initialization & Destruction

+ (BFColorPickerPopover *)sharedPopover
{
    static BFColorPickerPopover *sharedPopover = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPopover = [[BFColorPickerPopover alloc] init];
    });
    return sharedPopover;
}

- (id)init
{
    self = [super init];
    if (self) {
		self.behavior = NSPopoverBehaviorSemitransient;
		_color = [NSColor whiteColor];
	}
    return self;
}

#pragma mark -
#pragma mark Getters & Setters

- (NSColorPanel *)colorPanel {
	return ((BFColorPickerViewController *)self.contentViewController).colorPanel;
}

- (NSColor *)color {
	return self.colorPanel.color;
}

- (void)setColor:(NSColor *)color {
	_color = color;
	if (self.isShown) {
		self.colorPanel.color = color;
	}
}

#pragma mark -
#pragma mark Popover Lifecycle

- (void)showRelativeToRect:(NSRect)positioningRect ofView:(NSView *)positioningView preferredEdge:(NSRectEdge)preferredEdge {
	
	// Close the popover without an animation if it's already on screen.
	if (self.isShown) {
		id targetBackup = self.target;
		SEL actionBackup = self.action;
		BOOL animatesBackup = self.animates;
		self.animates = NO;
		[self close];
		self.animates = animatesBackup;
		self.target = targetBackup;
		self.action = actionBackup;
	}
	
	self.contentViewController = [[BFColorPickerViewController alloc] init];
	[super showRelativeToRect:positioningRect ofView:positioningView preferredEdge:preferredEdge];
	
	self.colorPanel.color = _color;
	self.observingColor = YES;
}

// On pressing Esc, close the popover.
- (void)cancelOperation:(id)sender {
	[self close];
}

- (void)removeTargetAndAction {
	self.target = nil;
	self.action = nil;
}

- (void)deactivateColorWell {
	[self.colorWell deactivate];
	self.colorWell = nil;
}

- (void)closeAndDeactivateColorWell:(BOOL)deactivate removeTarget:(BOOL)removeTarget removeObserver:(BOOL)removeObserver {
	
	if (removeTarget) {
		[self removeTargetAndAction];
	}
	if (removeObserver) {
		self.observingColor = NO;
	}
	
	// For some strange reason I couldn't figure out, the panel changes it's color when closed.
	// To fix this, I reset the color after it's closed.
	NSColor *backupColor = self.colorPanel.color;
	[super close];
	self.colorPanel.color = backupColor;
	
	if (deactivate) {
		[self deactivateColorWell];
	}
}

- (void)close {
	[self closeAndDeactivateColorWell:YES removeTarget:YES removeObserver:YES];
}

- (BOOL)_delegatePopoverShouldClose:(id)sender {
	if ([super _delegatePopoverShouldClose:sender]) {
		[self removeTargetAndAction];
		self.observingColor = NO;
		[self deactivateColorWell];
		return YES;
	}
	return NO;
}

#pragma mark -
#pragma mark Observation

// Notify the target when the color changes.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (object == self.colorPanel && [keyPath isEqualToString:@"color"] && context == (__bridge void *)self) {
		_color = self.colorPanel.color;
		if (self.target && self.action && [self.target respondsToSelector:self.action]) {
      
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

			[self.target performSelector:self.action withObject:self];
      
#pragma clang diagnostic pop
		}
	}
}

@end
