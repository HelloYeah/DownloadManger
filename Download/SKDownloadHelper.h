//
//  SKDownloadHelper.h
//  DownloadTest
//
//  Created by 韦健 on 15/7/31.
//  Copyright (c) 2015年 韦健. All rights reserved.
//
//  帮助类

#import <Foundation/Foundation.h>

@interface SKDownloadHelper : NSObject

/** 获取下载存储文件夹 */
+ (NSString *)getBaseDownloadFolder;

/** 未下载完成文件存储文件夹的路径；返回nil表示文件夹创建失败 */
+ (NSString *)getTempFolderPath;

/** 未下载完成文件夹Plist文件数组 */
+ (NSArray *)getTempFolderPlistFiles;

/** 未下载完成文件大小 */
+ (NSUInteger)getTempFileSize:(NSString *)path;

/** 下载完成文件存储文件夹的路径；返回nil表示文件夹创建失败 */
+ (NSString *)getFinishFolderPath;

/** 下载完成文件plist文件路径; 返回nil表示plist文件创建失败 */
+ (NSString *)getFinishPlistPath;

/** 文件是否存在 */
+ (BOOL)isExistingFileAtPath:(NSString *)path;

/** 删除文件 */
+ (BOOL)deleteFileAtPath:(NSString *)path;

/** 移动文件 */
+ (BOOL)moveFileAtPath:(NSString *)path toPath:(NSString *)toPath;

/** 当前时间*/
+ (NSDate *)currentDate;

/** 时间转字符  */
+ (NSString *)dateToString:(NSDate *)date withFormat:(NSString *)format;

/** 字符转时间 格式“yyyy-MM-dd HH:mm:ss” */
+ (NSDate *)stringToDate:(NSString *)dateStr;

/** 将文件大小转化成M单位或者B单位 */
+ (NSString *)getFileSizeString:(NSString *)size;

/** 将文件大小转化成M单位 */
+ (NSString *)getFileMSizeString:(NSString *)size;

/** 将文件大下载速度 B/S K/S M/S */
+ (NSString *)getDownloadSpeed:(NSString *)speed;

@end
