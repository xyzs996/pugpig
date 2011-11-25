//
//  KGDiskImageStore.m
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

#import "KGDiskImageStore.h"

@interface KGDiskImageStore()

@property (nonatomic, retain) NSString *cacheDir;
@property (nonatomic, retain) NSMutableDictionary *store;
@property (nonatomic, retain) NSMutableArray *queue;

- (id)keyForPageNumber:(NSUInteger)pageNumber variant:(NSString*)variant;
- (void)removeFilesStartingWith:(NSString*)filename;
- (NSString*)fileNameForKey:(id)key;
- (BOOL)imageWrittenForKey:(id)key;
- (UIImage*)readImageForKey:(id)key;
- (void)writeImage:(UIImage*)image forKey:(id)key;
- (void)eraseImageForKey:(id)key;
- (void)enqueueImage:(UIImage*)image forKey:(id)key;

@end


@interface KGDiskImageStoreObject : NSObject {
}
@property (nonatomic,assign) BOOL onDisk;
@property (nonatomic,retain) UIImage *image;
@end

@implementation KGDiskImageStoreObject

@synthesize onDisk;
@synthesize image;

- (void)dealloc {
  [image release];
  [super dealloc];
}

@end


@implementation KGDiskImageStore

@synthesize cacheSize;
@synthesize cacheDir;
@synthesize store;
@synthesize queue;

- (id)init {
  return [self initWithPath:nil];
}

- (id)initWithPath:(NSString*)path {
  self = [super init];
  if (self) {
    if (![path hasPrefix:@"/"]) {
      NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
      if ([cachePaths count])
        path = [[cachePaths objectAtIndex:0] stringByAppendingPathComponent:path];
    }
    
    NSFileManager *fileman = [NSFileManager defaultManager];
    [fileman createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];

    self.cacheSize = 7;   // default cache size
    self.cacheDir = path;
    self.store = [[[NSMutableDictionary alloc] init] autorelease];
    self.queue = [[[NSMutableArray alloc] init] autorelease];
  }
  return self;
}

- (void)dealloc {
  [queue release];
  [store release];
  [cacheDir release];
  [super dealloc];
}

- (void)releaseMemory {
  for (id key in store) {
    KGDiskImageStoreObject *obj = [store objectForKey:key];
    obj.image = nil;
  }
}

- (void)saveImage:(UIImage*)image forPageNumber:(NSUInteger)pageNumber variant:(NSString*)variant {
  if (![self hasImageForPageNumber:pageNumber variant:variant]) {
    id key = [self keyForPageNumber:pageNumber variant:variant];
    KGDiskImageStoreObject *obj = [store objectForKey:key];
    obj.onDisk = YES;
    obj.image = image;
    [self writeImage:image forKey:key];
    [self enqueueImage:image forKey:key];
  }
}

- (UIImage*)imageForPageNumber:(NSUInteger)pageNumber variant:(NSString*)variant {
  return [self imageForPageNumber:pageNumber variant:variant withOptions:KGImageStoreFetch];
}

- (UIImage*)imageForPageNumber:(NSUInteger)pageNumber variant:(NSString*)variant withOptions:(KGImageStoreOptions)options {
  UIImage *image = nil;
  if ([self hasImageForPageNumber:pageNumber variant:variant]) {
    id key = [self keyForPageNumber:pageNumber variant:variant];
    KGDiskImageStoreObject *obj = [store objectForKey:key];

    image = (obj.image ? obj.image : [self readImageForKey:key]);
    
    if (image && !(options & KGImageStoreTemporary)) {
      // if not temporary, add to in-memory store and queue
      obj.image = image;
      [self enqueueImage:image forKey:key];
    }
  }
  return image; 
}

