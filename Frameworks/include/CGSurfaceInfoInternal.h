//******************************************************************************
//
// Copyright (c) 2016 Intel Corporation. All rights reserved.
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

#ifndef __CGSURFACEINFOINTERNAL_H
#define __CGSURFACEINFOINTERNAL_H

#import "CoreGraphics/CoreGraphicsExport.h"

typedef struct {
    CGColorSpaceModel colorSpaceModel;
    CGBitmapInfo bitmapInfo;
    unsigned int bitsPerComponent;
    unsigned int bytesPerPixel;
}__CGFormatProperties;

static const __CGFormatProperties c_FormatTable[_ColorMax] = {
    { kCGColorSpaceModelRGB,        (kCGImageAlphaNone  | kCGBitmapByteOrderDefault),          5, 2 }, //_Color565,
    { kCGColorSpaceModelRGB,        (kCGImageAlphaFirst | kCGBitmapByteOrderDefault),          8, 4 }, //_ColorARGB,
    { kCGColorSpaceModelRGB,        (kCGImageAlphaLast  | kCGBitmapByteOrder32Little),         8, 4 }, //_ColorABGR,
    { kCGColorSpaceModelRGB,        (kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrderDefault),  8, 4 }, //_ColorBGRX,
    { kCGColorSpaceModelRGB,        (kCGImageAlphaNoneSkipLast  | kCGBitmapByteOrder32Little), 8, 4 }, //_ColorXBGR,
    { kCGColorSpaceModelMonochrome, (kCGImageAlphaNone | kCGBitmapByteOrderDefault),           8, 1 }, //_ColorGrayscale,
    { kCGColorSpaceModelRGB,        (kCGImageAlphaNone | kCGBitmapByteOrderDefault),           8, 3 }, //_ColorBGR,
    { kCGColorSpaceModelPattern,    (kCGImageAlphaOnly | kCGBitmapByteOrderDefault),           8, 1 }, //_ColorA8,
    { kCGColorSpaceModelIndexed,    (kCGImageAlphaNone | kCGBitmapByteOrderDefault),           8, 2 }, //_ColorIndexed,
};

static CGBitmapInfo c_kCGBitmapInfoInvalidBits = 0xDEADBEEF;

static inline __CGSurfaceInfo _CGSurfaceInfoInit(size_t width,
                                                 size_t height,
                                                 surfaceFormat fmt,
                                                 void* data = NULL,
                                                 size_t bytesPerRow = 0,
                                                 CGBitmapInfo bitmapInfo = c_kCGBitmapInfoInvalidBits) {
    __CGSurfaceInfo surfaceInfo;

    assert(fmt < _ColorMax);
    surfaceInfo.colorSpaceModel = c_FormatTable[fmt].colorSpaceModel;
    surfaceInfo.bitmapInfo = c_FormatTable[fmt].bitmapInfo;
    surfaceInfo.bitsPerComponent = c_FormatTable[fmt].bitsPerComponent;
    surfaceInfo.bytesPerPixel = c_FormatTable[fmt].bytesPerPixel;
    surfaceInfo.format = fmt;
    surfaceInfo.width = width;
    surfaceInfo.height = height;
    surfaceInfo.surfaceData = data;

    // Set bytesPerRow if necessary
    if ((data != NULL) && (bytesPerRow == 0)) {
        surfaceInfo.bytesPerRow = width * surfaceInfo.bytesPerPixel;
    }

    // Override bitmapInfo if it is passed in
    if (bitmapInfo != c_kCGBitmapInfoInvalidBits) {
        surfaceInfo.bitmapInfo = bitmapInfo;
    }


    return surfaceInfo;
}

#endif