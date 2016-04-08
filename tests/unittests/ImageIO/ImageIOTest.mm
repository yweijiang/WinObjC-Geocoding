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

#include "gtest-api.h"
#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>
#import <CoreGraphics/CGImage.h>
#include "Starboard.h"
#include <windows.h>

const CFStringRef kUTTypeJPEG = static_cast<const CFStringRef>(@"public.jpeg");
const CFStringRef kUTTypeTIFF = static_cast<const CFStringRef>(@"public.tiff");
const CFStringRef kUTTypeGIF = static_cast<const CFStringRef>(@"com.compuserve.gif");
const CFStringRef kUTTypePNG = static_cast<const CFStringRef>(@"public.png");
const CFStringRef kUTTypeBMP = static_cast<const CFStringRef>(@"com.microsoft.bmp");
const CFStringRef kUTTypeICO = static_cast<const CFStringRef>(@"com.microsoft.ico");
const CFStringRef kUTTypeData = static_cast<const CFStringRef>(@"public.data");

static void checkInt(int res, int expected, const char* name) {
    ASSERT_NEAR_MSG(res, expected, 0, "TEST FAILED: %s \nEXPECTED: %i\nFOUND: %i", name, expected, res);
}

static NSData* getDataFromImageFile(const wchar_t* imageFilename) {
    // get test startup full path
    wchar_t fullPath[_MAX_PATH];
    GetModuleFileNameW(NULL, fullPath, _MAX_PATH);

    // split test startup full path into components like drive, directory, filename and ext etc.
    wchar_t drive[_MAX_DRIVE];
    wchar_t directory[_MAX_DIR];
    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);

    // reconstruct fullpath for test artifact file. e.g., C:\WinObjc\WinObjC\build\Debug\data\photo6_1024x670.jpg
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), L"data\\");
    wcscat_s(fullPath, _countof(fullPath), imageFilename);
    NSString* testFileFullPath = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    EbrFile* fp = EbrFopen([testFileFullPath UTF8String], "rb");
    if (!fp) {
        return nil;
    } 
    
    EbrFseek(fp, 0, SEEK_END);
    size_t length = EbrFtell(fp);
    char* byteData = (char*)IwMalloc(length);
    EbrFseek(fp, 0, SEEK_SET);
    size_t newLen = EbrFread(byteData, sizeof(char), length, fp);
    EbrFclose(fp);

    NSData* imgData = [NSData dataWithBytes:(const void*)byteData length:length];
    IwFree(byteData);
    return imgData;
}

TEST(ImageIO, ImageAtIndexWithData) {
    const wchar_t* imageFile = L"photo6_1024x670.jpg";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeJPEG",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 670, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");
    size_t frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");
    CFRelease(imageSource);
}

TEST(ImageIO, ImageAtIndexWithDataProvider) {
    const wchar_t* imageFile = L"photo6_1024x670.jpg";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeJPEG",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData((CFDataRef)imageData);
    CGImageSourceRef imageSource = CGImageSourceCreateWithDataProvider(imgDataProvider, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithDataProvider returned nullptr");
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 670, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");
    size_t frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");
    CFRelease(imageSource);
}

TEST(ImageIO, ImageAtIndexWithUrl) {
    // get test startup full path
    wchar_t fullPath[_MAX_PATH];
    GetModuleFileNameW(NULL, fullPath, _MAX_PATH);

    // split test startup full path into components like drive, directory, filename and ext etc.
    wchar_t drive[_MAX_DRIVE];
    wchar_t directory[_MAX_DIR];
    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);

    // reconstruct fullpath for test artifact file. e.g., C:\WinObjc\WinObjC\build\Debug\data\photo6_1024x670.jpg
    const wchar_t* imageFile = L"photo6_1024x670.jpg";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), L"data\\");
    wcscat_s(fullPath, _countof(fullPath), imageFile);
    NSString* directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];

    CFURLRef imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile]; 
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeJPEG",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL(imgUrl, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithURL returned nullptr");
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 670, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");
    size_t frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");
    CFRelease(imageSource);
}

TEST(ImageIO, ImageTypeTest) {
    const wchar_t* imageFile = L"photo6_1024x670.jpg";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, nullptr);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CFStringRef imageType = CGImageSourceGetType(imageSource);
    ASSERT_TRUE_MSG(imageType != nil, "FAILED: ImageIOTest::CGImageSourceGetType returned nullptr");
    ASSERT_OBJCEQ_MSG(static_cast<NSString*>(imageType), @"public.jpeg", "FAILED: ImageIOTest::Incorrect Image Type");
    CFRelease(imageSource);
}

TEST(ImageIO, ThumbnailAtIndexFromSrcWithoutThumbnail) {
    const wchar_t* imageFile = L"photo6_1024x670.jpg";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeJPEG",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue",
                              @"kCGImageSourceCreateThumbnailFromImageIfAbsent":@"kCFBooleanTrue",
                              @"kCGImageSourceCreateThumbnailFromImageAlways":@"kCFBooleanTrue",
                              @"kCGImageSourceThumbnailMaxPixelSize":[NSNumber numberWithInt:1024],
                              @"kCGImageSourceCreateThumbnailWithTransform":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateThumbnailAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 670, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");
    CFRelease(imageSource);
}

TEST(ImageIO, ThumbnailAtIndexFromAsymmetricSrcWithThumbnail) {
    const wchar_t* imageFile = L"photo6_1024x670_thumbnail_227x149.jpg";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeJPEG",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue",
                              @"kCGImageSourceCreateThumbnailFromImageIfAbsent":@"kCFBooleanTrue",
                              @"kCGImageSourceCreateThumbnailFromImageAlways":@"kCFBooleanTrue",
                              @"kCGImageSourceThumbnailMaxPixelSize":[NSNumber numberWithInt:1024],
                              @"kCGImageSourceCreateThumbnailWithTransform":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateThumbnailAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 149, "Height");
    checkInt(CGImageGetWidth(imageRef), 227, "Width");
    CFRelease(imageSource);
}

