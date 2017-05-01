//
//  SKNode+JMActionAnimation.h
//  JMGomuko
//
//  Created by Martin S. on 25/04/2017.
//  Copyright © 2017 Martin. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 All functions that are of type -set...:animated: should be able to use the action proxy to run custom action durations/timing functions, and so on.
 The function can be stacked!
 Hower you should not rely on a invocation of the completionBlock, since the action might be removed when removeAllAction on a node was called.
 Generally all actions perform
 */
@interface SKNode (JMActionAnimation)

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(nonnull void (^)(void))animations completion:(void (^ _Nullable)(BOOL finished))completion;

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(nonnull void (^)(void))animations;

+ (void)animateWithDuration:(NSTimeInterval)duration mode:(SKActionTimingMode)mode animations:(nonnull void (^)(void))animations completion:(void (^ _Nullable)(BOOL finished))completion;

+ (void)animateWithDuration:(NSTimeInterval)duration mode:(SKActionTimingMode)mode animations:(nonnull void (^)(void))animations;


/**
 The method that specifies animate shall use this function to schedule the action.
 */
- (void)animateAction:(SKAction *)action;
- (void)animateAction:(SKAction *)action forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END


