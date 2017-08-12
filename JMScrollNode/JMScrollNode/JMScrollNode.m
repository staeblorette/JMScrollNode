//
//  JMScrollNode.m
//  JMScrollNode
//
//  Created by Martin Stähler. on 20/04/2017.
//  Copyright © 2017 Martin Stähler. All rights reserved.
//

#import "JMScrollNode.h"
#import "UIGestureRecognizer+JMAddition.h"
#import "SKNode+JMActionAnimation.h"
#import "SKNode+JMHitTesting.h"

@interface JMScrollNode () <UIGestureRecognizerDelegate>
@property (nonatomic, weak) UIView *view;
@property (nonatomic, weak) SKNode <JMScrollNodeContent> *content;

@property (nonatomic, weak) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, weak) UIPinchGestureRecognizer *pinchGestureRecognizer;

@property (nonatomic, assign) CGPoint contentPositionStart;
@property (nonatomic, assign) CGPoint previousTranslation;
@property (nonatomic, assign) CGFloat maxHorizontalTranslationLeft;
@property (nonatomic, assign) CGFloat maxHorizontalTranslationRight;
@property (nonatomic, assign) CGFloat maxVerticalTranslationTop;
@property (nonatomic, assign) CGFloat maxVerticalTranslationBottom;

@property (nonatomic, assign) CGFloat contentScaleStart;
@property (nonatomic, assign) CGFloat contentScale;

@property (nonatomic, weak) SKAction *runningAction;

@end

@implementation JMScrollNode

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    // TODO: To implement coding, remove the dependency on view. The view is simply the target for the gesture recognizer, so replace each self.view with self.gestureRecognizer.view
    // Handle the case where the gesutre recognizer hasn't been added to a view
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Coding not yet implementd" userInfo:nil];
    
    return [self initWithView:nil content:nil];
}

- (instancetype)initWithView:(UIView *)view content:(SKNode <JMScrollNodeContent>*)content
{
    self = [super init];
    if (self) {
        _maxZoom = 1.0f;
        _minZoom = 1.0f;
        _zoom = 1.0f;
        _view = view;
        _content = content;
        [self addChild:content];
        
        [self createGestureRecognizer];
    }
    return self;
}

#pragma mark - GestureRecognizers

- (void)createGestureRecognizer
{
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [panGestureRecognizer setDelegate:self];
    [panGestureRecognizer setCancelsTouchesInView:NO];
    [[self view] addGestureRecognizer:panGestureRecognizer];
    [self setPanGestureRecognizer:panGestureRecognizer];
    
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(didPinch:)];
    [pinchGestureRecognizer setDelegate:self];
    [pinchGestureRecognizer setDelaysTouchesBegan:YES];
    [pinchGestureRecognizer setCancelsTouchesInView:NO];
    [[self view] addGestureRecognizer:pinchGestureRecognizer];
    [self setPinchGestureRecognizer:pinchGestureRecognizer];
}

#pragma mark - Zooming

- (void)didPinch:(UIPinchGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        // We will always use xScale
        [self setContentScaleStart:[[self content] xScale]];
        [self setContentPositionStart:[[self content] position]];
    }
    
    CGFloat newScale = [self contentScaleStart] * [gestureRecognizer scale];
    if (newScale > [self maxZoom])
        return;
    if (newScale < [self minZoom])
        return;
    
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        [self setZoom:newScale];
        [self calculateMaxBounceTranslation];
        
        CGPoint adjustment = [self calculateTranslationFromTranslation:CGPointZero];
        CGPoint contentPosition = [self contentPositionStart];
        contentPosition.x += adjustment.x;
        contentPosition.y += adjustment.y;
        
        self.contentPositionStart = contentPosition;
        CGPoint position = CGPointMake(self.contentPositionStart.x * gestureRecognizer.scale, self.contentPositionStart.y * gestureRecognizer.scale);
        
        [[self content] setPosition:position];
    }
}

- (void)setZoom:(CGFloat)zoom
{
    [self setZoom:zoom animated:NO];
}

static NSTimeInterval const JMScrollNodeZoomAnimationDuration = 0.2f;
static NSString *     const JMScrollNodeZoomAnimationKey = @"JMScrollNodeZoomAnimationKey";
- (void)setZoom:(CGFloat)zoom animated:(BOOL)animated
{
    _zoom = zoom;
    if (animated) {
        [SKNode animateWithDuration:JMScrollNodeZoomAnimationDuration
                         animations:^{
                             SKAction *action = [SKAction scaleTo:zoom
                                                         duration:JMScrollNodeAnimationDuration];
                             [action setTimingFunction:^(float x){return sqrtf(x);}];
                             [[self content] animateAction:action forKey:JMScrollNodeZoomAnimationKey];}
         ];
    } else {
        [[self content] removeActionForKey:JMScrollNodeZoomAnimationKey];
        [[self content] setScale:zoom];
    }
}