TEST(ImageIO, ThumbnailSizesRelativeToImage) {
    const wchar_t* imageFile = L"photo6_1024x670_thumbnail_227x149.jpg";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeJPEG",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue",
                              @"kCGImageSourceCreateThumbnailFromImageIfAbsent":@"kCFBooleanTrue",
                              @"kCGImageSourceCreateThumbnailFromImageAlways":@"kCFBooleanTrue",
                              @"kCGImageSourceThumbnailMaxPixelSize":[NSNumber numberWithInt:10],
                              @"kCGImageSourceCreateThumbnailWithTransform":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateThumbnailAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 10, "Height");
    checkInt(CGImageGetWidth(imageRef), 10, "Width");
    CFRelease(imageSource);

    options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeJPEG",
                @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                @"kCGImageSourceShouldCache":@"kCFBooleanTrue",
                @"kCGImageSourceCreateThumbnailFromImageIfAbsent":@"kCFBooleanTrue",
                @"kCGImageSourceCreateThumbnailFromImageAlways":@"kCFBooleanTrue",
                @"kCGImageSourceThumbnailMaxPixelSize":[NSNumber numberWithInt:1000],
                @"kCGImageSourceCreateThumbnailWithTransform":@"kCFBooleanTrue"};
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateThumbnailAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 149, "Height");
    checkInt(CGImageGetWidth(imageRef), 227, "Width");
    CFRelease(imageSource);
}

TEST(ImageIO, GIF_TIFF_MultiFrameSourceTest) {
    const wchar_t* imageFile = L"photo7_4layers_683x1024.gif";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeGIF",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 2, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    CFStringRef imageType = CGImageSourceGetType(imageSource);
    ASSERT_TRUE_MSG(imageType != nil, "FAILED: ImageIOTest::CGImageSourceGetType returned nullptr");
    ASSERT_OBJCEQ_MSG(static_cast<NSString*>(imageType), @"com.compuserve.gif", "FAILED: ImageIOTest::Incorrect Image Type");
    size_t frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 4, "FrameCount");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 1024, "Height");
    checkInt(CGImageGetWidth(imageRef), 683, "Width");
    
    imageFile = L"photo8_4layers_1024x683.tif";
    imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeTIFF",
                @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 3, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    imageType = CGImageSourceGetType(imageSource);
    ASSERT_TRUE_MSG(imageType != nil, "FAILED: ImageIOTest::CGImageSourceGetType returned nullptr");
    ASSERT_OBJCEQ_MSG(static_cast<NSString*>(imageType), @"public.tiff", "FAILED: ImageIOTest::Incorrect Image Type");
    frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 4, "FrameCount");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 1024, "Height");
    checkInt(CGImageGetWidth(imageRef), 683, "Width");
    CFRelease(imageSource);
}

TEST(ImageIO, BMP_ICO_PNG_SingleFrameSourceTest) {
    const wchar_t* imageFile = L"testimg_227x149.bmp";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeBMP",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    CFStringRef imageType = CGImageSourceGetType(imageSource);
    ASSERT_TRUE_MSG(imageType != nil, "FAILED: ImageIOTest::CGImageSourceGetType returned nullptr");
    ASSERT_OBJCEQ_MSG(static_cast<NSString*>(imageType), @"com.microsoft.bmp", "FAILED: ImageIOTest::Incorrect Image Type");
    size_t frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 149, "Height");
    checkInt(CGImageGetWidth(imageRef), 227, "Width");

    imageFile = L"photo2_683x1024.ico";
    imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeICO",
                @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    imageType = CGImageSourceGetType(imageSource);
    ASSERT_TRUE_MSG(imageType != nil, "FAILED: ImageIOTest::CGImageSourceGetType returned nullptr");
    ASSERT_OBJCEQ_MSG(static_cast<NSString*>(imageType), @"com.microsoft.ico", "FAILED: ImageIOTest::Incorrect Image Type");
    frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 1024, "Height");
    checkInt(CGImageGetWidth(imageRef), 683, "Width");

    imageFile = L"seafloor_256x256.png";
    imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypePNG",
                @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    imageType = CGImageSourceGetType(imageSource);
    ASSERT_TRUE_MSG(imageType != nil, "FAILED: ImageIOTest::CGImageSourceGetType returned nullptr");
    ASSERT_OBJCEQ_MSG(static_cast<NSString*>(imageType), @"public.png", "FAILED: ImageIOTest::Incorrect Image Type");
    frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 256, "Height");
    checkInt(CGImageGetWidth(imageRef), 256, "Width");
    CFRelease(imageSource);
}

TEST(ImageIO, NegativeScenarioTest) {
    const wchar_t* imageFile = L"photo6_1024x670.jpg";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeJPEG",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData(nullptr, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource == nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData should return nullptr");

    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, nullptr);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");

    imageSource = CGImageSourceCreateWithData(nullptr, nullptr);
    ASSERT_TRUE_MSG(imageSource == nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData should return nullptr");

    CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData((CFDataRef)imageData);
    imageSource = CGImageSourceCreateWithDataProvider(nullptr, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource == nil, "FAILED: ImageIOTest::CGImageSourceCreateWithDataProvider should return nullptr");

    imageSource = CGImageSourceCreateWithDataProvider(imgDataProvider, nullptr);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithDataProvider returned nullptr");

    imageSource = CGImageSourceCreateWithDataProvider(nullptr, nullptr);
    ASSERT_TRUE_MSG(imageSource == nil, "FAILED: ImageIOTest::CGImageSourceCreateWithDataProvider should return nullptr");

    // get test startup full path
    wchar_t fullPath[_MAX_PATH];
    GetModuleFileNameW(NULL, fullPath, _MAX_PATH);

    // split test startup full path into components like drive, directory, filename and ext etc.
    wchar_t drive[_MAX_DRIVE];
    wchar_t directory[_MAX_DIR];
    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);

    // reconstruct fullpath for test artifact file. e.g., C:\WinObjc\WinObjC\build\Debug\data\photo6_1024x670.jpg
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), L"data\\");
    wcscat_s(fullPath, _countof(fullPath), imageFile);
    NSString* directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];

    CFURLRef imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile]; 
    imageSource = CGImageSourceCreateWithURL(nullptr, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource == nil, "FAILED: ImageIOTest::CGImageSourceCreateWithURL should return nullptr");

    imageSource = CGImageSourceCreateWithURL(nullptr, nullptr);
    ASSERT_TRUE_MSG(imageSource == nil, "FAILED: ImageIOTest::CGImageSourceCreateWithURL should return nullptr");

    imageSource = CGImageSourceCreateWithURL(imgUrl, nullptr);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithURL returned nullptr");
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 5, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef == nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex should return nullptr");

    imageRef = CGImageSourceCreateImageAtIndex(imageSource, -1, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef == nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex should return nullptr");

    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, nullptr);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");

    imageRef = CGImageSourceCreateImageAtIndex(nullptr, 0, nullptr);
    ASSERT_TRUE_MSG(imageRef == nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex should return nullptr");

    size_t frameCount = CGImageSourceGetCount(nullptr);
    checkInt(frameCount, 0, "FrameCount");
    options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeJPEG",
                @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                @"kCGImageSourceShouldCache":@"kCFBooleanTrue",
                @"kCGImageSourceCreateThumbnailFromImageIfAbsent":@"kCFBooleanTrue",
                @"kCGImageSourceCreateThumbnailFromImageAlways":@"kCFBooleanTrue",
                @"kCGImageSourceThumbnailMaxPixelSize":[NSNumber numberWithInt:1024],
                @"kCGImageSourceCreateThumbnailWithTransform":@"kCFBooleanTrue"};
 
    imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 5, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef == nil, "FAILED: ImageIOTest::CGImageSourceCreateThumbnailAtIndex should return nullptr");

    imageRef = CGImageSourceCreateThumbnailAtIndex(nullptr, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef == nil, "FAILED: ImageIOTest::CGImageSourceCreateThumbnailAtIndex should return nullptr");

    imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, nullptr);
    ASSERT_TRUE_MSG(imageRef == nil, "FAILED: ImageIOTest::CGImageSourceCreateThumbnailAtIndex should return nullptr");
    CFRelease(imageSource);
}

