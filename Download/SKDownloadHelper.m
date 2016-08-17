//
//  SKDownloadHelper.m
//  DownloadTest
//
//  Created by 韦健 on 15/7/31.
//  Copyright (c) 2015年 韦健. All rights reserved.
//

#import "SKDownloadHelper.h"
#import "SKDownloadConfig.h"
#import "SKDownloadManager.h"

@implementation SKDownloadHelper

#pragma mark - private method
#pragma mark 取得Documents路径
+ (NSString *)getDocumentPath
{
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}

#pragma mark - public method
+ (NSString *)getBaseDownloadFolder
{
    return [SKDownloadManager downloadManager].baseDownloadFolder;
}

+ (NSString *)getTempFolderPath
{
    NSString *documentPath = [[self class] getDocumentPath];
    NSString *baseFolderPath = [documentPath stringByAppendingPathComponent:baseFolder];
    NSString *tempFolderPath =  [baseFolderPath stringByAppendingPathComponent:tempFolder];
    NSFileManager *fileManager=[NSFileManager defaultManager];
    NSError *error;
    if(![fileManager fileExistsAtPath:tempFolderPath]) {
        [fileManager createDirectoryAtPath:tempFolderPath withIntermediateDirectories:YES attributes:nil error:&error];
        if(error) { // 创建失败
            return nil;
        }
    }
    return tempFolderPath;
}

+ (NSArray *)getTempFolderPlistFiles
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:[[self class] getTempFolderPath] error:&error];
    
    NSMutableArray *plistFileList = [NSMutableArray array];
    for (NSString *file in fileList) {
        NSString *fileType = [file  pathExtension];
        if([fileType isEqualToString:@"plist"]) {
            [plistFileList addObject:[[[self class] getTempFolderPath] stringByAppendingPathComponent:file]];
        }
    }
    
    return plistFileList;
}

+ (NSUInteger)getTempFileSize:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSData *fileData = [fileManager contentsAtPath:path];
    
    return [fileData length];
}

+ (NSString *)getFinishFolderPath
{
    NSString *documentPath = [[self class] getDocumentPath];
    NSString *baseFolderPath = [documentPath stringByAppendingPathComponent:baseFolder];
    NSString *finishFolderPath =  [baseFolderPath stringByAppendingPathComponent:finishFolder];
    NSFileManager *fileManager=[NSFileManager defaultManager];
    NSError *error;
    if(![fileManager fileExistsAtPath:finishFolderPath]) {
        [fileManager createDirectoryAtPath:finishFolderPath withIntermediateDirectories:YES attributes:nil error:&error];
        if(error) {
            return nil;
        }
    }
    return finishFolderPath;
}

+ (NSString *)getFinishPlistPath
{
    NSString *finishFolderPath =  [[self class] getFinishFolderPath];
    NSString *finishPlistPath = [finishFolderPath stringByAppendingPathComponent:finishPlist];
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:finishPlistPath]) {
        if (![@[] writeToFile:finishPlistPath atomically:NO]) { // 写文件失败
            return nil;
        }
    }
    
    return finishPlistPath;
}

+ (BOOL)isExistingFileAtPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path];
}

+ (BOOL)deleteFileAtPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager removeItemAtPath:path error:nil];
}

+ (BOOL)moveFileAtPath:(NSString *)path toPath:(NSString *)toPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager moveItemAtPath:path toPath:toPath error:nil];
}

+ (NSDate *)currentDate
{
    NSDate *date = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate:date];
    NSDate *currentDate = [date  dateByAddingTimeInterval:interval];
    
    return currentDate;
}

+ (NSString *)dateToString:(NSDate *)date withFormat:(NSString *)format
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:format];
    
    return [dateFormatter stringFromDate:date];
}

+ (NSDate *)stringToDate:(NSString *)dateStr
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    return [dateFormatter dateFromString:dateStr];
}


+ (NSString *)getFileSizeString:(NSString *)size
{
    if([size floatValue] >= 1024 * 999) {
        // 大于999K，则转化成M单位的字符串
        return [NSString stringWithFormat:@"%1.1fM", [size floatValue] / 1024 / 1024];
    } else if([size floatValue] >= 999 && [size floatValue] < 1024 * 999) {
        // 不到999K,但是超过了1KB，则转化成KB单位
        return [NSString stringWithFormat:@"%1.1fK", [size floatValue] / 1024];
    } else {
        // 剩下的都是小于1K的，则转化成B单位
        return [NSString stringWithFormat:@"%1.1fB", [size floatValue]];
    }
}

+ (NSString *)getFileMSizeString:(NSString *)size
{
    return [NSString stringWithFormat:@"%1.1fM", [size floatValue] / 1024 / 1024];
}

+ (NSString *)getDownloadSpeed:(NSString *)speed
{
    if([speed floatValue] >= 1024 * 999) {
        // 大于999K，则转化成M单位的字符串
        return [NSString stringWithFormat:@"%1.1fM/S", [speed floatValue] / 1024 / 1024];
    } else if([speed floatValue] >= 999 && [speed floatValue] < 1024 * 999) {
        // 不到999K,但是超过了1KB，则转化成KB单位
        return [NSString stringWithFormat:@"%1.0fK/S", [speed floatValue] / 1024];
    } else {
        // 剩下的都是小于1K的，则转化成B单位
        return [NSString stringWithFormat:@"%1.0fB/S", [speed floatValue]];
    }
}







@end
