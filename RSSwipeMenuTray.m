//
//  RSSwipeMenuTray.m
//
//  Created by Rex Sheng on 8/6/12.
//  Copyright (c) 2012 lognllc.com. All rights reserved.
//

#import "RSSwipeMenuTray.h"
#import "RSSwipeMenuGestureRecognizer.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface RSSwipeMenuTray ()
@property (nonatomic) CGFloat moveOffsetX;
@property (nonatomic) CGFloat perWidth;
@end

#pragma mark - UITableView+RSSwipeMenu
@implementation UITableView (RSSwipeMenu)

#pragma mark - properties
static char kSwipeMenuInstanceCount;
static char kEnabledSwipeMenu;
static char kSwipeMenuDelegate;
static char kReusableMenuSet;

- (NSMutableSet *)reusableMenu
{
	return objc_getAssociatedObject(self, &kReusableMenuSet);
}

- (BOOL)swipeMenuEnabled
{
	return [objc_getAssociatedObject(self, &kEnabledSwipeMenu) boolValue];
}

- (void)setSwipeMenuEnabled:(BOOL)enabled
{
	if (self.swipeMenuEnabled != enabled) {
		objc_setAssociatedObject(self, &kEnabledSwipeMenu, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		for (UIGestureRecognizer *gr in self.gestureRecognizers) {
			if ([gr isKindOfClass:[RSSwipeMenuGestureRecognizer class]]) {
				[self closeAnySwipeMenuAnimated:NO];
				[self removeGestureRecognizer:gr];
			}
		}
		objc_setAssociatedObject(self, &kReusableMenuSet, nil, OBJC_ASSOCIATION_ASSIGN);
		if (enabled) {
			objc_setAssociatedObject(self, &kReusableMenuSet, [NSMutableSet setWithCapacity:2], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
			[self addGestureRecognizer:[[RSSwipeMenuGestureRecognizer alloc] initWithTarget:self action:@selector(_RS_swipeMenuPan:)]];
		}
		self.swipeMenuInstanceCount = 0;
	}
}

- (id<RSSwipeMenuTrayDelegate>)swipeMenuDelegate
{
	return objc_getAssociatedObject(self, &kSwipeMenuDelegate);
}

- (void)setSwipeMenuDelegate:(id<RSSwipeMenuTrayDelegate>)delegate
{
	objc_setAssociatedObject(self, &kSwipeMenuDelegate, delegate, OBJC_ASSOCIATION_ASSIGN);
}

- (NSUInteger)swipeMenuInstanceCount
{
	return [objc_getAssociatedObject(self, &kSwipeMenuInstanceCount) unsignedIntegerValue];
}

- (void)setSwipeMenuInstanceCount:(NSUInteger)count
{
	objc_setAssociatedObject(self, &kSwipeMenuInstanceCount, @(count), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (RSSwipeMenuTray *)dequeueReusableSwipeMenu
{
	RSSwipeMenuTray *menu = [self.reusableMenu anyObject];
	if (menu) {
		[self.reusableMenu removeObject:menu];
	}
	return menu;
}

- (void)enqueueReusableSwipeMenu:(RSSwipeMenuTray *)menu
{
	if (menu) {
		[self.reusableMenu addObject:menu];
		self.swipeMenuInstanceCount--;
	}
}

- (RSSwipeMenuTray *)currentSwipeMenuAtIndexPath:(NSIndexPath *)indexPath
{
	RSSwipeMenuTray *menu = nil;
	
	for (RSSwipeMenuTray *mt in [self subviews]) {
		if ([mt isKindOfClass:[RSSwipeMenuTray class]]) {
			if (!menu && [mt.indexPath isEqual:indexPath]) {
				menu = mt;
			} else {
				[mt resetAnimated:YES];
			}
		}
	}
	return menu;
}

- (void)closeAnySwipeMenuAnimated:(BOOL)animated
{
	if (self.swipeMenuInstanceCount) {
		for (RSSwipeMenuTray *mt in [self subviews]) {
			if ([mt isKindOfClass:[RSSwipeMenuTray class]]) {
				[mt resetAnimated:animated];
			}
		}
	}
}

- (void)_RS_swipeMenuPan:(RSSwipeMenuGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateFailed) {
		return [self closeAnySwipeMenuAnimated:YES];
	}
	RSSwipeMenuTray *menu = [self currentSwipeMenuAtIndexPath:gesture.indexPath];
	
	if (gesture.state == UIGestureRecognizerStateChanged) {
		CGPoint translation = [gesture translationInView:gesture.cell];
		if (!menu) {
			menu = [self dequeueReusableSwipeMenu];
			if (!menu) {
				menu = [[RSSwipeMenuTray alloc] initWithDelegate:objc_getAssociatedObject(self, &kSwipeMenuDelegate)];
			}
			UITableViewCell *cell = [self cellForRowAtIndexPath:gesture.indexPath];
			menu.indexPath = gesture.indexPath;
			menu.cell = cell;
			[self insertSubview:menu atIndex:0];
			
			[menu move:translation.x];
			if (menu.moveOffsetX) {
				self.swipeMenuInstanceCount++;
			} else {
				[self.reusableMenu addObject:menu];
				[menu removeFromSuperview];
			}
		} else {
			[menu move:translation.x];
		}
		[gesture setTranslation:CGPointZero inView:gesture.cell];
	} else if (gesture.state == UIGestureRecognizerStateEnded) {
		[menu makeDecision:[gesture velocityInView:self]];
	} else if (gesture.state == UIGestureRecognizerStateCancelled) {
		if (menu) {
			[menu resetAnimated:YES];
		}
	}
}

@end


#pragma mark - RSSwipeMenuTray
@implementation RSSwipeMenuTray
{
	UIView *holderView;
	NSMutableSet *reusableButtons;
	NSUInteger disabledMask;
	NSMutableArray *buttons;
	UIImageView *backgroundView;
}

- (id)initWithDelegate:(id<RSSwipeMenuTrayDelegate>)delegate
{
	if (self = [super initWithFrame:CGRectMake(0, 0, 320, 44)]) {
		_delegate = delegate;
		_swipeDuration = .1f;
		reusableButtons = [NSMutableSet set];
		_disabledAlpha = .5;
		_maxOffset = 1.f;
		_minOffset = -1.f;
		_edgeInsets = UIEdgeInsetsZero;
		UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(reset)];
		[self addGestureRecognizer:swipe];
		UISwipeGestureRecognizer *swipe2 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(reset)];
		swipe2.direction = UISwipeGestureRecognizerDirectionLeft;
		[self addGestureRecognizer:swipe2];
		[self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuItemClicked:)]];
		buttons = [@[] mutableCopy];
	}
	return self;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
	_backgroundImage = backgroundImage;
	if (!backgroundView) {
		backgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
		backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self insertSubview:backgroundView atIndex:0];
	}
	[backgroundView setImage:backgroundImage];
}

