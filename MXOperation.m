//
//  MXOperation.m
//  HMXStockInfo
//
//  Created by IOS_HMX on 15/6/29.
//  Copyright (c) 2015年 IOS_HMX. All rights reserved.
//

#import "MXOperation.h"

static const NSUInteger kTimeoutCount = 10;
typedef NS_ENUM(NSInteger, MXOperationState) {
    MXOperationReadyState       = 1,
    MXOperationExecutingState   = 2,
    MXOperationFinishedState    = 3,
};
static inline NSString * MXKeyPathFromOperationState(MXOperationState state) {
    switch (state) {
        case MXOperationReadyState:
            return @"isReady";
        case MXOperationExecutingState:
            return @"isExecuting";
        case MXOperationFinishedState:
            return @"isFinished";
        default: {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
            return @"state";
#pragma clang diagnostic pop
        }
    }
}

@interface MXOperation ()<NSURLConnectionDelegate,NSURLConnectionDataDelegate>
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSMutableURLRequest *request;
@property (strong, nonatomic) NSHTTPURLResponse *response;
@property (strong, nonatomic) NSMutableData *mutableData;
@property (assign, nonatomic) MXOperationState state;
@end
@implementation MXOperation
- (id)initWithUrlString:(NSString *)urlString paramString:(NSString *)paramString delegate:(id<MXOperationDelegate>)delegate
{
    if (self = [super init]) {
        self.urlString = urlString;
        self.paramString = paramString;
        self.delegate = delegate;
        self.state = MXOperationReadyState;
    }
    return self;
}
-(void)main
{
    @autoreleasepool {
        [self start];
    }
}
-(void)start
{
    if (![self isCancelled]) {
        self.request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",self.urlString,self.paramString]] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:kTimeoutCount];
        [self.request setHTTPMethod:@"GET"];
        dispatch_async(dispatch_get_main_queue(), ^{
           
            self.connection = [[NSURLConnection alloc] initWithRequest:self.request
                                                              delegate:self
                                                      startImmediately:NO];
            
            [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                       forMode:NSRunLoopCommonModes];
            
            [self.connection start];
        });
        self.state = MXOperationExecutingState;
    }
}

-(BOOL)isReady
{
    return  (self.state == MXOperationReadyState && [super isReady]);
}
-(BOOL)isFinished
{
    return (self.state == MXOperationFinishedState);
}
-(BOOL)isExecuting
{
    return (self.state == MXOperationExecutingState);
}
-(BOOL)isAsynchronous
{
    return YES;
}
-(BOOL)isConcurrent
{
    return YES;
}
-(void)cancel
{
    if (![self isCancelled] && ![self isFinished]) {
        
        if ([self isExecuting]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                 NSLog(@"%@ cancel",self.connection);
                [self.connection cancel];
            });
            self.state = MXOperationFinishedState;
        }
        [super cancel];
    }
}
- (void)setState:(MXOperationState)state {
    
    NSString *oldStateKey = MXKeyPathFromOperationState(self.state);
    NSString *newStateKey = MXKeyPathFromOperationState(state);
    
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
}
#pragma mark - NSURLConnection delegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.state = MXOperationFinishedState;
    self.mutableData = nil;
    if (self.delegate && [self.delegate respondsToSelector:@selector(operation:finishedGetData:error:)]) {
        [self.delegate operation:self finishedGetData:nil error:error];
    }
}
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.mutableData = [NSMutableData dataWithCapacity:[response expectedContentLength]];
    self.response = (NSHTTPURLResponse*) response;
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.mutableData appendData:data];
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    self.state = MXOperationFinishedState;
    if (self.mutableData.length<=0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(operation:finishedGetData:error:)]) {
            [self.delegate operation:self finishedGetData:nil error:[NSError errorWithDomain:NSURLErrorDomain
                                                                                        code:self.response.statusCode
                                                                                    userInfo:self.response.allHeaderFields]];
        }
    }else
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(operation:finishedGetData:error:)]) {
            [self.delegate operation:self finishedGetData:self.mutableData error:nil];
        }
    }
}
@end











