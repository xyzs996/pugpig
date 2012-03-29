//
//  UIWebView+KGAdditions.m
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

#import <QuartzCore/QuartzCore.h>
#import "UIWebView+KGAdditions.h"

@implementation UIWebView(KGAdditions)

- (BOOL)isScrollEnabled {
  UIScrollView *webScrollView = [[self subviews] lastObject];
  return (webScrollView && [webScrollView isKindOfClass:[UIScrollView class]]) ? webScrollView.scrollEnabled : NO;
}

- (void)setScrollEnabled:(BOOL)canScroll {
  UIScrollView *webScrollView = [[self subviews] lastObject];
  if (webScrollView && [webScrollView isKindOfClass:[UIScrollView class]]) {
    // When changing from a scrolling webview to a non-scrolling webview
    // we need to scrollToTop to make sure the view doesn't end up scrolled
    // halfway down a page with no way to get back up.
    if (webScrollView.scrollEnabled && !canScroll)
      [self stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('body')[0].scrollTop = 0;"];
    webScrollView.scrollEnabled = canScroll;
  }
}

- (void)setScrollWidth:(CGFloat)width {
  UIScrollView *webScrollView = [[self subviews] lastObject];
  if (webScrollView && [webScrollView isKindOfClass:[UIScrollView class]]) {
    webScrollView.contentSize = CGSizeMake((NSInteger)width, (NSInteger)webScrollView.contentSize.height);
  }  
}

- (UIImage*)getImageFromView {
  BOOL isRetina = [UIScreen mainScreen].scale > 1.0;
  UIImage *snapImage;
  for (int i = 0; i < 2; i++) {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (isRetina) CGContextSetInterpolationQuality(ctx, kCGInterpolationLow);
    [self.layer renderInContext:ctx];
    snapImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  }
  return snapImage;
}

@end
