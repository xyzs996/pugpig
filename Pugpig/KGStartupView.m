//
//  KGStartupView.m
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

#import "KGStartupView.h"

//==============================================================================
// MARK: - Private interface

@interface KGStartupView()
@property (nonatomic,retain) UIViewController *rootViewController;
@property (nonatomic,retain) UIImageView *background;
@property (nonatomic,retain) UIProgressView *progressBar;

- (CGSize)sizeFromPortraitFrame:(CGRect)frame;
- (BOOL)isStatusBarInitiallyHidden;
@end

//==============================================================================
// MARK: - Main implementation

@implementation KGStartupView

@dynamic progress;

@synthesize rootViewController;
@synthesize background;
@synthesize progressBar;

//------------------------------------------------------------------------------
// MARK: NSObject/UIView messages

- (id)init {
  UIWindow *window = [[UIApplication sharedApplication] keyWindow];
  CGRect frame = window.frame;

  self = [super initWithFrame:frame];
  if (self) {
    self.rootViewController = window.rootViewController;
    [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self setBackgroundColor:[UIColor blackColor]];
    
    self.background = [[[UIImageView alloc] initWithFrame:frame] autorelease];
    [self addSubview:background];
    
    self.progressBar = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar] autorelease];
    CGSize isize = frame.size;
    CGSize psize = progressBar.bounds.size;
    [progressBar setFrame:CGRectMake((isize.width-psize.width)/2,(isize.height-psize.height)/2,psize.width,psize.height)];
    [progressBar setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin];
    [self addSubview:progressBar];
  
    [rootViewController.view addSubview:self];
  }
  return self;
}

- (void)dealloc {
  [rootViewController release];
  [background release];
  [progressBar release];
  [super dealloc];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  BOOL initialStatus = ![self isStatusBarInitiallyHidden];
  const CGFloat statusHeight = 20; // TODO: compute the size of the status bar
  
  CGSize size = [self sizeFromPortraitFrame:[UIScreen mainScreen].applicationFrame];
  CGRect bounds = self.bounds;
  bounds.size = size;
  [self setFrame:bounds]; 
  
  UIImage *image;
  CGSize isize, screenSize;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    image = [UIImage imageNamed:@"Default.png"];
    isize = [image size];  
    if (!image) isize = CGSizeMake(320, 480);
    [background setTransform:CGAffineTransformIdentity];
    screenSize = [[UIApplication sharedApplication] keyWindow].frame.size;
  }
  else {
    CGSize isizedef;
    if (size.width < size.height) {
      image = [UIImage imageNamed:@"Default-Portrait~ipad.png"];
      isizedef = CGSizeMake(768, 1004);
    }
    else {
      image = [UIImage imageNamed:@"Default-Landscape~ipad.png"];
      isizedef = CGSizeMake(1024, 748);
    }
    isize = [image size];
    if (!image) isize = isizedef;
    screenSize = [self sizeFromPortraitFrame:[[UIApplication sharedApplication] keyWindow].frame];
  }
    
  CGFloat xoff = 0, yoff = 0;
  BOOL special = (initialStatus && isize.width == screenSize.width && isize.height == screenSize.height);
  if (initialStatus) screenSize.height -= statusHeight;
  if (special) {
    // If the image width matches the screen width and the image height 
    // matches the screen height without the status bar, this is treated as
    // a special case and the image isn't stretched but will be positioned
    // under the status bar.
    yoff = -statusHeight;
  }  
  else {
    // If this is not a special case, the general rule is to scale the image 
    // to fit the visible screen area.
    CGFloat ymul = screenSize.height/isize.height;
    CGFloat xmul = screenSize.width/isize.width;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
      // On an iPhone we don't care about maintaining the aspect ratio.
      isize.width *= xmul;
      isize.height *= ymul;
    }
    else {
      // On an iPad we use the maximum scale that maintains the aspect ratio.
      CGFloat mul = MAX(ymul,xmul);
      isize.width *= mul;
      isize.height *= mul;
    }
  }

  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    // On an iPhone all our previous calculations were based on portrait
    // orientation, since that is how the phone always starts up. Now we need
    // to adjust everything to the actual orientation that will be displayed.
    if (UIInterfaceOrientationIsLandscape(rootViewController.interfaceOrientation)) {
      if (rootViewController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
        [background setTransform:CGAffineTransformMakeRotation(M_PI/2)];
      else  
        [background setTransform:CGAffineTransformMakeRotation(-M_PI/2)];
      CGFloat tmp = isize.width;
      isize.width = isize.height;
      isize.height = tmp;
      tmp = screenSize.width;
      screenSize.width = screenSize.height;
      screenSize.height = tmp;
      tmp = xoff;
      xoff = yoff;
      yoff = tmp;
    }
  }

  // If we started with a status bar but don't have one now (or vice versa)
  // we may need to adjust the x and y offsets accordingly.
  yoff += (size.height - screenSize.height);
  xoff += (size.width - screenSize.width);
  
  CGRect frame = CGRectMake(xoff, yoff, isize.width, isize.height);
  [background setFrame:frame];
  [background setImage:image];
}

- (CGSize)sizeFromPortraitFrame:(CGRect)frame {
  // frame size is always in portrait mode, so rotate it to match the window orientation
  CGSize size;
  if (UIInterfaceOrientationIsLandscape(rootViewController.interfaceOrientation)) {
    size.width = frame.size.height;
    size.height = frame.size.width;
  }
  else {
    size.width = frame.size.width;
    size.height = frame.size.height;
  }
  return size;
}

-(BOOL)isStatusBarInitiallyHidden {
  NSNumber *initialStatusBarState = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UIStatusBarHidden"];
  return initialStatusBarState ? [initialStatusBarState boolValue] : NO;  
}

//------------------------------------------------------------------------------
// MARK: Public methods

- (void)setProgress:(CGFloat)progress {
  [progressBar setProgress:progress];
}

- (CGFloat)progress {
  return [progressBar progress];
}

@end
