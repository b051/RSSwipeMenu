//
//  RSSwipeMenuTray.h
//
//  Created by Rex Sheng on 8/6/12.
//  Copyright (c) 2012 lognllc.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RSSwipeMenuTray;
@protocol RSSwipeMenuTrayDelegate <NSObject>

- (NSUInteger)numberOfItemsInMenuTray:(RSSwipeMenuTray *)menuTray;
- (UIView *)menuTray:(RSSwipeMenuTray *)menuTray buttonAtIndex:(NSUInteger)index reusableButton:(UIView *)view;

@optional
- (void)menuTray:(RSSwipeMenuTray *)menuTray selectedButtonAtIndex:(NSUInteger)index;
- (CGAffineTransform)menuTray:(RSSwipeMenuTray *)menuTray transformForButtonAtIndex:(NSUInteger)index visibleWidth:(CGFloat)visible;
@end

@interface RSSwipeMenuTray : UIView

@property (nonatomic, readonly) BOOL resetting;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, unsafe_unretained) UITableViewCell *cell;
@property (nonatomic) CGFloat margin UI_APPEARANCE_SELECTOR;

@property (nonatomic, unsafe_unretained) id<RSSwipeMenuTrayDelegate> delegate;

@property (nonatomic) UIImage *backgroundImage UI_APPEARANCE_SELECTOR;
@property (nonatomic) CGFloat disabledAlpha UI_APPEARANCE_SELECTOR;
@property (nonatomic) CGFloat swipeDuration UI_APPEARANCE_SELECTOR;
@property (nonatomic) CGFloat minOffset UI_APPEARANCE_SELECTOR;
@property (nonatomic) CGFloat maxOffset UI_APPEARANCE_SELECTOR;

- (id)initWithDelegate:(id<RSSwipeMenuTrayDelegate>)_delegate;
- (void)move:(CGFloat)x;
- (void)makeDecision __deprecated;
- (void)makeDecision:(CGPoint)velocity;
- (void)resetAnimated:(BOOL)animated;
- (void)setButtonAtIndex:(NSUInteger)index disabled:(BOOL)disabled;
@end

@interface UITableView (RSSwipeMenu)

- (NSUInteger)swipeMenuInstanceCount;
- (BOOL)swipeMenuEnabled;
- (void)setSwipeMenuEnabled:(BOOL)enabled;
- (void)setSwipeMenuDelegate:(id<RSSwipeMenuTrayDelegate>)delegate;
- (void)closeAnySwipeMenuAnimated:(BOOL)animated;

@end