TEST(ImageIO, TypeIdentifierTest) {
    NSArray* expectedTypeIdentifiers = [NSArray arrayWithObjects:@"public.png", 
                                                                 @"public.jpeg", 
                                                                 @"com.compuserve.gif", 
                                                                 @"public.tiff", 
                                                                 @"com.microsoft.ico", 
                                                                 @"com.microsoft.bmp", 
                                                                 nil];
    NSArray* actualTypeIdentifiers = (NSArray*)CGImageSourceCopyTypeIdentifiers();
    ASSERT_TRUE_MSG([expectedTypeIdentifiers isEqualToArray:actualTypeIdentifiers], 
                    "FAILED: ImageIOTest::Incorrect TypeIdentifier list returned");

    NSArray* expectedDestinationTypeIdentifiers = [NSArray arrayWithObjects:@"public.png", 
                                                                            @"public.jpeg", 
                                                                            @"com.compuserve.gif", 
                                                                            @"public.tiff", 
                                                                            @"com.microsoft.bmp", 
                                                                            nil];
    NSArray* actualDestinationTypeIdentifiers = (NSArray*)CGImageDestinationCopyTypeIdentifiers();
    ASSERT_TRUE_MSG([expectedDestinationTypeIdentifiers isEqualToArray:actualDestinationTypeIdentifiers], 
                    "FAILED: ImageIOTest::Incorrect Destination TypeIdentifier list returned");
}

TEST(ImageIO, TypeIDTest) {
    checkInt(CGImageSourceGetTypeID(), 286, "SourceTypeID");
}
/*
TEST(ImageIO, CopyPropertiesTest) {
    const wchar_t* imageFile = L"photo7_4layers_683x1024.gif";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeJPEG",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CFDictionaryRef imageProperties = CGImageSourceCopyProperties(imageSource, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageProperties != nil, "FAILED: ImageIOTest::CGImageSourceCopyProperties returned nullptr");
    if (imageProperties && CFDictionaryContainsKey(imageProperties, kCGImageSourceTypeIdentifierHint)) {
        //int maxThumbnailSize = [(id)CFDictionaryGetValue(options, kCGImageSourceThumbnailMaxPixelSize) intValue];
    }

    //checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    CFRelease(imageSource);
}
*/

TEST(ImageIO, CopyJPEGPropertiesAtIndexTest) {
    const wchar_t* imageFile = L"photo6_1024x670.jpg";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeJPEG",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageProperties != nil, "FAILED: ImageIOTest::CGImageSourceCopyPropertiesAtIndex returned nullptr");
    if (imageProperties) {
        if (CFDictionaryContainsKey(imageProperties, kCGImagePropertyDPIHeight)) {
            int actualDPIHeight = [(id)CFDictionaryGetValue(imageProperties, kCGImagePropertyDPIHeight) intValue];
            checkInt(actualDPIHeight, 72, "FAILED: ImageIOTest::CGImageSourceCopyPropertiesAtIndex returned incorrect DPIHeight");
        }
    }

    CFRelease(imageSource);
}

TEST(ImageIO, CopyGIFPropertiesAtIndexTest) {
    const wchar_t* imageFile = L"photo7_4layers_683x1024.gif";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeGIF",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageProperties != nil, "FAILED: ImageIOTest::CGImageSourceCopyPropertiesAtIndex returned nullptr");
    if (imageProperties) {
        CFStringRef expectedDPIHeight = static_cast<const CFStringRef>(@"72");
        CFStringRef actualDPIHeight;
        if (CFDictionaryGetValueIfPresent(imageProperties, kCGImagePropertyDPIHeight, (const void**)&actualDPIHeight)) {
                //ASSERT_OBJCEQ_MSG((NSString*)actualDPIHeight, @"72", "FAILED: ImageIOTest::CGImageSourceCopyPropertiesAtIndex returned incorrect DPIHeight");
        }
    }

    CFRelease(imageSource);
}

TEST(ImageIO, CopyTIFPropertiesAtIndexTest) {
    const wchar_t* imageFile = L"photo8_4layers_1024x683.tif";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeTIFF",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageProperties != nil, "FAILED: ImageIOTest::CGImageSourceCopyPropertiesAtIndex returned nullptr");
    if (imageProperties) {
        CFStringRef expectedDPIHeight = static_cast<const CFStringRef>(@"72");
        CFStringRef actualDPIHeight;
        if (CFDictionaryGetValueIfPresent(imageProperties, kCGImagePropertyDPIHeight, (const void**)&actualDPIHeight)) {
                //ASSERT_OBJCEQ_MSG((NSString*)actualDPIHeight, @"72", "FAILED: ImageIOTest::CGImageSourceCopyPropertiesAtIndex returned incorrect DPIHeight");
        }
    }

    CFRelease(imageSource);
}

