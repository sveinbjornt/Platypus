//
//  IconTabBar.h
//  CocosGame
//
//  Created by Balázs Faludi on 20.05.12.
//  Copyright (c) 2012 Universität Basel. All rights reserved.
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

#import <Cocoa/Cocoa.h>

@class BFIconTabBarItem;
@class BFIconTabBar;

@protocol BFIconTabBarDelegate <NSObject>

- (void)tabBarChangedSelection:(BFIconTabBar *)tabbar;

@end


@interface BFIconTabBar : NSControl

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic) CGFloat itemWidth;
@property (nonatomic) BOOL multipleSelection;
@property (nonatomic, unsafe_unretained) IBOutlet id<BFIconTabBarDelegate> delegate;

- (BFIconTabBarItem *)selectedItem;
- (NSInteger)selectedIndex;
- (NSArray *)selectedItems;
- (NSIndexSet *)selectedIndexes;

- (IBAction)selectAll;
- (void)selectIndex:(NSUInteger)index;
- (void)selectItem:(BFIconTabBarItem *)item;
- (void)selectIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extending;

- (IBAction)deselectAll;
- (void)deselectIndex:(NSUInteger)index;
- (void)deselectIndexes:(NSIndexSet *)indexes;

@end


@interface BFIconTabBarItem : NSObject

@property (nonatomic, strong) NSImage *icon;
@property (nonatomic, copy) NSString *tooltip;
@property (nonatomic, unsafe_unretained) BFIconTabBar *tabBar;

- (id)initWithIcon:(NSImage *)image tooltip:(NSString *)tooltipString;
+ (BFIconTabBarItem *)itemWithIcon:(NSImage *)image tooltip:(NSString *)tooltipString;

@end
