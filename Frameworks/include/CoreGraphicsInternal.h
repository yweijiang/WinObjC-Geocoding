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
#pragma once

#import <CoreGraphics/CoreGraphicsExport.h>

typedef enum {
    _Color565 = 0,
    _ColorARGB,
    _ColorABGR,
    _ColorBGRX,
    _ColorXBGR,
    _ColorGrayscale,
    _ColorBGR,
    _ColorA8,
    _ColorIndexed,
    _ColorMax,
    _ColorRGBA = _ColorABGR
} __CGSurfaceFormat;

typedef struct {
    CGColorSpaceModel colorSpaceModel;
    CGBitmapInfo bitmapInfo;
    unsigned int bitsPerComponent;
    unsigned int bytesPerPixel;
} __CGPixelProperties;

static const __CGPixelProperties c_FormatTable[_ColorMax] = {
    { kCGColorSpaceModelRGB, (kCGImageAlphaNone | kCGBitmapByteOrder32Big), 5, 2 }, //_Color565,
    { kCGColorSpaceModelRGB, (kCGImageAlphaFirst | kCGBitmapByteOrder32Big), 8, 4 }, //_ColorARGB,
    { kCGColorSpaceModelRGB, (kCGImageAlphaLast | kCGBitmapByteOrder32Little), 8, 4 }, //_ColorABGR,
    { kCGColorSpaceModelRGB, (kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big), 8, 4 }, //_ColorBGRX,
    { kCGColorSpaceModelRGB, (kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Little), 8, 4 }, //_ColorXBGR,
    { kCGColorSpaceModelMonochrome, (kCGImageAlphaNone | kCGBitmapByteOrder32Big), 8, 1 }, //_ColorGrayscale,
    { kCGColorSpaceModelRGB, (kCGImageAlphaNone | kCGBitmapByteOrder32Big), 8, 3 }, //_ColorBGR,
    { kCGColorSpaceModelPattern, (kCGImageAlphaOnly | kCGBitmapByteOrder32Big), 8, 1 }, //_ColorA8,
    { kCGColorSpaceModelIndexed, (kCGImageAlphaNone | kCGBitmapByteOrder32Big), 8, 2 }, //_ColorIndexed,
};

struct __CGSurfaceInfo {
    unsigned int width;
    unsigned int height;
    unsigned int bytesPerRow;
    void* surfaceData;
    __CGPixelProperties pixelProperties;
    __CGSurfaceFormat format;
};