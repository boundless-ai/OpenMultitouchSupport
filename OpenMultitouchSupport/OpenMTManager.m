//
//  OpenMTManager.m
//  OpenMultitouchSupport
//
//  Created by Guillaume Robin on 16/06/2022.
//  Copyright © 2022 Guillaume Robin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "OpenMTManagerInternal.h"
#import "OpenMTListenerInternal.h"
#import "OpenMTTouchInternal.h"
#import "OpenMTEventInternal.h"
#import "OpenMTInternal.h"
#import "OpenMTDevice.h"
#import "OpenMTDeviceListenerInternal.h"

@interface OpenMTManager()

@property (strong, readwrite) NSMutableArray *listeners;
@property (strong, readwrite) NSMutableArray *multitouchDevices;
//@property (assign, readwrite) MTDeviceRef device;

@end

@implementation OpenMTManager

+ (BOOL)systemSupportsMultitouch {
    return MTDeviceIsAvailable();
}

+ (OpenMTManager *)sharedManager {
    static OpenMTManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = self.new;
    });
    return sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        self.listeners = NSMutableArray.new;
        self.multitouchDevices = NSMutableArray.new;
        
        [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self selector:@selector(willSleep:) name:NSWorkspaceWillSleepNotification object:nil];
        [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self selector:@selector(didWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
    }
    return self;
}

- (void)makeDevices {
    if (MTDeviceIsAvailable()) {
//        self.device = MTDeviceCreateDefault();
        
        NSArray *mtDevices = (NSArray *)CFBridgingRelease(MTDeviceCreateList());
        
        int mtDeviceCount = (int)mtDevices.count;
        NSLog(@"Number of touchable devices: %d", mtDeviceCount);
        
        while (--mtDeviceCount >= 0) {
            id deviceId = mtDevices[mtDeviceCount];
            MTDeviceRef device = (__bridge MTDeviceRef)mtDevices[mtDeviceCount];
            
            uuid_t guid;
            OSStatus err = MTDeviceGetGUID(device, &guid);
            if (!err) {
                uuid_string_t val;
                uuid_unparse(guid, val);
                NSLog(@"GUID: %s", val);
            }
            
            int type;
            err = MTDeviceGetDriverType(device, &type);
            //if (!err) NSLog(@"Driver Type: %d", type);
            
            uint64_t deviceID;
            err = MTDeviceGetDeviceID(device, &deviceID);
            //if (!err) NSLog(@"DeviceID: %llu", deviceID);
            
            int familyID;
            err = MTDeviceGetFamilyID(device, &familyID);
            //if (!err) NSLog(@"FamilyID: %d", familyID);
            
            int width, height;
            err = MTDeviceGetSensorSurfaceDimensions(device, &width, &height);
            //if (!err) NSLog(@"Surface Dimensions: %d x %d ", width, height);
            
            int rows, cols;
            err = MTDeviceGetSensorDimensions(device, &rows, &cols);
            //if (!err) NSLog(@"Dimensions: %d x %d ", rows, cols);
            
            bool isOpaque = MTDeviceIsOpaqueSurface(device);
            //NSLog(isOpaque ? @"Opaque: true" : @"Opaque: false");
            
            // MTPrintImageRegionDescriptors(self.device); work
            
    //        @try {
    //            MTDeviceRef mtDevice = (__bridge MTDeviceRef)device;
    //            MTRegisterContactFrameCallback(mtDevice, mtEventHandler);
    //            MTDeviceStart(mtDevice, 0);
    //        } @catch (NSException *exception) {}
            OpenMTDevice *mtDevice = [[OpenMTDevice alloc] init];
            
            mtDevice.deviceId = deviceId;
            mtDevice.type = type;
            mtDevice.deviceID = deviceID;
            mtDevice.familyID = familyID;
            mtDevice.width = width;
            mtDevice.height = height;
            mtDevice.rows = rows;
            mtDevice.cols = cols;
            mtDevice.isOpaque = isOpaque;
            mtDevice.isError = !!err;
            
            NSLog(@"Device: %@", mtDevice.description);
            
            [self.multitouchDevices addObject:mtDevice];
        }
    }
}

//- (void)handlePathEvent:(OpenMTTouch *)touch {
//    NSLog(@"%@", touch.description);
//}

- (void)handleMultitouchEvent:(OpenMTEvent *)event {
    for (int i = 0; i < (int)self.listeners.count; i++) {
        OpenMTListener *listener = self.listeners[i];
        if (listener.dead) {
            [self removeListener:listener];
            continue;
        }
        if (!listener.listening) {
            continue;
        }
        dispatchResponse(^{
            [listener listenToEvent:event];
        });
    }
}