#pragma mark - Panning

static NSTimeInterval const JMScrollNodeBounceRelaxTime = 0.2f;
- (void)didPan:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self scrollNodeWillBeginDragging];

        [self setContentPositionStart:[[self content] position]];
        [self setContentOffset:[[self content] position]];
        [self calculateMaxBounceTranslation];
        return;
    }
    CGPoint translation = [self calculateTranslationFromTranslation:[[self panGestureRecognizer] translationInNode:self]];
    CGPoint velocity = CGPointZero;
    
    NSTimeInterval decelerationDuration = 0;
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // Calculate translations to move back to on end.
        BOOL outsideBounds = NO;
        velocity = [[self panGestureRecognizer] velocityInNode:self];
        decelerationDuration = [self decelerationTimeForVelocity:velocity];
        CGPoint decelerationDelta = [self decelarationDelta:velocity duration:decelerationDuration];
        translation = CGPointMake(translation.x + decelerationDelta.x, translation.y + decelerationDelta.y);

        if (translation.x > self.maxHorizontalTranslationLeft) {
            outsideBounds = YES;
            translation.x = self.maxHorizontalTranslationLeft;
        }
        if (translation.x < self.maxHorizontalTranslationRight) {
            outsideBounds = YES;
            translation.x = self.maxHorizontalTranslationRight;
        }
        if (translation.y < self.maxVerticalTranslationTop) {
            outsideBounds = YES;
            translation.y = self.maxVerticalTranslationTop;
        }
        if (translation.y > self.maxVerticalTranslationBottom) {
            outsideBounds = YES;
            translation.y = self.maxVerticalTranslationBottom;
        }
        if (outsideBounds) {
            velocity = CGPointZero;
            decelerationDuration = JMScrollNodeBounceRelaxTime;
        }
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
        velocity = CGPointZero;
    }
    
    CGPoint newPosition = CGPointMake([self contentPositionStart].x + translation.x, [self contentPositionStart].y + translation.y);
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        [self setContentOffset:newPosition animated:NO];
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint endPosition = newPosition;
        
        [self scrollNodeWillEndDraggingWithVelocity:velocity targetContentOffset:&endPosition];
        
        // In case the delegate updated, or velocity is not equal 0 we animate
        BOOL decelerating = !CGPointEqualToPoint(newPosition, endPosition) || !CGPointEqualToPoint(velocity, CGPointZero);
        [self scrollNodeDidEndDraggingWillDecelerate:decelerating];
        
        if(decelerating)
            [self scrollNodeWillBeginDecelerating];
        
        [SKNode animateWithDuration:decelerationDuration
                               mode:SKActionTimingEaseOut
                         animations:^{ [self setContentOffset:newPosition animated:YES]; }
                         completion:^(BOOL finished){ if (decelerating) [self scrollNodeDidEndDecelerating]; }];
    }
}

#pragma mark - Translation Constraints

// Calculates for what translations the left,right,top,bottom edge of the content is dragged into the visible screen.
// Here the "visible screen" is the uiview.
// This might be improved upon
- (void)calculateMaxBounceTranslation
{
    // In Laymans term:
    // We convert the top/bottom point of the UIView into the coordinates of the content.
    // However this calculates with the zoom (which we don't want).
    // What the transform in the content coordinate system does, is give the point of the screnn edges
    // while incorporating the position of the content.
    // The distance of the content (and hence the max translation) must be independent of the zoom.
    // The contentSize is however depedependet on the zoom and shrinks with it.
    // The maximum translation for each direction is then the contentSize * zoom - convertedPoint
    CGSize viewSize = self.view.bounds.size;
    CGSize contentSize = self.content.contentSize;
    contentSize = CGSizeMake(contentSize.width * [self zoom], contentSize.height * [self zoom]);
    CGPoint leftView = CGPointZero;
    CGPoint rightView = CGPointMake(viewSize.width, viewSize.height);
    CGPoint leftPoint = [self.scene convertPointFromView:leftView];
    leftPoint = [self.content convertPoint:leftPoint fromNode:self.scene];
    
    CGPoint rightPoint = [self.scene convertPointFromView:rightView];
    rightPoint = [self.content convertPoint:rightPoint fromNode:self.scene];
    
    CGFloat maxXL =  contentSize.width / 2  + leftPoint.x  * [self zoom];
    self.maxHorizontalTranslationLeft = maxXL;
    
    CGFloat maxXR =  - contentSize.width / 2 + rightPoint.x  * [self zoom];
    self.maxHorizontalTranslationRight = maxXR;
    
    CGFloat maxYL =  - contentSize.height / 2 + leftPoint.y * [self zoom];
    self.maxVerticalTranslationTop = maxYL;
    
    CGFloat maxYR = contentSize.height / 2 + rightPoint.y  * [self zoom];
    self.maxVerticalTranslationBottom = maxYR;
    
    if (contentSize.width < viewSize.width) {
        self.maxHorizontalTranslationLeft = 0;
        self.maxHorizontalTranslationRight = 0;
    }
    if (contentSize.height < viewSize.height) {
        self.maxVerticalTranslationTop = 0;
        self.maxVerticalTranslationBottom = 0;
    }
}

