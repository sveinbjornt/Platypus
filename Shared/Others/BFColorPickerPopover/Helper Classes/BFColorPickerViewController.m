//
//  ColorPickerViewController.m
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

#import "BFColorPickerViewController.h"
#import "BFIconTabBar.h"
#import "NSColorWell+BFColorPickerPopover.h"
#import "BFColorPickerPopoverView.h"

#define kColorPickerViewControllerTabbarHeight 30.0f

@interface BFColorPickerViewController ()

@property (nonatomic) BFIconTabBar *tabbar;
@property (nonatomic, weak) NSView *colorPanelView;

@end


@implementation BFColorPickerViewController

- (void)loadView {
	CGFloat tabbarHeight = 34.0f;
	BFColorPickerPopoverView *view = [[BFColorPickerPopoverView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 250.0f, 400.0f)];
	self.view = view;
	
	// If the shared color panel is visible, close it, because we need to steal its views.
	if ([NSColorPanel sharedColorPanelExists] && [[NSColorPanel sharedColorPanel] isVisible]) {
		[[NSColorPanel sharedColorPanel] orderOut:self];
		[NSColorWell deactivateAll];
	}

	self.colorPanel = [NSColorPanel sharedColorPanel];
	self.colorPanel.showsAlpha = YES;
	
	// Steal the color panel's toolbar icons ...
	NSMutableArray *tabbarItems = [[NSMutableArray alloc] initWithCapacity:6];
	NSToolbar *toolbar = self.colorPanel.toolbar;
	NSUInteger selectedIndex = 0;
	for (NSUInteger i = 0; i < toolbar.items.count; i++) {
		NSToolbarItem *toolbarItem = toolbar.items[i];
		NSImage *image = toolbarItem.image;
		
		BFIconTabBarItem *tabbarItem = [[BFIconTabBarItem alloc] initWithIcon:image tooltip:toolbarItem.toolTip];
		[tabbarItems addObject:tabbarItem];
		
		if ([toolbarItem.itemIdentifier isEqualToString:toolbar.selectedItemIdentifier]) {
			selectedIndex = i;
		}
	}

	// ... and put them into a custom toolbar replica.
	self.tabbar = [[BFIconTabBar alloc] init];
	self.tabbar.delegate = self;
	self.tabbar.items = tabbarItems;
	self.tabbar.frame = CGRectMake(0.0f, view.bounds.size.height - tabbarHeight, view.bounds.size.width, tabbarHeight);
	self.tabbar.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
	[self.tabbar selectIndex:selectedIndex];
	[view addSubview:self.tabbar];
	
	// Add the color picker view.
	self.colorPanelView = self.colorPanel.contentView;
	self.colorPanelView.frame = CGRectMake(0.0f, 0.0f, view.bounds.size.width, view.bounds.size.height - tabbarHeight);
	self.colorPanelView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[view addSubview:self.colorPanelView];
	
	// Find and remove the color swatch resize dimple, because it crashes if used outside of a panel.
	NSArray *panelSubviews = [NSArray arrayWithArray:self.colorPanelView.subviews];
	for (NSView *subview in panelSubviews) {
		if ([subview isKindOfClass:NSClassFromString(@"NSColorPanelResizeDimple")]) {
			[subview removeFromSuperview];
		}
	}
}

// Forward the selection action message to the color panel.
- (void)tabBarChangedSelection:(BFIconTabBar *)tabbar {
  if (tabbar.selectedIndex != -1)
  {
    NSToolbarItem *selectedItem = self.colorPanel.toolbar.items[(NSUInteger)tabbar.selectedIndex];
    SEL action = selectedItem.action;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

    [self.colorPanel performSelector:action withObject:selectedItem];

#pragma clang diagnostic pop
  }
}



@end
