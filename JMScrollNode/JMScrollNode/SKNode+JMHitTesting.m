//
//  SKNode+JMHitTesting.m
//  JMScrollNode
//
//  Created by Martin Stähler. on 26/05/2017.
//  Copyright © 2017 Martin Stähler. All rights reserved.
//


#import "SKNode+JMHitTesting.h"
#import <objc/runtime.h>

@interface JMUserInteractionLevelController : NSObject
@property (nonatomic, strong) NSHashTable <SKNode *> *enabledNodes;
@end

@implementation JMUserInteractionLevelController

+ (instancetype)sharedInstance
{
    static JMUserInteractionLevelController *sharedController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[JMUserInteractionLevelController alloc] init];
    });
    return sharedController;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _enabledNodes = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (NSArray <SKNode *> *)allEnabledNodes
{
    return [[self enabledNodes] allObjects];
}

@end

@implementation SKNode (JMHitTesting)

- (BOOL)hitTest:(CGPoint)point
{
    SKScene *scene = [self scene];
    NSArray<SKNode *> *levels = [SKNode userInteractionEnabledLevels];
    levels = [levels filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SKNode *obj1, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [obj1 scene] == scene;
    }]];
    levels = [levels sortedArrayUsingComparator:^NSComparisonResult(SKNode *obj1, SKNode *obj2) {
        NSInteger obj1Level = [obj1 userInteractionLevel];
        NSInteger obj2Level = [obj2 userInteractionLevel];
        if (obj1Level > obj2Level) {
            return NSOrderedAscending;
        } else if (obj1Level < obj2Level) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    for (SKNode *node in levels) {
        CGPoint transformed = [[node parent] convertPoint:point fromNode:[self parent]];
        if([node containsPoint:transformed]) {
            return node == self;
        }
    }
    
    return NO;
}

+ (NSArray<SKNode *> *)userInteractionEnabledLevels
{
    return [[[JMUserInteractionLevelController sharedInstance] enabledNodes] allObjects];
}

- (void)setUserInteractionLevel:(NSUInteger)userInteractionLevel
{
    [self setInternalUserInteractionLevel:userInteractionLevel];
    
    [[[JMUserInteractionLevelController sharedInstance] enabledNodes] addObject:self];
}

- (NSUInteger)userInteractionLevel
{
    return [[self internalUserInteractionLevel] unsignedIntegerValue];
}

#pragma mark - Storage

- (NSNumber *)internalUserInteractionLevel
{
    return objc_getAssociatedObject(self, @selector(internalUserInteractionLevel));
}

- (void)setInternalUserInteractionLevel:(NSUInteger)level
{
    objc_setAssociatedObject(self, @selector(internalUserInteractionLevel), @(level), OBJC_ASSOCIATION_RETAIN);
}

@end
