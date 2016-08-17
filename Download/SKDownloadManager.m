//
//  SKDownloadManager.m
//  DownloadTest
//
//  Created by 韦健 on 15/7/31.
//  Copyright (c) 2015年 韦健. All rights reserved.
//

#import "SKDownloadManager.h"

#import "RequestDownloadToken.h"
#import "SKProgressHUB.h"

/** 通知userInfo 文件模型对应键 */
NSString *const SKOperationUserInfoFileKey = @"download.SKDownloadManager.SKOperationUserInfoFileKey";

/** 开始下载通知 */
NSString *const SKDownloadStartNotification = @"download.SKDownloadManager.SKDownloadStartNotification";

/** 开始下载保密文件的通知 */
NSString *const SKDownloadSerctFileNotification = @"download.SKDownloadManager.SKDownloadSerctFileNotification";
/** 正在下载通知 */
NSString *const SKDownloadingNotification = @"download.SKDownloadManager.SKDownloadingNotification";
/** 取消下载通知 */
NSString *const SKDownloadCancelNotification = @"download.SKDownloadManager.SKDownloadCancelNotification";
/** 下载成功通知 */
NSString *const SKDownloadSuccessNotification = @"download.SKDownloadManager.SKDownloadSuccessNotification";
/** 下载失败通知 */
NSString *const SKDownloadFailureNotification = @"download.SKDownloadManager.SKDownloadFailureNotification";
/** 服务器返回错误码通知 */
NSString *const SKDownloadVerifyErrorNotification = @"download.SKDownloadManager.SKDownloadVerifyErrorNotification";

/** key值 */
static NSString *const fileIdKey = @"fileId";
static NSString *const fileNameKey = @"fileName";
static NSString *const fileSuffixKey = @"fileSuffix";
static NSString *const fileSizeKey = @"fileSize";
static NSString *const fileDownloadURLKey = @"fileDownloadURL";
static NSString *const fileDownloadTimeKey = @"fileDownloadTime";
static NSString *const fileSecretKey = @"Secret";

static SKDownloadManager *downloadManager = nil;

@interface SKDownloadManager () <UIAlertViewDelegate>

/** 下载文件模型 */
@property (nonatomic, strong) SKDownloadFile *downloadFile;

@end

@implementation SKDownloadManager

#pragma mark - 初始化
+ (instancetype)downloadManager
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        downloadManager = [[super allocWithZone:NULL] init];
        
    });
    return downloadManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [self downloadManager];
}

- (id)copy
{
    return downloadManager;
}

#pragma mark - private method
#pragma mark 初始化配置
- (void)downloadManagerConfig
{

    self.finishList = [self loadFinishFiles];
    self.tempList = [self loadTempFiles];
    self.downloadingList = [self getDownloadOperetionsWithTempFiles:self.tempList];
}

#pragma mark 获取下载完成的文件数组
- (NSMutableArray *)loadFinishFiles
{
    NSMutableArray *array = [NSMutableArray array];
    // 下载完成对应的plist文件地址
    NSString *finishPlistPath = [SKDownloadHelper getFinishPlistPath];
    
    if ([SKDownloadHelper isExistingFileAtPath:finishPlistPath]) {
        // finishPlist文件中存储的是下载完成文件的信息
        NSMutableArray *finishArray = [[NSMutableArray alloc] initWithContentsOfFile:finishPlistPath];
        for (NSDictionary *dic in finishArray) {
            SKDownloadFile *downloadFile = [[SKDownloadFile alloc] init];
            downloadFile.fileID = [dic objectForKey:fileIdKey];
            downloadFile.name = [dic objectForKey:fileNameKey];
            downloadFile.suffix = [dic objectForKey:fileSuffixKey];
            downloadFile.totalSize = [dic objectForKey:fileSizeKey];
            downloadFile.finishPath = [[SKDownloadHelper getFinishFolderPath] stringByAppendingPathComponent:downloadFile.fileID];
            downloadFile.tempPath = [[SKDownloadHelper getTempFolderPath] stringByAppendingPathComponent:downloadFile.fileID];
            downloadFile.downloadURL = [dic objectForKey:fileDownloadURLKey];
            downloadFile.downloadTime = [dic objectForKey:fileDownloadTimeKey];
            downloadFile.downloadStatus = SKDownloadStatusFinish;
            downloadFile.dataLevel = [[dic objectForKey:fileSecretKey] integerValue];
//            if (downloadFile.dataLevel == DataLevelTypePublic || downloadFile.dataLevel == DataLevelTypeVIPSecret) {
            [array addObject:downloadFile];
//            }
            
        }
    }
    
    return array;
}