static CGFloat const JMScrollNodeBounceDropOff = 40.0f;
- (CGPoint)calculateTranslationFromTranslation:(CGPoint)translation
{
    CGFloat dropOff = JMScrollNodeBounceDropOff;
    CGSize contentSize = self.content.contentSize;
    CGSize viewSize = self.view.bounds.size;
    
    CGFloat bounceX = contentSize.width > viewSize.width ? 1.0 : 0;
    CGFloat bounceY = contentSize.height > viewSize.height ? 1.0 : 0;

    if (translation.x > self.maxHorizontalTranslationLeft) {
        CGFloat delta = translation.x - self.maxHorizontalTranslationLeft;
        translation.x = self.maxHorizontalTranslationLeft + [self bounceWithDropOff:dropOff delta:delta] * bounceX;
    }
    if (translation.x < self.maxHorizontalTranslationRight) {
        CGFloat delta = self.maxHorizontalTranslationRight - translation.x;
        translation.x = self.maxHorizontalTranslationRight - [self bounceWithDropOff:dropOff delta:delta] * bounceX;
    }
    if (translation.y < self.maxVerticalTranslationTop) {
        CGFloat delta = self.maxVerticalTranslationTop - translation.y;
        translation.y = self.maxVerticalTranslationTop - [self bounceWithDropOff:dropOff delta:delta] * bounceY;
    }
    if (translation.y > self.maxVerticalTranslationBottom) {
        CGFloat delta = translation.y - self.maxVerticalTranslationBottom;
        translation.y = self.maxVerticalTranslationBottom + [self bounceWithDropOff:dropOff delta:delta] * bounceY;
    }
    
    return translation;
}

#pragma mark - Content Offset

- (void)setContentOffset:(CGPoint)contentOffset
{
    [self setContentOffset:contentOffset animated:NO];
}

static NSTimeInterval const JMScrollNodeAnimationDuration = 0.2f;
static NSString *     const JMScrollNodeAnimationKey = @"JMScrollNodeAnimationKey";
- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated
{
    NSLog(@"%@", NSStringFromCGPoint(contentOffset));
    _contentOffset = contentOffset;

    if (animated) {
        [SKNode animateWithDuration:JMScrollNodeAnimationDuration
                         animations:^{
                             SKAction *action = [SKAction moveTo:contentOffset duration:JMScrollNodeAnimationDuration];
                             [action setTimingFunction:^(float x){return sqrtf(x);}];
                             [[self content] animateAction:action forKey:JMScrollNodeAnimationKey];}
                         completion:^(BOOL finished){
                             [self scrollNodeDidEndScrollingAnimation];
                         }];
    } else {
        [[self content] removeActionForKey:JMScrollNodeAnimationKey];
        [[self content] setPosition:contentOffset];
    }
    
    // Notifiy Delegate
    [self scrollNodeDidScroll];
}

#pragma mark - <UIGestureRecognizerDelegate>

// I handle touch with gesture recognizers, even on other SKNodes.
// Implement other UIGestureRecognizer if you need to finetune if the drag should begin
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer
{
    if (otherGestureRecognizer != [self pinchGestureRecognizer] && otherGestureRecognizer != [self panGestureRecognizer]) {
        return YES;
    }
    if (gestureRecognizer == [self pinchGestureRecognizer] || gestureRecognizer == [self panGestureRecognizer]) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint touchLocation = [touch locationInNode:[self parent]];
    return [self hitTest:touchLocation];
}

#pragma mark - Dynamics
/**
 * The following dynamic after touch ended is proposed, where
 * v_0: Velocity at start of deceleration
 * x_0: Translation at start of deceleration
 * g  : constant deceleration
 * With constant deceleration g, this gives
 * (I)  v(t) = v_0 - gt
 * (II) x(t) = x_0 + v_0t - 1/2 gt^2
 * The time t_e to stop must then be v_0 / g ( from (I) )
 * The delta distance to stop is then v_0t_e - 1/2 v_0^2 /g = v_0 / (2g)
 */