TEST(ImageIO, CopyPNGPropertiesAtIndexTest) {
    const wchar_t* imageFile = L"seafloor_256x256.png";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypePNG",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageProperties != nil, "FAILED: ImageIOTest::CGImageSourceCopyPropertiesAtIndex returned nullptr");
    if (imageProperties) {
        CFStringRef expectedDPIHeight = static_cast<const CFStringRef>(@"72");
        CFStringRef actualDPIHeight;
        if (CFDictionaryGetValueIfPresent(imageProperties, kCGImagePropertyDPIHeight, (const void**)&actualDPIHeight)) {
                //ASSERT_OBJCEQ_MSG((NSString*)actualDPIHeight, @"72", "FAILED: ImageIOTest::CGImageSourceCopyPropertiesAtIndex returned incorrect DPIHeight");
        }
    }

    CFRelease(imageSource);
}

TEST(ImageIO, IncrementalJPEGImageWithData) {
    const wchar_t* imageFile = L"photo6_1024x670.jpg";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 100 * 1024;
    NSUInteger imageOffset = 0;
    CGImageSourceRef incImageSrcRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(incImageSrcRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];

    do {
        NSUInteger currentChunkSize = imageLength - imageOffset > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset length:currentChunkSize freeWhenDone:NO];
        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(incImageSrcRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        CGImageRef incImg = CGImageSourceCreateImageAtIndex(incImageSrcRef, 0, nil);
        if (!incImg) {
            NSLog(@"ImageAtIndex1 unavailable. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"ImageAtIndex1 displayed. Done - [%d]", imageLength == imageOffset);
        }

        if (CGImageSourceGetStatus(incImageSrcRef) == kCGImageStatusComplete) {
            NSLog(@"Loading ImageTotal Complete. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"ImageTotal Load Status - [%d]. Done - [%d]", CGImageSourceGetStatus(incImageSrcRef), imageLength == imageOffset);
        }

        if (CGImageSourceGetStatusAtIndex(incImageSrcRef, 0) == kCGImageStatusComplete) {
            NSLog(@"Loading Image1 Complete. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"Image1 Load Status - [%d]. Done - [%d]", CGImageSourceGetStatusAtIndex(incImageSrcRef, 0), imageLength == imageOffset);
        }
    } while(imageOffset < imageLength);
    CFRelease(incImageSrcRef);
    /*
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 670, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");
    size_t frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");
    CFRelease(imageSource);
    */
}

TEST(ImageIO, IncrementalBMPImageWithData) {
    const wchar_t* imageFile = L"testimg_227x149.bmp";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 15 * 1024;
    NSUInteger imageOffset = 0;
    CGImageSourceRef incImageSrcRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(incImageSrcRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];

    do {
        NSUInteger currentChunkSize = imageLength - imageOffset > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset length:currentChunkSize freeWhenDone:NO];
        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(incImageSrcRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        CGImageRef incImg = CGImageSourceCreateImageAtIndex(incImageSrcRef, 0, nil);
        if (!incImg) {
            NSLog(@"ImageAtIndex1 unavailable. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"ImageAtIndex1 displayed. Done - [%d]", imageLength == imageOffset);
        }

        if (CGImageSourceGetStatus(incImageSrcRef) == kCGImageStatusComplete) {
            NSLog(@"Loading ImageTotal Complete. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"ImageTotal Load Status - [%d]. Done - [%d]", CGImageSourceGetStatus(incImageSrcRef), imageLength == imageOffset);
        }

        if (CGImageSourceGetStatusAtIndex(incImageSrcRef, 0) == kCGImageStatusComplete) {
            NSLog(@"Loading Image1 Complete. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"Image1 Load Status - [%d]. Done - [%d]", CGImageSourceGetStatusAtIndex(incImageSrcRef, 0), imageLength == imageOffset);
        }
    } while(imageOffset < imageLength);
    CFRelease(incImageSrcRef);
}

TEST(ImageIO, IncrementalPNGImageWithData) {
    const wchar_t* imageFile = L"seafloor_256x256.png";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 25 * 1024;
    NSUInteger imageOffset = 0;
    CGImageSourceRef incImageSrcRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(incImageSrcRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];

    do {
        NSUInteger currentChunkSize = imageLength - imageOffset > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset length:currentChunkSize freeWhenDone:NO];
        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(incImageSrcRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        CGImageRef incImg = CGImageSourceCreateImageAtIndex(incImageSrcRef, 0, nil);
        if (!incImg) {
            NSLog(@"ImageAtIndex1 unavailable. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"ImageAtIndex1 displayed. Done - [%d]", imageLength == imageOffset);
        }

        if (CGImageSourceGetStatus(incImageSrcRef) == kCGImageStatusComplete) {
            NSLog(@"Loading ImageTotal Complete. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"ImageTotal Load Status - [%d]. Done - [%d]", CGImageSourceGetStatus(incImageSrcRef), imageLength == imageOffset);
        }

        if (CGImageSourceGetStatusAtIndex(incImageSrcRef, 0) == kCGImageStatusComplete) {
            NSLog(@"Loading Image1 Complete. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"Image1 Load Status - [%d]. Done - [%d]", CGImageSourceGetStatusAtIndex(incImageSrcRef, 0), imageLength == imageOffset);
        }
    } while(imageOffset < imageLength);
    CFRelease(incImageSrcRef);
}

TEST(ImageIO, IncrementalGIFImageWithData) {
    const wchar_t* imageFile = L"photo7_4layers_683x1024.gif";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 300 * 1024;
    NSUInteger imageOffset = 0;
    CGImageSourceRef incImageSrcRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(incImageSrcRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];

    do {
        NSUInteger currentChunkSize = imageLength - imageOffset > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset length:currentChunkSize freeWhenDone:NO];
        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(incImageSrcRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        CGImageRef incImg = CGImageSourceCreateImageAtIndex(incImageSrcRef, 0, nil);
        if (!incImg) {
            NSLog(@"ImageAtIndex1 unavailable. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"ImageAtIndex1 displayed. Done - [%d]", imageLength == imageOffset);
        }

        if (CGImageSourceGetStatus(incImageSrcRef) == kCGImageStatusComplete) {
            NSLog(@"Loading ImageTotal Complete. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"ImageTotal Load Status - [%d]. Done - [%d]", CGImageSourceGetStatus(incImageSrcRef), imageLength == imageOffset);
        }

        if (CGImageSourceGetStatusAtIndex(incImageSrcRef, 0) == kCGImageStatusComplete) {
            NSLog(@"Loading Image1 Complete. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"Image1 Load Status - [%d]. Done - [%d]", CGImageSourceGetStatusAtIndex(incImageSrcRef, 0), imageLength == imageOffset);
        }
    } while(imageOffset < imageLength);
    CFRelease(incImageSrcRef);
}

TEST(ImageIO, IncrementalTIFFImageWithData) {
    const wchar_t* imageFile = L"photo8_4layers_1024x683.tif";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 1000 * 1024;
    NSUInteger imageOffset = 0;
    CGImageSourceRef incImageSrcRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(incImageSrcRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];

    do {
        NSUInteger currentChunkSize = imageLength - imageOffset > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset length:currentChunkSize freeWhenDone:NO];
        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(incImageSrcRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        CGImageRef incImg = CGImageSourceCreateImageAtIndex(incImageSrcRef, 0, nil);
        if (!incImg) {
            NSLog(@"ImageAtIndex1 unavailable. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"ImageAtIndex1 displayed. Done - [%d]", imageLength == imageOffset);
        }

        if (CGImageSourceGetStatus(incImageSrcRef) == kCGImageStatusComplete) {
            NSLog(@"Loading ImageTotal Complete. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"ImageTotal Load Status - [%d]. Done - [%d]", CGImageSourceGetStatus(incImageSrcRef), imageLength == imageOffset);
        }

        if (CGImageSourceGetStatusAtIndex(incImageSrcRef, 0) == kCGImageStatusComplete) {
            NSLog(@"Loading Image1 Complete. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"Image1 Load Status - [%d]. Done - [%d]", CGImageSourceGetStatusAtIndex(incImageSrcRef, 0), imageLength == imageOffset);
        }
    } while(imageOffset < imageLength);
    CFRelease(incImageSrcRef);
}

TEST(ImageIO, IncrementalICOImageWithData) {
    const wchar_t* imageFile = L"photo2_683x1024.ico";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 400 * 1024;
    NSUInteger imageOffset = 0;
    CGImageSourceRef incImageSrcRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(incImageSrcRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];

    do {
        NSUInteger currentChunkSize = imageLength - imageOffset > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset length:currentChunkSize freeWhenDone:NO];
        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(incImageSrcRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        CGImageRef incImg = CGImageSourceCreateImageAtIndex(incImageSrcRef, 0, nil);
        if (!incImg) {
            NSLog(@"ImageAtIndex1 unavailable. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"ImageAtIndex1 displayed. Done - [%d]", imageLength == imageOffset);
        }

        if (CGImageSourceGetStatus(incImageSrcRef) == kCGImageStatusComplete) {
            NSLog(@"Loading ImageTotal Complete. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"ImageTotal Load Status - [%d]. Done - [%d]", CGImageSourceGetStatus(incImageSrcRef), imageLength == imageOffset);
        }

        if (CGImageSourceGetStatusAtIndex(incImageSrcRef, 0) == kCGImageStatusComplete) {
            NSLog(@"Loading Image1 Complete. Done - [%d]", imageLength == imageOffset);
        } else {
            NSLog(@"Image1 Load Status - [%d]. Done - [%d]", CGImageSourceGetStatusAtIndex(incImageSrcRef, 0), imageLength == imageOffset);
        }
    } while(imageOffset < imageLength);
    CFRelease(incImageSrcRef);
} 

TEST(ImageIO, DestinationTest) {
    const wchar_t* imageFile = L"photo6_1024x670.jpg";
    NSData* imageData = getDataFromImageFile(imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeJPEG",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 670, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");
    size_t frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");
    
    // get test startup full path
    wchar_t fullPath[_MAX_PATH];
    GetModuleFileNameW(NULL, fullPath, _MAX_PATH);

    // split test startup full path into components like drive, directory, filename and ext etc.
    wchar_t drive[_MAX_DRIVE];
    wchar_t directory[_MAX_DIR];
    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);

    // reconstruct fullpath for test artifact file. e.g., C:\WinObjc\WinObjC\build\Debug\data\photo6_1024x670.jpg
    const wchar_t* outFile = L"outphoto.tif";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), L"data\\");
    wcscat_s(fullPath, _countof(fullPath), outFile);
    NSString* directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    CFURLRef imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile];

    CGImageDestinationRef myImageDest = CGImageDestinationCreateWithURL(imgUrl, kUTTypeTIFF, 1, NULL);
    CGImageDestinationAddImage(myImageDest, imageRef, NULL);
    CGImageDestinationFinalize(myImageDest);

    // Read back in the newly written image to check properties
    CFRelease(imageSource);
    imageData = getDataFromImageFile(outFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", outFile);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 670, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");
    frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");

    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);
    const wchar_t* outFile2 = L"outphoto.jpg";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), outFile2);
    directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile]; 

    CFRelease(myImageDest);
    myImageDest = CGImageDestinationCreateWithURL(imgUrl, kUTTypeJPEG, 1, NULL);
    CGImageDestinationAddImage(myImageDest, imageRef, NULL);
    CGImageDestinationFinalize(myImageDest);

    // Read back in the newly written image to check properties
    CFRelease(imageSource);
    imageData = getDataFromImageFile(outFile2);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", outFile2);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 670, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");
    frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");

    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);
    const wchar_t* outFile3 = L"outphoto.png";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), outFile3);
    directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile]; 

    CFRelease(myImageDest);
    myImageDest = CGImageDestinationCreateWithURL(imgUrl, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(myImageDest, imageRef, NULL);
    CGImageDestinationFinalize(myImageDest);

    // Read back in the newly written image to check properties
    CFRelease(imageSource);
    imageData = getDataFromImageFile(outFile3);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", outFile3);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 670, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");
    frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");

    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);
    const wchar_t* outFile4 = L"outphoto.bmp";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), outFile4);
    directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile]; 

    CFRelease(myImageDest);
    myImageDest = CGImageDestinationCreateWithURL(imgUrl, kUTTypeBMP, 1, NULL);
    CGImageDestinationAddImage(myImageDest, imageRef, NULL);
    CGImageDestinationFinalize(myImageDest);
    
    // Read back in the newly written image to check properties
    CFRelease(imageSource);
    imageData = getDataFromImageFile(outFile4);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", outFile4);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 670, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");
    frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");

    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);
    const wchar_t* outFile5 = L"outphoto.gif";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), outFile5);
    directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile]; 

    CFRelease(myImageDest);
    myImageDest = CGImageDestinationCreateWithURL(imgUrl, kUTTypeGIF, 1, NULL);
    CGImageDestinationAddImage(myImageDest, imageRef, NULL);
    CGImageDestinationFinalize(myImageDest);
    
    // Read back in the newly written image to check properties
    CFRelease(imageSource);
    imageData = getDataFromImageFile(outFile5);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", outFile5);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 670, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");
    frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");
    
    CFRelease(myImageDest);
    CFRelease(imageSource);
}