#pragma mark 获取下载未完成的文件数组
- (NSMutableArray *)loadTempFiles
{
    NSMutableArray *array = [NSMutableArray array];

    for (NSString *tempPlist in [SKDownloadHelper getTempFolderPlistFiles]) {
        NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:tempPlist];
        SKDownloadFile *downloadFile = [[SKDownloadFile alloc] init];
        downloadFile.fileID = [dic objectForKey:fileIdKey];
        downloadFile.name = [dic objectForKey:fileNameKey];
        downloadFile.suffix = [dic objectForKey:fileSuffixKey];
        downloadFile.totalSize = [dic objectForKey:fileSizeKey];
        downloadFile.tempPath = [[SKDownloadHelper getTempFolderPath] stringByAppendingPathComponent:downloadFile.fileID];
        downloadFile.finishPath = [[SKDownloadHelper getFinishFolderPath] stringByAppendingPathComponent:downloadFile.fileID];
        downloadFile.receivedSize = [NSString stringWithFormat:@"%lu", (unsigned long)[SKDownloadHelper getTempFileSize:downloadFile.tempPath]];
        downloadFile.downloadURL = [dic objectForKey:fileDownloadURLKey];
        downloadFile.downloadTime = [dic objectForKey:fileDownloadTimeKey];
        downloadFile.progress = downloadFile.receivedSize.floatValue /  downloadFile.totalSize.floatValue;
        downloadFile.speed = @"0K/S";
        downloadFile.downloadStatus = SKDownloadStatusPause;
        downloadFile.dataLevel = [[dic objectForKey:fileSecretKey] integerValue];
        
        
        [array addObject:downloadFile];
    }
    
    return [self sortByTimeWithArray:array];
}

