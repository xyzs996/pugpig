//
//  UIView+KGAnimatedHide.m
//  Pugpig
//
//  Copyright (c) 2011, Kaldor Holdings Ltd.
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this list of
//  conditions and the following disclaimer. Redistributions in binary form must reproduce
//  the above copyright notice, this list of conditions and the following disclaimer in
//  the documentation and/or other materials provided with the distribution.
//  Neither the name of pugpig nor the names of its contributors may be
//  used to endorse or promote products derived from this software without specific prior
//  written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
//  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
//  IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//  SUCH DAMAGE.
//

#import <objc/message.h>
#import "UIView+KGAnimatedHide.h"

@implementation UIView (KGAnimatedHide)

- (void)setHidden:(BOOL)hidden animationStyle:(KGAnimationStyle)style duration:(NSTimeInterval)duration {
  if (hidden != [self isHidden]) {
    BOOL inProgress = objc_getAssociatedObject(self, @"KGAnimatedHideInProgress") ? YES : NO;
    if (inProgress) return;
    
    objc_setAssociatedObject(self, @"KGAnimatedHideInProgress", [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN);
    
    CGFloat oldAlpha = self.alpha;
    CGFloat newAlpha = self.alpha;
    CGRect oldFrame = self.frame;
    CGRect newFrame = self.frame;
    CGSize size = self.frame.size;
    CGSize parentSize = self.superview.frame.size;
    
    if (style & KGAnimationFade)
      newAlpha = 0.0;
    if (style & KGAnimationSlideLeft)
      newFrame.origin.x = -size.width;
    if (style & KGAnimationSlideRight)
      newFrame.origin.x = parentSize.width + size.width;
    if (style & KGAnimationSlideUp)
      newFrame.origin.y = -size.height;
    if (style & KGAnimationSlideDown)
      newFrame.origin.y = parentSize.height + size.height;
    
    CGFloat xoff = newFrame.origin.x - oldFrame.origin.x;
    CGFloat yoff = newFrame.origin.y - oldFrame.origin.y;
    CGAffineTransform oldTransform = CGAffineTransformIdentity;
    CGAffineTransform newTransform = CGAffineTransformMakeTranslation(xoff, yoff);
    
    if (!hidden) {
      CGFloat tmpAlpha = oldAlpha;
      oldAlpha = newAlpha;
      newAlpha = tmpAlpha;
      
      CGAffineTransform tmpTransform = oldTransform;
      oldTransform = newTransform;
      newTransform = tmpTransform;
    }  
      
    [self setTransform:oldTransform];
    [self setAlpha:oldAlpha];
    if (!hidden) [self setHidden:NO];
    [UIView animateWithDuration:duration animations:^{
      [self setTransform:newTransform];
      [self setAlpha:newAlpha];
    } completion:^(BOOL completed){
      objc_setAssociatedObject(self, @"KGAnimatedHideInProgress", nil, OBJC_ASSOCIATION_ASSIGN);
      if (hidden) {
        CGRect restoreFrame = oldFrame;
        if (!CGSizeEqualToSize(self.frame.size, restoreFrame.size))
          restoreFrame = self.frame;
        [self setHidden:YES];
        [self setTransform:oldTransform];
        [self setAlpha:oldAlpha];
        [self setFrame:restoreFrame];
      }  
    }];
  }
}

@end