- (void)startHandlingMultitouchEvents {
    [self makeDevices];
    int mtDeviceCount = (int)self.multitouchDevices.count;
    NSLog(@"Number of touchable devices: %d", mtDeviceCount);
    
    while (--mtDeviceCount >= 0) {
        OpenMTDevice *mtDevice = self.multitouchDevices[mtDeviceCount];
        id deviceId = mtDevice.deviceId;
        MTDeviceRef device = (__bridge MTDeviceRef)deviceId;
        @try {
            MTRegisterContactFrameCallback(device, contactEventHandler); // work
            // MTEasyInstallPrintCallbacks(self.device, YES, NO, NO, NO, NO, NO); // work
            // MTRegisterPathCallback(self.device, pathEventHandler); // work
            // MTRegisterMultitouchImageCallback(self.device, MTImagePrintCallback); // not work
            MTDeviceStart(device, 0);
        } @catch (NSException *exception) {
            NSLog(@"Failed Start Handling Multitouch Events");
        }
    }
    
    [[OpenMTDeviceListener shared] startListeningWithTarget:self selector:@selector(deviceConnectedHandler)];

    return;
}

- (void)deviceConnectedHandler {
    NSLog(@"New device connected!!!!!!!!!!!!");
}

- (void)stopHandlingMultitouchEvents {
    int mtDeviceCount = (int)self.multitouchDevices.count;
    NSLog(@"Number of touchable devices: %d", mtDeviceCount);
    
    while (--mtDeviceCount >= 0) {
        OpenMTDevice *mtDevice = self.multitouchDevices[mtDeviceCount];
        id deviceId = mtDevice.deviceId;
        MTDeviceRef device = (__bridge MTDeviceRef)deviceId;
        [self.multitouchDevices removeObject:mtDevice];

        if (!MTDeviceIsRunning(device)) { return; }

        @try {
            MTUnregisterContactFrameCallback(device, contactEventHandler); // work
            // MTUnregisterPathCallback(self.device, pathEventHandler); // work
            // MTUnregisterImageCallback(self.device, MTImagePrintCallback); // not work
            MTDeviceStop(device);
            // MTDeviceRelease(device); // Cause a crash when waking-up from sleep
            device = NULL;
        } @catch (NSException *exception) {
            NSLog(@"Failed Stop Handling Multitouch Events");
        }
    }
}

- (void)willSleep:(NSNotification *)note {
    dispatchSync(dispatch_get_main_queue(), ^{
        [self stopHandlingMultitouchEvents];
    });
}

- (void)didWakeUp:(NSNotification *)note {
    dispatchSync(dispatch_get_main_queue(), ^{
        [self startHandlingMultitouchEvents];
    });
}

// Public Function
- (OpenMTListener *)addListenerWithTarget:(id)target selector:(SEL)selector {
    __block OpenMTListener *listener = nil;
    dispatchSync(dispatch_get_main_queue(), ^{
        if (!self.class.systemSupportsMultitouch) { return; }
        listener = [[OpenMTListener alloc] initWithTarget:target selector:selector];
        if (self.listeners.count == 0) {
            [self startHandlingMultitouchEvents];
        }
        [self.listeners addObject:listener];
    });
    return listener;
}

- (void)removeListener:(OpenMTListener *)listener {
    dispatchSync(dispatch_get_main_queue(), ^{
        [self.listeners removeObject:listener];
        if (self.listeners.count == 0) {
            [self stopHandlingMultitouchEvents];
        }
    });
}

// Utility Tools C Language
static void dispatchSync(dispatch_queue_t queue, dispatch_block_t block) {
    if (!strcmp(dispatch_queue_get_label(queue), dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))) {
        block();
        return;
    }
    dispatch_sync(queue, block);
}

static void dispatchResponse(dispatch_block_t block) {
    static dispatch_queue_t responseQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        responseQueue = dispatch_queue_create("com.kyome.openmt", DISPATCH_QUEUE_SERIAL);
    });
    dispatch_sync(responseQueue, block);
}

static void contactEventHandler(MTDeviceRef eventDevice, MTTouch eventTouches[], int numTouches, double timestamp, int frame) {
    NSMutableArray *touches = [NSMutableArray array];
    
    for (int i = 0; i < numTouches; i++) {
        OpenMTTouch *touch = [[OpenMTTouch alloc] initWithMTTouch:&eventTouches[i]];
        [touches addObject:touch];
    }
    
    int n = 0;
    while (n < OpenMTManager.sharedManager.multitouchDevices.count) {
        OpenMTDevice *device = OpenMTManager.sharedManager.multitouchDevices[n];
        if (device.deviceId == eventDevice) {
            break;
        }
        n++;
    }
    
    OpenMTEvent *event = OpenMTEvent.new;
    event.touches = touches;
    event.deviceID = (int)eventDevice;
    event.frameID = frame;
    event.timestamp = timestamp;
    
    if (n < OpenMTManager.sharedManager.multitouchDevices.count) {
        OpenMTDevicePublic *pDevice = [[OpenMTDevicePublic alloc] initFromDevice:OpenMTManager.sharedManager.multitouchDevices[n]];
        event.device = pDevice;
    } else {
        event.device = nil;
    }
    
    
    [OpenMTManager.sharedManager handleMultitouchEvent:event];
}

//static void pathEventHandler(MTDeviceRef device, long pathID, long state, MTTouch* touch) {
//    OpenMTTouch *otouch = [[OpenMTTouch alloc] initWithMTTouch:touch];
//    [OpenMTManager.sharedManager handlePathEvent:otouch];
//}

@end