- (BOOL)hasImageForPageNumber:(NSUInteger)pageNumber variant:(NSString*)variant {
  id key = [self keyForPageNumber:pageNumber variant:variant];
  KGDiskImageStoreObject *obj = [store objectForKey:key];
  if ([store objectForKey:key] == nil) { 
    obj = [[[KGDiskImageStoreObject alloc] init] autorelease];
    obj.onDisk = [self imageWrittenForKey:key];
    [store setObject:obj forKey:key];
  }
  return [obj onDisk];
}

- (void)removeImageForPageNumber:(NSUInteger)pageNumber variant:(NSString*)variant {
  // TODO: don't erase entire store and queue
  id key = [self keyForPageNumber:pageNumber variant:variant];
  NSString *filepath = [self fileNameForKey:key];
  NSFileManager *fileman = [NSFileManager defaultManager];
  [fileman removeItemAtPath:filepath error:nil];
  self.store = [[[NSMutableDictionary alloc] init] autorelease];
  self.queue = [[[NSMutableArray alloc] init] autorelease];
}

- (void)removeImagesForPageNumber:(NSUInteger)pageNumber {
  // TODO: don't erase entire store and queue
  NSString *baseFilename = [NSString stringWithFormat:@"snap-%d-",pageNumber];
  [self removeFilesStartingWith:baseFilename];
  self.store = [[[NSMutableDictionary alloc] init] autorelease];
  self.queue = [[[NSMutableArray alloc] init] autorelease];
}

- (void)removeAllImages {
  [self removeFilesStartingWith:@"snap-"];
  self.store = [[[NSMutableDictionary alloc] init] autorelease];
  self.queue = [[[NSMutableArray alloc] init] autorelease];
}

- (id)keyForPageNumber:(NSUInteger)pageNumber variant:(NSString*)variant {
  return [NSString stringWithFormat:@"%d-%@", pageNumber, variant];
}

- (void)removeFilesStartingWith:(NSString*)filename {
  NSString *predicateString = [NSString stringWithFormat:@"self BEGINSWITH '%@'",filename];
  NSFileManager *fileman = [NSFileManager defaultManager];
  NSArray *filenames = [fileman contentsOfDirectoryAtPath:cacheDir error:nil];
  filenames = [filenames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicateString]];
  for (NSString *filename in filenames) {
    NSString *filepath = [cacheDir stringByAppendingPathComponent:filename];
    [fileman removeItemAtPath:filepath error:nil];
  }
}

- (NSString*)fileNameForKey:(id)key {
  return  [cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"snap-%@.jpg", key]];
}

- (BOOL)imageWrittenForKey:(id)key {
  NSString *cacheFile = [self fileNameForKey:key];
  return [[NSFileManager defaultManager] fileExistsAtPath:cacheFile];    
}

- (UIImage*)readImageForKey:(id)key {
  NSString *cacheFile = [self fileNameForKey:key];
  return [[NSFileManager defaultManager] fileExistsAtPath:cacheFile] ? [UIImage imageWithContentsOfFile:cacheFile] : nil;
}

- (void)writeImage:(UIImage*)image forKey:(id)key {
  NSString *cacheFile = [self fileNameForKey:key];
  [UIImageJPEGRepresentation(image, 0.5) writeToFile:cacheFile atomically:YES];
}

- (void)eraseImageForKey:(id)key {
  NSString *cacheFile = [self fileNameForKey:key];
  [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
}

- (void)enqueueImage:(UIImage *)image forKey:(id)key {
  NSUInteger keyIdx = [queue indexOfObject:key];
  if (keyIdx != NSNotFound) {
    // image in recent use queue; move it to the back so it's the most recently used.
    id moveKey = [queue objectAtIndex:keyIdx];
    [queue addObject:moveKey];
    [queue removeObjectAtIndex:keyIdx];
  }
  else {
    // image not in queue - add it and drop the oldest if necessary
    [queue addObject:key];
    if ([queue count] > cacheSize) {
      id lastKey = [queue objectAtIndex:0];
      [[store objectForKey:lastKey] setImage:nil];
      [queue removeObjectAtIndex:0];
    }
  }
}

@end
