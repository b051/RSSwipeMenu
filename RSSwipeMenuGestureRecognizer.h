//
//  RSSwipeMenuGestureRecognizer.h
//
//  Created by Rex Sheng on 8/6/12.
//  Copyright (c) 2012 lognllc.com. All rights reserved.
//

#import <UIKit/UIGestureRecognizerSubclass.h>


@interface RSSwipeMenuGestureRecognizer : UIPanGestureRecognizer

@property (nonatomic, weak, readonly) UITableViewCell *cell;
@property (nonatomic, strong) NSIndexPath *indexPath;

- (void)reset;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end