#pragma mark 按照时间大小排序
- (NSMutableArray *)sortByTimeWithArray:(NSArray *)array
{
    NSArray *sortArray = [array sortedArrayUsingComparator:^(id obj1, id obj2){
        SKDownloadFile *downloadFile1 = (SKDownloadFile *)obj1;
        SKDownloadFile *downloadFile2 = (SKDownloadFile *)obj2;
        NSDate *date1 = downloadFile1.downloadTime;
        NSDate *date2 = downloadFile2.downloadTime;
        if ([[date1 earlierDate:date2] isEqualToDate:date1]) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        
        if ([[date1 earlierDate:date2] isEqualToDate:date2]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        
        return (NSComparisonResult)NSOrderedSame;
    }];
    return [sortArray mutableCopy];
}

- (NSMutableArray *)sortByTimeWithArray2:(NSArray *)array2
{
    NSArray *sortArray = [array2 sortedArrayUsingComparator:^(id obj1, id obj2){
        NSDictionary *dic1 = (NSDictionary *)obj1;
        NSDictionary *dic2 = (NSDictionary *)obj2;
        NSDate *date1 = [SKDownloadHelper stringToDate:dic1[fileDownloadTimeKey]];
        NSDate *date2 = [SKDownloadHelper stringToDate:dic2[fileDownloadTimeKey]];
        if ([[date1 earlierDate:date2] isEqualToDate:date1]) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        
        if ([[date1 earlierDate:date2] isEqualToDate:date2]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        
        return (NSComparisonResult)NSOrderedSame;
    }];
    return [sortArray mutableCopy];
}


#pragma mark 根据未下载的文件创建请求对象
- (NSMutableArray *)getDownloadOperetionsWithTempFiles:(NSMutableArray *)tempFiles
{
    NSMutableArray *array = [NSMutableArray array];
    for (SKDownloadFile *downloadFile in tempFiles) {
       
        [array addObject:[self getRequestOperationWithDownloadFile:downloadFile]];
    }
    
    return array;
}

#pragma mark 保存正在下载文件对应的plist文件
- (void)saveDownloadingFilePlist:(SKDownloadFile *)downloadFile
{
    // plist文件路径
    NSString *plistPath = [downloadFile.tempPath stringByAppendingPathExtension:@"plist"];
    if ([SKDownloadHelper isExistingFileAtPath:plistPath]) {
        return;
    }
    
    NSDictionary *fileDic = @{fileIdKey: downloadFile.fileID,
                              fileNameKey: downloadFile.name,
                              fileSuffixKey: downloadFile.suffix,
                              fileDownloadURLKey: downloadFile.downloadURL,
                              fileDownloadTimeKey: downloadFile.downloadTime,
                              fileSecretKey: @(downloadFile.dataLevel)};
    

        if (![fileDic writeToFile:plistPath atomically:YES]) {
            NSLog(@"write plist fail");
        }

}

#pragma mark 保存下载完成文件对应的plist文件
- (void)saveFinishFilePlist:(SKDownloadFile *)downloadFile
{
    NSString *plistPath = [SKDownloadHelper getFinishPlistPath];
    NSMutableArray *fileArray = [NSMutableArray arrayWithContentsOfFile:plistPath];
    
    NSDictionary *fileDic = @{fileIdKey: downloadFile.fileID,
                              fileNameKey: downloadFile.name,
                              fileSuffixKey: downloadFile.suffix,
                              fileSizeKey: downloadFile.totalSize,
                              fileDownloadURLKey: downloadFile.downloadURL,
                              fileDownloadTimeKey: downloadFile.downloadTime,
                              fileSecretKey: @(downloadFile.dataLevel)};
    

    [fileArray insertObject:fileDic atIndex:0];

    
    if (![fileArray writeToFile:plistPath atomically:YES]) {
        NSLog(@"write plist fail");
    }
}

#pragma mark 删除未完成下载
- (BOOL)deleteTempWithDownloadFile:(SKDownloadFile *)downloadFile requestOperation:(AFHTTPRequestOperation *)requestOperation
{
    // 如果临时文件夹存在该文件，删除
    if ([SKDownloadHelper isExistingFileAtPath:downloadFile.tempPath] && ![SKDownloadHelper deleteFileAtPath:downloadFile.tempPath]) {
        // 删除文件失败处理
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                            message:@"删除文件出错，请重试。"
                                                           delegate:nil
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        
        return NO;
    }
    
    // 删除plist文件
    NSString *plistPath = [downloadFile.tempPath stringByAppendingString:@".plist"];
    if ([SKDownloadHelper isExistingFileAtPath:plistPath] && ![SKDownloadHelper deleteFileAtPath:plistPath]) {
        // 删除文件失败处理
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                            message:@"删除文件出错，请重试。"
                                                           delegate:nil
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        
        return NO;
    }
    
    // 删除该临时文件模型
    if ([self.tempList containsObject:downloadFile]) {
        [self.tempList removeObject:downloadFile];
    }
    
    // 删除该文件下载请求
    if (![requestOperation isCancelled]) {
        if ([requestOperation isExecuting]) {
            [requestOperation cancel];
        } else {
            [requestOperation resume];
            [requestOperation cancel];
        }
    }
    if ([self.downloadingList containsObject:requestOperation]) {
        [self.downloadingList removeObject:requestOperation];
    }

    return YES;
}

#pragma mark 将临时目录中下载完成的文件移动到完成目录
- (BOOL)moveTempFileToFinishFolder:(SKDownloadFile *)downloadFile requestOperation:(AFHTTPRequestOperation *)requestOperation
{
    // 并行线程中，保证只有一个操作执行
    dispatch_barrier_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 删除临时目录中plist文件
        NSString *plistPath = [downloadFile.tempPath stringByAppendingString:@".plist"];
        if ([SKDownloadHelper isExistingFileAtPath:plistPath] && ![SKDownloadHelper deleteFileAtPath:plistPath]) {
            
        }
        
        // 删除该临时文件模型
        if ([self.tempList containsObject:downloadFile]) {
            [self.tempList removeObject:downloadFile];
        }
        
        // 删除该临时文件下载请求
        if (![requestOperation isCancelled]) {
            if ([requestOperation isExecuting]) {
                [requestOperation cancel];
            } else {
                [requestOperation resume];
                [requestOperation cancel];
            }
        }
        if ([self.downloadingList containsObject:requestOperation]) {
            [self.downloadingList removeObject:requestOperation];
        }

        // 添加到下载完成数组中
        [self.finishList insertObject:downloadFile atIndex:0];
        // 保存文件在plist中
        [self saveFinishFilePlist:downloadFile];
        // 下载成功通知
        [[NSNotificationCenter defaultCenter] postNotificationName:SKDownloadSuccessNotification object:requestOperation];

        
    });

    
    return [SKDownloadHelper moveFileAtPath:downloadFile.tempPath toPath:downloadFile.finishPath];

}

