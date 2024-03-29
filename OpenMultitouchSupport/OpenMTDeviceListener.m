//
//  OpenMTDeviceListener.m
//
//
//  Created by Ronith Kandallu on 3/28/24.
//


#import "OpenMTDeviceListenerInternal.h"

#import <IOKit/IOKitLib.h>
#import <IOKit/IOMessage.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/hid/IOHIDManager.h>
#import <IOKit/hid/IOHIDKeys.h>


@interface OpenMTDeviceListener()

@property (strong, nonatomic) NSDate *lastNotificationDate;
@property (nonatomic, assign) NSTimeInterval debounceInterval;

@end

@implementation OpenMTDeviceListener

+ (instancetype)shared {
    static OpenMTDeviceListener *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _debounceInterval = 1.0;
    }
    return self;
}

- (void)startListening{
    NSLog(@"started listening"); // Debug
    
    CFMutableDictionaryRef usbDeviceMatchingDict = IOServiceMatching(kIOUSBDeviceClassName);
    if (!usbDeviceMatchingDict) {
        NSLog(@"Failed to create matching dictionary");
        return;
    }
    
    CFMutableDictionaryRef bthDeviceMatchingDict = IOServiceMatching(kIOHIDDeviceKey);
    if (!bthDeviceMatchingDict) {
        NSLog(@"Failed to create matching dictionary");
        return;
    }
    
    NSLog(@"created dictionaries"); // Debug

    // Get a reference to the I/O Kit's master port
    IONotificationPortRef notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
    CFRunLoopSourceRef runLoopSource = IONotificationPortGetRunLoopSource(notificationPort);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
    
    // Register for notifications
    io_iterator_t usbDeviceAddedIterator;
    kern_return_t usbKR = IOServiceAddMatchingNotification(notificationPort,
                                                        kIOMatchedNotification,
                                                        usbDeviceMatchingDict,
                                                        handleDeviceConnected, // Callback function
                                                        (__bridge void *)(self), // Context
                                                        &usbDeviceAddedIterator);
    if (usbKR != KERN_SUCCESS) {
        NSLog(@"Failed to register for device added notifications");
        return;
    }
    
    NSLog(@"registered USB notification"); // Debug

    io_iterator_t bthDeviceAddedIterator;
    kern_return_t bthKR = IOServiceAddMatchingNotification(notificationPort,
                                                        kIOMatchedNotification,
                                                        bthDeviceMatchingDict,
                                                        handleDeviceConnected, // Callback function
                                                        (__bridge void *)(self), // Context
                                                        &bthDeviceAddedIterator);
    if (bthKR != KERN_SUCCESS) {
        NSLog(@"Failed to register for device added notifications");
        return;
    }
    
    NSLog(@"registered BTH notification"); // Debug
    
    handleDeviceConnected(NULL, bthDeviceAddedIterator);
}

- (void)stopListening{
    
}

void handleDeviceConnected(void *refcon, io_iterator_t iterator) {
    NSLog(@"device connected!!!");
    io_service_t device;
    while ((device = IOIteratorNext(iterator))) {
        // It's important to release the device object when you're done with it
        IOObjectRelease(device);
    }
}

@end
