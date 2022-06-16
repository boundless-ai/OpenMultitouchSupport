//
//  OpenMTEvent.h
//  OpenMultitouchSupport
//
//  Created by Guillaume Robin on 16/06/2022.
//  Copyright © 2022 Guillaume Robin. All rights reserved.
//

#ifndef OpenMTEvent_h
#define OpenMTEvent_h

#import <Foundation/Foundation.h>
#import "OpenMTDevice.h"

@interface OpenMTEvent: NSObject

@property (strong, readonly) NSArray *touches;
@property (assign, readonly) int deviceID;
@property (assign, readonly) int frameID;
@property (assign, readonly) double timestamp;
@property (strong, readonly) OpenMTDevicePublic *device;

@end

typedef void (^OpenMTEventCallback)(OpenMTEvent *event);

#endif /* OpenMTEvent_h */