TEST(ImageIO, DestinationFromSourceTest) {
    const wchar_t* imageFile = L"testimg_227x149.bmp";
    NSData* imageData = getDataFromImageFile(imageFile);
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    
    // get test startup full path
    wchar_t fullPath[_MAX_PATH];
    GetModuleFileNameW(NULL, fullPath, _MAX_PATH);

    // split test startup full path into components like drive, directory, filename and ext etc.
    wchar_t drive[_MAX_DRIVE];
    wchar_t directory[_MAX_DIR];
    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);

    // reconstruct fullpath for test artifact file. e.g., C:\WinObjc\WinObjC\build\Debug\data\photo6_1024x670.jpg
    const wchar_t* outFile = L"outphoto2.tif";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), L"data\\");
    wcscat_s(fullPath, _countof(fullPath), outFile);
    NSString* directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    CFURLRef imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile]; 

    CGImageDestinationRef myImageDest = CGImageDestinationCreateWithURL(imgUrl, kUTTypeTIFF, 1, NULL);
    CGImageDestinationAddImageFromSource(myImageDest, imageSource, 0, NULL);
    CGImageDestinationFinalize(myImageDest);
    CFRelease(myImageDest);

    // Read back in the newly written image to check properties
    CFRelease(imageSource);
    imageData = getDataFromImageFile(outFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", outFile);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 149, "Height");
    checkInt(CGImageGetWidth(imageRef), 227, "Width");
    size_t frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");

    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);
    const wchar_t* outFile2 = L"outphoto2.jpg";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), outFile2);
    directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile]; 

    myImageDest = CGImageDestinationCreateWithURL(imgUrl, kUTTypeJPEG, 1, NULL);
    CGImageDestinationAddImageFromSource(myImageDest, imageSource, 0, NULL);
    CGImageDestinationFinalize(myImageDest);
    CFRelease(myImageDest);

    // Read back in the newly written image to check properties
    CFRelease(imageSource);
    imageData = getDataFromImageFile(outFile2);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", outFile2);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 149, "Height");
    checkInt(CGImageGetWidth(imageRef), 227, "Width");
    frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");

    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);
    const wchar_t* outFile3 = L"outphoto2.png";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), outFile3);
    directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile]; 

    myImageDest = CGImageDestinationCreateWithURL(imgUrl, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImageFromSource(myImageDest, imageSource, 0, NULL);
    CGImageDestinationFinalize(myImageDest);
    CFRelease(myImageDest);

    // Read back in the newly written image to check properties
    CFRelease(imageSource);
    imageData = getDataFromImageFile(outFile3);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", outFile3);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 149, "Height");
    checkInt(CGImageGetWidth(imageRef), 227, "Width");
    frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");

    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);
    const wchar_t* outFile4 = L"outphoto2.bmp";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), outFile4);
    directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile]; 

    myImageDest = CGImageDestinationCreateWithURL(imgUrl, kUTTypeBMP, 1, NULL);
    CGImageDestinationAddImageFromSource(myImageDest, imageSource, 0, NULL);
    CGImageDestinationFinalize(myImageDest);
    CFRelease(myImageDest);

    // Read back in the newly written image to check properties
    CFRelease(imageSource);
    imageData = getDataFromImageFile(outFile4);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", outFile4);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 149, "Height");
    checkInt(CGImageGetWidth(imageRef), 227, "Width");
    frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");
    
    CFRelease(imageSource);
}

