//
//  OpenMTDeviceListenerInternal.h
//
//
//  Created by Ronith Kandallu on 3/28/24.
//

#ifndef OpenMTDeviceListenerInternal_h
#define OpenMTDeviceListenerInternal_h

#import "OpenMTDeviceListener.h"

@interface OpenMTDeviceListener()

+ (instancetype)shared;

- (void)startListeningWithTarget:(id)target selector:(SEL)selector;
- (void)stopListening;

@end

#endif /* OpenMTDeviceListenerInternal_h */
