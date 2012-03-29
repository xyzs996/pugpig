//
//  KGHTMLManifest.m
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

#import "KGHTMLManifest.h"

//==============================================================================
// MARK: - Private interface

@interface KGHTMLManifest()
@property (nonatomic,retain) NSMutableArray *cacheLines;
@end

//==============================================================================
// MARK: - Main implementation

@implementation KGHTMLManifest

@synthesize baseURL;
@dynamic cacheURLs;
@synthesize cacheLines;

//------------------------------------------------------------------------------
// MARK: NSObject/init messages

- (id)initWithContentsOfFile:(NSString*)path {
  NSURL *url = [NSURL fileURLWithPath:path];
  return [self initWithContentsOfURL:url];
}

- (id)initWithContentsOfURL:(NSURL*)url {
  self = [self initWithData:[NSData dataWithContentsOfURL:url]];
  if (self) self.baseURL = url;
  return self;
}

- (id)initWithData:(NSData*)data {
  self = [super init];
  if (self) {
    NSString *manifestString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    
    NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
    
    NSEnumerator *lines = [[manifestString componentsSeparatedByCharactersInSet:newlines] objectEnumerator];
    NSString *line = [lines nextObject];
    if ([line hasPrefix:@"CACHE MANIFEST"]) {
      if ([line length] == 14 || [whitespace characterIsMember:[line characterAtIndex:14]]) {
        self.cacheLines = [[[NSMutableArray alloc] init] autorelease];
        BOOL cache = YES;
        while ((line = [lines nextObject])) {
          line = [line stringByTrimmingCharactersInSet:whitespace];
          if ([line hasPrefix:@"#"] || [line length] == 0) 
            continue;
          else if ([line isEqualToString:@"CACHE:"])
            cache = YES;
          else if ([line isEqualToString:@"NETWORK:"] || [line isEqualToString:@"FALLBACK:"])
            cache = NO;
          else if (cache) {
            line = [line stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
            [cacheLines addObject:line];
          }  
        }
      }
    }  
  }
  return self;  
}

- (void)dealloc {
  [baseURL release];
  [cacheLines release];
  [super dealloc];
}

//------------------------------------------------------------------------------
// MARK: Public messages and properties

- (NSArray*)cacheURLs {
  NSMutableArray *urls = [[[NSMutableArray alloc] initWithCapacity:cacheLines.count] autorelease];
  for (NSString *line in cacheLines) {
    NSURL *url = [NSURL URLWithString:line relativeToURL:baseURL];
    if (url) [urls addObject:url];
  }
  return urls;  
}

@end
