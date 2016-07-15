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

#import <CoreGraphics\CGPath.h>
#import <Foundation\Foundation.h>
#import <Starboard.h>
#import <TestFramework.h>

static NSString* const kPointsKey = @"PointsKey";
static NSString* const kTypeKey = @"TypeKey";
// Helper function to know # of points in an element
int cgPathPointCountForElementType(CGPathElementType type) {
    int pointCount = 0;

    switch (type) {
        case kCGPathElementMoveToPoint:
        case kCGPathElementAddLineToPoint:
            pointCount = 1;
            break;
        case kCGPathElementAddQuadCurveToPoint:
            pointCount = 2;
            break;
        case kCGPathElementAddCurveToPoint:
            pointCount = 3;
            break;
        case kCGPathElementCloseSubpath:
            pointCount = 0;
            break;
    }
    return pointCount;
}

// CGPathApplierFunction that adds elements to an NSMutableArray
void cgPathApplierFunction(void* info, const CGPathElement* element) {
    NSMutableArray* result = (__bridge NSMutableArray*)(info);

    int pointCount = cgPathPointCountForElementType(element->type);

    NSMutableArray* points = [NSMutableArray array];

    for (int i = 0; i < pointCount; i++) {
        CGPoint point = element->points[i];
        [points addObject:@(point.x)];
        [points addObject:@(point.y)];
    }

    [result addObject:@{ kTypeKey : @(element->type), kPointsKey : points }];
}

// Helper function that compares results from cgPathApplierFunction to expected results
void cgPathCompare(NSArray* expected, NSArray* result) {
    ASSERT_EQ(expected.count, result.count) << "Counts do not match for expected and result";

    [expected enumerateObjectsUsingBlock:^(NSDictionary* expectedDict, NSUInteger elementIndex, BOOL* stop) {
        NSDictionary* resultDict = result[elementIndex];
        CGPathElementType expectedType = (CGPathElementType)[expectedDict[kTypeKey] integerValue];
        CGPathElementType resultType = (CGPathElementType)[resultDict[kTypeKey] integerValue];
        ASSERT_EQ(expectedType, resultType) << "Elements in result and expected do not match";
        ASSERT_EQ([expectedDict[kPointsKey] count], [resultDict[kPointsKey] count])
            << "Point count in result and expected element do not match";

        [expectedDict[kPointsKey] enumerateObjectsUsingBlock:^(NSNumber* expectedPointValue, NSUInteger pointIndex, BOOL* stop) {
            float resultPoint = [resultDict[kPointsKey][pointIndex] floatValue];
            ASSERT_FLOAT_EQ([expectedPointValue floatValue], resultPoint);
        }];
    }];
}

TEST(CGPath, CGPathApplyAddRect) {
    CGMutablePathRef path = CGPathCreateMutable();

    CGRect rect = CGRectMake(2, 4, 8, 16);

    CGPathAddRect(path, NULL, rect);

    NSMutableArray* result = [NSMutableArray array];

    CGPathApply(path, result, cgPathApplierFunction);

    NSArray* expected = @[
        @{ kTypeKey : @(kCGPathElementMoveToPoint),
           kPointsKey : @[ @2, @4 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @10, @4 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @10, @20 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @2, @20 ] },
        @{ kTypeKey : @(kCGPathElementCloseSubpath),
           kPointsKey : [NSArray array] }
    ];

    cgPathCompare(expected, result);

    CGPathRelease(path);
}

TEST(CGPath, CGPathApplyAddEllipse) {
    CGMutablePathRef path = CGPathCreateMutable();

    CGRect rect = CGRectMake(40, 40, 200, 40);

    CGPathAddEllipseInRect(path, NULL, rect);

    NSMutableArray* result = [NSMutableArray array];

    CGPathApply(path, result, cgPathApplierFunction);

    NSArray* expected = @[
        @{ kTypeKey : @(kCGPathElementMoveToPoint),
           kPointsKey : @[ @240, @60 ] },
        @{ kTypeKey : @(kCGPathElementAddCurveToPoint),
           kPointsKey : @[ @240, @71.045695, @195.228475, @80, @140, @80 ] },
        @{ kTypeKey : @(kCGPathElementAddCurveToPoint),
           kPointsKey : @[ @84.771525, @80, @40, @71.045695, @40, @60 ] },
        @{ kTypeKey : @(kCGPathElementAddCurveToPoint),
           kPointsKey : @[ @40, @48.954305, @84.771525, @40, @140, @40 ] },
        @{ kTypeKey : @(kCGPathElementAddCurveToPoint),
           kPointsKey : @[ @195.228475, @40, @240, @48.954305, @240, @60 ] },
        @{ kTypeKey : @(kCGPathElementCloseSubpath),
           kPointsKey : [NSArray array] }
    ];

    cgPathCompare(expected, result);

    CGPathRelease(path);
}

TEST(CGPath, CGPathApplyAddArc) {
    CGMutablePathRef path = CGPathCreateMutable();

    CGPathAddArc(path, NULL, 25, 100, 20, M_PI * 1.25, 0, 1);

    NSMutableArray* result = [NSMutableArray array];

    CGPathApply(path, result, cgPathApplierFunction);

    NSArray* expected = @[
        @{ kTypeKey : @(kCGPathElementMoveToPoint),
           kPointsKey : @[ @10.857863, @85.857865 ] },
        @{
            kTypeKey : @(kCGPathElementAddCurveToPoint),
            kPointsKey : @[ @3.047378, @93.668352, @3.047379, @106.331651, @10.857865, @114.142137 ]
        },
        @{
            kTypeKey : @(kCGPathElementAddCurveToPoint),
            kPointsKey : @[ @18.668352, @121.952622, @31.331651, @121.952621, @39.142137, @114.142135 ]
        },
        @{ kTypeKey : @(kCGPathElementAddCurveToPoint),
           kPointsKey : @[ @42.892864, @110.391407, @45, @105.304329, @45, @100 ] }
    ];

    cgPathCompare(expected, result);

    CGPathRelease(path);
}

