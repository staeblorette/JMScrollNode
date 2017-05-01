//
//  UIGestureRecognizer+JMAddition.m
//  JMGomuko
//
//  Created by Martin S. on 22/04/2017.
//  Copyright © 2017 Martin. All rights reserved.
//

#import "UIGestureRecognizer+JMAddition.h"

@implementation UIGestureRecognizer (JMAddition)

- (CGPoint)locationInNode:(SKNode *)node
{
    SKView *view;
    SKScene *scene;
    
    scene = [node scene];
    view = [scene view];

    NSAssert(scene, @"Node must be in the scene");
    NSAssert(view, @"Node must be in a scene that is in a view");
    
    CGPoint location;
    location = [self locationInView:view];
    location = [scene convertPointFromView:location];
    location = [node convertPoint:location fromNode:scene];
    return location;
}

@end

@implementation UIPanGestureRecognizer (JMPanAddition)

- (CGPoint)convertRelativeViewPoint:(CGPoint)point inNode:(SKNode *)node
{
    SKView *view;
    SKScene *scene;
    
    scene = [node scene];
    view = [scene view];
    
    NSAssert(scene, @"Node must be in the scene");
    NSAssert(view, @"Node must be in a scene that is in a view");
    
    CGPoint end;
    end = point;
    end = [scene convertPointFromView:end];
    end = [node convertPoint:end fromNode:scene];
    
    CGPoint start;
    start = [view convertPoint:CGPointZero fromView:self.view];
    start = [scene convertPointFromView:start];
    start = [node convertPoint:start fromNode:scene];
    return CGPointMake(end.x - start.x, end.y - start.y);
}

- (CGPoint)translationInNode:(SKNode *)node
{
    return [self convertRelativeViewPoint:[self translationInView:[self view]] inNode:node];
}

- (CGPoint)velocityInNode:(SKNode *)node
{
    return [self convertRelativeViewPoint:[self velocityInView:[self view]] inNode:node];
}

@end

