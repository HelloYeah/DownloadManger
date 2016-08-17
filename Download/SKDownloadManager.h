//
//  SKDownloadManager.h
//  DownloadTest
//
//  Created by 韦健 on 15/7/31.
//  Copyright (c) 2015年 韦健. All rights reserved.
//
//  下载管理器，基于AFNetworking

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "SKDownloadConfig.h"
#import "SKDownloadHelper.h"
#import "SKDownloadFile.h"

/** 文件状态 */
typedef NS_ENUM(NSInteger, SKFileStauts) {
    SKFileStautsNone, // 未添加
    SKFileStautsAddSuccess, // 添加到下载队列成功
    SKFileStautsAddFail, // 添加到下载队列失败
    SKFileStautsDownloading, // 已经添加到下载队列，不能再次添加
    SKFileStautsFinish, // 已经下载完成，不能添加
};


/** AFHTTPRequestOperation.userInfo 文件模型对应键 */
extern NSString *const SKOperationUserInfoFileKey;

/** 开始下载通知 */
extern NSString *const SKDownloadStartNotification;
/** 正在下载通知 */
extern NSString *const SKDownloadingNotification;
/** 取消下载通知 */
extern NSString *const SKDownloadCancelNotification;
/** 下载成功通知 */
extern NSString *const SKDownloadSuccessNotification;
/** 下载失败通知 */
extern NSString *const SKDownloadFailureNotification;
/** 服务器校验错误通知 */
extern NSString *const SKDownloadVerifyErrorNotification;
/** 开始下载保密文件的通知 */
extern NSString *const SKDownloadSerctFileNotification;

@interface SKDownloadManager : NSObject

/** 必须先设置下载文件夹 */
@property(nonatomic, copy) NSString *baseDownloadFolder;
/** 下载完成的文件列表（SKDownloadFile对象） */
@property(nonatomic, strong) NSMutableArray *finishList;
/** 下载未完成的文件列表（SKDownloadFile对象） */
@property(nonatomic, strong) NSMutableArray *tempList;
/** 下载请求对象（AFHTTPRequestOperation对象，与tempList一一对应） */
@property(nonatomic, strong) NSMutableArray *downloadingList;

/**
 *  初始化
 *
 *  @return 对象
 */
+ (instancetype)downloadManager;

/**
 *  下载文件
 *
 *  @param url      文件下载地址
 *  @param fileId 文件id（根据文件id判断文件下载唯一性，下载的文件都是以文件id命名）
 *  @param fileName 文件名
 *  @param fileSuffix 文件后缀
 *  @param isPublic 文件是否公开
 *
 *  @return 文件状态
 */
- (SKFileStauts)downloadFileWithUrl:(NSString *)url
                             fileId:(NSString *)fileId
                           fileName:(NSString *)fileName
                         fileSuffix:(NSString *)fileSuffix
                          isPublic:(BOOL)isPublic;



/**
 *  重新下载 针对下载失败后重新下载
 *
 *  @param requestOperation 下载对象
 *
 *  @return 新的下载对象
 */
- (AFHTTPRequestOperation *)restartWithRequestOperation:(AFHTTPRequestOperation *)requestOperation;

/**
 *  暂停下载
 *
 *  @param requestOperation 下载对象
 */
- (void)pauseWithRequestOperation:(AFHTTPRequestOperation *)requestOperation;

/**
 *  恢复下载
 *
 *  @param requestOperation 下载对象
 */
- (void)resumeWithRequestOperation:(AFHTTPRequestOperation *)requestOperation;

/**
 *  取消下载
 *
 *  @param requestOperation requestOperation
 */
- (void)cancelWithRequestOperation:(AFHTTPRequestOperation *)requestOperation;

/**
 *  暂停所有下载
 */
- (void)pauseAllRequest;

/**
 *  取消所有下载
 */
- (void)cancelAllRequest;

/**
 *  取消内部预览操作
 */
- (void)cancelInsideRequest;

/**
 *  用户退出，清空数据；下次用户登录，可继续下载。
 */
- (void)clearData;

/**
 *  删除对应的下载完成的文件
 *
 *  @param downloadFile 文件模型
 *
 *  @return yes/no
 */
- (BOOL)deleteFinishWithDownloadFile:(SKDownloadFile *)downloadFile;



/**
 *  检测文件状态，是否已下载或在正在下载
 *
 *  @param fileId 文件id
 *
 *  @return 文件状态
 */
- (SKFileStauts)checkFileWithFileId:(NSString *)fileId;


@end
