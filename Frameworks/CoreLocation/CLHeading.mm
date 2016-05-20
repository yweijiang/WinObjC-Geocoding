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

#import <StubReturn.h>
#import <CoreLocation/CLHeading.h>
#import <Foundation/Foundation.h>

/**
 * CLHeading class extension.

@interface CLHeading () {
}

@property (readwrite, nonatomic) CLLocationDirection magneticHeading;
@property (readwrite, nonatomic) CLLocationDirection trueHeading;
@property (readwrite, nonatomic) CLLocationDirection headingAccuracy;
@property (readwrite, copy, nonatomic) NSDate* timestamp;
@property (readwrite, copy, nonatomic) NSString* description;
@property (readwrite, nonatomic) CLHeadingComponentValue x;
@property (readwrite, nonatomic) CLHeadingComponentValue y;
@property (readwrite, nonatomic) CLHeadingComponentValue z;
@end
*/

@implementation CLHeading

- (instancetype)initWithAccuracy:(CLLocationDirection)accuracy
                 magneticHeading:(CLLocationDirection)magneticHeading
                     trueHeading:(CLLocationDirection)trueHeading {
	NSLog(@"Made it to init function");
    if (self = [super init]) {
        _headingAccuracy = accuracy;
        _magneticHeading = magneticHeading;
        _trueHeading = trueHeading;
        _timestamp = [NSDate date];
		NSLog(@"After Init. Magnetic Heading: %.3f        True Heading: %.3f        ", _magneticHeading, _trueHeading);
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