static CGFloat const JMScrollNodeDecelartion = 18000;
- (NSTimeInterval)decelerationTimeForVelocity:(CGPoint)velocity
{
    CGFloat lengthValue = sqrtf(velocity.x * velocity.x + velocity.y * velocity.y);
    return MAX(MIN(lengthValue / JMScrollNodeDecelartion, 1.0f),0.2);
}

- (CGPoint)decelarationDelta:(CGPoint)velocity duration:(NSTimeInterval)duration
{
    CGFloat multiplier = (CGFloat)duration / 2.0f;
    return CGPointMake(velocity.x * multiplier, velocity.y * multiplier);
}

/**
 Calculate the dropoff in translation for an input value in one dimension
 */
- (CGFloat)bounceWithDropOff:(CGFloat)dropOff delta:(CGFloat)delta
{
    return (dropOff - dropOff * exp(-(delta) / dropOff)) * [self zoom];
}

#pragma mark - ConentReveal

static CGFloat const JMScrollNodeContentRevealEdgeInset = 40;
static CGFloat const JMScrollNodeContentRevealDropoff = 6.0;
- (void)revealContentAtPoint:(CGPoint)point
{
    CGPoint viewPoint;
    viewPoint = [[self scene] convertPoint:point fromNode:self];
    viewPoint = [[self scene] convertPointToView:viewPoint];
    viewPoint = [[self view] convertPoint:viewPoint fromView:[[self scene] view]];
    
    CGRect bounds = self.view.bounds;
    CGFloat inset = JMScrollNodeContentRevealEdgeInset;
    UIEdgeInsets insets = UIEdgeInsetsMake(inset, inset, inset, inset);
    bounds = UIEdgeInsetsInsetRect(bounds, insets);
    
    BOOL shouldReveal = !CGRectContainsPoint(bounds, viewPoint);
    
    if (!shouldReveal) {
        return;
    }
    
    CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    CGPoint vector = CGPointMake(viewPoint.x - center.x, - viewPoint.y + center.y);
    
    CGPoint currentOffset = [self contentOffset];
    [self setContentPositionStart:currentOffset];
    [self calculateMaxBounceTranslation];

    CGFloat dropoff = JMScrollNodeContentRevealDropoff;
    CGPoint translation = [self calculateTranslationFromTranslation:CGPointMake(- vector.x / bounds.size.width * dropoff,- vector.y / bounds.size.height * dropoff)];
    [self setContentOffset:CGPointMake(translation.x + currentOffset.x,translation.y + currentOffset.y)];
}

#pragma mark - Delegate Notifcation

- (void)scrollNodeDidScroll
{
    if ([[self delegate] respondsToSelector:@selector(scrollNodeDidScroll:)]) {
        [[self delegate] scrollNodeDidScroll:self];
    }
}

- (void)scrollNodeWillBeginDragging
{
    if ([[self delegate] respondsToSelector:@selector(scrollNodeWillBeginDragging:)]) {
        [[self delegate] scrollNodeWillBeginDragging:self];
    }
}

- (void)scrollNodeWillEndDraggingWithVelocity:(CGPoint)velocity
                          targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if ([[self delegate] respondsToSelector:@selector(scrollNodeWillEndDragging:withVelocity:targetContentOffset:)]) {
        [[self delegate] scrollNodeWillEndDragging:self withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

- (void)scrollNodeDidEndDraggingWillDecelerate:(BOOL)decelerate
{
    if ([[self delegate] respondsToSelector:@selector(scrollNodeDidEndDragging:willDecelerate:)]) {
        [[self delegate] scrollNodeDidEndDragging:self willDecelerate:decelerate];
    }
}

- (void)scrollNodeWillBeginDecelerating
{
    if ([[self delegate] respondsToSelector:@selector(scrollNodeWillBeginDecelerating:)]) {
        [[self delegate] scrollNodeWillBeginDecelerating:self];
    }
}

- (void)scrollNodeDidEndDecelerating
{
    if ([[self delegate] respondsToSelector:@selector(scrollNodeDidEndDecelerating:)]) {
        [[self delegate] scrollNodeDidEndDecelerating:self];
    }
}

- (void)scrollNodeDidEndScrollingAnimation
{
    if ([[self delegate] respondsToSelector:@selector(scrollNodeDidEndScrollingAnimation:)]) {
        [[self delegate] scrollNodeDidEndScrollingAnimation:self];
    }
}

@end
