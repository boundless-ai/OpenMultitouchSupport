//
//  OpenMTEvent.m
//  OpenMultitouchSupport
//
//  Created by Guillaume Robin on 16/06/2022.
//  Copyright © 2022 Guillaume Robin. All rights reserved.
//

#import "OpenMTEventInternal.h"

@implementation OpenMTEvent

- (NSString *)description {
    return [NSString stringWithFormat:@"Touches: %@, Device ID: %i, Frame ID: %i, Timestamp: %f, Device: %@", _touches.description, _deviceID, _frameID, _timestamp, _device.description];
}

@end

