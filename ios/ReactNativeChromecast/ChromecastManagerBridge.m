//
//  ChromecastManagerBridge.m
//  ReactNativeChromecast
//
//  Created by Albert Fernández on 10/10/15.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTEventDispatcher.h"
#import "RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(ChromecastManager, NSObject)

RCT_EXTERN_METHOD(startScan)
RCT_EXTERN_METHOD(stopScan)

RCT_EXTERN_METHOD(connectToDevice: (NSString *) deviceName)
RCT_EXTERN_METHOD(disconnect)

RCT_EXTERN_METHOD(castVideo: (NSString *) videoUrl title: (NSString *) title description: (NSString *) description imageUrl: (NSString *) imageUrl)

RCT_EXTERN_METHOD(play)
RCT_EXTERN_METHOD(pause)

RCT_EXTERN_METHOD(getStreamPosition: (RCTResponseSenderBlock *) successCallback)

@end