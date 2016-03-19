//
//  NSColorPanel+ColorPickerPopover.m
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

#import "NSColorPanel+BFColorPickerPopover.h"
#import "BFColorPickerPopover.h"

#include <tgmath.h>

static BOOL colorPanelEnabled = YES;

@interface BFColorPickerPopover ()
@property (nonatomic) NSColorPanel *colorPanel;
@end

@implementation NSColorPanel (BFColorPickerPopover)

- (void)disablePanel {
	colorPanelEnabled = NO;
}

- (void)enablePanel {
	colorPanelEnabled = YES;
}

- (void)orderFront:(id)sender {
	if (colorPanelEnabled) {
		NSColorPanel *panel = [BFColorPickerPopover sharedPopover].colorPanel;
		if (panel) {
			self.contentView = panel.contentView;
		}
		[super orderFront:sender];
	} else {
		// Don't do anything.
	}
}

+ (NSString *)color {
	NSColorPanel *panel = [NSColorPanel sharedColorPanel];
	NSColor *color = [panel color];
	return [NSString stringWithFormat:@"r: %d, g: %d, b: %d, a: %d",
			(int)round([color redComponent]*255),
			(int)round([color greenComponent]*255),
			(int)round([color blueComponent]*255),
			(int)round([color alphaComponent]*255)];
}

@end