TEST(CGPath, CGPathApplyAddArcToPoint) {
    CGMutablePathRef path = CGPathCreateMutable();

    CGPathMoveToPoint(path, NULL, 400, 400);
    CGPathAddArcToPoint(path, NULL, 140, 250, 110, 180, 50);

    NSMutableArray* result = [NSMutableArray array];

    CGPathApply(path, result, cgPathApplierFunction);

    NSArray* expected = @[
        @{ kTypeKey : @(kCGPathElementMoveToPoint),
           kPointsKey : @[ @400, @400 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @154.415379, @258.316565 ] },
        @{
            kTypeKey : @(kCGPathElementAddCurveToPoint),
            kPointsKey : @[ @145.057503, @252.917790, @137.699975, @244.633276, @133.444250, @234.703250 ]
        }
    ];

    cgPathCompare(expected, result);

    CGPathRelease(path);
}

TEST(CGPath, CGPathAddQuadCurveToPoint) {
    CGMutablePathRef path = CGPathCreateMutable();

    CGPathMoveToPoint(path, NULL, 400, 400);
    CGPathAddQuadCurveToPoint(path, NULL, 140, 250, 110, 180);

    NSMutableArray* result = [NSMutableArray array];

    CGPathApply(path, result, cgPathApplierFunction);

    NSArray* expected = @[
        @{ kTypeKey : @(kCGPathElementMoveToPoint),
           kPointsKey : @[ @400, @400 ] },
        @{ kTypeKey : @(kCGPathElementAddQuadCurveToPoint),
           kPointsKey : @[ @140, @250, @110, @180 ] }
    ];

    cgPathCompare(expected, result);

    CGPathRelease(path);
}

TEST(CGPath, CGPathCreateMutableCopy) {
    CGMutablePathRef path1 = CGPathCreateMutable();

    CGRect rect = CGRectMake(2, 4, 8, 16);

    CGPathAddEllipseInRect(path1, NULL, rect);

    CGMutablePathRef path2 = CGPathCreateMutableCopy(path1);

    ASSERT_NE(path1, path2);

    ASSERT_TRUE(CGPathEqualToPath(path1, path2));

    CGPathRelease(path1);

    CGPathRelease(path2);
}

TEST(CGPath, CGPathEqualToPath) {
    CGMutablePathRef path1 = CGPathCreateMutable();

    CGRect rect = CGRectMake(2, 4, 8, 16);

    CGPathAddRect(path1, NULL, rect);

    // Create a copy of the path
    CGMutablePathRef path2 = CGPathCreateMutableCopy(path1);

    // Change the copy
    CGPathAddEllipseInRect(path2, NULL, rect);

    // Make sure the paths are not the same object
    ASSERT_NE(path1, path2);

    // Make sure paths are not equal
    ASSERT_FALSE(CGPathEqualToPath(path1, path2));

    // Release the copy
    CGPathRelease(path2);

    // Now test the original path to make sure it's still what we expect
    NSArray* expected = @[
        @{ kTypeKey : @(kCGPathElementMoveToPoint),
           kPointsKey : @[ @2, @4 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @10, @4 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @10, @20 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @2, @20 ] },
        @{ kTypeKey : @(kCGPathElementCloseSubpath),
           kPointsKey : [NSArray array] }
    ];

    NSMutableArray* result = [NSMutableArray array];

    CGPathApply(path1, result, cgPathApplierFunction);

    cgPathCompare(expected, result);

    CGPathRelease(path1);
}

TEST(CGPath, CGPathAddPath) {
    CGMutablePathRef path1 = CGPathCreateMutable();

    CGRect rect1 = CGRectMake(2, 4, 8, 16);

    CGPathAddRect(path1, NULL, rect1);

    CGMutablePathRef path2 = CGPathCreateMutable();

    CGRect rect2 = CGRectMake(4, 4, 8, 16);

    CGPathAddRect(path2, NULL, rect2);

    CGPathAddPath(path1, NULL, path2);

    NSArray* expected1 = @[
        @{ kTypeKey : @(kCGPathElementMoveToPoint),
           kPointsKey : @[ @2, @4 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @10, @4 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @10, @20 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @2, @20 ] },
        @{ kTypeKey : @(kCGPathElementCloseSubpath),
           kPointsKey : [NSArray array] },
        @{ kTypeKey : @(kCGPathElementMoveToPoint),
           kPointsKey : @[ @4, @4 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @12, @4 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @12, @20 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @4, @20 ] },
        @{ kTypeKey : @(kCGPathElementCloseSubpath),
           kPointsKey : [NSArray array] }
    ];

    NSArray* expected2 = @[
        @{ kTypeKey : @(kCGPathElementMoveToPoint),
           kPointsKey : @[ @4, @4 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @12, @4 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @12, @20 ] },
        @{ kTypeKey : @(kCGPathElementAddLineToPoint),
           kPointsKey : @[ @4, @20 ] },
        @{ kTypeKey : @(kCGPathElementCloseSubpath),
           kPointsKey : [NSArray array] }
    ];

    NSMutableArray* result2 = [NSMutableArray array];

    CGPathApply(path1, result2, cgPathApplierFunction);

    cgPathCompare(expected1, result2);

    CGPathRelease(path2);

    NSMutableArray* result1 = [NSMutableArray array];

    CGPathApply(path1, result1, cgPathApplierFunction);

    cgPathCompare(expected1, result1);

    CGPathRelease(path1);
}