//
//  JMScrollNode.h
//  JMGomuko
//
//  Created by Martin S. on 20/04/2017.
//  Copyright © 2017 Martin. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol JMScrollNodeContent <NSObject>

@property (nonatomic, readonly) CGSize contentSize;

@end
@class JMScrollNode;
@protocol JMScrollNodeDelegate <NSObject>

@optional
// any offset changes
- (void)scrollNodeDidScroll:(JMScrollNode *)scrollNode;

// called on start of dragging (may require some time and or distance to move)
- (void)scrollNodeWillBeginDragging:(JMScrollNode *)scrollNode;

// called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
- (void)scrollNodeWillEndDragging:(JMScrollNode *)scrollNode withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset;

// called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
- (void)scrollNodeDidEndDragging:(JMScrollNode *)scrollNode willDecelerate:(BOOL)decelerate;

// called on finger up as we are moving
- (void)scrollNodeWillBeginDecelerating:(JMScrollNode *)scrollNode;

// called when scroll view grinds to a halt
- (void)scrollNodeDidEndDecelerating:(JMScrollNode *)scrollNode;

// called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
- (void)scrollNodeDidEndScrollingAnimation:(JMScrollNode *)scrollNode;

@end

// Informal scroll Node accessibility delegate
// TODO: Needs to be implemented
@protocol JMScrollNodeAccessibilityDelegate <JMScrollNodeDelegate>

- (NSString *)accessibilityScrollStatusForScrollNode:(JMScrollNode *)scrollNode;

@end



@interface JMScrollNode : SKNode

/**
 Creates a new scroll node and adds the content as a child. 
 */
- (instancetype)initWithView:(UIView *)view content:(nullable SKNode <JMScrollNodeContent> *)content NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readwrite, weak) id<JMScrollNodeDelegate> delegate;

@property (nonatomic, readonly , weak) SKNode <JMScrollNodeContent> *content;

#pragma mark - Animation

@property (nonatomic, readwrite, assign) CGPoint contentOffset;

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;

#pragma mark - 

/** 
 If the point (in the coordinates of the node) is at the edge of the visible area, depending on the distance to the edge,
 the scroll view moves to reveal this content.
 */
- (void)revealContentAtPoint:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END