TEST(ImageIO, DestinationMultiFrameTest) {
    const wchar_t* imageFile = L"photo2_683x1024.ico";
    NSData* imageData = getDataFromImageFile(imageFile);
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);

    const wchar_t* imageFile2 = L"photo8_4layers_1024x683.tif";
    NSData* imageData2 = getDataFromImageFile(imageFile2);
    CGImageSourceRef imageSource2 = CGImageSourceCreateWithData((CFDataRef)imageData2, NULL);
    CGImageRef imageRef2 = CGImageSourceCreateImageAtIndex(imageSource2, 0, NULL);
    
    // get test startup full path
    wchar_t fullPath[_MAX_PATH];
    GetModuleFileNameW(NULL, fullPath, _MAX_PATH);

    // split test startup full path into components like drive, directory, filename and ext etc.
    wchar_t drive[_MAX_DRIVE];
    wchar_t directory[_MAX_DIR];
    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);

    // reconstruct fullpath for test artifact file. e.g., C:\WinObjc\WinObjC\build\Debug\data\photo6_1024x670.jpg
    const wchar_t* outFile = L"outphoto_multiframe.tif";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), L"data\\");
    wcscat_s(fullPath, _countof(fullPath), outFile);
    NSString* directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    CFURLRef imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile]; 

    CGImageDestinationRef myImageDest = CGImageDestinationCreateWithURL(imgUrl, kUTTypeTIFF, 3, NULL);
    CGImageDestinationAddImage(myImageDest, imageRef, NULL);
    CGImageDestinationAddImageFromSource(myImageDest, imageSource2, 0, NULL);
    CGImageDestinationAddImageFromSource(myImageDest, imageSource2, 2, NULL);
    CGImageDestinationFinalize(myImageDest);
    CFRelease(myImageDest);

    // Read back in the newly written image to check properties
    CFRelease(imageSource);
    imageData = getDataFromImageFile(outFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", outFile);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    size_t frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 3, "FrameCount");

    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 1024, "Height");
    checkInt(CGImageGetWidth(imageRef), 683, "Width");

    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 1, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 683, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");

    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 2, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 683, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");

    CFRelease(imageSource);
}

