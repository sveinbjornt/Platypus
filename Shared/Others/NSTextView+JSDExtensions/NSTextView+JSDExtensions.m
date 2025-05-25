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

#import <objc/runtime.h>

#import "NSTextView+JSDExtensions.h"
#import "NoodleLineNumberView.h"


#pragma mark - Constants for associative references


// Can't define new iVars, but associated references help out.
// These constants will serve as keys. Values aren't important; only the pointer value is.

static char const * const JSDtagLine = "JSDtagLine";
static char const * const JSDtagColumn = "JSDtagColumn";
static char const * const JSDtagShowsHighlight = "JSDtagShowsHighlight";
static char const * const JSDtagWordwrapsText = "JSDtagWordwrapsText";
static char const * const JSDtagShowsLineNumbers = "JSDtagShowsLineNumbers";


#pragma mark - Implementation


@implementation NSTextView (JSDExtensions)


#pragma mark - HIGHLIGHT property accessors and mutators


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	highlitLine
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSInteger)highlitLine
{
	NSNumber *item = objc_getAssociatedObject(self, JSDtagLine);

	if (item != nil)
	{
		return [item integerValue];

	}
	else
	{
		return 0;
	}
}

- (void)setHighlitLine:(NSInteger)line
{
	objc_setAssociatedObject(self, JSDtagLine, @(line), OBJC_ASSOCIATION_COPY_NONATOMIC);
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	highlitColumn
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSInteger)highlitColumn
{
	NSNumber *item = objc_getAssociatedObject(self, JSDtagColumn);

	if (item != nil)
	{
		return [item integerValue];

	}
	else
	{
		return 0;
	}
}

- (void)setHighlitColumn:(NSInteger)column
{
	objc_setAssociatedObject(self, JSDtagColumn, @(column), OBJC_ASSOCIATION_COPY_NONATOMIC);
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	ShowsHighlight
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)ShowsHighlight
{
	NSNumber *item = objc_getAssociatedObject(self, JSDtagShowsHighlight);

	if (item != nil)
	{
		return [item boolValue];

	}
	else
	{
		return NO;
	}
}

- (void)setShowsHighlight:(BOOL)state
{
	// Remember the new setting
	objc_setAssociatedObject(self, JSDtagShowsHighlight, @(state), OBJC_ASSOCIATION_COPY_NONATOMIC);

	if (!state)
	{
		// Remove current highlighting from entire contents
		[[self layoutManager] removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, [[self textStorage] length])];
	}
	else
	{
		// Setup the variables we need for the loop
		NSRange aRange;								// a range for counting lines
		NSRange lineCharRange;						// a range for counting lines
		NSUInteger i = 0;							// glyph counter
		NSUInteger j = 1;							// line counter
		NSUInteger k;								// column counter
		NSLayoutManager *lm = [self layoutManager];	// get layout manager.
		NSInteger litLine = [self highlitLine];		// get the line to light.
		NSInteger litColumn = [self highlitColumn];	// Get the column to light.

		// Remove any existing coloring.
		[lm removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, [[self textStorage] length])];

		// Only highlight if there's a row to highlight.
		if (litLine >= 1)
		{
			// The line number counting loop
			while ( i < [lm numberOfGlyphs] )
			{
				// Retrieve the rect |r| and range |aRange| for the current line.
				[lm lineFragmentRectForGlyphAtIndex:i effectiveRange:&aRange];

				// If the current line is what we're looking for, then highlight it
				if (j == litLine)
				{
					k = [lm characterIndexForGlyphAtIndex:i] + litColumn - 1;						// Column position

					lineCharRange = [lm characterRangeForGlyphRange:aRange actualGlyphRange:NULL];	// Whole row range

					// Color them
					[lm addTemporaryAttributes:@{NSBackgroundColorAttributeName: [NSColor secondarySelectedControlColor]} forCharacterRange:lineCharRange];
					[lm addTemporaryAttributes:@{NSBackgroundColorAttributeName: [NSColor selectedTextBackgroundColor]} forCharacterRange:NSMakeRange(k, 1)];
				}

				i += [[[self string] substringWithRange:aRange] length];							// Advance glyph counter to EOL
				j ++;
			}
		}
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	scrollLineToVisible:
		Scrolls the display to a specific line.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)scrollLineToVisible:(NSInteger)line
{
	// setup the variables we need for the loop
	NSRange aRange;								// Range for counting lines
	NSInteger i = 0;							// Glyph counter
	NSInteger j = 1; 							// Line counter
	NSLayoutManager *lm = [self layoutManager];	// Layout manager
	
	if (line >= 1)
	{
		// The line number counting loop
		while ( i < [lm numberOfGlyphs] )
		{
			// Retrieve the rect |r| and range |aRange| for the current line.
			[lm lineFragmentRectForGlyphAtIndex:i effectiveRange:&aRange];

			// If the current line is what we're looking for, then scroll to it.
			if (j == line)
			{
				[self scrollRangeToVisible:aRange];
			}

			i += [[[self string] substringWithRange:aRange] length];	// Advance glyph counter to EOL
			j ++;														// Increment the line number
		}
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	highlightLine:
		Sets |highlitLine|, |highlitColumn|, and |highlit| in
		one go, as well as scrolls that line into view.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)highlightLine:(NSInteger)line Column:(NSInteger)column
{
	[self setHighlitLine:line];
	[self setHighlitColumn:column];
	[self setShowsHighlight:YES];
	[self scrollLineToVisible:line];
}


#pragma mark - WORDWRAP property accessors and mutators


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	WordwrapsText
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)WordwrapsText
{
	NSNumber *item = objc_getAssociatedObject(self, JSDtagWordwrapsText);

	if (item != nil)
	{
		return [item boolValue];

	}
	else
	{
		return YES;
	}
}