#pragma mark 读取本地缓存入流
- (void)readCacheToOutStreamWithRequestOperation:(AFHTTPRequestOperation *)requestOperation path:(NSString *)path
{
    NSFileHandle* fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData* currentData = [fileHandle readDataToEndOfFile];
    
    if (currentData.length) {
        [requestOperation.outputStream open];
        
        NSInteger bytesWritten;
        NSInteger bytesWrittenSoFar;
        
        NSInteger  dataLength = [currentData length];
        const uint8_t * dataBytes  = [currentData bytes];
        
        bytesWrittenSoFar = 0;
        do {
            bytesWritten = [requestOperation.outputStream write:&dataBytes[bytesWrittenSoFar] maxLength:dataLength - bytesWrittenSoFar];
            assert(bytesWritten != 0);
            if (bytesWritten == -1) {
                break;
            } else {
                bytesWrittenSoFar += bytesWritten;
            }
        } while (bytesWrittenSoFar != dataLength);
    }
}

#pragma mark 下载请求对象
- (AFHTTPRequestOperation *)getRequestOperationWithDownloadFile:(SKDownloadFile *)downloadFile
{
#warning 获取token机制不太合理。
    NSString * token = [self getToken];
    SKLog(@"getToken = %@",token);
    NSString * urlString = [NSString stringWithFormat:@"%@&token=%@",downloadFile.downloadURL,token];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                  cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                              timeoutInterval:60.0f];
    unsigned long long downloadedBytes = downloadFile.receivedSize.longLongValue;
    // 如果已经下载，则追加下载请求头
    if (downloadedBytes > 0) {
        NSMutableURLRequest *mutableURLRequest = [request mutableCopy];
        NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
        [mutableURLRequest setValue:requestRange forHTTPHeaderField:@"Range"];
        request = mutableURLRequest;
    }

    // 不使用缓存，避免断点续传出现问题
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
    // 下载请求
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    // 设置上下文的文件基本信息
    requestOperation.userInfo = @{SKOperationUserInfoFileKey: downloadFile};
    // 设置下载流
    requestOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:downloadFile.tempPath append:NO];
    // 处理流
    [self readCacheToOutStreamWithRequestOperation:requestOperation path:downloadFile.tempPath];
    // 下载进度回调
    __weak __typeof(requestOperation) weakRequestOperation = requestOperation;
    __block unsigned long long downloadSize = 0;
    [requestOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
        if (weakRequestOperation.isExecuting) {
            // AFNetworking暂停不是线程安全的
            // 如果已经暂停，则不设置文件
            downloadFile.downloadStatus = SKDownloadStatusDownloading;
        }
        
        // 如果totalSize为空
        if (!downloadFile.totalSize) {
            downloadFile.totalSize = [NSString stringWithFormat:@"%llu", totalBytesExpectedToRead];
            
            NSString *plistPath = [downloadFile.tempPath stringByAppendingPathExtension:@"plist"];
            NSDictionary *tempDic = [NSDictionary dictionaryWithContentsOfFile:plistPath];
            [tempDic setValue:downloadFile.totalSize forKey:fileSizeKey];
            [tempDic writeToFile:plistPath atomically:YES];
        }
        
        // 时时更新文件模型的已下载大小和下载进度
        CGFloat progress = ((CGFloat)totalBytesRead + downloadedBytes) / downloadFile.totalSize.floatValue;
        downloadFile.receivedSize = [NSString stringWithFormat:@"%llu", downloadedBytes + totalBytesRead];
        downloadFile.progress = progress;
//        NSLog(@"------%f",progress);
        // 设置开始下载时间
        if (!downloadFile.speedDownloadTime) {
            downloadFile.speedDownloadTime = [NSDate date];
            // 开始下载通知
            [[NSNotificationCenter defaultCenter] postNotificationName:SKDownloadStartNotification object:weakRequestOperation];
        }
        
       
        
        // 计算下载速度（/秒）
        NSDate *currentTime = [NSDate date];
        NSTimeInterval timeInterval = [currentTime timeIntervalSinceDate:downloadFile.speedDownloadTime];
        NSDecimalNumber *decimalTime = [[NSDecimalNumber alloc] initWithDouble:timeInterval];
        if ([decimalTime compare:@(1)] == NSOrderedAscending) {
            // 下载的文件大小
            downloadSize += bytesRead;
        } else if ([decimalTime compare:@(1)] == NSOrderedSame || [decimalTime compare:@(1)] == NSOrderedDescending) {
            downloadFile.speed = [SKDownloadHelper getDownloadSpeed:[NSString stringWithFormat:@"%llu", downloadSize]];
            downloadSize = 0;
            downloadFile.speedDownloadTime = currentTime;
        }
        
        // 正在下载通知
        [[NSNotificationCenter defaultCenter] postNotificationName:SKDownloadingNotification object:weakRequestOperation];
    }];
    
    // 成功和失败回调
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // 服务器返回错误码
        SKDownloadErrorCode errorCode = ((NSString *)operation.response.allHeaderFields[@"errorCode"]).integerValue;
        
        if (errorCode != SKDownloadErrorCodeNone) {
            // 设置文件
            downloadFile.downloadStatus = SKDownloadStatusError;
            //删除
            if(downloadFile.dataLevel >= DataLevelTypeInside && errorCode == SKDownloadErrorCodeThresholdError){
                
                [self deleteTempWithDownloadFile:downloadFile requestOperation:operation];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SKDownloadVerifyErrorNotification object:operation];
            return ;
        }
        // 设置文件
        downloadFile.downloadStatus = SKDownloadStatusFinish;
      
        [self moveTempFileToFinishFolder:downloadFile requestOperation:operation];
        
        
     
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (error.code == NSURLErrorCancelled) { // 取消下载
            // 取消下载通知
            [[NSNotificationCenter defaultCenter] postNotificationName:SKDownloadCancelNotification object:operation];
        } else  { // 下载失败
            // 设置文件
            downloadFile.downloadStatus = SKDownloadStatusError;
            downloadFile.error = error;
            downloadFile.speedDownloadTime = nil;
            downloadFile.speed = @"0K/S";
            // 下载失败通知
            [[NSNotificationCenter defaultCenter] postNotificationName:SKDownloadFailureNotification object:operation];
        }
    }];
    
    [requestOperation start];
    
    // 设置状态：根据文件模型状态判断请求是否执行或者暂停
    switch (downloadFile.downloadStatus) {
        case SKDownloadStatusPause:
            [requestOperation pause];
            break;
        default:
            [requestOperation resume];
            break;
    }

    return requestOperation;
}