TEST(ImageIO, DestinationMultiFrameGifTest) {
    const wchar_t* imageFile = L"photo2_683x1024.ico";
    NSData* imageData = getDataFromImageFile(imageFile);
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);

    const wchar_t* imageFile2 = L"photo8_4layers_1024x683.tif";
    NSData* imageData2 = getDataFromImageFile(imageFile2);
    CGImageSourceRef imageSource2 = CGImageSourceCreateWithData((CFDataRef)imageData2, NULL);
    CGImageRef imageRef2 = CGImageSourceCreateImageAtIndex(imageSource2, 0, NULL);
    
    // get test startup full path
    wchar_t fullPath[_MAX_PATH];
    GetModuleFileNameW(NULL, fullPath, _MAX_PATH);

    // split test startup full path into components like drive, directory, filename and ext etc.
    wchar_t drive[_MAX_DRIVE];
    wchar_t directory[_MAX_DIR];
    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);

    // reconstruct fullpath for test artifact file. e.g., C:\WinObjc\WinObjC\build\Debug\data\photo6_1024x670.jpg
    const wchar_t* outFile = L"outphoto_multiframe.gif";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), L"data\\");
    wcscat_s(fullPath, _countof(fullPath), outFile);
    NSString* directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    CFURLRef imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile]; 

    CGImageDestinationRef myImageDest = CGImageDestinationCreateWithURL(imgUrl, kUTTypeGIF, 3, NULL);
    CGImageDestinationAddImage(myImageDest, imageRef, NULL);
    CGImageDestinationAddImageFromSource(myImageDest, imageSource2, 0, NULL);
    CGImageDestinationAddImageFromSource(myImageDest, imageSource2, 2, NULL);
    CGImageDestinationFinalize(myImageDest);
    CFRelease(myImageDest);

    // Read back in the newly written image to check properties
    CFRelease(imageSource);
    imageData = getDataFromImageFile(outFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", outFile);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    size_t frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 3, "FrameCount");

    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 1024, "Height");
    checkInt(CGImageGetWidth(imageRef), 683, "Width");

    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 1, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 683, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");

    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 2, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 683, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");

    CFRelease(imageSource);
}

TEST(ImageIO, DestinationDataTest) {
    const wchar_t* imageFile = L"photo2_683x1024.ico";
    NSData* imageData = getDataFromImageFile(imageFile);
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    
    NSMutableData* dataBuffer = [NSMutableData dataWithCapacity:10000000];

    CGImageDestinationRef myImageDest = CGImageDestinationCreateWithData((CFMutableDataRef)dataBuffer, kUTTypeTIFF, 1, NULL);
    CGImageDestinationAddImage(myImageDest, imageRef, NULL);
    CGImageDestinationFinalize(myImageDest);
    CFRelease(myImageDest);

    CFRelease(imageSource);
    imageSource = CGImageSourceCreateWithData((CFDataRef)dataBuffer, NULL);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    size_t frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 1024, "Height");
    checkInt(CGImageGetWidth(imageRef), 683, "Width");

    CFRelease(imageSource);
}

TEST(ImageIO, DestinationMultiFrameDataTest) {
    const wchar_t* imageFile = L"photo2_683x1024.ico";
    NSData* imageData = getDataFromImageFile(imageFile);
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);

    const wchar_t* imageFile2 = L"photo8_4layers_1024x683.tif";
    NSData* imageData2 = getDataFromImageFile(imageFile2);
    CGImageSourceRef imageSource2 = CGImageSourceCreateWithData((CFDataRef)imageData2, NULL);
    CGImageRef imageRef2 = CGImageSourceCreateImageAtIndex(imageSource2, 0, NULL);
    
    NSMutableData* dataBuffer = [NSMutableData dataWithCapacity:10000000];

    CGImageDestinationRef myImageDest = CGImageDestinationCreateWithData((CFMutableDataRef)dataBuffer, kUTTypeTIFF, 3, NULL);
    CGImageDestinationAddImage(myImageDest, imageRef, NULL);
    CGImageDestinationAddImageFromSource(myImageDest, imageSource2, 0, NULL);
    CGImageDestinationAddImageFromSource(myImageDest, imageSource2, 2, NULL);
    CGImageDestinationFinalize(myImageDest);
    CFRelease(myImageDest);

    // Read back in the newly written image to check properties
    CFRelease(imageSource);
    imageSource = CGImageSourceCreateWithData((CFDataRef)dataBuffer, NULL);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    size_t frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 3, "FrameCount");

    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 1024, "Height");
    checkInt(CGImageGetWidth(imageRef), 683, "Width");

    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 1, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 683, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");

    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 2, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 683, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");

    CFRelease(imageSource);
}

TEST(ImageIO, DestinationOptionsTest) {
    const wchar_t* imageFile = L"photo6_1024x670.jpg";
    NSData* imageData = getDataFromImageFile(imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeJPEG",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    
    // get test startup full path
    wchar_t fullPath[_MAX_PATH];
    GetModuleFileNameW(NULL, fullPath, _MAX_PATH);

    // split test startup full path into components like drive, directory, filename and ext etc.
    wchar_t drive[_MAX_DRIVE];
    wchar_t directory[_MAX_DIR];
    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);

    // reconstruct fullpath for test artifact file. e.g., C:\WinObjc\WinObjC\build\Debug\data\photo6_1024x670.jpg
    const wchar_t* outFile = L"outphotoLQ.jpg";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), L"data\\");
    wcscat_s(fullPath, _countof(fullPath), outFile);
    NSString* directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    CFURLRef imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile];

    float quality = 0.0;
    NSNumber* encodeQuality = [NSNumber numberWithFloat:quality];
    NSDictionary* encodeOptions = @{@"kCGImageDestinationLossyCompressionQuality":encodeQuality};

    CGImageDestinationRef myImageDest = CGImageDestinationCreateWithURL(imgUrl, kUTTypeJPEG, 1, NULL);
    CGImageDestinationAddImage(myImageDest, imageRef, (CFDictionaryRef)encodeOptions);
    CGImageDestinationFinalize(myImageDest);
    CFRelease(myImageDest);

    // Read back in the newly written image to check properties
    CFRelease(imageSource);
    imageData = getDataFromImageFile(outFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", outFile);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 670, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");
    size_t frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 1, "FrameCount");

    imageFile = L"photo2_683x1024.ico";
    imageData = getDataFromImageFile(imageFile);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);

    const wchar_t* imageFile2 = L"photo8_4layers_1024x683.tif";
    NSData* imageData2 = getDataFromImageFile(imageFile2);
    CGImageSourceRef imageSource2 = CGImageSourceCreateWithData((CFDataRef)imageData2, NULL);
    CGImageRef imageRef2 = CGImageSourceCreateImageAtIndex(imageSource2, 0, NULL);
    
    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);
    const wchar_t* outFile2 = L"outphoto_loopcount.gif";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), outFile2);
    NSString* directoryWithFile2 = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile2]; 

    int loopCount = 15;
    NSNumber* gifLoops = [NSNumber numberWithInt:loopCount];
    NSDictionary *gifEncodeOptions = @{
        (id)kCGImagePropertyGIFLoopCount:gifLoops,
    };

    NSDictionary *encodeDictionary = @{
        (id)kCGImagePropertyGIFDictionary:gifEncodeOptions,
    };

    myImageDest = CGImageDestinationCreateWithURL(imgUrl, kUTTypeGIF, 3, NULL);
    CGImageDestinationSetProperties(myImageDest, (CFDictionaryRef)encodeDictionary);
    CGImageDestinationAddImage(myImageDest, imageRef, NULL);
    CGImageDestinationAddImageFromSource(myImageDest, imageSource2, 0, NULL);
    CGImageDestinationAddImageFromSource(myImageDest, imageSource2, 2, NULL);
    CGImageDestinationFinalize(myImageDest);
    CFRelease(myImageDest);

    // Read back in the newly written image to check properties
    CFRelease(imageSource);
    imageData = getDataFromImageFile(outFile2);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", outFile2);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    frameCount = CGImageSourceGetCount(imageSource);
    checkInt(frameCount, 3, "FrameCount");

    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 1024, "Height");
    checkInt(CGImageGetWidth(imageRef), 683, "Width");

    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 1, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 683, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");

    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 2, NULL);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: ImageIOTest::CGImageSourceCreateImageAtIndex returned nullptr");
    checkInt(CGImageGetAlphaInfo(imageRef), 4, "AlphaInfo");
    checkInt(CGImageGetBitmapInfo(imageRef), 4, "BitmapInfo");
    checkInt(CGImageGetBitsPerComponent(imageRef), 8, "BitsPerComponent");
    checkInt(CGImageGetBitsPerPixel(imageRef), 32, "BitsPerPixel");
    checkInt(CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(imageRef)), 3, "ColorSpaceComponentCount");
    checkInt(CGImageGetHeight(imageRef), 683, "Height");
    checkInt(CGImageGetWidth(imageRef), 1024, "Width");

    CFRelease(imageSource);
}

