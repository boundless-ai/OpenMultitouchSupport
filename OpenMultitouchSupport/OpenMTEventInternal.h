//
//  OpenMTDevice.h
//  OpenMultitouchSupport
//
//  Created by Guillaume Robin on 16/06/2022.
//  Copyright © 2022 Guillaume Robin. All rights reserved.
//

#ifndef OpenMTEventInternal_h
#define OpenMTEventInternal_h

#import "OpenMTEvent.h"
#import "OpenMTDevice.h"

@interface OpenMTEvent()

@property (strong, readwrite) NSArray *touches;
@property (assign, readwrite) int deviceID;
@property (assign, readwrite) int frameID;
@property (assign, readwrite) double timestamp;
@property (strong, readwrite) OpenMTDevicePublic *device;

@end

#endif /* OpenMTEventInternal_h */
