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

#include <TestFramework.h>
#include <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UWP/WindowsDevicesGeolocation.h>
#import <UWP/WindowsServicesMaps.h>

static const NSTimeInterval c_testTimeoutInSec = 120;

TEST(GeocodingTest, BaseTests) {
    NSCondition* geocodeCondition1 = [[NSCondition alloc] init];

    // Lock for whole test
    [geocodeCondition1 lock];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        LOG_INFO("Geocoding Base Test: ");
        CLGeocoder* geocoder = [[CLGeocoder alloc] init];
        
        NSCondition* geocodeCondition2 = [[NSCondition alloc] init];
        NSCondition* geocodeCondition3 = [[NSCondition alloc] init];
        NSCondition* geocodeCondition4 = [[NSCondition alloc] init];
        NSCondition* geocodeCondition5 = [[NSCondition alloc] init];
        NSCondition* geocodeCondition6 = [[NSCondition alloc] init];
        NSCondition* geocodeCondition7 = [[NSCondition alloc] init];

        [geocoder geocodeAddressString:@"Moscow, Russia"
            completionHandler:^(NSArray* placemarks, NSError* error) {
                LOG_INFO("Error: %@", error);
                for (CLPlacemark* aPlacemark in placemarks) {
                    LOG_INFO("Placemark: %@: %@", [aPlacemark name], [aPlacemark location]);
                }

                [geocodeCondition2 signal];
            }];

        if ([geocodeCondition2 waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:c_testTimeoutInSec]]) {
            // Wait timed out.
            ASSERT_FALSE_MSG(false, "FAILED: Waiting for geocoding timed out!");
        }

        /* 
        //Actual geographical values
        CLLocation* locationSeattle = [[CLLocation alloc] initWithLatitude:47.6062 longitude:-122.3321];
        CLLocation* locationLosAngeles = [[CLLocation alloc] initWithLatitude:34.0522 longitude:-118.2437];
        CLLocation* locationSanFrancisco = [[CLLocation alloc] initWithLatitude:37.7749 longitude:-122.4194];
        CLLocation* locationChicago = [[CLLocation alloc] initWithLatitude:41.8781 longitude:-87.6298];
        CLLocation* locationNewYork = [[CLLocation alloc] initWithLatitude:40.7128 longitude:-74.0059];
        */

        CLLocation* locationSeattle = [[CLLocation alloc] initWithLatitude:47.6062 longitude:-122.5321];
        CLLocation* locationLosAngeles = [[CLLocation alloc] initWithLatitude:34.0522 longitude:-118.4437];
        CLLocation* locationSanFrancisco = [[CLLocation alloc] initWithLatitude:37.7749 longitude:-122.6194];
        CLLocation* locationChicago = [[CLLocation alloc] initWithLatitude:41.8781 longitude:-87.8298];
        CLLocation* locationNewYork = [[CLLocation alloc] initWithLatitude:40.7128 longitude:-74.2059];

        [geocoder reverseGeocodeLocation:locationSeattle
            completionHandler:^(NSArray* placemarks, NSError* error) {
                LOG_INFO("Error: %@", error);
                for (CLPlacemark* aPlacemark in placemarks) {
                    LOG_INFO("Placemark: %@: %@", [aPlacemark name], [aPlacemark location]);
                }

                [geocodeCondition3 signal];
            }];

        if ([geocodeCondition3 waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:c_testTimeoutInSec]]) {
            // Wait timed out.
            ASSERT_FALSE_MSG(false, "FAILED: Waiting for geocoding timed out!");
        }

        [geocoder reverseGeocodeLocation:locationLosAngeles
            completionHandler:^(NSArray* placemarks, NSError* error) {
                LOG_INFO("Error: %@", error);
                for (CLPlacemark* aPlacemark in placemarks) {
                    LOG_INFO("Placemark: %@: %@", [aPlacemark name], [aPlacemark location]);
                }

                [geocodeCondition4 signal];
            }];

        if ([geocodeCondition4 waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:c_testTimeoutInSec]]) {
            // Wait timed out.
            ASSERT_FALSE_MSG(false, "FAILED: Waiting for geocoding timed out!");
        }

        [geocoder reverseGeocodeLocation:locationSanFrancisco
            completionHandler:^(NSArray* placemarks, NSError* error) {
                LOG_INFO("Error: %@", error);
                for (CLPlacemark* aPlacemark in placemarks) {
                    LOG_INFO("Placemark: %@: %@", [aPlacemark name], [aPlacemark location]);
                }

                [geocodeCondition5 signal];
            }];

        if ([geocodeCondition5 waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:c_testTimeoutInSec]]) {
            // Wait timed out.
            ASSERT_FALSE_MSG(false, "FAILED: Waiting for geocoding timed out!");
        }
        
        [geocoder reverseGeocodeLocation:locationChicago
            completionHandler:^(NSArray* placemarks, NSError* error) {
                LOG_INFO("Error: %@", error);
                for (CLPlacemark* aPlacemark in placemarks) {
                    LOG_INFO("Placemark: %@: %@", [aPlacemark name], [aPlacemark location]);
                }

                [geocodeCondition6 signal];
            }];

        if ([geocodeCondition6 waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:c_testTimeoutInSec]]) {
            // Wait timed out.
            ASSERT_FALSE_MSG(false, "FAILED: Waiting for geocoding timed out!");
        }
        
        WDGBasicGeoposition* geopositionNewYork = [[WDGBasicGeoposition alloc] init];
        geopositionNewYork.latitude = 40.7128;
        geopositionNewYork.longitude = -74.2059;

        WDGGeopoint* geopointNewYork = [WDGGeopoint make:geopositionNewYork];

        [WSMMapLocationFinder findLocationsAtAsync: geopointNewYork
                                            success:^void(WSMMapLocationFinderResult* results) {
                // Unknown Error and Status Not Supported don't map to any iOS error codes
                WSMMapLocationFinderStatus status = results.status;
                NSError* geocodeStatus;
                if (status == WSMMapLocationFinderStatusSuccess) {
                    geocodeStatus = nullptr;
                } else if (status == WSMMapLocationFinderStatusUnknownError) {
                    geocodeStatus = nullptr;
                } else if (status == WSMMapLocationFinderStatusInvalidCredentials) {
                    geocodeStatus = [NSError errorWithDomain:@"kCLErrorDomain" code:kCLErrorDenied userInfo:nullptr];
                } else if (status == WSMMapLocationFinderStatusBadLocation) {
                    geocodeStatus = [NSError errorWithDomain:@"kCLErrorDomain" code:kCLErrorLocationUnknown userInfo:nullptr];
                } else if (status == WSMMapLocationFinderStatusIndexFailure) {
                    geocodeStatus = [NSError errorWithDomain:@"kCLErrorDomain" code:kCLErrorGeocodeFoundNoResult userInfo:nullptr];
                } else if (status == WSMMapLocationFinderStatusNetworkFailure) {
                    geocodeStatus = [NSError errorWithDomain:@"kCLErrorDomain" code:kCLErrorNetwork userInfo:nullptr];
                } else if (status == WSMMapLocationFinderStatusNotSupported) {
                    geocodeStatus = nullptr;
                }

                LOG_INFO("Result status: %d", status);
                LOG_INFO("Geocode Error: %@", geocodeStatus);

                int reverseGeocodeResultCount = [results.locations count];
                for (int i = 0; i < reverseGeocodeResultCount; i++) {
                    WSMMapLocation* currentResult = [results.locations objectAtIndex:i];

                    NSString* resultName = [[currentResult address] formattedAddress];
                    CLLocation* resultLocation = [[CLLocation alloc] initWithLatitude:[[[currentResult point] position] latitude]
                                                                            longitude:[[[currentResult point] position] longitude]];

                    CLPlacemark* currentPlacemark = [[CLPlacemark alloc] initWithName:resultName location:resultLocation];

                    LOG_INFO("Placemark: %@: %@", [currentPlacemark name], [currentPlacemark location]);
                }

                [geocodeCondition7 signal];
            }
            failure:^void(NSError* error) {
                LOG_INFO(@"Failure status reached");
            }];

        if ([geocodeCondition7 waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:c_testTimeoutInSec]]) {
            // Wait timed out.
            ASSERT_FALSE_MSG(false, "FAILED: Waiting for geocoding timed out!");
        }

        [geocodeCondition1 signal];
    });

    if ([geocodeCondition1 waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:c_testTimeoutInSec]]) {
        // Wait timed out.
        ASSERT_FALSE_MSG(false, "FAILED: Waiting for geocoding timed out!");
    }
    [geocodeCondition1 unlock];
}
