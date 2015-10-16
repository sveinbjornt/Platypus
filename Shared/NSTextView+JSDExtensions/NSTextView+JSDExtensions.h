/**************************************************************************************************

	NSTextView+JSDExtensions.h

	Some nice extensions to NSTextView

	These extensions will add some features to any NSTextView

		o Highlight a logical line number and column in the text view.
		o Turn word-wrapping on and off.
		o Own and instantiate its own NoodleLineNumberView.
			- note dependency on JanX2’s fork of Noodlekit: <https://github.com/JanX2/NoodleKit>


	The MIT License (MIT)

	Copyright (c) 2001 to 2013 James S. Derry <http://www.balthisar.com>

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 **************************************************************************************************/

#import <Cocoa/Cocoa.h>

@interface NSTextView (JSDExtensions)

	@property (nonatomic) NSInteger highlitLine;				// Highlight this row number (0 for none).
	
	@property (nonatomic) NSInteger highlitColumn;				// Highlight this column of the row (0 for none).
	
	@property (nonatomic) BOOL ShowsHighlight;					// Sets/Indicates the current highlight state.

	@property (nonatomic) BOOL WordwrapsText;					// Sets/Indicates the current wordwrap state.

	@property (nonatomic) BOOL ShowsLineNumbers;				// Sets/Indicates whether or not line numbers appear.


- (void)scrollLineToVisible:(NSInteger)line;					// Ensures that a logical line is visible in the view.

- (void)highlightLine:(NSInteger)line Column:(NSInteger)column;	// As above, including scrolling into view.

@end
