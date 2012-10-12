//
//  RSSwipeMenuTray.m
//
//  Created by Rex Sheng on 8/6/12.
//  Copyright (c) 2012 lognllc.com. All rights reserved.
//

#import "RSSwipeMenuTray.h"
#import "RSSwipeMenuGestureRecognizer.h"
#import <objc/runtime.h>

#define BASETAG 5120

#pragma marl - RSSwipeMenuTray
@implementation RSSwipeMenuTray
{
	UIView *holderView;
	CGFloat perWidth;
	CGFloat swipeDuration;
	UIImageView *background;
	NSMutableSet *reusableButtons;
	__unsafe_unretained UITableViewCell *_cell;
}

@synthesize indexPath=_indexPath;
@synthesize delegate;
@synthesize resetting;

- (id)initWithCell:(UITableViewCell *)cell
{
	CGRect frame = cell.frame;
	//	frame.origin.y -= 1;
	self = [super initWithFrame:frame];
	if (self) {
		_cell = cell;
		swipeDuration = .1f;
		reusableButtons = [NSMutableSet set];
		
		UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(reset)];
		[self addGestureRecognizer:swipe];
		UISwipeGestureRecognizer *swipe2 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(reset)];
		swipe2.direction = UISwipeGestureRecognizerDirectionLeft;
		[self addGestureRecognizer:swipe2];
	}
	return self;
}

- (UIButton *)dequeueReusableButton
{
	UIButton *button = [reusableButtons anyObject];
	if (button) [reusableButtons removeObject:button];
	return button;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
	if (!background) {
		background = [[UIImageView alloc] initWithFrame:self.bounds];
		background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self insertSubview:background atIndex:0];
	}
	background.image = backgroundImage;
}

- (void)layoutSubviews
{
	for (UIView *view in self.subviews) {
		if (view != background) {
			[reusableButtons addObject:view];
			[view removeFromSuperview];
		}
	}
	NSUInteger count = [self.delegate numberOfItemsInMenuTray:self];
	perWidth = self.bounds.size.width / count;
	for (NSUInteger i = 0; i < count; i++) {
		UIButton *button = [self dequeueReusableButton];
		button = [self.delegate menuTray:self buttonAtIndex:i reusableButton:button];
		button.tag = BASETAG + i;
		[button removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
		[button addTarget:self action:@selector(menuItemClicked:) forControlEvents:UIControlEventTouchUpInside];
		button.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
		[self addSubview:button];
	}
}

- (void)setButtonAtIndex:(NSUInteger)index disabled:(BOOL)disabled
{
	UIButton *button = (UIButton *)[self viewWithTag:index + BASETAG];
	if ([button respondsToSelector:@selector(setEnabled:)]) {
		[button setEnabled:!disabled];
	}
}

- (void)move:(CGFloat)offset
{
	CGRect frame = _cell.frame;
	frame.origin.x = MIN(0, offset + frame.origin.x); //only right unveil is allowed.
	_cell.frame = frame;
	if ([self.delegate respondsToSelector:@selector(menuTray:transformForButtonAtIndex:visibleWidth:)]) {
		CGFloat x = frame.origin.x;
		BOOL rightUnveiling = x < 0;
		if (rightUnveiling) x += frame.size.width;
		for (UIButton *button in self.subviews) {
			if ([button isKindOfClass:[UIButton class]]) {
				CGFloat left = button.frame.origin.x;
				CGFloat right = left + button.frame.size.width;
				if (x > left && x < right) {
					CGFloat visible;
					if (rightUnveiling) {
						visible = right - x;
					} else {
						visible = x - left;
					}
					CGAffineTransform transform = [self.delegate menuTray:self transformForButtonAtIndex:button.tag - BASETAG visibleWidth:visible];
					button.transform = transform;
				} else {
					button.transform = CGAffineTransformIdentity;
				}
			}
		}
	}
}

- (void)menuItemClicked:(UIButton *)sender
{
	sender.selected = YES;
	for (UIButton *button in self.subviews) {
		if (button != sender && [button isKindOfClass:[UIButton class]]) {
			button.selected = NO;
		}
	}
	if ([self.delegate respondsToSelector:@selector(menuTray:selectedButtonAtIndex:)]) {
		NSUInteger index = sender.tag - BASETAG;
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate menuTray:self selectedButtonAtIndex:index];
		});
	}
}

- (BOOL)makeDecision
{
	__block CGRect frame = _cell.frame;
	if (frame.origin.x < -perWidth) {
		for (UIView *view in self.subviews) {
			view.transform = CGAffineTransformIdentity;
		}
		[UIView animateWithDuration:swipeDuration animations:^{
			frame.origin.x = -frame.size.width;
			_cell.frame = frame;
		}];
	} else {
		if (!resetting) {
			[self reset];
			return NO;
		}
	}
	return YES;
}

