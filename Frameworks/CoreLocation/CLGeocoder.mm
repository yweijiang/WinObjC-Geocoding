//******************************************************************************
//
// Copyright (c) 2016 Intel Corporation. All rights reserved.
// Copyright (c) 2016 Microsoft Corporation. All rights reserved.
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

#import "Windows.h"
#import <CoreLocation/CLGeocoder.h>
#import <CoreLocation/CLLocation.h>
#import <CoreLocation/CLPlacemark.h>
#import <StubReturn.h>
#import <UWP/WindowsDevicesGeolocation.h>
#import <UWP/WindowsServicesMaps.h>
#import "CLPlacemarkInternal.h"

/**
 * CLLocationManager class extension.
 */
@interface CLGeocoder () {
}

@property (nonatomic, readwrite, getter=isGeocoding) BOOL geocoding;
@end

@implementation CLGeocoder

- (instancetype)init {
    if (self = [super init]) {
        _geocoding = false;
    }

    return self;
}

/**
 @Status Caveat
 @Notes This has not been tested yet as the projections do not work.
*/
- (void)reverseGeocodeLocation:(CLLocation*)location completionHandler:(CLGeocodeCompletionHandler)completionHandler {
    @synchronized(self) {
        if (self.isGeocoding) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nullptr, nullptr); // TODO: Need appropriate error code
            });
        } else {
            self.geocoding = true;

            WDGBasicGeoposition* geoposition = [[WDGBasicGeoposition alloc] init];
            geoposition.latitude = location.coordinate.latitude;
            geoposition.longitude = location.coordinate.longitude;

            WDGGeopoint* geopoint = [WDGGeopoint make:geoposition];

            [WSMMapLocationFinder findLocationsAtAsync:geopoint
                success:^void(WSMMapLocationFinderResult* results) {
                    self.geocoding = false;
                    NSMutableArray* reverseGeocodeResult = [[NSMutableArray alloc] init];

                    int reverseGeocodeResultCount = [results.locations count];
                    for (int i = 0; i < reverseGeocodeResultCount; i++) {
                        WSMMapLocation* currentResult = [results.locations objectAtIndex:i];

                        NSString* resultName = [currentResult displayName];
                        CLLocation* resultLocation = [[CLLocation alloc] initWithLatitude:[[[currentResult point] position] latitude]
                                                                                longitude:[[[currentResult point] position] longitude]];

                        CLPlacemark* currentPlacemark = [[CLPlacemark alloc] initWithName:resultName location:resultLocation];
                        [reverseGeocodeResult addObject:currentPlacemark];
                    }

                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(reverseGeocodeResult, nullptr);
                    });
                }
                failure:^void(NSError* error) {
                    self.geocoding = false;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(nullptr, error);
                    });
                }];
        }
    }
}

/**
 @Status Caveat
 @Notes This has not been tested yet as the projections do not work.
*/
- (void)geocodeAddressDictionary:(NSDictionary*)addressDictionary completionHandler:(CLGeocodeCompletionHandler)completionHandler {
    @synchronized(self) {
        if (self.isGeocoding) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nullptr, nullptr); // TODO: Need appropriate error code
            });
        } else {
            self.geocoding = true;

            const NSString* addressStreet = (const NSString*)[addressDictionary objectForKey:@"Street"];
            const NSString* addressCity = (const NSString*)[addressDictionary objectForKey:@"City"];
            const NSString* addressState = (const NSString*)[addressDictionary objectForKey:@"State"];
            const NSString* addressZIP = (const NSString*)[addressDictionary objectForKey:@"ZIP"];
            const NSString* addressCountry = (const NSString*)[addressDictionary objectForKey:@"Country"];

            NSMutableString* fullAddress = [[NSMutableString alloc] init];
            if (addressStreet) {
                [fullAddress appendFormat:@"%@, ", addressStreet];
            }

            if (addressCity) {
                [fullAddress appendFormat:@"%@, ", addressCity];
            }

            if (addressState && addressZIP) {
                [fullAddress appendFormat:@"%@ %@, ", addressState, addressZIP];
            } else if (addressState) {
                [fullAddress appendFormat:@"%@, ", addressState];
            } else if (addressZIP) {
                [fullAddress appendFormat:@"%@, ", addressZIP];
            }

            if (addressCountry) {
                [fullAddress appendFormat:@"%@", addressCountry];
            }

            if ([fullAddress hasSuffix:@", "]) {
                [fullAddress deleteCharactersInRange:NSMakeRange([fullAddress length] - 2, 2)];
            }

            [WSMMapLocationFinder findLocationsAsync:fullAddress
                referencePoint:nullptr
                success:^void(WSMMapLocationFinderResult* results) {
                    self.geocoding = false;
                    NSMutableArray* geocodeResult = [[NSMutableArray alloc] init];

                    int geocodeResultCount = [results.locations count];
                    for (int i = 0; i < geocodeResultCount; i++) {
                        WSMMapLocation* currentResult = [results.locations objectAtIndex:i];

                        NSString* resultName = [currentResult displayName];
                        CLLocation* resultLocation = [[CLLocation alloc] initWithLatitude:[[[currentResult point] position] latitude]
                                                                                longitude:[[[currentResult point] position] longitude]];

                        CLPlacemark* currentPlacemark = [[CLPlacemark alloc] initWithName:resultName location:resultLocation];
                        [geocodeResult addObject:currentPlacemark];
                    }

                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(geocodeResult, nullptr);
                    });
                }
                failure:^void(NSError* error) {
                    self.geocoding = false;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(nullptr, error);
                    });
                }];
        }
    }
}

