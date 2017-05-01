//
//  ViewController.m
//  JMScrollNodeDemo
//
//  Created by Martin S. on 01/05/2017.
//  Copyright © 2017 juma. All rights reserved.
//

#import "ViewController.h"
#import <SpriteKit/SpriteKit.h>
#import "JMScrollNode.h"
#import "JMBoard.h"

@interface ViewController () <JMScrollNodeDelegate>
@property (nonatomic, weak) IBOutlet SKView *sceneView;
@property (nonatomic, weak) JMBoard *board;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    SKView *view = [self sceneView];
    
    [view setShowsDrawCount:YES];
    [view setShowsFPS:YES];
    [view setShowsFields:YES];
    [view setShowsNodeCount:YES];
    [view setShowsQuadCount:YES];
    
    // Create Scene
    SKScene *scene = [SKScene sceneWithSize:CGSizeMake(view.bounds.size.width, view.bounds.size.height)];
    [scene setBackgroundColor:[UIColor lightGrayColor]];
    [scene setAnchorPoint:CGPointMake(0.5, 0.5)];
    [view presentScene:scene];
    
    // Create Background
    JMBoard *board = [[JMBoard alloc] init];
    [self setBoard:board];
    
    // Create ScrollNode
    JMScrollNode *scrollNode = [[JMScrollNode alloc] initWithView:view content:board];
    [scene addChild:scrollNode];
    [scrollNode setDelegate:self];
}

#pragma mark - <JMScrollNodeDelegate>

- (void)scrollNodeDidEndScrollingAnimation:(JMScrollNode *)scrollNode
{
    NSLog(@"ANIMATE END");
}

- (void)scrollNodeWillBeginDragging:(JMScrollNode *)scrollNode
{
    NSLog(@"BEGIN DRAGGING");
}

- (void)scrollNodeDidEndDragging:(JMScrollNode *)scrollNode willDecelerate:(BOOL)decelerate
{
    NSLog(@"END DRAGGING %@", @(decelerate));
}

- (void)scrollNodeDidScroll:(JMScrollNode *)scrollNode
{
    NSLog(@"DID SCROLL");
}

- (void)scrollNodeWillBeginDecelerating:(JMScrollNode *)scrollNode
{
    NSLog(@"WILL DECELERATE");
}

- (void)scrollNodeDidEndDecelerating:(JMScrollNode *)scrollNode
{
    NSLog(@"DID DECELERATE");
}

@end
