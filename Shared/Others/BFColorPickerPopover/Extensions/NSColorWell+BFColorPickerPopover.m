//
//  NSColorWell+ColorPickerPopover.m
//  ColorPickerPopover
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

#import "NSColorWell+BFColorPickerPopover.h"
#import "NSColorPanel+BFColorPickerPopover.h"
#import "BFColorPickerPopover.h"

static NSColorWell *hiddenWell = nil;

@implementation NSColorWell (BFColorPickerPopover)

+ (void)deactivateAll {
	[[NSColorPanel sharedColorPanel] disablePanel];
	hiddenWell = [[NSColorWell alloc] init];
	hiddenWell.color = [NSColor colorWithCalibratedRed:1/255.0 green:2/255.0 blue:3/255.0 alpha:1];
	[hiddenWell activate:YES];
	[hiddenWell deactivate];
	[[NSColorPanel sharedColorPanel] enablePanel];
}

+ (NSColorWell *)hiddenWell {
	return hiddenWell;
}

- (void)_performActivationClickWithShiftDown:(BOOL)shift {
	if (!self.isActive) {
		BFColorPickerPopover *popover = [BFColorPickerPopover sharedPopover];
		if (popover.isShown) {
			BOOL animatesBackup = popover.animates;
			popover.animates = NO;
			[popover close];
			popover.animates = animatesBackup;
		}
		[BFColorPickerPopover sharedPopover].target = nil;
		[BFColorPickerPopover sharedPopover].action = NULL;
		[self activate:!shift];
	} else {
		[self deactivate];
	}
}

@end