/**
 @Status Caveat
 @Notes This has not been tested yet as the projections do not work.
*/
- (void)geocodeAddressString:(NSString*)addressString completionHandler:(CLGeocodeCompletionHandler)completionHandler {
    @synchronized(self) {
        if (self.isGeocoding) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nullptr, nullptr); // // TODO: Need appropriate error code
            });
        } else {
            self.geocoding = true;
            [WSMMapLocationFinder findLocationsAsync:addressString
                referencePoint:nullptr
                success:^void(WSMMapLocationFinderResult* results) {
                    self.geocoding = false;
                    NSMutableArray* geocodeResult = [[NSMutableArray alloc] init];

                    int geocodeResultCount = [results.locations count];
                    for (int i = 0; i < geocodeResultCount; i++) {
                        WSMMapLocation* currentResult = [results.locations objectAtIndex:i];

                        NSString* resultName = [currentResult displayName];
                        CLLocation* resultLocation = [[CLLocation alloc] initWithLatitude:[[[currentResult point] position] latitude]
                                                                                longitude:[[[currentResult point] position] longitude]];

                        CLPlacemark* currentPlacemark = [[CLPlacemark alloc] initWithName:resultName location:resultLocation];
                        [geocodeResult addObject:currentPlacemark];
                    }

                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(geocodeResult, nullptr);
                    });
                }
                failure:^void(NSError* error) {
                    self.geocoding = false;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(nullptr, error);
                    });
                }];
        }
    }
}

/**
 @Status Caveat
 @Notes This has not been tested yet as the projections do not work.
*/
- (void)geocodeAddressString:(NSString*)addressString
                    inRegion:(CLRegion*)region
           completionHandler:(CLGeocodeCompletionHandler)completionHandler {
    @synchronized(self) {
        if (self.isGeocoding) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nullptr, nullptr); // // TODO: Need appropriate error code
            });
        } else {
            self.geocoding = true;
            // Create a geoposition using the CLRegion specified.
            // TODO: Implement reading the CLRegion now that it has been added.
            WDGBasicGeoposition* geoposition = [[WDGBasicGeoposition alloc] init];

            WDGGeopoint* geopoint = [WDGGeopoint make:geoposition];

            [WSMMapLocationFinder findLocationsAsync:addressString
                referencePoint:geopoint
                success:^void(WSMMapLocationFinderResult* results) {
                    self.geocoding = false;
                    NSMutableArray* geocodeResult = [[NSMutableArray alloc] init];

                    int geocodeResultCount = [results.locations count];
                    for (int i = 0; i < geocodeResultCount; i++) {
                        WSMMapLocation* currentResult = [results.locations objectAtIndex:i];

                        NSString* resultName = [currentResult displayName];
                        CLLocation* resultLocation = [[CLLocation alloc] initWithLatitude:[[[currentResult point] position] latitude]
                                                                                longitude:[[[currentResult point] position] longitude]];

                        CLPlacemark* currentPlacemark = [[CLPlacemark alloc] initWithName:resultName location:resultLocation];
                        [geocodeResult addObject:currentPlacemark];
                    }

                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(geocodeResult, nullptr);
                    });
                }
                failure:^void(NSError* error) {
                    self.geocoding = false;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(nullptr, error);
                    });
                }];
        }
    }
}

/**
 @Status Stub
*/
- (void)cancelGeocode {
    UNIMPLEMENTED();
}

@end