- (void)reset
{
	[self resetAnimated:YES];
}

- (void)resetAnimated:(BOOL)animated
{
	if (resetting) {
		return;
	}
	resetting = YES;
	if (animated) {
		for (UIButton *button in self.subviews) {
			if ([button isKindOfClass:[UIButton class]]) {
				button.selected = NO;
			}
		}
		__block CGRect frame = _cell.frame;
		CGFloat bounceDistance = MIN(10, -frame.origin.x / 10);
		[UIView animateWithDuration:.3 animations:^{
			frame.origin.x = bounceDistance;
			_cell.frame = frame;
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:swipeDuration animations:^{
				frame.origin.x = 0;
				_cell.frame = frame;
			} completion:^(BOOL finished) {
				resetting = NO;
				[self removeFromSuperview];
			}];
		}];
	} else {
		CGRect frame = _cell.frame;
		frame.origin.x = 0;
		_cell.frame = frame;
		resetting = NO;
		[self removeFromSuperview];
	}
}

@end

#pragma mark - UITableView+RSSwipeMenu
@implementation UITableView (RSSwipeMenu)

static char kSwipeMenuInstanceCount;
static char kEnabledSwipeMenu;
static char kSwipeMenuDelegate;

- (RSSwipeMenuTray *)swipeMenuAtIndexPath:(NSIndexPath *)indexPath
{
	if (!indexPath) return nil;
	RSSwipeMenuTray *menu = nil;
	
	NSUInteger _instanceCount = self.swipeMenuInstanceCount;
	NSUInteger originCount = _instanceCount;
	for (RSSwipeMenuTray *mt in [self subviews]) {
		if ([mt isKindOfClass:[RSSwipeMenuTray class]]) {
			if (!menu && mt.indexPath == indexPath) {
				menu = mt;
			} else {
				if (!mt.resetting) {
					[mt resetAnimated:YES];
					_instanceCount--;
				}
			}
		}
	}
	
	if (!menu) {
		UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
		menu = [[RSSwipeMenuTray alloc] initWithCell:cell];
		menu.indexPath = indexPath;
		menu.delegate = objc_getAssociatedObject(self, &kSwipeMenuDelegate);
		if ([menu.delegate respondsToSelector:@selector(backgroundImageForMenuTray:)]) {
			[menu setBackgroundImage:[menu.delegate backgroundImageForMenuTray:menu]];
		}
		_instanceCount++;
		[self insertSubview:menu atIndex:0];
	}
	if (originCount != _instanceCount)
		self.swipeMenuInstanceCount = _instanceCount;
	return menu;
}

- (BOOL)swipeMenuEnabled
{
	return [objc_getAssociatedObject(self, &kEnabledSwipeMenu) boolValue];
}

- (void)setSwipeMenuEnabled:(BOOL)enabled
{
	objc_setAssociatedObject(self, &kEnabledSwipeMenu, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	for (UIGestureRecognizer *gr in self.gestureRecognizers) {
		if ([gr isKindOfClass:[RSSwipeMenuGestureRecognizer class]]) {
			[self removeGestureRecognizer:gr];
		}
	}
	if (enabled) {
		[self addGestureRecognizer:[[RSSwipeMenuGestureRecognizer alloc] initWithTarget:self action:@selector(_RS_swipeMenuPan:)]];
	}
	self.swipeMenuInstanceCount = 0;
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
	NSLog(@"set instanceCount = %d", count);
	objc_setAssociatedObject(self, &kSwipeMenuInstanceCount, @(count), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)closeAnySwipeMenuAnimated:(BOOL)animated
{
	if (self.swipeMenuInstanceCount) {
		for (RSSwipeMenuTray *mt in [self subviews]) {
			if ([mt isKindOfClass:[RSSwipeMenuTray class]]) {
				[mt resetAnimated:animated];
			}
		}
		self.swipeMenuInstanceCount = 0;
	}
}

- (void)_RS_swipeMenuPan:(RSSwipeMenuGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateFailed) {
		return [self closeAnySwipeMenuAnimated:YES];
	}
	RSSwipeMenuTray *menu = [self swipeMenuAtIndexPath:gesture.indexPath];
	if (gesture.state == UIGestureRecognizerStateChanged) {
		CGPoint translation = [gesture translationInView:gesture.cell];
		[menu move:translation.x];
		[gesture setTranslation:CGPointZero inView:gesture.cell];
	} else if (gesture.state == UIGestureRecognizerStateEnded) {
		if (![menu makeDecision]) {
			self.swipeMenuInstanceCount--;
		}
	} else if (gesture.state == UIGestureRecognizerStateCancelled) {
		if (menu) {
			if (!menu.resetting) {
				[menu resetAnimated:YES];
				self.swipeMenuInstanceCount--;
			}
		}
	}
}

@end
