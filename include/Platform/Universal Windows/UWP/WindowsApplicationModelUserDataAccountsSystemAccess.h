//******************************************************************************
//
// Copyright (c) 2015 Microsoft Corporation. All rights reserved.
//
// This code is licensed under the MIT License (MIT).
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//******************************************************************************

// WindowsApplicationModelUserDataAccountsSystemAccess.h
// Generated from winmd2objc

#pragma once

#include <UWP/interopBase.h>

@class WAUSDeviceAccountConfiguration, WAUSUserDataAccountSystemAccessManager;
@protocol WAUSIDeviceAccountConfiguration
, WAUSIUserDataAccountSystemAccessManagerStatics;

// Windows.ApplicationModel.UserDataAccounts.SystemAccess.DeviceAccountServerType
enum _WAUSDeviceAccountServerType {
    WAUSDeviceAccountServerTypeExchange = 0,
    WAUSDeviceAccountServerTypePop = 1,
    WAUSDeviceAccountServerTypeImap = 2,
};
typedef unsigned WAUSDeviceAccountServerType;

#import <Foundation/Foundation.h>

// Windows.ApplicationModel.UserDataAccounts.SystemAccess.DeviceAccountConfiguration
#ifndef __WAUSDeviceAccountConfiguration_DEFINED__
#define __WAUSDeviceAccountConfiguration_DEFINED__

WINRT_EXPORT
@interface WAUSDeviceAccountConfiguration : RTObject
+ (instancetype)make ACTIVATOR;
@property (retain) NSString* incomingServerAddress;
@property (retain) NSString* incomingServerUsername;
@property (retain) NSString* emailAddress;
@property (retain) NSString* accountName;
@property (retain) NSString* deviceAccountTypeId;
@property BOOL calendarSyncEnabled;
@property (retain) NSString* domain;
@property int incomingServerPort;
@property WAUSDeviceAccountServerType serverType;
@property (retain) NSString* outgoingServerUsername;
@property BOOL contactsSyncEnabled;
@property BOOL outgoingServerRequiresSsl;
@property int outgoingServerPort;
@property (retain) NSString* outgoingServerAddress;
@property BOOL emailSyncEnabled;
@property BOOL incomingServerRequiresSsl;
@end

#endif // __WAUSDeviceAccountConfiguration_DEFINED__

// Windows.ApplicationModel.UserDataAccounts.SystemAccess.UserDataAccountSystemAccessManager
#ifndef __WAUSUserDataAccountSystemAccessManager_DEFINED__
#define __WAUSUserDataAccountSystemAccessManager_DEFINED__

WINRT_EXPORT
@interface WAUSUserDataAccountSystemAccessManager : RTObject
+ (void)addAndShowDeviceAccountsAsync:(id<NSFastEnumeration> /* WAUSDeviceAccountConfiguration* */)accounts
                              success:(void (^)(NSArray* /* NSString * */))success
                              failure:(void (^)(NSError*))failure;
@end

#endif // __WAUSUserDataAccountSystemAccessManager_DEFINED__
