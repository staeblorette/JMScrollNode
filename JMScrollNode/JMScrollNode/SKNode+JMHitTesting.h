//
//  SKNode+JMHitTesting.h
//  JMScrollNode
//
//  Created by Martin Stähler. on 26/05/2017.
//  Copyright © 2017 Martin Stähler. All rights reserved.
//


#import <SpriteKit/SpriteKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SKNode (JMHitTesting)

- (BOOL)hitTest:(CGPoint)point;

@property (nonatomic, assign) NSUInteger userInteractionLevel;

@end

NS_ASSUME_NONNULL_END