#pragma mark - public method
#pragma mark 下载文件入口
- (SKFileStauts)downloadFileWithUrl:(NSString *)url fileId:(NSString *)fileId fileName:(NSString *)fileName fileSuffix:(NSString *)fileSuffix isPublic:(BOOL)isPublic
{
    /** 检查能否添加到下载队列 */
    if (!fileId || [fileId isEqualToString:@""]) {
        return SKFileStautsAddFail;
    }
    
    /** 检查是否有下载完成或者正在下载的文件；有，提示用户。 */
    if (self.downloadFile) {
        self.downloadFile = nil;
    }
    _downloadFile = [[SKDownloadFile alloc] init];
    _downloadFile.fileID = fileId;
    _downloadFile.name = fileName;
    _downloadFile.suffix = fileSuffix;
    _downloadFile.downloadURL = url;
    _downloadFile.downloadTime = [SKDownloadHelper currentDate];
    _downloadFile.tempPath = [[SKDownloadHelper getTempFolderPath] stringByAppendingPathComponent:_downloadFile.fileID];
    _downloadFile.finishPath = [[SKDownloadHelper getFinishFolderPath] stringByAppendingPathComponent:_downloadFile.fileID];
    _downloadFile.downloadStatus = SKDownloadStatusWait;
    _downloadFile.receivedSize = [SKDownloadHelper getFileSizeString:@"0"];
    _downloadFile.error = nil;
    if (isPublic) {
        _downloadFile.dataLevel = DataLevelTypePublic;
    }else{
        _downloadFile.dataLevel = DataLevelTypeInside;
 
    }
    // 已经下载过该文件
    if([SKDownloadHelper isExistingFileAtPath:_downloadFile.finishPath]) {
        return SKFileStautsFinish;
    }
    
    // 文件存在于临时文件夹
    if([SKDownloadHelper isExistingFileAtPath:_downloadFile.tempPath] && _downloadFile.dataLevel < DataLevelTypeInside) {
        return SKFileStautsDownloading;
    }

    // 若不存在文件和临时文件，则是新的下载
    [self.tempList insertObject:_downloadFile atIndex:0];

    AFHTTPRequestOperation *operationRequest = [self getRequestOperationWithDownloadFile:_downloadFile];
    [self.downloadingList insertObject:operationRequest atIndex:0];
    // 保存信息在plist文件中
    [self saveDownloadingFilePlist:_downloadFile];
    
    return SKFileStautsAddSuccess;
}



