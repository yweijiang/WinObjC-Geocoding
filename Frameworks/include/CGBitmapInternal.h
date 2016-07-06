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

#ifndef __CGBITMAPINTERNAL_H
#define __CGBITMAPINTERNAL_H

#import "CoreGraphics/CoreGraphicsExport.h"

static CGBitmapInfo c_kCGBitmapInfoInvalidBits = 0xDEADBEEF;

static inline CGBitmapInfo _CGBitmapGetBitmapInfoFromFormat(surfaceFormat fmt) { 
    CGBitmapInfo ret;

    switch (fmt) {
        case _ColorARGB:
            ret = kCGImageAlphaFirst | kCGBitmapByteOrderDefault;
            break;
        case _ColorABGR:
            ret = kCGImageAlphaLast | kCGBitmapByteOrder32Little;
            break;
        case _ColorBGRX:
            ret = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrderDefault;
            break;
        case _ColorXBGR:
            ret = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Little;
            break;
        case _ColorGrayscale:
        case _ColorIndexed:
        case _Color565:
        case _ColorBGR:
            ret = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
            break;
        case _ColorA8:
            ret = kCGImageAlphaOnly | kCGBitmapByteOrderDefault;
            break;
        default:
            ret = kCGImageAlphaFirst | kCGBitmapByteOrderDefault;
            break;
    }

    return ret;
}

static inline __CGSurfaceInfo _CGSurfaceInfoInit(size_t width, size_t height, surfaceFormat fmt, void* data = NULL, size_t bytesPerRow = 0, CGBitmapInfo bitmapInfo = c_kCGBitmapInfoInvalidBits) {
    __CGSurfaceInfo surfaceInfo;

    switch (fmt) {
        case _ColorARGB:
            surfaceInfo.bitmapInfo = kCGImageAlphaFirst | kCGBitmapByteOrderDefault;
            surfaceInfo.colorSpaceModel = kCGColorSpaceModelRGB;
            surfaceInfo.bitsPerComponent = 8;
            surfaceInfo.bytesPerPixel = 4;
            break;
        case _ColorABGR:
            surfaceInfo.bitmapInfo = kCGImageAlphaLast | kCGBitmapByteOrder32Little;
            surfaceInfo.colorSpaceModel = kCGColorSpaceModelRGB;
            surfaceInfo.bitsPerComponent = 8;
            surfaceInfo.bytesPerPixel = 4;
            break;
        case _ColorBGRX:
            surfaceInfo.bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrderDefault;
            surfaceInfo.colorSpaceModel = kCGColorSpaceModelRGB;
            surfaceInfo.bitsPerComponent = 8;
            surfaceInfo.bytesPerPixel = 4;
            break;
        case _ColorXBGR:
            surfaceInfo.bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Little;
            surfaceInfo.colorSpaceModel = kCGColorSpaceModelRGB;
            surfaceInfo.bitsPerComponent = 8;
            surfaceInfo.bytesPerPixel = 4;
            break;
        case _ColorGrayscale:
            surfaceInfo.bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
            surfaceInfo.colorSpaceModel = kCGColorSpaceModelMonochrome;
            surfaceInfo.bitsPerComponent = 8;
            surfaceInfo.bytesPerPixel = 1;
            break;
        case _ColorIndexed:
            surfaceInfo.bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
            surfaceInfo.colorSpaceModel = kCGColorSpaceModelIndexed;
            surfaceInfo.bitsPerComponent = 8;
            surfaceInfo.bytesPerPixel = 4;
            break;
        case _Color565:
            surfaceInfo.bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
            surfaceInfo.colorSpaceModel = kCGColorSpaceModelRGB;
            surfaceInfo.bitsPerComponent = 5;
            surfaceInfo.bytesPerPixel = 2;
            break;
        case _ColorBGR:
            surfaceInfo.bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
            surfaceInfo.colorSpaceModel = kCGColorSpaceModelRGB;
            surfaceInfo.bitsPerComponent = 8;
            surfaceInfo.bytesPerPixel = 3;
            break;
        case _ColorA8:
            surfaceInfo.bitmapInfo = kCGImageAlphaOnly | kCGBitmapByteOrderDefault;
            surfaceInfo.colorSpaceModel = kCGColorSpaceModelPattern;
            surfaceInfo.bitsPerComponent = 8;
            surfaceInfo.bytesPerPixel = 1;
            break;
        default:
            surfaceInfo.bitmapInfo = kCGImageAlphaFirst | kCGBitmapByteOrderDefault;
            surfaceInfo.colorSpaceModel = kCGColorSpaceModelRGB;
            surfaceInfo.bitsPerComponent = 8;
            surfaceInfo.bytesPerPixel = 4;
            break;
    }

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

    surfaceInfo.format = fmt;

    return surfaceInfo;
}

inline size_t _CGSurfaceInfoGetBitsPerComponent(surfaceFormat fmt) {
    switch (fmt) {
        case _ColorARGB:
        case _ColorABGR:
        case _ColorBGRX:
        case _ColorXBGR:
        case _ColorBGR:
        case _ColorA8:
        case _ColorGrayscale:
        case _ColorIndexed:
            return 8;
            break;
        case _Color565:
            return 5;
            break;
        default:
            return 8;
            break;
    }
}

#endif