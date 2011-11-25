//
//  KGLocalFileDataSource.m
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

#import "KGLocalFileDataSource.h"

@interface KGLocalFileDataSource()
@property (nonatomic, retain) NSArray *urls;
@end

@implementation KGLocalFileDataSource

@synthesize urls;

- (id)initWithPath:(NSString*)path {
  return [self initWithPath:path andExtension:@"html"];
}

- (id)initWithPath:(NSString*)path andExtension:(NSString*)extension {
  self = [super init];
  if (self) {
    NSMutableArray *tmp = [[[NSMutableArray alloc] init] autorelease];
    
    if (![path hasPrefix:@"/"]) {
      NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
      path = [bundleRoot stringByAppendingPathComponent:path];
    }  
    
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSString *predicate = [NSString stringWithFormat:@"self ENDSWITH '.%@'",extension];
    fileNames = [fileNames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicate]];    
    
    for (NSUInteger i = 0; i < fileNames.count; i++) {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      NSString *fileName = [fileNames objectAtIndex:i];
      NSString *filePath = [path stringByAppendingPathComponent:fileName];
      NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
      [tmp addObject:fileUrl];
      [pool release];
    }
    
    self.urls = [NSArray arrayWithArray:tmp];
  }
  return self;
}

- (void)dealloc {
  [urls release];
  [super dealloc];
}

- (NSUInteger)numberOfPages {
  return urls.count;
}

- (NSURL*)urlForPageNumber:(NSUInteger)pageNumber {
  if (pageNumber >= [self numberOfPages]) return nil;
  return [urls objectAtIndex:pageNumber];
}

- (NSInteger)pageNumberForURL:(NSURL*)url {
  NSString *urlPath = [url path];
  NSInteger page = -1;
  for (NSInteger i = 0; page == -1 && i < urls.count; i++) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *cmpUrlPath = [[self urlForPageNumber:i] path];
    if ([cmpUrlPath isEqual:urlPath])
      page = i;
    [pool release];    
  }
  return page;
}

@end
