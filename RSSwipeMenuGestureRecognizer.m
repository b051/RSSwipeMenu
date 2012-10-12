//
//  RSSwipeMenuGestureRecognizer.m
//
//  Created by Rex Sheng on 8/6/12.
//  Copyright (c) 2012 lognllc.com. All rights reserved.
//

#import "RSSwipeMenuGestureRecognizer.h"

@implementation RSSwipeMenuGestureRecognizer

@synthesize indexPath=_indexPath;
@synthesize cell=_cell;

- (id) initWithTarget:(id)target action:(SEL)action
{
	if ((self = [super initWithTarget:target action:action])) {
		self.maximumNumberOfTouches = 1;
	}
	return self;
}

- (void)reset
{
	[super reset];
	self.indexPath = nil;
	_cell = nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesMoved:touches withEvent:event];
	if (self.state == UIGestureRecognizerStateFailed || _indexPath) return;
	UITableView *tableView = (UITableView *)self.view;
	[tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:NO];
	CGPoint curr = [[touches anyObject] locationInView:tableView];
	CGPoint prev = [[touches anyObject] previousLocationInView:tableView];
	CGFloat horizontalWin = prev.x - curr.x - ABS(curr.y - prev.y);
	if (horizontalWin > 0) {
		_indexPath = [tableView indexPathForRowAtPoint:curr];
		_cell = nil;
		for (UITableViewCell *cell in [tableView visibleCells]) {
			if (CGRectContainsPoint(cell.frame, curr)) {
				_cell = cell;
				break;
			}
		}
		if (_cell == nil) {
			self.state = UIGestureRecognizerStateFailed;
			return;
		}
		_cell.selected = NO;
	} else {
		self.state = UIGestureRecognizerStateFailed;
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event];
	self.state = UIGestureRecognizerStateEnded;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesCancelled:touches withEvent:event];
	self.state = UIGestureRecognizerStateCancelled;
}

@end