#pragma mark 重新下载
- (AFHTTPRequestOperation *)restartWithRequestOperation:(AFHTTPRequestOperation *)requestOperation
{
    
    SKDownloadFile *downloadFile = [requestOperation.userInfo objectForKey:SKOperationUserInfoFileKey];
    downloadFile.downloadStatus = SKDownloadStatusDownloading;
    downloadFile.error = nil;

    NSInteger index = [self.downloadingList indexOfObject:requestOperation];
    AFHTTPRequestOperation *operation = [self getRequestOperationWithDownloadFile:downloadFile];
    [self.downloadingList replaceObjectAtIndex:index withObject:operation];
    
    return operation;
}

#pragma mark 暂停下载
- (void)pauseWithRequestOperation:(AFHTTPRequestOperation *)requestOperation
{
    if ([requestOperation isExecuting]) {
        [requestOperation pause];
        
        SKDownloadFile *downloadFile = [requestOperation.userInfo objectForKey:SKOperationUserInfoFileKey];
        downloadFile.downloadStatus = SKDownloadStatusPause;
        downloadFile.speedDownloadTime = nil;
        downloadFile.speed = @"0K/S";
    }
}

#pragma mark 恢复下载
- (void)resumeWithRequestOperation:(AFHTTPRequestOperation *)requestOperation
{
    if ([requestOperation isPaused]) {
        [requestOperation resume];
        
        SKDownloadFile *downloadFile = [requestOperation.userInfo objectForKey:SKOperationUserInfoFileKey];
        downloadFile.downloadStatus = SKDownloadStatusDownloading;
    }
}

#pragma mark 取消下载
- (void)cancelWithRequestOperation:(AFHTTPRequestOperation *)requestOperation
{
    SKDownloadFile *downloadFile = [requestOperation.userInfo objectForKey:SKOperationUserInfoFileKey];
    [self deleteTempWithDownloadFile:downloadFile requestOperation:requestOperation];
}

#pragma mark 暂停所有下载
- (void)pauseAllRequest
{
    for (AFHTTPRequestOperation *operation in self.downloadingList) {
        [self pauseWithRequestOperation:operation];
    }
}

