//
//  JMBoard.m
//  JMScrollNodeDemo
//
//  Created by Martin S. on 01/05/2017.
//  Copyright © 2017 juma. All rights reserved.
//

#import "JMBoard.h"

static NSUInteger const JMBoardSize = 30;
static CGFloat const JMBoardTileSize = 100;

@interface JMBoard ()
@property (nonatomic, weak) SKTileMapNode *background;
@end

@implementation JMBoard
@synthesize contentSize = _contentSize;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self createBackground];
        
        // We add 0.5*row top, bottom, left and right to the contentSize
        // So you can scroll one tile further than the board
        _contentSize = CGSizeMake((JMBoardSize + 1) * JMBoardTileSize, (JMBoardSize + 1) * JMBoardTileSize);
    }
    return self;
}

- (void)createBackground
{
    NSString *  boardTileSet;
    CGSize      boardTileSize;
    SKColor *   boardBackgroundColor;
    
    boardTileSet = @"DemoTileSet";
    boardTileSize = CGSizeMake(JMBoardTileSize, JMBoardTileSize);
    boardBackgroundColor = [UIColor lightGrayColor];
    
    SKTileSet *tileSet = [SKTileSet tileSetNamed:boardTileSet];
    SKTileMapNode *background = [[SKTileMapNode alloc] initWithTileSet:tileSet columns:JMBoardSize rows:JMBoardSize tileSize:boardTileSize];
    _background = background;
    [self addChild:background];
    
    [background fillWithTileGroup:[[tileSet tileGroups] firstObject]];
    [background setColor:boardBackgroundColor];
}

@end
