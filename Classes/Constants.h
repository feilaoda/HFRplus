//
//  Constants.h
//  HFRplus
//
//  Created by FLK on 05/08/10.
//

#import <Foundation/Foundation.h>
#import "UITableViewController+Ext.h"
#import "NSDictionary+Merging.h"
#import "HFRNavigationController.h"

#define NSLog(__FORMAT__, ...) TFLog((@"%s [Line %d] " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

static const NSInteger kDispatchPeriodSeconds = 20;

typedef enum {
	kIdle,
	kMaintenance,
	kNoResults,
    kNoAuth,
	kComplete
} STATUS;

#define kForumURL				@"http://forum.hardware.fr"

#define kTimeoutMini		30
#define kTimeoutMaxi		60
#define kTimeoutAvatar      10

#define MAX_HEIGHT 1200.0f 
#define MAX_CELL_CONTENT 300.0f
#define MAX_TEXT_WIDTH 250.0f

#ifndef DEBUG_LOGS
	#define DEBUG_LOGS 0
#endif

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define kNewMessageFromUpdate   1
#define kNewMessageFromShake    2
#define kNewMessageFromEditor   3
#define kNewMessageFromUnkwn    4