- (void)setCell:(UITableViewCell *)cell
{
	_cell = cell;
	CGRect frame = cell.frame;
	frame.size.width = cell.superview.bounds.size.width;
	self.frame = UIEdgeInsetsInsetRect(frame, _edgeInsets);
	[self layoutItems];
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
{
	_edgeInsets = edgeInsets;
	CGRect frame = _cell.frame;
	frame.size.width = _cell.superview.bounds.size.width;
	self.frame = UIEdgeInsetsInsetRect(frame, edgeInsets);
	[self layoutItems];
}

- (void)setMargin:(CGFloat)margin
{
	_margin = margin;
	[self layoutItems];
}

- (void)setMinOffset:(CGFloat)minOffset
{
	_minOffset = minOffset;
	[self layoutItems];
}

- (UIView *)dequeueReusableButton
{
	UIView *button = [reusableButtons anyObject];
	if (button) [reusableButtons removeObject:button];
	return button;
}

- (void)layoutItems
{
	for (UIView *view in buttons) {
		[reusableButtons addObject:view];
		[view removeFromSuperview];
	}
	[buttons removeAllObjects];
	NSUInteger count = [self.delegate numberOfItemsInMenuTray:self];
	CGFloat totalWidth = -_minOffset * self.bounds.size.width;
	self.perWidth = (totalWidth - 2 * _margin) / count;
	CGFloat height = self.bounds.size.height;
	for (NSUInteger i = 0; i < count; i++) {
		UIView *button = [self dequeueReusableButton];
		button = [self.delegate menuTray:self buttonAtIndex:i reusableButton:button];
		button.autoresizingMask = UIViewAutoresizingNone;
		button.transform = CGAffineTransformIdentity;
		[button sizeToFit];
		CGRect frame = button.frame;
		frame.origin.x = _margin + i * _perWidth + self.bounds.size.width - totalWidth;
		frame.size.width = _perWidth;
		frame.origin.y = (height - frame.size.height) / 2;
		button.frame = frame;
		
		[buttons addObject:button];
		[self addSubview:button];
	}
	self.moveOffsetX = 0;
}

- (void)setButtonAtIndex:(NSUInteger)index disabled:(BOOL)disabled
{
	UIView *button = buttons[index];
	button.alpha = disabled ? _disabledAlpha : 1;
	if (disabled) {
		disabledMask |= 1 << disabled;
	} else {
		disabledMask &= ~(1 << disabled);
	}
}

- (void)move:(CGFloat)offset
{
	self.moveOffsetX = MAX(_minOffset * self.bounds.size.width, MIN(_maxOffset * self.bounds.size.width, offset + _moveOffsetX));
	if (self.moveOffsetX && [self.delegate respondsToSelector:@selector(menuTray:transformForButtonAtIndex:visibleWidth:)]) {
		CGRect frame = _cell.frame;
		CGFloat x = _moveOffsetX;
		BOOL rightUnveiling = x < 0;
		if (rightUnveiling) x += frame.size.width;
		NSUInteger idx = floorf((x - _margin) / _perWidth);
		if (idx >= buttons.count) return;
		CGFloat visible;
		if (rightUnveiling) {
			visible = (idx + 1) *_perWidth + _margin - x;
		} else {
			visible = x - idx *_perWidth - _margin;
		}
		UIView *view = buttons[idx];
		for (int i = idx + 1; i < buttons.count; i++) {
			UIView *v = buttons[i];
			if (!CGAffineTransformEqualToTransform(v.transform, CGAffineTransformIdentity)) {
				[UIView animateWithDuration:.25 animations:^{
					v.transform = CGAffineTransformIdentity;
				}];
			}
		}
		view.transform = [self.delegate menuTray:self transformForButtonAtIndex:idx visibleWidth:visible];
	}
}

- (void)menuItemClicked:(UITapGestureRecognizer *)tap
{
	CGFloat totalWidth = (1 + _minOffset) * self.bounds.size.width;
	CGFloat x = [tap locationInView:self].x - totalWidth - _margin;
	NSUInteger idx = MIN(buttons.count, floorf(x /_perWidth));
	if ((disabledMask | (1 << idx)) == disabledMask) {
		return;
	}
	int i = 0;
	for (UIView *button in buttons) {
		if ([button respondsToSelector:@selector(setHighlighted:)]) {
			objc_msgSend(button, @selector(setHighlighted:), idx == i);
		}
		i++;
	}
	if ([self.delegate respondsToSelector:@selector(menuTray:selectedButtonAtIndex:)]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate menuTray:self selectedButtonAtIndex:idx];
		});
	}
}

