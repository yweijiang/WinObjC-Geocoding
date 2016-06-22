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
#import "Accelerate/vImage.h"
#import "CGImageInternal.h"

vImage_Error vImageBuffer_InitWithCGImage(
    vImage_Buffer* buffer, const vImage_CGImageFormat* format, void* unknown, CGImageRef image, vImage_Flags flags) {
    const vImagePixelCount width = image->Backing()->Width();
    const vImagePixelCount height = image->Backing()->Height();

    vImage_Error result = vImageBuffer_Init(buffer, height, width, format->bitsPerPixel, flags);

    const uint32_t srcPitch = image->Backing()->BytesPerRow();
    const uint32_t dstPitch = buffer->rowBytes;
    BYTE* srcData = reinterpret_cast<BYTE*>(image->Backing()->LockImageData());
    BYTE* dstData = reinterpret_cast<BYTE*>(buffer->data);
    const uint32_t bpp = format->bitsPerPixel / 8;
    const uint32_t bytesToCopy = width * bpp;

    assert(srcPitch >= bytesToCopy);
    assert(dstPitch >= bytesToCopy);

    for (uint32_t i = 0; i < height; i++) {
        memcpy(dstData, srcData, bytesToCopy);

        srcData += srcPitch;
        dstData += dstPitch;
    }

    image->Backing()->ReleaseImageData();

    return result;
}

CGImageRef vImageCreateCGImageFromBuffer(vImage_Buffer* buffer,
                                         vImage_CGImageFormat* format,
                                         void* pCleanupFunction,
                                         void* pCleanupFunctionParams,
                                         vImage_Flags flags,
                                         void* error) {
    const uint32_t bpp = format->bitsPerPixel / 8;
    uint32_t packedWidthInBytes = buffer->width * bpp;

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
    } else {
        // Data is packed so pass it directly into
        packedBuffer = buffer->data;
        packedBufferAllocated = false;
    }

    CGContextRef ctx = CGBitmapContextCreate(packedBuffer,
                                             (size_t)buffer->width,
                                             (size_t)buffer->height,
                                             (size_t)format->bitsPerComponent,
                                             packedWidthInBytes,
                                             format->colorSpace,
                                             format->bitmapInfo);

    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);

    CGContextRelease(ctx);

    if (packedBufferAllocated == true) {
        free(packedBuffer);
    }

    return imageRef;
}