//
//  SimulatorChecker.h
//  Sign3Intelligence
//
//  Created by Ashish Gupta on 10/09/24.
//

#include <sys/socket.h>
#include <ifaddrs.h>
#include <net/if_dl.h>
#include <net/if_types.h>
#import <sys/stat.h>
#include <mach-o/dyld.h>

@interface SimulatorChecker : NSObject

- (BOOL)isSimulator;

@end

@interface JailBrokenChecker : NSObject

- (BOOL)isJailBroken;

@end

@interface DeviceSignalsApiImplObjC : NSObject

- (NSString *)getMacAddress;
- (NSString *)getIPhoneBluetoothMacAddress;
- (NSString *)getIPadBluetoothMacAddress;

@end

/// Runs a Swift closure inside an ObjC `@try/@catch`.
///
/// Swift cannot catch an `NSException` — a UIKit internal assert, a KVC failure, an
/// `NSInvalidArgumentException`, etc. thrown while our behavioural code runs *inside the host app's
/// call stack* (a swizzled `sendEvent`, a text notification, a clipboard action) would unwind
/// straight through the host and crash it. This shim is the only place that can stop that: it
/// swallows the exception and reports it, so an unexpected fault degrades to a no-op instead of
/// taking the client app down.
///
/// Returns `nil` on success, or a short "name: reason" string when an exception was caught, so the
/// caller can log it and feed the fault circuit-breaker. NEVER rethrows.
@interface Sign3ExceptionGuard : NSObject

+ (nullable NSString *)perform:(void (NS_NOESCAPE ^)(void))block;

@end

//#endif /* SimulatorChecker_h */
