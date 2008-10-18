/* Copyright © 2007-2008 The Sequential Project. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal with the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:
1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimers.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimers in the
   documentation and/or other materials provided with the distribution.
3. Neither the name of The Sequential Project nor the names of its
   contributors may be used to endorse or promote products derived from
   this Software without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
THE CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS WITH THE SOFTWARE. */
#import "PGColumnView.h"

// Views
#import "PGClipView.h"

@implementation PGColumnView

#pragma mark Instance Methods

- (NSArray *)views
{
	return [[_views copy] autorelease];
}
- (id)lastView
{
	return [_views lastObject];
}
- (id)viewAtIndex:(unsigned)index
{
	return [_views objectAtIndex:index];
}

#pragma mark -

- (void)addColumnWithView:(NSView *)aView
{
	[self insertColumnWithView:aView atIndex:[_views count]];
	[self scrollToLastColumn];
}
- (void)insertColumnWithView:(NSView *)aView
        atIndex:(unsigned)index
{
	NSParameterAssert(aView);
	NSParameterAssert([_views indexOfObjectIdenticalTo:aView] == NSNotFound);
	PGClipView *const clip = [[[PGClipView alloc] init] autorelease];
	[_clipViews insertObject:clip atIndex:index];
	[_views insertObject:aView atIndex:index];
	[_view addSubview:clip];
	[clip setDelegate:self];
	[clip setBackgroundColor:nil];
	[clip setShowsBorder:NO];
	[clip setDocumentView:aView];
	[self layout];
	[aView setFrameSize:NSMakeSize(NSWidth([clip bounds]), NSHeight([aView frame]))];
	[aView setAutoresizingMask:NSViewWidthSizable];
	[self scrollToTopOfColumnWithView:aView];
}
- (void)removeColumnWithView:(NSView *)aView
{
	NSParameterAssert(aView);
	unsigned const i = [_views indexOfObjectIdenticalTo:aView];
	NSParameterAssert(NSNotFound != i);
	(void)[[aView retain] autorelease];
	PGClipView *const clip = [_clipViews objectAtIndex:i];
	[clip setDocumentView:nil];
	[clip removeFromSuperview];
	[_clipViews removeObjectAtIndex:i];
	[_views removeObjectAtIndex:i];
	[self layout];
}
- (void)removeColumnsAfterView:(NSView *)aView
{
	unsigned const i = [_views indexOfObject:aView];
	NSParameterAssert(NSNotFound != i);
	while([_views count] > i + 1) {
		PGClipView *const clip = [_clipViews lastObject];
		[clip setDocumentView:nil];
		[clip removeFromSuperview];
		[_clipViews removeLastObject];
		[_views removeLastObject];
	}
	[self layout];
}
- (void)removeAllColumns
{
	[_clipViews makeObjectsPerformSelector:@selector(setDocumentView:) withObject:nil];
	[_clipViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[_clipViews removeAllObjects];
	[_views removeAllObjects];
	[self layout];
}

#pragma mark -

- (float)columnWidth
{
	return _columnWidth;
}
- (void)setColumnWidth:(float)width
{
	_columnWidth = roundf(width);
	[self layout];
}

#pragma mark -

- (void)scrollToTopOfColumnWithView:(NSView *)aView
{
	[[_clipViews objectAtIndex:[_views indexOfObjectIdenticalTo:aView]]  scrollToEdge:PGMaxYEdgeMask animation:PGAllowAnimation];
}
- (void)scrollToLastColumn
{
	[_clipView scrollToEdge:PGMaxXEdgeMask animation:PGPreferAnimation];
}

#pragma mark -

- (void)layout
{
	NSRect const b = [self bounds];
	[_view setFrameSize:NSMakeSize(MAX(_columnWidth * [_views count] - 1, NSWidth(b)), NSHeight(b))];
	NSRect const vb = [_view bounds];
	unsigned i = 0;
	unsigned const count = [_clipViews count];
	for(; i < count; i++) [[_clipViews objectAtIndex:i] setFrame:NSMakeRect(NSMinX(vb) + _columnWidth * i, NSMinY(vb), _columnWidth - 1, NSHeight(vb))];
	[self setNeedsDisplay:YES];
}

#pragma mark PGClipViewDelegate Protocol

- (BOOL)clipView:(PGClipView *)sender
        handleMouseEvent:(NSEvent *)anEvent
        first:(BOOL)flag
{
	unsigned const i = [_clipViews indexOfObjectIdenticalTo:sender];
	if(NSNotFound == i) return NO;
	[[_views objectAtIndex:i] mouseDown:anEvent];
	return YES;
}

#pragma mark NSView

- (id)initWithFrame:(NSRect)aRect
{
	if((self = [super initWithFrame:aRect])) {
		_clipView = [[PGClipView alloc] initWithFrame:[self bounds]];
		[_clipView setBackgroundColor:nil];
		[_clipView setShowsBorder:NO];
		[_clipView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[_clipView setPinLocation:PGMinXEdgeMask];
		[self addSubview:_clipView];
		_view = [[NSView alloc] initWithFrame:NSZeroRect];
		[_clipView setDocumentView:_view];
		_clipViews = [[NSMutableArray alloc] init];
		_views = [[NSMutableArray alloc] init];
		_columnWidth = (96 + 12) * 3 + 1;
	}
	return self;
}
- (void)drawRect:(NSRect)aRect
{
	[[NSColor colorWithDeviceWhite:(48.0f / 255.0f) alpha:0.75f] set];
	NSRectFill(aRect);
	NSRect const vb = [_view bounds];
	[[NSColor whiteColor] set];
	unsigned i = 0;
	unsigned const count = [_clipViews count];
	[[NSColor colorWithDeviceWhite:0.95 alpha:0.9] set];
	for(; i < count; i++) NSFrameRect([_view convertRect:NSMakeRect(NSMinX(vb) + _columnWidth * (i + 1) - 1, NSMinY(vb), 1, NSHeight(vb)) toView:self]);
}
- (void)setFrameSize:(NSSize)aSize
{
	[super setFrameSize:aSize];
	[self layout];
}

#pragma mark NSObject

- (id)init
{
	return [self initWithFrame:NSZeroRect];
}
- (void)dealloc
{
	[_clipView release];
	[_view release];
	[_clipViews release];
	[_views release];
	[super dealloc];
}

@end