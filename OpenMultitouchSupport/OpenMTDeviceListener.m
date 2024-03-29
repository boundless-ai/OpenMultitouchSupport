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
@property (assign, nonatomic) NSTimeInterval debounceInterval;

@property (weak, nonatomic) id target;
@property (assign, nonatomic) SEL selector;

@property (assign, nonatomic) IONotificationPortRef notificationPort;

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

- (void)startListeningWithTarget:(id)target selector:(SEL)selector {
    self.target = target;
    self.selector = selector;

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
    
    // Get a reference to the I/O Kit's master port
    self.notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
    CFRunLoopSourceRef runLoopSource = IONotificationPortGetRunLoopSource(self.notificationPort);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
    
    // Register for notifications
    io_iterator_t usbDeviceAddedIterator;
    kern_return_t usbKR = IOServiceAddMatchingNotification(self.notificationPort,
                                                        kIOMatchedNotification,
                                                        usbDeviceMatchingDict,
                                                        handleDeviceConnected, // Callback function
                                                        (__bridge void *)(self), // Context
                                                        &usbDeviceAddedIterator);
    if (usbKR != KERN_SUCCESS) {
        NSLog(@"Failed to register for device added notifications");
        return;
    }
    
    io_iterator_t bthDeviceAddedIterator;
    kern_return_t bthKR = IOServiceAddMatchingNotification(self.notificationPort,
                                                        kIOMatchedNotification,
                                                        bthDeviceMatchingDict,
                                                        handleDeviceConnected, // Callback function
                                                        (__bridge void *)(self), // Context
                                                        &bthDeviceAddedIterator);
    if (bthKR != KERN_SUCCESS) {
        NSLog(@"Failed to register for device added notifications");
        return;
    }
    
    handleDeviceConnected(NULL, usbDeviceAddedIterator);
    handleDeviceConnected(NULL, bthDeviceAddedIterator);
}

- (void)stopListening {
    if (self.notificationPort) {
        CFRunLoopSourceRef runLoopSource = IONotificationPortGetRunLoopSource(self.notificationPort);
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);

        IONotificationPortDestroy(self.notificationPort);
        self.notificationPort = NULL;
    }

    self.target = nil;
    self.selector = NULL;
}

void handleDeviceConnected(void *refcon, io_iterator_t iterator) {
    io_service_t device;
    while ((device = IOIteratorNext(iterator))) {
        IOObjectRelease(device);
    }

    OpenMTDeviceListener *listener = (__bridge OpenMTDeviceListener *)refcon;
    if (listener == nil) { return; }

    NSDate *currentDate = [NSDate date];
    bool isValidEvent = (listener.lastNotificationDate == nil ||
                         [currentDate timeIntervalSinceDate:listener.lastNotificationDate] > listener.debounceInterval);

    if (!isValidEvent) { return; }

    listener.lastNotificationDate = currentDate;

    id target = listener.target;
    SEL selector = listener.selector;

    if (!target) { return; }

    ((void(*)(id, SEL))[target methodForSelector:selector])(target, selector);
}

@end
