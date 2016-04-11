//
//  MXOperation.h
//  HMXStockInfo
//
//  Created by IOS_HMX on 15/6/29.
//  Copyright (c) 2015年 IOS_HMX. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MXOperation;
@protocol MXOperationDelegate <NSObject>
- (void)operation:(MXOperation *)operation finishedGetData:(NSData *)data error:(NSError *)error;
@end
@interface MXOperation : NSOperation
@property (nonatomic ,copy)NSString *urlString;
@property (nonatomic ,copy)NSString *paramString;
@property (nonatomic ,assign)NSInteger operationTag;
@property (nonatomic ,copy)NSDictionary *userInfo;
@property (nonatomic ,assign)id<MXOperationDelegate>delegate ;
- (id)initWithUrlString:(NSString *)urlString paramString:(NSString *)paramString delegate:(id<MXOperationDelegate>)delegate;
@end