#pragma mark 取消所有下载
- (void)cancelAllRequest
{
    for (AFHTTPRequestOperation *operation in self.downloadingList) {
        [self cancelWithRequestOperation:operation];
    }
}

#pragma mark 取消内部请求操作
- (void)cancelInsideRequest
{
    for (AFHTTPRequestOperation *requestOperation in self.downloadingList) {
        SKDownloadFile *file = [requestOperation.userInfo objectForKey:SKOperationUserInfoFileKey];
        if (file.dataLevel >= DataLevelTypeInside) {
            [self cancelWithRequestOperation:requestOperation];
        }
    }
}

#pragma mark 获取token

- (NSString *)getToken{

    NSDictionary * dict = [RequestDownloadToken postToDownLoadTokenWithSubUrl:SKServerGetTokenApi andParams:nil];
    
    if (dict == nil) {
        return nil;
    }else{
        NSString * token = [NSString stringWithFormat:@"%@", dict[@"data"][@"token"]];
        //NSString * token = data[@"token"];
        return token;
    }
}

#pragma mark 清空数据
- (void)clearData
{
    if (self.finishList) {
        [self.finishList removeAllObjects];
    }
    
    if (self.tempList) {
        [self.tempList removeAllObjects];
    }
    
    for (AFHTTPRequestOperation *operation in self.downloadingList) {
        // 删除该文件下载请求
        if (![operation isCancelled]) {
            if ([operation isExecuting]) {
                [operation cancel];
            } else {
                [operation resume];
                [operation cancel];
            }
        }
    }
    
    if (self.downloadingList) {
        [self.downloadingList removeAllObjects];
    }
    
    self.baseDownloadFolder = nil;
}

#pragma mark 删除已下载完成文件
- (BOOL)deleteFinishWithDownloadFile:(SKDownloadFile *)downloadFile
{
    if (!downloadFile) {
        return NO;
    }
    // 删除plist文件内容
    NSString *plistPath = [SKDownloadHelper getFinishPlistPath];
    if (!plistPath) {
        return NO;
    }
    
    NSMutableArray *fileArray = [NSMutableArray arrayWithContentsOfFile:plistPath];
    if (!fileArray || fileArray.count == 0) {
        return NO;
    }
    
    if (![self.finishList containsObject:downloadFile]) {
        return NO;
    }
    
    if ([self.finishList indexOfObject:downloadFile] >= fileArray.count) {
        return NO;
    }
    
    [fileArray removeObjectAtIndex:[self.finishList indexOfObject:downloadFile]];
    if (![fileArray writeToFile:plistPath atomically:YES]) {
        return NO;
    }
    
    // 如果下载完成文件夹存在该文件，删除
    if ([SKDownloadHelper isExistingFileAtPath:downloadFile.finishPath] && ![SKDownloadHelper deleteFileAtPath:downloadFile.finishPath]) {
        return NO;
    }
    
    // 删除模型
    [self.finishList removeObject:downloadFile];
    
    return YES;
}

#pragma mark 检测文件状态
- (SKFileStauts)checkFileWithFileId:(NSString *)fileId
{
    NSString *tempPath = [[SKDownloadHelper getTempFolderPath] stringByAppendingPathComponent:fileId];
    NSString *finishPath = [[SKDownloadHelper getFinishFolderPath] stringByAppendingPathComponent:fileId];
    // 已经下载过该文件
    if([SKDownloadHelper isExistingFileAtPath:finishPath]) {
        return SKFileStautsFinish;
    }
    
    // 文件存在于临时文件夹
    if([SKDownloadHelper isExistingFileAtPath:tempPath]) {
        return SKFileStautsDownloading;
    }
    
    return SKFileStautsNone;
}


#pragma mark - getter and setter
- (SKDownloadFile *)downloadFile
{
    if (!_downloadFile) {
        _downloadFile = [[SKDownloadFile alloc] init];
    }
    return _downloadFile;
}

- (void)setBaseDownloadFolder:(NSString *)baseDownloadFolder
{
    _baseDownloadFolder = baseDownloadFolder;
    [downloadManager downloadManagerConfig];

}


@end
