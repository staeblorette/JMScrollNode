# JMScrollNode
A simple sprite kit node, modelled after UIScrollView, to facilitate scrolling behaviour.
Could be extended to use other common UIKit elements for SpriteKit.

## Features
* Bounce effect at edge when content edge becomes visible.
* Velocity is maintained and decelerates on finger up
* UIScrollView like delegate
* UIView like animations in animation blocks with completion
* Scrolls to reveal content when point at edge is specified (Useful for drag & drop)
* Runs on UIGestureRecognizer

## UIView like Animations
You can customize the defualt scrolling behaviour by calling setContentOffset:animated inside an SKNode animation block:
```
        [SKNode animateWithDuration:1 animations:^{
            [self setContentOffset:CGPointMake(300, 100) animated:YES];
        }];
```
Also these animations can be nested. Currently the options specified by the outmost callers are used:

```
        // Animation will be 1 second long
        [SKNode animateWithDuration:1 animations:^{
            [SKNode animateWithDuration:3 animations:^{
              [self setContentOffset:CGPointMake(300, 100) animated:YES];
            }];
        }];
```

