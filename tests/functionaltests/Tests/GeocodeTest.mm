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

static const NSTimeInterval c_testTimeoutInSec = 15;

TEST(GeocodingTest, BaseTests) {
    LOG_INFO("Geocoding Base Test: ");
    CLGeocoder* geocoder = [[CLGeocoder alloc] init];
    NSCondition* geocodeCondition = [[NSCondition alloc] init];

    [geocodeCondition lock];
    [WSMMapLocationFinder findLocationsAsync:@"Washington, DC"
                              referencePoint:NULL
                                     success:^void(WSMMapLocationFinderResult* results) {
            int reverseGeocodeResultCount = [results.locations count];
            LOG_INFO("Number of results: %d", reverseGeocodeResultCount);
            for (int i = 0; i < reverseGeocodeResultCount; i++) {
                WSMMapLocation* currentResult = [results.locations objectAtIndex:i];

                NSString* resultAddress = [[currentResult address] formattedAddress];
                NSString* resultName = [currentResult displayName];
                LOG_INFO("Result Address %d: %@", i, resultAddress);
                LOG_INFO("Result Name %d: %@", i, resultName);
                LOG_INFO("Result Lat %d: %f", i, [[[currentResult point] position] latitude]);
                LOG_INFO("Result Long %d: %f", i, [[[currentResult point] position] longitude]);
            }

            [geocodeCondition signal];
            [geocodeCondition unlock];
        }
        failure:^void(NSError* error) {
            NSLog(@"Reached failure");
        }];

    if ([geocodeCondition waitUntilDate : [NSDate dateWithTimeIntervalSinceNow : c_testTimeoutInSec]]) {
        // Wait timed out.
        ASSERT_FALSE_MSG(false, "FAILED: Waiting for geocoding timed out!");
    }
    [geocodeCondition unlock];

    [geocodeCondition lock];
    [geocoder geocodeAddressString:@"New Orleans, LA"
                 completionHandler:^(NSArray* placemarks, NSError* error) {
                     [geocodeCondition lock];
                     LOG_INFO("Error: %@", error);
                     for (CLPlacemark* aPlacemark in placemarks) {
                         LOG_INFO("Placemark: %@: %@", [aPlacemark name], [aPlacemark location]);
                     }

                     [geocodeCondition signal];
                     [geocodeCondition unlock];
                 }];

    if ([geocodeCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:c_testTimeoutInSec]]) {
        // Wait timed out.
        ASSERT_FALSE_MSG(false, "FAILED: Waiting for geocoding timed out!");
    }
    [geocodeCondition unlock];

    [NSThread sleepForTimeInterval:1.0];

    CLLocation* locationSeattle = [[CLLocation alloc] initWithLatitude:47.6062 longitude : -122.3321];
    CLLocation* locationLosAngeles = [[CLLocation alloc] initWithLatitude:34.0522 longitude : -118.2437];
    CLLocation* locationSanFrancisco = [[CLLocation alloc] initWithLatitude:37.7749 longitude : -122.4194];
    CLLocation* locationChicago = [[CLLocation alloc] initWithLatitude:41.8781 longitude : -87.6298];
    CLLocation* locationNewYork = [[CLLocation alloc] initWithLatitude:40.7128 longitude : -74.0059];

    [geocodeCondition lock];
    [geocoder reverseGeocodeLocation:locationSeattle
                   completionHandler:^(NSArray* placemarks, NSError* error) {
                       [geocodeCondition lock];
                       LOG_INFO("Error: %@", error);
                       for (CLPlacemark* aPlacemark in placemarks) {
                           LOG_INFO("Placemark: %@: %@", [aPlacemark name], [aPlacemark location]);
                       }

                       [geocodeCondition signal];
                       [geocodeCondition unlock];
                   }];

    if ([geocodeCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:c_testTimeoutInSec]]) {
        // Wait timed out.
        ASSERT_FALSE_MSG(false, "FAILED: Waiting for geocoding timed out!");
    }
    [geocodeCondition unlock];
    
    [NSThread sleepForTimeInterval:1.0];

    [geocodeCondition lock];
    [geocoder reverseGeocodeLocation:locationLosAngeles
                   completionHandler:^(NSArray* placemarks, NSError* error) {
                       [geocodeCondition lock];
                       LOG_INFO("Error: %@", error);
                       for (CLPlacemark* aPlacemark in placemarks) {
                           LOG_INFO("Placemark: %@: %@", [aPlacemark name], [aPlacemark location]);
                       }

                       [geocodeCondition signal];
                       [geocodeCondition unlock];
                   }];

    if ([geocodeCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:c_testTimeoutInSec]]) {
        // Wait timed out.
        ASSERT_FALSE_MSG(false, "FAILED: Waiting for geocoding timed out!");
    }
    [geocodeCondition unlock];

    [NSThread sleepForTimeInterval:1.0];

    [geocodeCondition lock];
    [geocoder reverseGeocodeLocation:locationSanFrancisco
                   completionHandler:^(NSArray* placemarks, NSError* error) {
                       [geocodeCondition lock];
                       LOG_INFO("Error: %@", error);
                       for (CLPlacemark* aPlacemark in placemarks) {
                           LOG_INFO("Placemark: %@: %@", [aPlacemark name], [aPlacemark location]);
                       }

                       [geocodeCondition signal];
                       [geocodeCondition unlock];
                   }];

    if ([geocodeCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:c_testTimeoutInSec]]) {
        // Wait timed out.
        ASSERT_FALSE_MSG(false, "FAILED: Waiting for geocoding timed out!");
    }
    [geocodeCondition unlock];

    [NSThread sleepForTimeInterval:1.0];
    
    [geocodeCondition lock];
    [geocoder reverseGeocodeLocation:locationChicago
                   completionHandler:^(NSArray* placemarks, NSError* error) {
                       [geocodeCondition lock];
                       LOG_INFO("Error: %@", error);
                       for (CLPlacemark* aPlacemark in placemarks) {
                           LOG_INFO("Placemark: %@: %@", [aPlacemark name], [aPlacemark location]);
                       }

                       [geocodeCondition signal];
                       [geocodeCondition unlock];
                   }];

    if ([geocodeCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:c_testTimeoutInSec]]) {
        // Wait timed out.
        ASSERT_FALSE_MSG(false, "FAILED: Waiting for geocoding timed out!");
    }
    [geocodeCondition unlock];
    
    [NSThread sleepForTimeInterval:1.0];

    [geocodeCondition lock];
    [geocoder reverseGeocodeLocation:locationNewYork
                   completionHandler:^(NSArray* placemarks, NSError* error) {
                       [geocodeCondition lock];
                       LOG_INFO("Error: %@", error);
                       for (CLPlacemark* aPlacemark in placemarks) {
                           LOG_INFO("Placemark: %@: %@", [aPlacemark name], [aPlacemark location]);
                       }

                       [geocodeCondition signal];
                       [geocodeCondition unlock];
                   }];

    if ([geocodeCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:c_testTimeoutInSec]]) {
        // Wait timed out.
        ASSERT_FALSE_MSG(false, "FAILED: Waiting for geocoding timed out!");
    }
    [geocodeCondition unlock];

}
