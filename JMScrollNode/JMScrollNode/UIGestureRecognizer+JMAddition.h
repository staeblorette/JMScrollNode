//
//  UIGestureRecognizer+JMAddition.h
//  JMScrollNode
//
//  Created by Martin Stähler. on 22/04/2017.
//  Copyright © 2017 Martin Stähler. All rights reserved.
//


#import <SpriteKit/SpriteKit.h>
#import <UIKit/UIKit.h>

@interface UIGestureRecognizer (JMAddition)

- (CGPoint)locationInNode:(SKNode *)node;

@end

@interface UIPanGestureRecognizer (JMPanAddition)

- (CGPoint)translationInNode:(SKNode *)node;

- (CGPoint)velocityInNode:(SKNode *)node;

@end
