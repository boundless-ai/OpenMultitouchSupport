//
//  OpenMTDevice.h
//  OpenMultitouchSupport
//
//  Created by Guillaume Robin on 16/06/2022.
//  Copyright © 2022 Guillaume Robin. All rights reserved.
//
#ifndef OpenMTDevice_h
#define OpenMTDevice_h

#import <Foundation/Foundation.h>

@interface OpenMTDevice: NSObject

@property id deviceId;
@property int type;
@property uint64_t deviceID;
@property int familyID;
// Surface Dimensions
@property int width, height;
// Sensor Dimensions
@property int rows, cols;
@property bool isOpaque;
@property bool isError;

- (id) init;

@end

@interface OpenMTDevicePublic: NSObject

@property int type;
@property uint64_t deviceID;
@property int familyID;
// Surface Dimensions
@property int width, height;
// Sensor Dimensions
@property int rows, cols;
@property bool isOpaque;
@property bool isError;

- (id) initFromDevice:(OpenMTDevice *)device;

@end

#endif /* OpenMTDevice_h */