- (void)setWordwrapsText:(BOOL)state
{

	// Get current state
	BOOL currentState = [self WordwrapsText];

	if (state != currentState)
	{
		// Remember the new setting
		objc_setAssociatedObject(self, JSDtagWordwrapsText, @(state), OBJC_ASSOCIATION_COPY_NONATOMIC);

		if (!state)
		{
			NSSize layoutSize = NSMakeSize(FLT_MAX, FLT_MAX);

			[[self enclosingScrollView] setHasHorizontalScroller:YES];
			[self setHorizontallyResizable:YES];
			[self setMaxSize:layoutSize];
			[[self textContainer] setContainerSize:layoutSize];
			[[self textContainer] setWidthTracksTextView:NO];

		}
		else
		{

			NSSize layoutSize = NSMakeSize([[self enclosingScrollView] contentSize].width , FLT_MAX);

			[[self enclosingScrollView] setHasHorizontalScroller:NO];
			[[self textContainer] setContainerSize:layoutSize];
			[[self textContainer] setWidthTracksTextView:YES];
		}

		// Tickle the view to force ruler resisplay.
		if ([self ShowsLineNumbers])
		{
			[[[self enclosingScrollView] verticalRulerView] setNeedsDisplay:YES];
		}
	}
}


#pragma mark - LINE NUMBER property accessors and mutators


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	ShowsLineNumbers
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)ShowsLineNumbers
{
	id item = objc_getAssociatedObject(self, JSDtagShowsLineNumbers);

	if (item != nil)
	{
		return YES;

	}
	else
	{
		return NO;
	}
}

- (void)setShowsLineNumbers:(BOOL)state
{

	// Get current state
	BOOL currentState = [self ShowsLineNumbers];

	if (state != currentState)
	{
		// Remember the new setting
		objc_setAssociatedObject(self, JSDtagShowsLineNumbers, @(state), OBJC_ASSOCIATION_COPY_NONATOMIC);

		if (!state)
		{
			[[self enclosingScrollView] setHasHorizontalRuler:NO];
			[[self enclosingScrollView] setHasVerticalRuler:NO];
			[[self enclosingScrollView] setRulersVisible:NO];
			[[self enclosingScrollView] setVerticalRulerView:nil];
			objc_setAssociatedObject(self, JSDtagShowsLineNumbers, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

		}
		else
		{
			#if !__has_feature(objc_arc)
				NoodleLineNumberView *lineNumberView = [[[NoodleLineNumberView alloc] initWithScrollView:[self enclosingScrollView]] autorelease];
			#else
				NoodleLineNumberView *lineNumberView = [[NoodleLineNumberView alloc] initWithScrollView:[self enclosingScrollView]];
			#endif

			[[self enclosingScrollView] setVerticalRulerView:lineNumberView];
			[[self enclosingScrollView] setHasHorizontalRuler:NO];
			[[self enclosingScrollView] setHasVerticalRuler:YES];
			[[self enclosingScrollView] setRulersVisible:YES];
			objc_setAssociatedObject(self, JSDtagShowsLineNumbers, lineNumberView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		}
	}
}


@end
