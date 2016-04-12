
http://iyiming.me/blog/2014/12/28/ios-bing-fa-bian-cheng-zhi-nsoperation/

## NSOperation的理解
1，NSOperation可以用来封装并发或非并发的操作。
2，对于非并发的操作可以直接重写main方法（main方法里不开启多线程），这时候如果调用start方法，那么main里面的代码是同步执行的即会阻塞主线程。但是如果加入到 queue 中的话，queue会为没个operation分配一个线程，此时是异步执行的不会阻塞主线程。
3，对于并发的操作，你可以重写start方法用GCD或Thread或NSURLConnection来实现，特别注意如果你用NSURLConnection用代理的方式接受数据的时候，你必须在主线程中重新为connection指定线程，不然代理无法接受到数据，你可以这样写：
```objective-c
 dispatch_async(dispatch_get_main_queue(), ^{
      self.connection = [[NSURLConnection alloc] initWithRequest:self.request
                                                        delegate:self
                                                startImmediately:NO];
      [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                 forMode:NSRunLoopCommonModes];
      [self.connection start];
    });
```
或者这样写：
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
```
只是这样写程序虽然能运行，但并不完整，应为这个时候，operation的isFinished，isExecuting，isReady，isAsynchronous，isConcurrent状态都是不对的，当用queue管理的时候，你如果设置依赖，优先级等都会无效，所有你应该重写这几个方法以确保queue能正常管理。