- (void)makeDecision
{
	[self makeDecision:CGPointZero];
}

- (void)setMoveOffsetX:(CGFloat)moveOffsetX
{
	CGRect frame = _cell.frame;
	frame.origin.x = _moveOffsetX = moveOffsetX;
	if ([self.delegate respondsToSelector:@selector(menuTray:cellFrame:)]) {
		_cell.frame = [self.delegate menuTray:self cellFrame:frame];
	} else {
		_cell.frame = frame;
	}
}

- (void)makeDecision:(CGPoint)velocity
{
	CGFloat moved = _moveOffsetX;
	moved += velocity.x * _swipeDuration;
	
	if (-moved > _perWidth + _margin) {
		for (UIView *view in self.subviews) {
			view.transform = CGAffineTransformIdentity;
		}
		[UIView animateWithDuration:_swipeDuration animations:^{
			self.moveOffsetX = MAX(_minOffset, -1.0f) * self.bounds.size.width;
		}];
	} else {
		[self resetAnimated:YES];
	}
}

- (void)reset
{
	[self resetAnimated:YES];
}

- (void)RS_removeFromSuperview
{
	if (self.superview) {
		if ([self.superview respondsToSelector:@selector(enqueueReusableSwipeMenu:)]) {
			[(id)self.superview enqueueReusableSwipeMenu:self];
		}
		[self removeFromSuperview];
	}
}

- (void)resetAnimated:(BOOL)animated
{
	if (_resetting) {
		return;
	}
	_resetting = YES;
	if (animated) {
		for (UIView *button in buttons) {
			if ([button respondsToSelector:@selector(setHighlighted:)]) {
				objc_msgSend(button, @selector(setHighlighted:), NO);
			}
		}
		__block CGRect frame = _cell.frame;
		CGFloat bounceDistance = MIN(10, -frame.origin.x / 10);
		[UIView animateWithDuration:.3 animations:^{
			frame.origin.x = bounceDistance;
			_cell.frame = frame;
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:_swipeDuration animations:^{
				self.moveOffsetX = 0;
			} completion:^(BOOL finished) {
				_resetting = NO;
				[self RS_removeFromSuperview];
			}];
		}];
	} else {
		self.moveOffsetX = 0;
		_resetting = NO;
		[self RS_removeFromSuperview];
	}
}

@end