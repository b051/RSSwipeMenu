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
- (UIButton *)menuTray:(RSSwipeMenuTray *)menuTray buttonAtIndex:(NSUInteger)index reusableButton:(UIButton *)view;
@optional
- (UIImage *)backgroundImageForMenuTray:(RSSwipeMenuTray *)menuTray;
@optional
- (void)menuTray:(RSSwipeMenuTray *)menuTray selectedButtonAtIndex:(NSUInteger)index;
@optional
- (CGAffineTransform)menuTray:(RSSwipeMenuTray *)menuTray transformForButtonAtIndex:(NSUInteger)index visibleWidth:(CGFloat)visible;
@end

@interface RSSwipeMenuTray : UIView

@property (nonatomic, readonly) BOOL resetting;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, unsafe_unretained) id<RSSwipeMenuTrayDelegate> delegate;

- (id)initWithCell:(UITableViewCell *)cell;
- (void)move:(CGFloat)x;
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