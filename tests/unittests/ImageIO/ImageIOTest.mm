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
    EbrFile *fp = EbrFopen([testFileFullPath UTF8String], "rb");
    if (!fp) {
        return nil;
    } 
    
    EbrFseek(fp, 0, SEEK_END);
    size_t length = EbrFtell(fp);
    char *byteData = (char *)IwMalloc(length);
    EbrFseek(fp, 0, SEEK_SET);
    size_t newLen = EbrFread(byteData, sizeof(char), length, fp);
    EbrFclose(fp);

    NSData* imgData = [NSData dataWithBytes:(const void *)byteData length:length];
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
}

TEST(ImageIO, TypeIDTest) {
    checkInt(CGImageSourceGetTypeID(), 286, "SourceTypeID");
}

TEST(ImageIO, IncrementalJPEGImageWithData) {
    const wchar_t* imageFile = L"photo6_1024x670.jpg";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 100 * 1024;
    NSUInteger imageOffset = 0;

    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];
    static const int expectedImageStatus[] = {kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex[] = {kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusComplete};
    size_t expectedImageIndex = 0;

    do {
        NSUInteger currentChunkSize = (imageLength - imageOffset) > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset 
                                                         length:currentChunkSize 
                                                   freeWhenDone:NO];

        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(imageRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[expectedImageIndex], "ImageStatus");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex[expectedImageIndex++], "ImageStatusAtIndex");
    } while(imageOffset < imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalBMPImageWithData) {
    const wchar_t* imageFile = L"testimg_227x149.bmp";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 15 * 1024;
    NSUInteger imageOffset = 0;

    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];
    static const int expectedImageStatus[] = {kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex[] = {kCGImageStatusUnknownType, kCGImageStatusUnknownType, kCGImageStatusComplete};
    size_t expectedImageIndex = 0;

    do {
        NSUInteger currentChunkSize = (imageLength - imageOffset) > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset 
                                                         length:currentChunkSize 
                                                   freeWhenDone:NO];

        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(imageRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[expectedImageIndex], "ImageStatus");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex[expectedImageIndex++], "ImageStatusAtIndex");
    } while(imageOffset < imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalPNGImageWithData) {
    const wchar_t* imageFile = L"seafloor_256x256.png";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 25 * 1024;
    NSUInteger imageOffset = 0;

    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];
    static const int expectedImageStatus[] = {kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex[] = {kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusComplete};
    size_t expectedImageIndex = 0;

    do {
        NSUInteger currentChunkSize = (imageLength - imageOffset) > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset 
                                                         length:currentChunkSize 
                                                   freeWhenDone:NO];

        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(imageRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[expectedImageIndex], "ImageStatus");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex[expectedImageIndex++], "ImageStatus");
    } while(imageOffset < imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalGIFImageWithData) {
    const wchar_t* imageFile = L"photo7_4layers_683x1024.gif";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 300 * 1024;
    NSUInteger imageOffset = 0;

    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];
    static const int expectedImageStatus[] = {kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex1[] = {kCGImageStatusIncomplete, kCGImageStatusComplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex2[] = {kCGImageStatusUnknownType, kCGImageStatusComplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex3[] = {kCGImageStatusUnknownType, kCGImageStatusComplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex4[] = {kCGImageStatusUnknownType, kCGImageStatusIncomplete, kCGImageStatusComplete};
    size_t expectedImageIndex = 0;

    do {
        NSUInteger currentChunkSize = (imageLength - imageOffset) > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset 
                                                         length:currentChunkSize 
                                                   freeWhenDone:NO];

        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(imageRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[expectedImageIndex], "ImageStatus");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex1[expectedImageIndex], "ImageStatusAtIndex1");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 1), expectedImageStatusAtIndex2[expectedImageIndex], "ImageStatusAtIndex2");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 2), expectedImageStatusAtIndex3[expectedImageIndex], "ImageStatusAtIndex3");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 3), expectedImageStatusAtIndex4[expectedImageIndex++], "ImageStatusAtIndex4");
    } while(imageOffset < imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalTIFFImageWithData) {
    const wchar_t* imageFile = L"photo8_4layers_1024x683.tif";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 1000 * 1024;
    NSUInteger imageOffset = 0;

    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];
    static const int expectedImageStatus[] = {kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusIncomplete, 
                                              kCGImageStatusIncomplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex1[] = {kCGImageStatusUnknownType, kCGImageStatusComplete, kCGImageStatusComplete, 
                                                      kCGImageStatusComplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex2[] = {kCGImageStatusUnknownType, kCGImageStatusComplete, kCGImageStatusComplete, 
                                                      kCGImageStatusComplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex3[] = {kCGImageStatusUnknownType, kCGImageStatusUnknownType, kCGImageStatusUnknownType, 
                                                      kCGImageStatusComplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex4[] = {kCGImageStatusUnknownType, kCGImageStatusUnknownType, kCGImageStatusUnknownType, 
                                                      kCGImageStatusUnknownType, kCGImageStatusComplete};
    size_t expectedImageIndex = 0;

    do {
        NSUInteger currentChunkSize = (imageLength - imageOffset) > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset 
                                                         length:currentChunkSize 
                                                   freeWhenDone:NO];

        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(imageRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[expectedImageIndex], "ImageStatus");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex1[expectedImageIndex], "ImageStatusAtIndex1");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 1), expectedImageStatusAtIndex2[expectedImageIndex], "ImageStatusAtIndex2");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 2), expectedImageStatusAtIndex3[expectedImageIndex], "ImageStatusAtIndex3");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 3), expectedImageStatusAtIndex4[expectedImageIndex++], "ImageStatusAtIndex4");
    } while(imageOffset < imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalICOImageWithData) {
    const wchar_t* imageFile = L"photo2_683x1024.ico";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 200 * 1024;
    NSUInteger imageOffset = 0;

    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];
    static const int expectedImageStatus[] = {kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusIncomplete, 
                                              kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex[] = {kCGImageStatusUnknownType, kCGImageStatusUnknownType, kCGImageStatusUnknownType, 
                                                     kCGImageStatusUnknownType, kCGImageStatusUnknownType, kCGImageStatusComplete};
    size_t expectedImageIndex = 0;

    do {
        NSUInteger currentChunkSize = (imageLength - imageOffset) > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset 
                                                         length:currentChunkSize 
                                                   freeWhenDone:NO];

        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(imageRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[expectedImageIndex], "ImageStatus");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex[expectedImageIndex++], "ImageStatusAtIndex");
    } while(imageOffset < imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalJPEGImageCornerScenario) {
    const wchar_t* imageFile = L"photo6_1024x670.jpg";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize[] = {50, 100, 4000, imageLength};
    NSUInteger currentChunkSize = 0;

    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    static const int expectedImageStatus[] = {kCGImageStatusInvalidData, kCGImageStatusIncomplete, kCGImageStatusIncomplete, 
                                              kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex[] = {kCGImageStatusReadingHeader, kCGImageStatusUnknownType, kCGImageStatusIncomplete, 
                                                     kCGImageStatusComplete};
    size_t index = 0;

    do {
        currentChunkSize = imageChunkSize[index];
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] 
                                                         length:currentChunkSize 
                                                   freeWhenDone:NO];
        CGImageSourceUpdateData(imageRef, (CFDataRef)currentImageChunk, imageLength == currentChunkSize);
        checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[index], "ImageStatus");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex[index++], "ImageStatusAtIndex");
    } while(currentChunkSize != imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalBMPImageCornerScenario) {
    const wchar_t* imageFile = L"testimg_227x149.bmp";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize[] = {50, 100, imageLength};
    NSUInteger currentChunkSize = 0;

    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    static const int expectedImageStatus[] = {kCGImageStatusInvalidData, kCGImageStatusIncomplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex[] = {kCGImageStatusReadingHeader, kCGImageStatusUnknownType, kCGImageStatusComplete};
    size_t index = 0;

    do {
        currentChunkSize = imageChunkSize[index];
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] 
                                                         length:currentChunkSize 
                                                   freeWhenDone:NO];
        CGImageSourceUpdateData(imageRef, (CFDataRef)currentImageChunk, imageLength == currentChunkSize);
        checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[index], "ImageStatus");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex[index++], "ImageStatusAtIndex");
    } while(currentChunkSize != imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalPNGImageCornerScenario) {
    const wchar_t* imageFile = L"seafloor_256x256.png";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize[] = {50, 100, 1000, imageLength};
    NSUInteger currentChunkSize = 0;

    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    static const int expectedImageStatus[] = {kCGImageStatusInvalidData, kCGImageStatusIncomplete, kCGImageStatusIncomplete, 
                                              kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex[] = {kCGImageStatusReadingHeader, kCGImageStatusUnknownType, kCGImageStatusIncomplete, 
                                                     kCGImageStatusComplete};
    size_t index = 0;

    do {
        currentChunkSize = imageChunkSize[index];
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] 
                                                         length:currentChunkSize 
                                                   freeWhenDone:NO];
        CGImageSourceUpdateData(imageRef, (CFDataRef)currentImageChunk, imageLength == currentChunkSize);
        checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[index], "ImageStatus");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex[index++], "ImageStatusAtIndex");
    } while(currentChunkSize != imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalGIFImageCornerScenario) {
    const wchar_t* imageFile = L"photo7_4layers_683x1024.gif";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize[] = {50, 100, 1600, imageLength};
    NSUInteger currentChunkSize = 0;

    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    static const int expectedImageStatus[] = {kCGImageStatusInvalidData, kCGImageStatusIncomplete, kCGImageStatusIncomplete, 
                                              kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex[] = {kCGImageStatusReadingHeader, kCGImageStatusUnknownType, kCGImageStatusIncomplete, 
                                                     kCGImageStatusComplete};
    size_t index = 0;

    do {
        currentChunkSize = imageChunkSize[index];
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] 
                                                         length:currentChunkSize 
                                                   freeWhenDone:NO];
        CGImageSourceUpdateData(imageRef, (CFDataRef)currentImageChunk, imageLength == currentChunkSize);
        checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[index], "ImageStatus");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex[index++], "ImageStatusAtIndex");
    } while(currentChunkSize != imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalTIFFImageCornerScenario) {
    const wchar_t* imageFile = L"photo8_4layers_1024x683.tif";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize[] = {50, 100, 1151528, imageLength};
    NSUInteger currentChunkSize = 0;

    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    static const int expectedImageStatus[] = {kCGImageStatusInvalidData, kCGImageStatusIncomplete, kCGImageStatusIncomplete, 
                                              kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex[] = {kCGImageStatusReadingHeader, kCGImageStatusUnknownType, kCGImageStatusIncomplete, 
                                                     kCGImageStatusComplete};
    size_t index = 0;

    do {
        currentChunkSize = imageChunkSize[index];
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] 
                                                         length:currentChunkSize 
                                                   freeWhenDone:NO];
        CGImageSourceUpdateData(imageRef, (CFDataRef)currentImageChunk, imageLength == currentChunkSize);
        checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[index], "ImageStatus");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex[index++], "ImageStatusAtIndex");
    } while(currentChunkSize != imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalICOImageCornerScenario) {
    const wchar_t* imageFile = L"photo2_683x1024.ico";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize[] = {50, 100, imageLength};
    NSUInteger currentChunkSize = 0;

    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    static const int expectedImageStatus[] = {kCGImageStatusInvalidData, kCGImageStatusIncomplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex[] = {kCGImageStatusReadingHeader, kCGImageStatusUnknownType, kCGImageStatusComplete};
    size_t index = 0;

    do {
        currentChunkSize = imageChunkSize[index];
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] 
                                                         length:currentChunkSize 
                                                   freeWhenDone:NO];
        CGImageSourceUpdateData(imageRef, (CFDataRef)currentImageChunk, imageLength == currentChunkSize);
        checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[index], "ImageStatus");
        checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex[index++], "ImageStatusAtIndex");
    } while(currentChunkSize != imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalJPEGImageWithByteChunks) {
    const wchar_t* imageFile = L"photo6_1024x670.jpg";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 1;
    NSUInteger imageOffset = 0;

    static const int containerStatus[] = {kCGImageStatusInvalidData, kCGImageStatusIncomplete, kCGImageStatusComplete};
    static const int streamLength[] = {1, 96, 218940}; 
    static const int frameStatus[] = {kCGImageStatusReadingHeader, kCGImageStatusUnknownType, kCGImageStatusIncomplete, 
                                      kCGImageStatusComplete};
    static const int streamLengthAtIndex[] = {1, 96, 3851, 218940}; 

    size_t containerIndex = 0;
    size_t frameIndex = 0;
    static const int undefinedStatus = -10;
    int previousContainerStatus = undefinedStatus;
    int previousFrameStatus = undefinedStatus;

    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");

    do {
        imageOffset += imageChunkSize;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] 
                                                         length:imageOffset 
                                                   freeWhenDone:NO];
        CGImageSourceUpdateData(imageRef, (CFDataRef)currentImageChunk, imageLength == imageOffset);

        int currentStatus = CGImageSourceGetStatus(imageRef);
        if (previousContainerStatus == undefinedStatus) {
            checkInt(currentStatus, containerStatus[containerIndex], "ImageStatus");
            checkInt(imageOffset, streamLength[containerIndex++], "ImageStatusLength");
        } else if (currentStatus != previousContainerStatus) {
            checkInt(currentStatus, containerStatus[containerIndex], "ImageStatus");
            checkInt(imageOffset, streamLength[containerIndex++], "ImageStatusLength");
        }

        previousContainerStatus = currentStatus;
        currentStatus = CGImageSourceGetStatusAtIndex(imageRef, 0);
        if (previousFrameStatus == undefinedStatus) {
            checkInt(currentStatus, frameStatus[frameIndex], "ImageStatusAtIndex");
            checkInt(imageOffset, streamLengthAtIndex[frameIndex++], "ImageStatusAtIndexLength");
        } else if (currentStatus != previousFrameStatus) {
            checkInt(currentStatus, frameStatus[frameIndex], "ImageStatusAtIndex");
            checkInt(imageOffset, streamLengthAtIndex[frameIndex++], "ImageStatusAtIndexLength");
        }

        previousFrameStatus = currentStatus;
    } while(imageOffset < imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalBMPImageWithByteChunks) {
    const wchar_t* imageFile = L"testimg_227x149.bmp";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 1;
    NSUInteger imageOffset = 0;

    static const int containerStatus[] = {kCGImageStatusInvalidData, kCGImageStatusIncomplete, kCGImageStatusComplete};
    static const int streamLength[] = {1, 96, 218940}; 
    static const int frameStatus[] = {kCGImageStatusReadingHeader, kCGImageStatusUnknownType, kCGImageStatusIncomplete, 
                                      kCGImageStatusComplete};
    static const int streamLengthAtIndex[] = {1, 96, 3851, 218940}; 

    size_t containerIndex = 0;
    size_t frameIndex = 0;
    static const int undefinedStatus = -10;
    int previousContainerStatus = undefinedStatus;
    int previousFrameStatus = undefinedStatus;

    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");

    do {
        imageOffset += imageChunkSize;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] 
                                                         length:imageOffset 
                                                   freeWhenDone:NO];
        CGImageSourceUpdateData(imageRef, (CFDataRef)currentImageChunk, imageLength == imageOffset);

        int currentStatus = CGImageSourceGetStatus(imageRef);
        if (previousContainerStatus == undefinedStatus) {
            checkInt(currentStatus, containerStatus[containerIndex], "ImageStatus");
            checkInt(imageOffset, streamLength[containerIndex++], "ImageStatusLength");
        } else if (currentStatus != previousContainerStatus) {
            checkInt(currentStatus, containerStatus[containerIndex], "ImageStatus");
            checkInt(imageOffset, streamLength[containerIndex++], "ImageStatusLength");
        }

        previousContainerStatus = currentStatus;
        currentStatus = CGImageSourceGetStatusAtIndex(imageRef, 0);
        if (previousFrameStatus == undefinedStatus) {
            checkInt(currentStatus, frameStatus[frameIndex], "ImageStatusAtIndex");
            checkInt(imageOffset, streamLengthAtIndex[frameIndex++], "ImageStatusAtIndexLength");
        } else if (currentStatus != previousFrameStatus) {
            checkInt(currentStatus, frameStatus[frameIndex], "ImageStatusAtIndex");
            checkInt(imageOffset, streamLengthAtIndex[frameIndex++], "ImageStatusAtIndexLength");
        }

        previousFrameStatus = currentStatus;
    } while(imageOffset < imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalPNGImageWithByteChunks) {
    const wchar_t* imageFile = L"seafloor_256x256.png";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 1;//25 * 1024;
    NSUInteger imageOffset = 0;
    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];
    static const int expectedImageStatus[] = {kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex[] = {kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusComplete};
    size_t expectedImageIndex = 0;
    int previousStatus = 10;

    do {
        imageOffset += imageChunkSize;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] 
                                                         length:imageOffset 
                                                   freeWhenDone:NO];
        CGImageSourceUpdateData(imageRef, (CFDataRef)currentImageChunk, imageLength == imageOffset);

        int currentStatus = CGImageSourceGetStatus(imageRef);
        if (previousContainerStatus == undefinedStatus) {
            checkInt(currentStatus, containerStatus[containerIndex], "ImageStatus");
            checkInt(imageOffset, streamLength[containerIndex++], "ImageStatusLength");
        } else if (currentStatus != previousContainerStatus) {
            checkInt(currentStatus, containerStatus[containerIndex], "ImageStatus");
            checkInt(imageOffset, streamLength[containerIndex++], "ImageStatusLength");
        }

        previousContainerStatus = currentStatus;
        currentStatus = CGImageSourceGetStatusAtIndex(imageRef, 0);
        if (previousFrameStatus == undefinedStatus) {
            checkInt(currentStatus, frameStatus[frameIndex], "ImageStatusAtIndex");
            checkInt(imageOffset, streamLengthAtIndex[frameIndex++], "ImageStatusAtIndexLength");
        } else if (currentStatus != previousFrameStatus) {
            checkInt(currentStatus, frameStatus[frameIndex], "ImageStatusAtIndex");
            checkInt(imageOffset, streamLengthAtIndex[frameIndex++], "ImageStatusAtIndexLength");
        }

        previousFrameStatus = currentStatus;
    } while(imageOffset < imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalGIFImageWithByteChunks) {
    const wchar_t* imageFile = L"photo7_4layers_683x1024.gif";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 1;//300 * 1024;
    NSUInteger imageOffset = 0;
    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];
    static const int expectedImageStatus[] = {kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex1[] = {kCGImageStatusIncomplete, kCGImageStatusComplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex2[] = {kCGImageStatusUnknownType, kCGImageStatusComplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex3[] = {kCGImageStatusUnknownType, kCGImageStatusComplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex4[] = {kCGImageStatusUnknownType, kCGImageStatusIncomplete, kCGImageStatusComplete};
    size_t expectedImageIndex = 0;
    int previousStatus = 10;

    do {
        NSUInteger currentChunkSize = (imageLength - imageOffset) > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset 
                                            length:currentChunkSize 
                                            freeWhenDone:NO];
        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(imageRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        static int iterator = 0;
        int currentStatus = CGImageSourceGetStatusAtIndex(imageRef, 0);
        if (previousStatus == 10) {
          printf("Status[%d] Length[%d]", currentStatus, iterator);
        } else if (currentStatus != previousStatus) {
          printf("Status[%d] Length[%d]", currentStatus, iterator);
        }
        previousStatus = currentStatus;
        iterator++;
        CGImageSourceGetStatusAtIndex(imageRef, 0);
        //checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[expectedImageIndex], "ImageStatus");
        //checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex1[expectedImageIndex], "ImageStatusAtIndex1");
        //checkInt(CGImageSourceGetStatusAtIndex(imageRef, 1), expectedImageStatusAtIndex2[expectedImageIndex], "ImageStatusAtIndex2");
        //checkInt(CGImageSourceGetStatusAtIndex(imageRef, 2), expectedImageStatusAtIndex3[expectedImageIndex], "ImageStatusAtIndex3");
        //checkInt(CGImageSourceGetStatusAtIndex(imageRef, 3), expectedImageStatusAtIndex4[expectedImageIndex++], "ImageStatusAtIndex4");
    } while(imageOffset < imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalTIFFImageWithByteChunks) {
    const wchar_t* imageFile = L"photo8_4layers_1024x683.tif";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 1;//1000 * 1024;
    NSUInteger imageOffset = 0;
    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];
    static const int expectedImageStatus[] = {kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusIncomplete, 
                                              kCGImageStatusIncomplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex1[] = {kCGImageStatusUnknownType, kCGImageStatusComplete, kCGImageStatusComplete, 
                                                      kCGImageStatusComplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex2[] = {kCGImageStatusUnknownType, kCGImageStatusComplete, kCGImageStatusComplete, 
                                                      kCGImageStatusComplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex3[] = {kCGImageStatusUnknownType, kCGImageStatusUnknownType, kCGImageStatusUnknownType, 
                                                      kCGImageStatusComplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex4[] = {kCGImageStatusUnknownType, kCGImageStatusUnknownType, kCGImageStatusUnknownType, 
                                                      kCGImageStatusUnknownType, kCGImageStatusComplete};
    size_t expectedImageIndex = 0;
    int previousStatus = 10;

    do {
        NSUInteger currentChunkSize = (imageLength - imageOffset) > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset 
                                            length:currentChunkSize 
                                            freeWhenDone:NO];
        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(imageRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        static int iterator = 0;
        int currentStatus = CGImageSourceGetStatusAtIndex(imageRef, 0);
        if (previousStatus == 10) {
          printf("Status[%d] Length[%d]", currentStatus, iterator);
        } else if (currentStatus != previousStatus) {
          printf("Status[%d] Length[%d]", currentStatus, iterator);
        }
        previousStatus = currentStatus;
        iterator++;
        CGImageSourceGetStatusAtIndex(imageRef, 0);
        //checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[expectedImageIndex], "ImageStatus");
        //checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex1[expectedImageIndex], "ImageStatusAtIndex1");
        //checkInt(CGImageSourceGetStatusAtIndex(imageRef, 1), expectedImageStatusAtIndex2[expectedImageIndex], "ImageStatusAtIndex2");
        //checkInt(CGImageSourceGetStatusAtIndex(imageRef, 2), expectedImageStatusAtIndex3[expectedImageIndex], "ImageStatusAtIndex3");
        //checkInt(CGImageSourceGetStatusAtIndex(imageRef, 3), expectedImageStatusAtIndex4[expectedImageIndex++], "ImageStatusAtIndex4");
    } while(imageOffset < imageLength);
    CFRelease(imageRef);
}

TEST(ImageIO, IncrementalICOImageWithByteChunks) {
    const wchar_t* imageFile = L"photo2_683x1024.ico";
    NSData* imageData = getDataFromImageFile(imageFile);
    ASSERT_TRUE_MSG(imageData != nil, "FAILED: ImageIOTest::Could not find file: [%s]", imageFile);
    NSUInteger imageLength = [imageData length];
    NSUInteger imageChunkSize = 1;//200 * 1024;
    NSUInteger imageOffset = 0;
    CGImageSourceRef imageRef = CGImageSourceCreateIncremental(nil);
    ASSERT_TRUE_MSG(imageRef != nil, "FAILED: CGImageSourceCreateIncremental returned nullptr");
    NSMutableData* incrementalImageData = [NSMutableData data];
    static const int expectedImageStatus[] = {kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusIncomplete, 
                                              kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusComplete};
    static const int expectedImageStatusAtIndex[] = {kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusIncomplete, 
                                                     kCGImageStatusIncomplete, kCGImageStatusIncomplete, kCGImageStatusComplete};
    size_t expectedImageIndex = 0;
    int previousStatus = 10;

    do {
        NSUInteger currentChunkSize = (imageLength - imageOffset) > imageChunkSize ? imageChunkSize : imageLength - imageOffset;
        NSData* currentImageChunk = [NSData dataWithBytesNoCopy:(char*)[imageData bytes] + imageOffset 
                                            length:currentChunkSize 
                                            freeWhenDone:NO];
        [incrementalImageData appendData:currentImageChunk];
        imageOffset += currentChunkSize;
        CGImageSourceUpdateData(imageRef, (CFDataRef)incrementalImageData, imageLength == imageOffset);
        static int iterator = 0;
        int currentStatus = CGImageSourceGetStatusAtIndex(imageRef, 0);
        if (previousStatus == 10) {
          printf("Status[%d] Length[%d]", currentStatus, iterator);
        } else if (currentStatus != previousStatus) {
          printf("Status[%d] Length[%d]", currentStatus, iterator);
        }
        previousStatus = currentStatus;
        iterator++;
        CGImageSourceGetStatusAtIndex(imageRef, 0);
        //checkInt(CGImageSourceGetStatus(imageRef), expectedImageStatus[expectedImageIndex], "ImageStatus");
        //checkInt(CGImageSourceGetStatusAtIndex(imageRef, 0), expectedImageStatusAtIndex[expectedImageIndex++], "ImageStatusAtIndex");
    } while(imageOffset < imageLength);
    CFRelease(imageRef);
}