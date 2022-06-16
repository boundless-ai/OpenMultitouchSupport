//
//  OpenMTDevice.m
//  OpenMultitouchSupport
//
//  Created by Guillaume Robin on 16/06/2022.
//  Copyright © 2022 Guillaume Robin. All rights reserved.
//
#import "OpenMTDevice.h"

@implementation OpenMTDevice

- (id) init
{
    if (self = [super init]) {
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Device ID: %llu, Driver type: %d, Family ID: %d, Width: %d, Height: %d, Rows: %d, Cols: %d, Opaque: %s, Error: %s", self.deviceID, self.type, self.familyID, self.width, self.height, self.rows, self.cols, self.isOpaque ? "true" : "false", self.isError ? "true" : "false"];
}

@end

@implementation OpenMTDevicePublic

- (id) initFromDevice:(OpenMTDevice *)device
{
    if (self = [super init]) {
        self.type = device.type;
        self.deviceID = device.deviceID;
        self.familyID = device.familyID;
        self.width = device.width;
        self.height = device.height;
        self.rows = device.rows;
        self.cols = device.cols;
        self.isOpaque = device.isOpaque;
        self.isError = device.isError;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Device ID: %llu, Driver type: %d, Family ID: %d, Width: %d, Height: %d, Rows: %d, Cols: %d, Opaque: %s, Error: %s", self.deviceID, self.type, self.familyID, self.width, self.height, self.rows, self.cols, self.isOpaque ? "true" : "false", self.isError ? "true" : "false"];
}

@end
