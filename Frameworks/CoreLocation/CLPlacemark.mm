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

#import <CoreLocation/CLPlacemark.h>
#import <Starboard.h>
#import <StubReturn.h>

@interface CLPlacemark ()

@property (readwrite, nonatomic) CLLocation* location;
@property (readwrite, nonatomic) NSString* name;
@property (readwrite, nonatomic) NSDictionary* addressDictionary;
@property (readwrite, nonatomic) NSString* ISOcountryCode;
@property (readwrite, nonatomic) NSString* country;
@property (readwrite, nonatomic) NSString* postalCode;
@property (readwrite, nonatomic) NSString* administrativeArea;
@property (readwrite, nonatomic) NSString* subAdministrativeArea;
@property (readwrite, nonatomic) NSString* locality;
@property (readwrite, nonatomic) NSString* subLocality;
@property (readwrite, nonatomic) NSString* thoroughfare;
@property (readwrite, nonatomic) NSString* subThoroughfare;
@property (readwrite, nonatomic) CLRegion* region;
@property (readwrite, nonatomic) NSTimeZone* timeZone;
@property (readwrite, nonatomic) NSString* inlandWater;
@property (readwrite, nonatomic) NSString* ocean;
@property (readwrite, nonatomic) NSArray<NSString*>* areasOfInterest;

@end

@implementation CLPlacemark

- (instancetype)initWithName:(NSString*)name location:(CLLocation*)location {
    if (self = [super init]) {
        _name = name;
        _location = location;
    }

    return self;
}

/**
 @Status Interoperable
*/
- (instancetype)initWithPlacemark:(CLPlacemark*)placemark {
    if (self = [super init]) {
        _location = placemark.location;
        _name = [placemark.name copy];
        _addressDictionary = [placemark.addressDictionary copy];
        _ISOcountryCode = [placemark.ISOcountryCode copy];
        _country = [placemark.country copy];
        _postalCode = [placemark.postalCode copy];
        _administrativeArea = [placemark.administrativeArea copy];
        _subAdministrativeArea = [placemark.subAdministrativeArea copy];
        _locality = [placemark.locality copy];
        _subLocality = [placemark.subLocality copy];
        _thoroughfare = [placemark.thoroughfare copy];
        _subThoroughfare = [placemark.subThoroughfare copy];
        _region = placemark.region;
        _timeZone = placemark.timeZone;
        _inlandWater = [placemark.inlandWater copy];
        _ocean = [placemark.ocean copy];
        _areasOfInterest = placemark.areasOfInterest;
    }

    return self;
}

/**
 @Status Stub
*/
- (id)copyWithZone:(NSZone*)zone {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
*/
+ (BOOL)supportsSecureCoding {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
*/
- (instancetype)initWithCoder:(NSCoder*)decoder {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
*/
- (void)encodeWithCoder:(NSCoder*)encoder {
    UNIMPLEMENTED();
}

@end
