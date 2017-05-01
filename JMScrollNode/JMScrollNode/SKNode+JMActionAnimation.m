//
//  SKNode+JMActionAnimation.m
//  JMGomuko
//
//  Created by Martin S. on 25/04/2017.
//  Copyright © 2017 Martin. All rights reserved.
//

#import "SKNode+JMActionAnimation.h"
#import <libkern/osatomic.h>

@interface JMActionProxy : NSObject

/**
 Parent is strong by design, refrence cycle is broken by using a weak hash table.
 Thus, an action-proxy lives as long as it has children that keep a strong refrence.
 */
@property (nonatomic, strong) JMActionProxy *parent;
@property (nonatomic, strong) NSHashTable <JMActionProxy *> *children;

@property (nonatomic, assign) NSInteger waitOnComplete;
@property (nonatomic, assign) BOOL didFinishAll;

@property (nonatomic, assign) SKActionTimingMode mode;
@property (nonatomic, assign) NSTimeInterval duration;

@property (nonatomic, copy) void (^completion)(BOOL finished);
@end

@implementation JMActionProxy

- (instancetype)init
{
    self = [super init];
    if (self) {
        _children = [NSHashTable weakObjectsHashTable];
        _didFinishAll = YES;
        _waitOnComplete = 0;
    }
    return self;
}

- (void)addChild:(JMActionProxy *)child
{
    [[self children] addObject:child];
    [child setParent:self];
}

/**
 Called when one action or animation completes
 */
- (void)complete:(BOOL)finished
{
    if (!finished && self.waitOnComplete > 0) {
        [self setDidFinishAll:NO];
    }
    
    // Maybe use dispatch groups, but since we are only on the main this might not be worth the effort.
    if ((-- self.waitOnComplete) == 0) {
        
        [self onComplete];
        
        [[self parent] complete:[self didFinishAll]];
    }
}

/**
 Called when all child-actions and animations completed
 */
- (void)onComplete
{
    if ([self completion]) {
        [self completion]([self didFinishAll]);
    }
}

/**
 When no action or sub
 */
- (void)dealloc
{
    if ([self waitOnComplete] > 0) {
        [self setDidFinishAll:NO];
        
        [self onComplete];
    }
}

@end

static void *JMActionAnimationActionProxyKey = "JMActionAnimationActionProxyKey";

@implementation SKNode (JMActionAnimation)

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations
{
    [self animateWithDuration:duration animations:animations completion:NULL];
}

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(nonnull void (^)(void))animations completion:(void (^ _Nullable)(BOOL finished))completion
{
    [self animateWithDuration:duration mode:SKActionTimingLinear animations:animations completion:completion];
}

+ (void)animateWithDuration:(NSTimeInterval)duration mode:(SKActionTimingMode)mode animations:(void (^)(void))animations
{
    [self animateWithDuration:duration mode:mode animations:animations completion:NULL];
}

+ (void)animateWithDuration:(NSTimeInterval)duration mode:(SKActionTimingMode)mode animations:(void (^)(void))animations completion:(void (^_Nullable )(BOOL finished))completion
{
    NSAssert([NSThread isMainThread], @"Only call on main thread");
    
    JMActionProxy *parent = [self actionProxy];
    
    JMActionProxy *action = [[JMActionProxy alloc] init];
    // TODO: Add overwrite semantic to options(Allow for opt out, aka UIViewAnimationOptionOverrideInheritedCurve)
    [action setDuration:parent ? parent.duration : duration];
    [action setMode:parent ? parent.mode : mode];
    
    [parent addChild:action];
    
    // Increment expectation count of parent
    parent.waitOnComplete ++;
    
    [action setCompletion:completion];
    
    dispatch_queue_set_specific(dispatch_get_main_queue(), JMActionAnimationActionProxyKey, (__bridge void * _Nullable)(action), NULL);
    
    animations();
    
    dispatch_queue_set_specific(dispatch_get_main_queue(), JMActionAnimationActionProxyKey, (__bridge void * _Nullable)(parent), NULL);
}


+ (JMActionProxy *)actionProxy
{
    return (__bridge JMActionProxy *)(dispatch_queue_get_specific(dispatch_get_main_queue(), JMActionAnimationActionProxyKey));
}

static NSString *const JMAnimatedActionKey = @"JMAnimatedActionKey";
- (void)animateAction:(SKAction *)action
{
    [self animateAction:action forKey:JMAnimatedActionKey];
}

- (void)animateAction:(SKAction *)action forKey:(NSString *)key
{
    JMActionProxy *actionProxy = [SKNode actionProxy];

    if (actionProxy) {
        [action setDuration:[actionProxy duration]];
        [action setTimingMode:[actionProxy mode]];
    }
    
    actionProxy.waitOnComplete ++;
    
    // In case the action is cancelled, we depend on the weak refrencing of the action proxy to eventually call complete on dealloc.
    // This isn't ideal yet.
    SKAction *notify = [SKAction runBlock:^{
        [actionProxy complete:YES];
    }];
    
    SKAction *sequence = [SKAction sequence:@[action, notify]];
    [self runAction:sequence withKey:key];
}


@end
