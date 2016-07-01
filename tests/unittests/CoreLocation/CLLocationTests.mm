//******************************************************************************
//
// Copyright (c) 2016 Intel Corporation. All rights reserved.
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

TEST(CoreLocation, LocationDistanceTests) {
    LOG_INFO("CLLocation Distance Test: ");

    CLLocation* locationSeattle = [[CLLocation alloc] initWithLatitude:47.6062 longitude:-122.3321];
    CLLocation* locationLosAngeles = [[CLLocation alloc] initWithLatitude:34.0522 longitude:-118.2437];
    CLLocation* locationSanFrancisco = [[CLLocation alloc] initWithLatitude:37.7749 longitude:-122.4194];
    CLLocation* locationChicago = [[CLLocation alloc] initWithLatitude:41.8781 longitude:-87.6298];
    CLLocation* locationNewYork = [[CLLocation alloc] initWithLatitude:40.7128 longitude:-74.0059];

    CLLocationDistance distance1 = [locationSeattle getDistanceFrom:locationLosAngeles];
    CLLocationDistance distance2 = [locationLosAngeles getDistanceFrom:locationSanFrancisco];
    CLLocationDistance distance3 = [locationSeattle getDistanceFrom:locationChicago];
    CLLocationDistance distance4 = [locationLosAngeles getDistanceFrom:locationNewYork];

    // Check values within nearest 2 kilometers because radius of earth varies among measurements
    ASSERT_NEAR_MSG(distance1, 1545791, 2000, "FAILED: Distance: %f\n", distance1);
    ASSERT_NEAR_MSG(distance2, 559296, 2000, "FAILED: Distance: %f\n", distance2);
    ASSERT_NEAR_MSG(distance3, 2789733, 2000, "FAILED: Distance: %f\n", distance3);
    ASSERT_NEAR_MSG(distance4, 3936990, 2000, "FAILED: Distance: %f\n", distance4);

    [locationSeattle release];
    [locationLosAngeles release];
    [locationSanFrancisco release];
    [locationChicago release];
    [locationNewYork release];
}