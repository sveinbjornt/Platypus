//
//  NSFileManager+TempFile.h
//  Platypus
//
//  Created by Sveinbjorn Thordarson on 14/06/15.
//  Copyright (c) 2015 Sveinbjorn Thordarson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (TempFile)
- (NSString *)createTempFileWithContents:(NSString *)contentStr usingTextEncoding:(NSStringEncoding)textEncoding;
@end
