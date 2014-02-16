//
//  VWHTTPClientConstants.h
//  VWHTTPClient
//
//  Created by Sayan Chatterjee on 16/02/14.
//  Copyright (c) 2014 VaporWare Solutions. All rights reserved.
//

#ifndef VWHTTPClientConstants_h
#define VWHTTPClientConstants_h

typedef NS_ENUM(NSInteger, FileFetchingStatus) {
    FetchingNone,
    FetchingPreviousFile,
    FetchingNextFile
} ;


typedef NS_ENUM(NSInteger, DownloadingFileStatus) {
    NoActionYet = 0,
    ReadyForConversion,
    ConversionStart,
    ConversionDone,
    ConversionFailed,
    ReadyForPropertyFetching,
    PropertyFetchingStart,
    PropertyFetchingDone,
    PropertyFetchFailed,
    ConversionStatusNone = NSIntegerMax
};


#endif
