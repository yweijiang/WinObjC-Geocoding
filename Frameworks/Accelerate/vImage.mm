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

#import "Starboard.h"
#include "Accelerate/AccelerateExport.h"
#import <Accelerate/Accelerate.h>
//#import "CGImageInternal.h"
#import "CoreGraphics/CGImage.h"
#import <CoreGraphics/CoreGraphics.h>
#import "CoreGraphics/CGDataProvider.h"
#import <Foundation/Foundation.h>

/**
@Status Caveat
@Notes BitmapInfo, ColorSpace, flags and freeing function ignored
*/
vImage_Error vImageBuffer_InitWithCGImage(
    vImage_Buffer* buffer, const vImage_CGImageFormat* format, void* unknown, CGImageRef image, vImage_Flags flags) {
    const vImagePixelCount width = CGImageGetWidth(image);
    const vImagePixelCount height = CGImageGetHeight(image);

    vImage_Error result = vImageBuffer_Init(buffer, height, width, format->bitsPerPixel, flags);

    const uint32_t srcPitch = CGImageGetBytesPerRow(image);
    const uint32_t dstPitch = buffer->rowBytes;
    BYTE* srcData = reinterpret_cast<BYTE*>(_CGImageGetData(image));
    BYTE* dstData = reinterpret_cast<BYTE*>(buffer->data);
    const uint32_t bytesPerPixel = format->bitsPerPixel >> 3;
    const uint32_t bytesToCopy = width * bytesPerPixel;

    assert(srcPitch >= bytesToCopy);
    assert(dstPitch >= bytesToCopy);

    for (uint32_t i = 0; i < height; i++) {
        memcpy(dstData, srcData, bytesToCopy);

        srcData += srcPitch;
        dstData += dstPitch;
    }

    return result;
}

/**
@Status Caveat
@Notes Flags and cleanup function ignored
*/
CGImageRef vImageCreateCGImageFromBuffer(vImage_Buffer* buffer,
                                         vImage_CGImageFormat* format,
                                         void* pCleanupFunction,
                                         void* pCleanupFunctionParams,
                                         vImage_Flags flags,
                                         void* error) {

    static const wchar_t* TAG = L"vImageCreateCGImageFromBuffer";
    const uint32_t packedWidthInBytes = buffer->width * (format->bitsPerPixel >> 3);
    void* packedBuffer;
    bool packedBufferAllocated;

    if (packedWidthInBytes < buffer->rowBytes) {
        // packing needed
        packedBuffer = malloc(buffer->height * packedWidthInBytes);

        if (packedBuffer == nil) {
            return nil;
        }

        packedBufferAllocated = true;

        char* srcRow = (char*)buffer->data;
        char* dstRow = (char*)packedBuffer;

        for (int i = 0; i < buffer->height; i++) {
            memcpy(dstRow, srcRow, packedWidthInBytes);
            srcRow += buffer->rowBytes;
            dstRow += packedWidthInBytes;
        }
    }
    else {
        // Data is packed so pass it directly into
        packedBuffer = buffer->data;
        packedBufferAllocated = false;
    }

    CGImageRef imageRef;

    if ((flags & kvImageNoAllocate) != 0) {
        const size_t bufferSize = packedWidthInBytes * buffer->height;
        if (packedBufferAllocated) {
            TraceWarning(TAG, L"kvImageNoAllocate flag ignored since padded buffer passed in. Packed buffer allocated and used since padded buffers can't be used in CGImage.");
        }

        NSData *data = [NSData dataWithBytesNoCopy:packedBuffer length:bufferSize freeWhenDone:YES];

        CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)data);
  
        imageRef = CGImageCreate((size_t)buffer->width,
                                 (size_t)buffer->height,
                                 (size_t)format->bitsPerComponent,
                                 (size_t)format->bitsPerPixel,
                                 (size_t)packedWidthInBytes,
                                 format->colorSpace,
                                 format->bitmapInfo,
                                 dataProvider,
                                 NULL,
                                 false,
                                 format->renderingIntent);

        CGDataProviderRelease(dataProvider);
    } else {
        CGContextRef ctx = CGBitmapContextCreate(packedBuffer,
            (size_t)buffer->width,
            (size_t)buffer->height,
            (size_t)format->bitsPerComponent,
            packedWidthInBytes,
            format->colorSpace,
            format->bitmapInfo);

        imageRef = CGBitmapContextCreateImage(ctx);

        CGContextRelease(ctx);

        if (packedBufferAllocated == true) {
            free(packedBuffer);
        }
    }

    return imageRef;
}