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

#include <inttypes.h>
#include <BaseTsd.h>
#include "AccelerateExport.h"
#include <memory.h>

#if !defined(__clang__)
#ifndef __attribute__
#define __attribute__(x)
#endif
enum surfaceFormat { _Color565, _ColorARGB, _ColorRGBA, _ColorRGB32, _ColorRGB32HE, _ColorGrayscale, _ColorRGB, _ColorA8, _ColorIndexed };

#include "../../Frameworks/include/CGColorSpaceInternal.h"
typedef __CGColorSpace* CGColorSpaceRef;
typedef uint32_t CGBitmapInfo;
typedef float CGFloat;
typedef enum {
    kCGRenderingIntentDefault,
    kCGRenderingIntentAbsoluteColorimetric,
    kCGRenderingIntentRelativeColorimetric,
    kCGRenderingIntentSaturation,
    kCGRenderingIntentPerceptual,
} CGColorRenderingIntent;
#else
#import <CoreGraphics/CoreGraphics.h>
#import <CoreGraphics/CGBitmapContext.h>
#import <CoreGraphics/CGImage.h>
#import <CoreImage/CIImage.h>
#import <CoreImage/CIContext.h>
#endif




#if defined(_M_IX86) || defined(_M_X64)
#define VIMAGE_USE_SSE 1
#define VIMAGE_PAD_ALLOCS 1
#include <xmmintrin.h>
#include <emmintrin.h>
#else
#define VIMAGE_PAD_ALLOCS 0
#define VIMAGE_USE_SSE 0
#endif


#if (VIMAGE_PAD_ALLOCS == 1)
static const bool padAllocs = true;
#else
static const bool padAllocs = false;
#endif


enum
{
    kvImageNoError = 0,
    kvImageRoiLargerThanInputBuffer = -21766,
    kvImageInvalidKernelSize = -21767,
    kvImageInvalidEdgeStyle = -21768,
    kvImageInvalidOffset_X = -21769,
    kvImageInvalidOffset_Y = -21770,
    kvImageMemoryAllocationError = -21771,
    kvImageNullPointerArgument = -21772,
    kvImageInvalidParameter = -21773,
    kvImageBufferSizeMismatch = -21774,
    kvImageUnknownFlagsBit = -21775,
    kvImageInternalError = -21776,
    kvImageInvalidRowBytes = -21777,
    kvImageInvalidImageFormat = -21778,
    kvImageColorSyncIsAbsent = -21779,
    kvImageOutOfPlaceOperationRequired = -21780
};

enum
{
    kvImageNoFlags = 0,
    kvImageLeaveAlphaUnchanged = 1,
    kvImageCopyInPlace = 2,
    kvImageBackgroundColorFill = 4,
    kvImageEdgeExtend = 8,
    kvImageDoNotTile = 16,
    kvImageHighQualityResampling = 32,
    kvImageTruncateKernel = 64,
    kvImageGetTempBufferSize = 128,
    kvImagePrintDiagnosticsToConsole = 256,
    kvImageNoAllocate = 512
};

typedef unsigned long vImagePixelCount;

typedef SSIZE_T vImage_Error;

typedef uint32_t vImage_Flags;

typedef float Pixel_F;

typedef uint8_t Pixel_8888[4];

typedef struct {
    void* data;
    vImagePixelCount height;
    vImagePixelCount width;
    size_t rowBytes;
} vImage_Buffer;

typedef struct Pixel_8888_s {
    Pixel_8888 val;
} Pixel_8888_s;

typedef struct {
    uint32_t                bitsPerComponent;
    uint32_t                bitsPerPixel;
    CGColorSpaceRef         colorSpace;
    CGBitmapInfo            bitmapInfo;
    uint32_t                version;
    const CGFloat           *decode;
    CGColorRenderingIntent  renderingIntent;
}vImage_CGImageFormat;

struct Pixel_888_s {
    uint8_t val[3];
};

ACCELERATE_EXPORT vImage_Error vImageBoxConvolve_ARGB8888(const vImage_Buffer* src,
                                                          const vImage_Buffer* dest,
                                                          void* tempBuffer,
                                                          vImagePixelCount srcOffsetToROI_X,
                                                          vImagePixelCount srcOffsetToROI_Y,
                                                          uint32_t kernel_height,
                                                          uint32_t kernel_width,
                                                          const Pixel_8888 backgroundColor,
                                                          vImage_Flags flags);

