# MXOperation
## 写的比较简单，只是表明这种用法，不完整的或bug待后续补充修复

#### 以下是AF的写法
```objective-c
- (void)start {
    [self.lock lock];
    if ([self isCancelled]) {
        [self performSelector:@selector(cancelConnection) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    } else if ([self isReady]) {
        self.state = AFOperationExecutingState;

        [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }
    [self.lock unlock];
}

- (void)operationDidStart {
    [self.lock lock];
    if (![self isCancelled]) {
        self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];

        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        for (NSString *runLoopMode in self.runLoopModes) {
            [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
            [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
        }

        [self.outputStream open];
        [self.connection start];
    }
    [self.lock unlock];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidStartNotification object:self];
    });
}
```
区别在于作者是为请求建立独立的线程和运行循环便于管理。
#### 再来看看MKNetwork的写法
```objective-c
- (void) start
{
  
#if TARGET_OS_IPHONE
  self.backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.backgroundTaskId != UIBackgroundTaskInvalid)
      {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
        [self cancel];
      }
    });
  }];
  
#endif
  
  if(!self.isCancelled) {
    
    if (([self.request.HTTPMethod isEqualToString:@"POST"] ||
         [self.request.HTTPMethod isEqualToString:@"PUT"] ||
         [self.request.HTTPMethod isEqualToString:@"PATCH"]) && !self.request.HTTPBodyStream) {
      
      [self.request setHTTPBody:[self bodyData]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
      self.connection = [[NSURLConnection alloc] initWithRequest:self.request
                                                        delegate:self
                                                startImmediately:NO];
      
      [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                 forMode:NSRunLoopCommonModes];
      
      [self.connection start];
    });
    
    self.state = MKNetworkOperationStateExecuting;
  }
  else {
    self.state = MKNetworkOperationStateFinished;
    [self endBackgroundTask];
  }
}
```


