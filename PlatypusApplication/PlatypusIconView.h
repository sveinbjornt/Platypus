//
//  PlatypusIconView.h
//  Platypus
//
//  Created by Sveinbjorn Thordarson on 8/28/10.
//  Copyright 2010 Sveinbjorn Thordarson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IconFamily.h"
#import "Common.h"

@interface PlatypusIconView : NSImageView 
{
	id delegate;
	NSEvent *downEvent;
}
-(void)setDelegate: (id)theDelegate;
-(id)delegate;
@end
