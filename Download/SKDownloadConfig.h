//
//  SKDownloadConfig.h
//  DownloadTest
//
//  Created by 韦健 on 15/7/31.
//  Copyright (c) 2015年 韦健. All rights reserved.
//
//  配置文件

#ifndef DownloadTest_SKDownloadConfig_h
#define DownloadTest_SKDownloadConfig_h

/** 下载文件存储文件夹 */
#define baseFolder [SKDownloadHelper getBaseDownloadFolder]

/** 下载未完成文件存储文件夹*/
#define tempFolder @"Temp"

/** 下载完成文件存储文件夹 */
#define finishFolder @"Finish"

/** 下载完成文件plist文件名*/
#define finishPlist @"finishPlist.plist"

#endif