ACCELERATE_EXPORT vImage_Error vImageMatrixMultiply_ARGB8888(const vImage_Buffer* src,
                                                             const vImage_Buffer* dest,
                                                             const int16_t matrix[16],
                                                             int32_t divisor,
                                                             const int16_t* pre_bias_p,
                                                             const int32_t* post_bias_p,
                                                             vImage_Flags flags);

/// Separates an ARGB8888 image into four Planar8 images.
ACCELERATE_EXPORT vImage_Error vImageConvert_ARGB8888toPlanar8(const vImage_Buffer* srcARGB,
                                                               const vImage_Buffer* destA,
                                                               const vImage_Buffer* destR,
                                                               const vImage_Buffer* destG,
                                                               const vImage_Buffer* destB,
                                                               vImage_Flags flags);

/// Combines four Planar8 images into one ARGB8888 image.
ACCELERATE_EXPORT vImage_Error vImageConvert_Planar8toARGB8888(const vImage_Buffer* srcA,
                                                               const vImage_Buffer* srcR,
                                                               const vImage_Buffer* srcG,
                                                               const vImage_Buffer* srcB,
                                                               const vImage_Buffer* dest,
                                                               vImage_Flags flags);

/// Converts a Planar8 image to a PlanarF image.
ACCELERATE_EXPORT vImage_Error
vImageConvert_Planar8toPlanarF(const vImage_Buffer* src, const vImage_Buffer* dest, Pixel_F maxFloat, Pixel_F minFloat, vImage_Flags flags);

/// Combines three Planar8 images into one RGB888 image.
ACCELERATE_EXPORT vImage_Error vImageConvert_Planar8toRGB888(const vImage_Buffer* planarRed,
                                                             const vImage_Buffer* planarGreen,
                                                             const vImage_Buffer* planarBlue,
                                                             const vImage_Buffer* rgbDest,
                                                             vImage_Flags flags);

/// Converts a PlanarF image to a Planar8 image, clipping values to the provided minimum and maximum values.
ACCELERATE_EXPORT vImage_Error
vImageConvert_PlanarFtoPlanar8(const vImage_Buffer* src, const vImage_Buffer* dest, Pixel_F maxFloat, Pixel_F minFloat, vImage_Flags flags);

/// Takes an RGBA8888 image in premultiplied alpha format and transforms it into an image in nonpremultiplied alpha format.
ACCELERATE_EXPORT vImage_Error vImageUnpremultiplyData_RGBA8888(const vImage_Buffer* src, const vImage_Buffer* dest, vImage_Flags flags);

ACCELERATE_EXPORT vImage_Error vImageBuffer_Init(vImage_Buffer* buffer, vImagePixelCount height, vImagePixelCount width, uint32_t bitsPerFragment, vImage_Flags flags);


static inline float vImageMaxFloat(Pixel_F a, Pixel_F b) {
    return ((a >= b) ? a : b);
}

static inline float vImageMinFloat(Pixel_F a, Pixel_F b) {
    return ((a <= b) ? a : b);
}

static inline unsigned char vImageClipConvertAndSaturateFloatToUint8(Pixel_F inValue, Pixel_F minFloat, Pixel_F maxFloat) {
    if (inValue < minFloat) {
        return 0;
    } else if (inValue < maxFloat) {
        return (unsigned char)((inValue - minFloat) / (maxFloat - minFloat) * 255.0f);
    } else {
        return 255;
    }
}

static inline Pixel_F vImageConvertAndClampUint8ToFloat(unsigned char inValue, Pixel_F minFloat, Pixel_F maxFloat) {
    return ((Pixel_F)(inValue) * (maxFloat - minFloat) / 255.0f + minFloat);
}

static inline size_t vImageAlignSizeT(size_t inValue, size_t alignment) {
    return ((inValue + alignment - 1) & (~(alignment - 1)));
}

static inline uint32_t vImageAlignUInt(uint32_t inValue, uint32_t alignment) {
    return ((inValue + alignment - 1) & (~(alignment - 1)));
}


#if defined(__clang__)
ACCELERATE_EXPORT vImage_Error vImageBuffer_InitWithCGImage(vImage_Buffer* destImageBuffer, const vImage_CGImageFormat* format, void* unknown, CGImageRef image, vImage_Flags flags);
ACCELERATE_EXPORT CGImageRef vImageCreateCGImageFromBuffer(vImage_Buffer *buffer, vImage_CGImageFormat* format, void* pCleanupFunction, void* pCleanupFunctionParams, vImage_Flags flags, void* error);

#endif