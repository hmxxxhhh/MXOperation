//
//  MXOperation.m
//  HMXStockInfo
//
//  Created by IOS_HMX on 15/6/29.
//  Copyright (c) 2015年 IOS_HMX. All rights reserved.
//

#import "MXOperation.h"

static const NSUInteger kTimeoutCount = 10;

@interface MXOperation ()<NSURLConnectionDelegate,NSURLConnectionDataDelegate>
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSMutableURLRequest *request;
@property (strong, nonatomic) NSHTTPURLResponse *response;
@property (strong, nonatomic) NSMutableData *mutableData;
@end
@implementation MXOperation
- (id)initWithUrlString:(NSString *)urlString paramString:(NSString *)paramString delegate:(id<MXOperationDelegate>)delegate
{
    if (self = [super init]) {
        self.urlString = urlString;
        self.paramString = paramString;
        self.delegate = delegate;
    }
    return self;
}
- (void)main
{
    @autoreleasepool {
        self.request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",self.urlString,self.paramString]] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:kTimeoutCount];
        [self.request setHTTPMethod:@"GET"];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.connection = [[NSURLConnection alloc] initWithRequest:self.request
                                                              delegate:self
                                                      startImmediately:NO];
            
            [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                       forMode:NSRunLoopCommonModes];
            
            [self.connection start];
        });
    }
}
-(void)cancel
{
    if (![self isCancelled] && ![self isFinished]) {
        [super cancel];
        if ([self isExecuting]) {
            [self.connection cancel];
        }
    }
}
#pragma mark - NSURLConnection delegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
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