TEST(ImageIO, DestinationImageOptionsTest) {
    const wchar_t* imageFile = L"photo2_683x1024.ico";
    NSData* imageData = getDataFromImageFile(imageFile);
    NSDictionary* options = @{@"kCGImageSourceTypeIdentifierHint":@"kUTTypeJPEG",
                              @"kCGImageSourceShouldAllowFloat":@"kCFBooleanTrue",
                              @"kCGImageSourceShouldCache":@"kCFBooleanTrue"};
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
    
    // get test startup full path
    wchar_t fullPath[_MAX_PATH];
    GetModuleFileNameW(NULL, fullPath, _MAX_PATH);

    // split test startup full path into components like drive, directory, filename and ext etc.
    wchar_t drive[_MAX_DRIVE];
    wchar_t directory[_MAX_DIR];
    ::_wsplitpath_s(fullPath, drive, _countof(drive), directory, _countof(directory), NULL, 0, NULL, 0);

    // reconstruct fullpath for test artifact file. e.g., C:\WinObjc\WinObjC\build\Debug\data\photo6_1024x670.jpg
    const wchar_t* outFile = L"outphoto_options.jpg";
    wcscpy_s(fullPath, _countof(fullPath), drive);
    wcscat_s(fullPath, _countof(fullPath), directory);
    wcscat_s(fullPath, _countof(fullPath), L"data\\");
    wcscat_s(fullPath, _countof(fullPath), outFile);
    NSString* directoryWithFile = [NSString stringWithCharacters:(const unichar*)fullPath length:_MAX_PATH];
    CFURLRef imgUrl = (CFURLRef)[NSURL fileURLWithPath:directoryWithFile];

    NSDictionary *gpsOptions = @{
        (id)kCGImagePropertyGPSLatitude:[NSNumber numberWithDouble:100.55],
        (id)kCGImagePropertyGPSLongitude:[NSNumber numberWithDouble:200.0],
        (id)kCGImagePropertyGPSLatitudeRef:@"N",
        (id)kCGImagePropertyGPSLongitudeRef:@"W",
        (id)kCGImagePropertyGPSAltitude:[NSNumber numberWithDouble:150.25],
        (id)kCGImagePropertyGPSAltitudeRef:[NSNumber numberWithShort:1],
        (id)kCGImagePropertyGPSImgDirection:[NSNumber numberWithFloat:2.4],
        (id)kCGImagePropertyGPSImgDirectionRef:@"test",
    };

    NSDictionary *exifOptions = @{
        (id)kCGImagePropertyExifUserComment:@"test2",
        (id)kCGImagePropertyExifExposureTime:[NSNumber numberWithDouble:12.345],
    };

    int orientation = 2;
    NSNumber* encodeOrientation = [NSNumber numberWithInt:orientation];

    NSDictionary *encodeOptions = @{
        (id)kCGImagePropertyGPSDictionary:gpsOptions,
        (id)kCGImagePropertyOrientation:encodeOrientation,
        (id)kCGImagePropertyExifDictionary:exifOptions,
    };

    CGImageDestinationRef myImageDest = CGImageDestinationCreateWithURL(imgUrl, kUTTypeJPEG, 1, NULL);
    CGImageDestinationAddImage(myImageDest, imageRef, (CFDictionaryRef)encodeOptions);
    CGImageDestinationFinalize(myImageDest);
    CFRelease(myImageDest);

    CFRelease(imageSource);
    imageData = getDataFromImageFile(outFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", outFile);
    imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageSource != nil, "FAILED: ImageIOTest::CGImageSourceCreateWithData returned nullptr");
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (CFDictionaryRef)options);
    ASSERT_TRUE_MSG(imageProperties != nil, "FAILED: ImageIOTest::CGImageSourceCopyPropertiesAtIndex returned nullptr");
    if (imageProperties) {
        CFStringRef expectedDPIHeight = static_cast<const CFStringRef>(@"72");
        CFStringRef actualDPIHeight;
        if (CFDictionaryGetValueIfPresent(imageProperties, kCGImagePropertyDPIHeight, (const void**)&actualDPIHeight)) {
                //ASSERT_OBJCEQ_MSG((NSString*)actualDPIHeight, @"72", "FAILED: ImageIOTest::CGImageSourceCopyPropertiesAtIndex returned incorrect DPIHeight");
        }
    }

    CFRelease(imageSource);
}