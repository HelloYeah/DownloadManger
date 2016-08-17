//
//  SKDownloadFile.h
//  DownloadTest
//
//  Created by 韦健 on 15/7/31.
//  Copyright (c) 2015年 韦健. All rights reserved.
//
//  下载文件模型

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/** 下载状态 */
typedef NS_ENUM(NSInteger, SKDownloadStatus) {
    SKDownloadStatusWait = 0, // 等待下载
    SKDownloadStatusDownloading, // 正在下载
    SKDownloadStatusPause, // 下载暂停
    SKDownloadStatusFinish, // 下载完成
    SKDownloadStatusError, // 下载出错
};

@interface SKDownloadFile : NSObject


/** 当前资料私密等级 */
@property (nonatomic, assign) DataLevelType dataLevel;
/** 文件id */
@property(nonatomic, copy) NSString *fileID;
/** 文件名 */
@property(nonatomic, copy) NSString *name;
/** 文件后缀 */
@property(nonatomic, copy) NSString *suffix;
/** 文件大小 */
@property(nonatomic, copy) NSString *totalSize;
/** 已下载大小 */
@property(nonatomic, copy) NSString *receivedSize;
/** 下载进度 */
@property(nonatomic, assign) CGFloat progress;
/** 下载速度 */
@property(nonatomic, copy) NSString *speed;
/** 下载地址 */
@property(nonatomic, copy) NSString *downloadURL;
/** 点击下载时间 */
@property(nonatomic, strong) NSDate *downloadTime;
/** 计算下载速度用 */
@property(nonatomic, strong) NSDate *speedDownloadTime;
/** 下载完成文件存储路径 */
@property(nonatomic, copy) NSString *finishPath;
/** 下载未完成文件存储路径 */
@property(nonatomic, copy) NSString *tempPath;
/** 下载状态 */
@property(nonatomic, assign) SKDownloadStatus downloadStatus;
/** 下载错误 */
@property(nonatomic, strong) NSError *error;

@end




