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
#import "SKNode+JMHitTesting.h"

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
    
    // We added hitTesting to enable different gestureRecognizers to work together-
    // To distinguish wich node should receive a touch, we added the userInteraction level,
    // where nodes with a higher level will receive a touch before nodes with a lower level.
    // This should be combined with the drawing order in future releases.
    // If this doesn't work with your project, please adjust
    // the gestureRecognizerDelegate in JMScrollNode
    [scrollNode setUserInteractionLevel:0];
    
    // Enable Zooming
    [scrollNode setMinZoom:0.6];
    [scrollNode setMaxZoom:2.0];
    
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
