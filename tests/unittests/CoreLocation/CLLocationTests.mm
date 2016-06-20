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

#include <TestFramework.h>
#import <CoreLocation/CoreLocation.h>

TEST(CoreLocation, CLLocation_SanityTest) {
    LOG_INFO("CLLocation sanity test: ");

    CLLocation* location1 = [[CLLocation alloc] initWithLatitude:28.234 longitude:9873.133];
    CLLocation* location2 = [[CLLocation alloc] initWithLatitude:28.234 longitude:9873.133];
    ASSERT_OBJCEQ_MSG(location1, location2, "FAILED: location1 and location2 are equal!\n");
    [location1 release];
    [location2 release];
}

TEST(CoreLocation, CLLocation_HashTest) {
    LOG_INFO("CLLocation hash test: ");

    CLLocationCoordinate2D coordinate = { 245.2309, 90.124 };
    CLLocation* location1 = [[CLLocation alloc] initWithCoordinate:coordinate
                                                          altitude:874.0134
                                                horizontalAccuracy:78.8974
                                                  verticalAccuracy:2.452
                                                            course:90
                                                             speed:13.245
                                                         timestamp:[NSDate dateWithTimeInterval:875 sinceDate:[NSDate date]]];
    CLLocation* location2 = [location1 copy];
    ASSERT_EQ_MSG([location1 hash], [location2 hash], "FAILED: location1 and location2 hash values have to be the same\n");
    [location1 release];
    [location2 release];

    location1 = [[CLLocation alloc] initWithLatitude:28.234 longitude:9873.133];
    location2 = [[CLLocation alloc] initWithLatitude:28 longitude:9873.133];
    ASSERT_NE_MSG([location1 hash], [location2 hash], "FAILED: location1 and location2 hash values cannot be the same\n");
    [location1 release];
    [location2 release];
}

TEST(CoreLocation, CLLocation_CopyTest) {
    LOG_INFO("CLLocation copy test: ");

    CLLocationCoordinate2D coordinate = { 245.2309, 90.124 };
    CLLocation* location1 = [[CLLocation alloc] initWithCoordinate:coordinate
                                                          altitude:1293.23
                                                horizontalAccuracy:142.1
                                                  verticalAccuracy:98.139
                                                            course:21
                                                             speed:45.73
                                                         timestamp:[NSDate dateWithTimeInterval:10 sinceDate:[NSDate date]]];
    CLLocation* location2 = [location1 copy];
    ASSERT_OBJCEQ_MSG(location1, location2, "FAILED: location1 and location2 are equal!\n");
    [location1 release];
    [location2 release];
}

TEST(CoreLocation, GeocodingTest) {
    LOG_INFO("Geocoding test: ");

    CLLocation* location1 = [[CLLocation alloc] initWithLatitude:47.6062 longitude : -122.3321];
    CLLocationCoordinate2D coordinate = { 245.2309, 90.124 };
    

    //dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {

        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ (void) {
            CLLocation* location2 = [[CLLocation alloc] initWithCoordinate:coordinate
                altitude : 0
                horizontalAccuracy : 0
                verticalAccuracy : 0
                course : 0
                speed : 0
                timestamp : nil];
            CLGeocoder* geocoder = [[CLGeocoder alloc] init];

            [geocoder reverseGeocodeLocation:location1
                           completionHandler:^(NSArray* placemarks, NSError* error) {
                               LOG_INFO("Made it to completion handler");
                               for (CLPlacemark* aPlacemark in placemarks) {
                                   // Process the placemark.
                                   LOG_INFO("Placemark %@: %@", [aPlacemark name], [aPlacemark location]);
                               }

                               //dispatch_semaphore_signal(semaphore);
                           }];
            //});

            //dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        //});

        



    //while (1);
    LOG_INFO("end");
}