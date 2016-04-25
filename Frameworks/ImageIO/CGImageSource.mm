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

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGDataProvider.h>
#import <ImageIO/ImageIO.h>
#import <ImageIO/CGImageSource.h>
#import <ImageIO/CGImageSourceInternal.h>
#import <StubReturn.h>
#import <objc/runtime.h>
#import <Starboard.h>
#include <NSLogging.h>
#include <vector>

#include "COMIncludes.h"
#include "Wincodec.h"
#include <wrl/client.h>
#include "COMIncludes_End.h"

using namespace Microsoft::WRL;

static const wchar_t* TAG = L"CGImageSource"; 
const CFStringRef kCGImageSourceTypeIdentifierHint = static_cast<CFStringRef>(@"kCGImageSourceTypeIdentifierHint");
const CFStringRef kCGImageSourceShouldAllowFloat = static_cast<CFStringRef>(@"kCGImageSourceShouldAllowFloat");
const CFStringRef kCGImageSourceShouldCache = static_cast<CFStringRef>(@"kCGImageSourceShouldCache");
const CFStringRef kCGImageSourceCreateThumbnailFromImageIfAbsent =
    static_cast<CFStringRef>(@"kCGImageSourceCreateThumbnailFromImageIfAbsent");
const CFStringRef kCGImageSourceCreateThumbnailFromImageAlways = static_cast<CFStringRef>(@"kCGImageSourceCreateThumbnailFromImageAlways");
const CFStringRef kCGImageSourceThumbnailMaxPixelSize = static_cast<CFStringRef>(@"kCGImageSourceThumbnailMaxPixelSize");
const CFStringRef kCGImageSourceCreateThumbnailWithTransform = static_cast<CFStringRef>(@"kCGImageSourceCreateThumbnailWithTransform");
const CFStringRef kUTTypeJPEG = static_cast<const CFStringRef>(@"public.jpeg");
const CFStringRef kUTTypeTIFF = static_cast<const CFStringRef>(@"public.tiff");
const CFStringRef kUTTypeGIF = static_cast<const CFStringRef>(@"com.compuserve.gif");
const CFStringRef kUTTypePNG = static_cast<const CFStringRef>(@"public.png");
const CFStringRef kUTTypeBMP = static_cast<const CFStringRef>(@"com.microsoft.bmp");
const CFStringRef kUTTypeICO = static_cast<const CFStringRef>(@"com.microsoft.ico");
const size_t c_minDataStreamSize = 96;

@implementation ImageSource
- (instancetype)initWithData:(CFDataRef)data {
    if (self = [super init]) {
        _data = (NSData*)data;
    }

    return self;
}

- (instancetype)initWithURL:(CFURLRef)url {
    if (self = [super init]) {
        _data = [NSData dataWithContentsOfURL:(NSURL*)url];
    }

    return self;
}

- (instancetype)initWithDataProvider:(CGDataProviderRef)provider {
    if (self = [super init]) {
        _data = (NSData*)CGDataProviderCopyData(provider);
    }

    return self;                               
}

// Helper function to identify image format from image byte stream
- (CFStringRef)getImageType {
    char imageIdentifier[12] = {0};
    [self.data getBytes:&imageIdentifier length:12];
    static const unsigned char BMPIdentifier[] = {'B','M'};
    static const unsigned char GIFIdentifier[] = {'G','I','F'};
    static const unsigned char ICOIdentifier[] = {0x00, 0x00, 0x01, 0x00};
    static const unsigned char JPEGIdentifier[] = {0xFF, 0xD8, 0xFF};
    static const unsigned char PNGIdentifier[] = {0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a};
    static const unsigned char TIFFIdentifier1[] = {'M', 'M', 0x00, 0x2A};
    static const unsigned char TIFFIdentifier2[] = {'I', 'I', 0x2A, 0x00};
    CFStringRef imageFormat;

    if (!memcmp(imageIdentifier, BMPIdentifier, 2)) {
        imageFormat = kUTTypeBMP;
    } else if (!memcmp(imageIdentifier, GIFIdentifier, 3)) {
        imageFormat = kUTTypeGIF;
    } else if (!memcmp(imageIdentifier, ICOIdentifier, 4)) {
        imageFormat = kUTTypeICO;
    } else if (!memcmp(imageIdentifier, JPEGIdentifier, 3)) {
        imageFormat = kUTTypeJPEG;
    } else if (!memcmp(imageIdentifier, PNGIdentifier, 8)) {
        imageFormat = kUTTypePNG;
    } else if (!memcmp(imageIdentifier, TIFFIdentifier1, 4) || !memcmp(imageIdentifier, TIFFIdentifier2, 4)) {
        imageFormat = kUTTypeTIFF;
    } else {
        imageFormat = nullptr;
    }

    if (!imageFormat) {
        UNIMPLEMENTED_WITH_MSG("Image format is not supported. "
                               "Current release supports JPEG, BMP, PNG, GIF, TIFF & ICO image formats only.");
    } 

    return imageFormat;
}

// Helper functions used for getting multi-byte values from image data.
uint16_t get16BitValue(const uint8_t* data, size_t offset) {
    return data[offset] + (data[offset + 1] << 8);
}

uint32_t get32BitValue(const uint8_t* data, size_t offset) {
    return data[offset] + (data[offset + 1] << 8) + (data[offset + 2] << 16) + (data[offset + 3] << 24);
}

uint32_t get32BitValueBigEndian(const uint8_t* data, size_t offset) {
    return data[offset - 1] + (data[offset - 2] << 8) + (data[offset - 3] << 16) + (data[offset - 4] << 24);
}

/**
 @Notes      Helper function to get the status of JPEG images at the provided index.
             Progressively encoded JPEG images are not supported by Apple APIs and the current implementation does not support it.
 @References https://en.wikipedia.org/wiki/JPEG
             https://en.wikipedia.org/wiki/JPEG_File_Interchange_Format                    
*/
- (CGImageSourceStatus)getJPEGStatusAtIndex:(size_t)index {
    // Return if requesting for invalid frames
    if (index != 0) {
        return kCGImageStatusUnknownType;
    }

    const uint8_t* imageData = static_cast<const uint8_t*>([self.data bytes]);
    NSUInteger imageLength = [self.data length];

    static const uint8_t c_imageEndIdentifier[2] = {0xFF, 0xD9};
    static const uint8_t c_scanStartIdentifier[2] = {0xFF, 0xDA};
    
    if (imageLength < c_minDataStreamSize) {
        return kCGImageStatusReadingHeader;
    }

    // Check if the End Of Image marker is present in the data stream
    if (imageData[imageLength - 2] == c_imageEndIdentifier[0] && imageData[imageLength - 1] == c_imageEndIdentifier[1]) {
        return kCGImageStatusComplete;
    } 

    // Check if the Start Of Scan marker is present in the data stream
    for (size_t offset = 2, blockLength = 0; offset < imageLength - 3; offset += blockLength + 2) {
        blockLength = (imageData[offset + 2] << 8) | imageData[offset + 3];

        if (imageData[offset] == c_scanStartIdentifier[0] && imageData[offset + 1] == c_scanStartIdentifier[1]) {
            if (offset + blockLength + 2 > imageLength) {
                return kCGImageStatusUnknownType;
            } else {
                return kCGImageStatusIncomplete;
            }
        }
    }

    return kCGImageStatusUnknownType;
}

/**
 @Notes      Helper function to get the status of TIFF images at the provided index
 @References http://www.fileformat.info/format/tiff/egff.htm
             https://en.wikipedia.org/wiki/Tagged_Image_File_Format
*/
- (CGImageSourceStatus)getTIFFStatusAtIndex:(size_t)index {
    static const size_t c_ifdOffsetSize = 4;

    const uint8_t* imageData = static_cast<const uint8_t*>([self.data bytes]);
    NSUInteger imageLength = [self.data length];

    if (imageLength < c_minDataStreamSize) {
        return kCGImageStatusReadingHeader;
    }
    
    // Offset into the first Image File Directory (IFD) starts at byte offset 4
    uint32_t offset = get32BitValue(imageData, 4);

    // Check if data for previous image frames are present 
    for (size_t currentFrameIndex = 0; currentFrameIndex < index; currentFrameIndex++) {
        if (offset + 1 >= imageLength) {
            return kCGImageStatusUnknownType;
        }

        uint16_t tagCount = get16BitValue(imageData, offset);

        // Each tag is 12 bytes and each tag count size is 2 bytes
        offset += (tagCount * 12) + 2;

        if (offset + 3 >= imageLength) {
            return kCGImageStatusUnknownType;
        }

        offset = get32BitValue(imageData, offset);
    }

    // Check if all image frame data is present in the data stream
    if ((offset + c_ifdOffsetSize) < imageLength) {
        return kCGImageStatusComplete;
    } else {
        return kCGImageStatusIncomplete;
    }
}

/**
 @Notes      Helper function to get the status of GIF images at the provided index
             Interlaced GIF images are not supported by Apple APIs and the current implementation does not support it.
 @References https://www.w3.org/Graphics/GIF/spec-gif89a.txt
             https://en.wikipedia.org/wiki/GIF
             http://giflib.sourceforge.net/whatsinagif/bits_and_bytes.html
*/
- (CGImageSourceStatus)getGIFStatusAtIndex:(size_t)index {
    static const size_t c_headerSize = 6;
    static const size_t c_logicalDescriptorSize = 7;
    static const size_t c_packedFieldOffset = 10;
    static const size_t c_extensionTypeSize = 2; 
    static const size_t c_imageDescriptorSize = 10;
    static const uint8_t c_gifExtensionHeader = 0x21;
    static const uint8_t c_gifDescriptorHeader = 0x2C;

    const uint8_t* imageData = static_cast<const uint8_t*>([self.data bytes]);
    NSUInteger imageLength = [self.data length];
        
    if (imageLength < c_minDataStreamSize) {
        return kCGImageStatusReadingHeader;
    }

    size_t offset = c_headerSize + c_logicalDescriptorSize;

    // Advance Start of Frame offset if global color table exists. Check for existence by reading MSB of packed byte 
    if (imageData[c_packedFieldOffset] & 0x80) {
        // Extract the last three bits from packed byte to get the Global Color Table Size representation and compute actual size
        offset += 3 << ((imageData[c_packedFieldOffset] & 0x7) + 1);

        // Return unknown if offset is somewhere past the end of the image data before any image frames are found
        if (offset >= imageLength) {
            return kCGImageStatusUnknownType;
        }
    }

    // Count the number of frames we find by keeping track of the number of image descriptor blocks encountered.
    // Exit loop when the number of frames encountered goes past the index we're looking for, or we go past the end of the image data.
    size_t framesLoaded = 0;
    while (framesLoaded <= index) {
        bool extensionHeaderFound = imageData[offset] == c_gifExtensionHeader;
        bool descriptorHeaderFound = imageData[offset] == c_gifDescriptorHeader;

        // Advance Start of Frame offset through various Extensions - Graphic Control, Plain Text, Application & Comment
        if (extensionHeaderFound) {
            offset += c_extensionTypeSize;
        } else if (descriptorHeaderFound) {
            // Check for the start of an Image Descriptor
            offset += c_imageDescriptorSize;

            // Advance Start of Frame offset if local color table exists. Check for existence by reading MSB of packed byte 
            if (offset < imageLength && imageData[offset - 1] & 0x80) {
                // Extract the last three bits from packed byte to get the Local Color Table Size representation and compute actual size
                offset += 3 << ((imageData[offset - 1] & 0x7) + 1);
            }
            offset++;
        } else {
            // Neither of the valid block headers were encountered, this means we have an unknown type
            return kCGImageStatusUnknownType;
        }

        // Iterate over all extension sub-blocks by checking the block length. A block length of 0 marks the end of current extension 
        while (offset < imageLength && imageData[offset] != 0) {
            offset += imageData[offset] + 1;
        }

        if (offset < imageLength && descriptorHeaderFound) {
            // Increment the number of frames encountered if we see descriptor and fully advance through the image data block
            framesLoaded++;
        }

        // Increment to start of next block, then check if we've gone past the ended of the loaded image
        offset++;
        if (offset >= imageLength) {
            break;
        }
    }

    // If we have encountered less frames than the index, then loading the frame at the index is not started, so return Unknown Type
    // If the end was reached during index, then return Incomplete, and if we have found all frames plus the index, return Complete
    if (framesLoaded < index) {
        return kCGImageStatusUnknownType;
    } else if (framesLoaded == index) {
        return kCGImageStatusIncomplete;
    } else {
        return kCGImageStatusComplete;
    }
}

/**
 @Notes      Helper function to get the status of BMP images at the provided index
 @References https://en.wikipedia.org/wiki/BMP_file_format
             http://www.fileformat.info/format/bmp/egff.htm
*/
- (CGImageSourceStatus)getBMPStatusAtIndex:(size_t)index {
    // Return if requesting for invalid frames
    if (index != 0) {
        return kCGImageStatusUnknownType;
    }

    static const size_t c_fileSizeIndex = 2;
    static const size_t c_pixelOffsetIndex = 10;
    

    const uint8_t* imageData = static_cast<const uint8_t*>([self.data bytes]);
    NSUInteger imageLength = [self.data length];

    if (imageLength < c_minDataStreamSize) {
        return kCGImageStatusReadingHeader;
    }

    // Check if incoming data stream size matches image file size 
    // Bound check in parent CGImageSourceGetStatusAtIndex function for a length of 96 
    NSUInteger fileSize = (NSUInteger) get32BitValue(imageData, c_fileSizeIndex);

    if (imageLength == fileSize) {
        return kCGImageStatusComplete;
    }

    // Check if partial image data is present in the data stream
    uint32_t pixelArrayOffset = get32BitValue(imageData, c_pixelOffsetIndex);

    return (pixelArrayOffset >= imageLength) ? kCGImageStatusIncomplete : kCGImageStatusUnknownType;
}

/**
 @Notes      Helper function to get the status of PNG images at the provided index
             Interlaced PNG images are not supported by Apple APIs and the current implementation does not support it.
 @References https://www.w3.org/TR/PNG/
             https://en.wikipedia.org/wiki/Portable_Network_Graphics
*/
- (CGImageSourceStatus)getPNGStatusAtIndex:(size_t)index {
    // Return if requesting for invalid frames
    if (index != 0) {
        return kCGImageStatusUnknownType;
    }

    static const size_t c_imageEndIdentifierReverseIndex = 8;
    static const size_t c_headerSize = 8;
    static const size_t c_lengthSize = 4;
    static const size_t c_chunkTypeSize = 4;
    static const size_t c_CRCSize = 4;
    static const uint8_t c_imageEndIdentifier[] = {0x49, 0x45, 0x4E, 0x44};
    static const uint8_t c_frameStartIdentifier[] = {0x49, 0x44, 0x41, 0x54};
     
    const uint8_t* imageData = static_cast<const uint8_t*>([self.data bytes]);
    NSUInteger imageLength = [self.data length];

    if (imageLength < c_minDataStreamSize) {
        return kCGImageStatusReadingHeader;
    }

    // Check if the End of Image identifier is present in the data stream
    size_t endIndex = imageLength - c_imageEndIdentifierReverseIndex;

    // Check for Image End identifier
    if (imageData[endIndex] == c_imageEndIdentifier[0] &&
        imageData[endIndex + 1] == c_imageEndIdentifier[1] && 
        imageData[endIndex + 2] == c_imageEndIdentifier[2] && 
        imageData[endIndex + 3] == c_imageEndIdentifier[3]) {
        return kCGImageStatusComplete;
    }

    // Check if the Start of Frame identifier is present in the data stream
    size_t offset = c_headerSize + c_lengthSize;
    while (offset + 3 < imageLength) {
        if (imageData[offset] == c_frameStartIdentifier[0] &&
            imageData[offset + 1] == c_frameStartIdentifier[1] && 
            imageData[offset + 2] == c_frameStartIdentifier[2] && 
            imageData[offset + 3] == c_frameStartIdentifier[3]) {
            return kCGImageStatusIncomplete;
        }

        uint32_t chunkLength = get32BitValueBigEndian(imageData, offset);
        offset += c_chunkTypeSize + chunkLength + c_CRCSize + c_lengthSize;
    }

    return kCGImageStatusUnknownType;
}

/**
 @Notes      Helper function to get the status of ICO images at the provided index
 @References https://msdn.microsoft.com/en-us/library/ms997538.aspx 
             https://en.wikipedia.org/wiki/ICO_(file_format)
*/
- (CGImageSourceStatus)getICOStatusAtIndex:(size_t)index {
    static const size_t c_headerSize = 6;
    static const size_t c_pixelOffset = 8;
    static const size_t c_imageDataLengthSize = 4;
    static const size_t c_imagePixelOffsetSize = 4;
    
    const uint8_t* imageData = static_cast<const uint8_t*>([self.data bytes]);
    NSUInteger imageLength = [self.data length];
    size_t offset = c_headerSize + c_pixelOffset;
    
    if (imageLength < c_minDataStreamSize) {
        return kCGImageStatusReadingHeader;
    }

    for (size_t currentFrameIndex = 0; currentFrameIndex <= index; currentFrameIndex++) {
        if (offset + 3 >= imageLength) {
            return kCGImageStatusUnknownType;
        } 

        uint32_t imageDataLength = get32BitValue(imageData, offset);

        offset += c_imageDataLengthSize;
        if (offset + 3 >= imageLength) {
            return kCGImageStatusUnknownType;
        } 

        uint32_t imagePixelOffset = get32BitValue(imageData, offset);

        // Check if any of the image data is present in the data stream
        if (imagePixelOffset >= imageLength) {
            return kCGImageStatusUnknownType;
        }

        imagePixelOffset += imageDataLength - 1;

        // Check if all image data is present in the data stream
        if (imagePixelOffset >= imageLength) {
            return kCGImageStatusUnknownType;
        }

        offset += c_imagePixelOffsetSize + c_pixelOffset;
    }

    return kCGImageStatusComplete;
}
@end

/**
 @Status Caveat
 @Notes The current implementation supports common image file formats such as JPEG, GIF, TIFF, BMP, PNG and ICO. 
        Not all formats are supported.
        kCGImageSourceTypeIdentifierHint is not supported when passed in as an options dictionary key. 
*/
CGImageSourceRef CGImageSourceCreateWithDataProvider(CGDataProviderRef provider, CFDictionaryRef options) {
    RETURN_NULL_IF(!provider);
    if (options && CFDictionaryContainsKey(options, kCGImageSourceTypeIdentifierHint)) {
        UNIMPLEMENTED_WITH_MSG("kCGImageSourceTypeIdentifierHint is not supported in current implementation.");
    }

    return (CGImageSourceRef)[[ImageSource alloc] initWithDataProvider:provider];
}

/**
 @Status Caveat
 @Notes The current implementation supports common image file formats such as JPEG, GIF, TIFF, BMP, PNG and ICO. 
        Not all formats are supported.
        kCGImageSourceTypeIdentifierHint is not supported when passed in as an options dictionary key. 
*/
CGImageSourceRef CGImageSourceCreateWithData(CFDataRef data, CFDictionaryRef options) {
    RETURN_NULL_IF(!data);
    if (options && CFDictionaryContainsKey(options, kCGImageSourceTypeIdentifierHint)) {
        UNIMPLEMENTED_WITH_MSG("kCGImageSourceTypeIdentifierHint is not supported in current implementation.");
    }

    return (CGImageSourceRef)[[ImageSource alloc] initWithData:data];
}

/**
 @Status Caveat
 @Notes The current implementation supports common image file formats such as JPEG, GIF, TIFF, BMP, PNG and ICO. 
        Not all formats are supported.
        kCGImageSourceTypeIdentifierHint is not supported when passed in as an options dictionary key.
*/
CGImageSourceRef CGImageSourceCreateWithURL(CFURLRef url, CFDictionaryRef options) {
    RETURN_NULL_IF(!url);
    if (options && CFDictionaryContainsKey(options, kCGImageSourceTypeIdentifierHint)) {
        UNIMPLEMENTED_WITH_MSG("kCGImageSourceTypeIdentifierHint is not supported in current implementation.");
    }

    return (CGImageSourceRef)[[ImageSource alloc] initWithURL:url];
}

/**
 @Status Caveat
 @Notes Current implementation does not support kCGImageSourceShouldAllowFloat & kCGImageSourceShouldCache 
        when passed in as options dictionary keys
*/
CGImageRef CGImageSourceCreateImageAtIndex(CGImageSourceRef isrc, size_t index, CFDictionaryRef options) {
    RETURN_NULL_IF(!isrc);
    NSData* imageData = ((ImageSource*)isrc).data;
    RETURN_NULL_IF(!imageData);
    RETURN_NULL_IF(index > (CGImageSourceGetCount(isrc) - 1));

    MULTI_QI imageQueryInterface = {0};
    static const GUID IID_IWICImagingFactory = {0xec5ec8a9,0xc395,0x4314,0x9c,0x77,0x54,0xd7,0xa9,0x35,0xff,0x70};
    imageQueryInterface.pIID = &IID_IWICImagingFactory;
    RETURN_NULL_IF_FAILED(
        CoCreateInstanceFromApp(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, nullptr, 1, &imageQueryInterface));

    ComPtr<IWICImagingFactory> imageFactory = (IWICImagingFactory*)imageQueryInterface.pItf;
    ComPtr<IWICStream> imageStream;
    RETURN_NULL_IF_FAILED(imageFactory->CreateStream(&imageStream));

    unsigned char* imageByteArray = (unsigned char*)[imageData bytes];
    int imageLength = [imageData length];
    RETURN_NULL_IF_FAILED(imageStream->InitializeFromMemory(imageByteArray, imageLength));

    if (options && CFDictionaryContainsKey(options, kCGImageSourceShouldCache)) {
        UNIMPLEMENTED_WITH_MSG("kCGImageSourceShouldCache is not supported in current implementation.");
    }

    ComPtr<IWICBitmapDecoder> imageDecoder;                
    RETURN_NULL_IF_FAILED(imageFactory->CreateDecoderFromStream(imageStream.Get(), nullptr, WICDecodeMetadataCacheOnDemand, &imageDecoder));

    ComPtr<IWICBitmapFrameDecode> imageFrame;
    RETURN_NULL_IF_FAILED(imageDecoder->GetFrame(index, &imageFrame));

    unsigned int frameWidth = 0;
    unsigned int frameHeight = 0;
    RETURN_NULL_IF_FAILED(imageFrame->GetSize(&frameWidth, &frameHeight));

    ComPtr<IWICFormatConverter> imageFormatConverter;
    RETURN_NULL_IF_FAILED(imageFactory->CreateFormatConverter(&imageFormatConverter));

    if (options && CFDictionaryContainsKey(options, kCGImageSourceShouldAllowFloat)) {
        UNIMPLEMENTED_WITH_MSG("kCGImageSourceShouldAllowFloat is not supported in current implementation.");
    }

    RETURN_NULL_IF_FAILED(imageFormatConverter->Initialize(imageFrame.Get(), 
                                                           GUID_WICPixelFormat32bppRGBA,
                                                           WICBitmapDitherTypeNone, 
                                                           nullptr, 
                                                           0.f, 
                                                           WICBitmapPaletteTypeCustom));

    const unsigned int frameSize = frameWidth * frameHeight * 4;
    unsigned char* frameByteArray = static_cast<unsigned char*>(IwMalloc(frameSize));
    if (!frameByteArray) {
        NSTraceInfo(TAG, @"CGImageSourceCreateImageAtIndex cannot allocate memory");
        return nullptr;
    }

    auto cleanup = wil::ScopeExit([&]() { IwFree(frameByteArray); });
    RETURN_NULL_IF_FAILED(imageFormatConverter->CopyPixels(0, frameWidth * 4, frameSize, frameByteArray));
    cleanup.Dismiss();

    NSData* frameData = [NSData dataWithBytesNoCopy:frameByteArray length:frameSize freeWhenDone:YES];    
    CGDataProviderRef frameDataProvider =  CGDataProviderCreateWithCFData((CFDataRef)frameData);
    CGColorSpaceRef colorspaceRgb = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageRef = CGImageCreate(frameWidth, 
                                        frameHeight, 
                                        8, 
                                        32, 
                                        frameWidth * 4, 
                                        colorspaceRgb, 
                                        kCGImageAlphaFirst, 
                                        frameDataProvider, 
                                        nullptr, 
                                        true, 
                                        kCGRenderingIntentDefault);
    CGDataProviderRelease(frameDataProvider);
    CGColorSpaceRelease(colorspaceRgb);                                         
    return imageRef;
}

/**
 @Status Caveat
 @Notes Current implementation does not support kCGImageSourceShouldAllowFloat, kCGImageSourceShouldCache & 
        kCGImageSourceCreateThumbnailWithTransform when passed in as options dictionary keys
*/
CGImageRef CGImageSourceCreateThumbnailAtIndex(CGImageSourceRef isrc, size_t index, CFDictionaryRef options) {
    RETURN_NULL_IF(!isrc);
    NSData* imageData = ((ImageSource*)isrc).data;
    RETURN_NULL_IF(!imageData);
    RETURN_NULL_IF(index > (CGImageSourceGetCount(isrc) - 1));

    MULTI_QI imageQueryInterface = {0};
    static const GUID IID_IWICImagingFactory = {0xec5ec8a9,0xc395,0x4314,0x9c,0x77,0x54,0xd7,0xa9,0x35,0xff,0x70};
    imageQueryInterface.pIID = &IID_IWICImagingFactory;
    RETURN_NULL_IF_FAILED(
        CoCreateInstanceFromApp(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, nullptr, 1, &imageQueryInterface));

    ComPtr<IWICImagingFactory> imageFactory = (IWICImagingFactory*)imageQueryInterface.pItf;
    ComPtr<IWICStream> imageStream;        
    RETURN_NULL_IF_FAILED(imageFactory->CreateStream(&imageStream));

    unsigned char* imageByteArray = (unsigned char*)[imageData bytes];
    int imageLength = [imageData length];
    RETURN_NULL_IF_FAILED(imageStream->InitializeFromMemory(imageByteArray, imageLength));

    if (options && CFDictionaryContainsKey(options, kCGImageSourceShouldCache)) {
        UNIMPLEMENTED_WITH_MSG("kCGImageSourceShouldCache is not supported in current implementation.");
    }

    ComPtr<IWICBitmapDecoder> imageDecoder;
    RETURN_NULL_IF_FAILED(imageFactory->CreateDecoderFromStream(imageStream.Get(), nullptr, WICDecodeMetadataCacheOnDemand, &imageDecoder));

    ComPtr<IWICBitmapFrameDecode> imageFrame;
    RETURN_NULL_IF_FAILED(imageDecoder->GetFrame(index, &imageFrame));

    if (options && CFDictionaryContainsKey(options, kCGImageSourceCreateThumbnailWithTransform)) {
        UNIMPLEMENTED_WITH_MSG("kCGImageSourceCreateThumbnailWithTransform is not supported in "
                                "current implementation.");
    }
    
    ComPtr<IWICFormatConverter> imageFormatConverter;                        
    RETURN_NULL_IF_FAILED(imageFactory->CreateFormatConverter(&imageFormatConverter));

    ComPtr<IWICBitmapScaler> imageScaler;
    RETURN_NULL_IF_FAILED(imageFactory->CreateBitmapScaler(&imageScaler));

    unsigned int thumbnailWidth = 0;
    unsigned int thumbnailHeight = 0;
    bool thumbnailExists = false;
    ComPtr<IWICBitmapSource> imageThumbnail;

    // Check if incoming image frame has an existing thumbnail. Return NULL if absent & thumbnail creation flags are not specified.
    if (!SUCCEEDED(imageFrame->GetThumbnail(&imageThumbnail))) {
        if (options && (CFDictionaryContainsKey(options, kCGImageSourceCreateThumbnailFromImageIfAbsent) || 
                        CFDictionaryContainsKey(options, kCGImageSourceCreateThumbnailFromImageAlways))) {
            RETURN_NULL_IF_FAILED(imageFrame->GetSize(&thumbnailWidth, &thumbnailHeight));
        }  
    } else {
        thumbnailExists = true;
        RETURN_NULL_IF_FAILED(imageThumbnail->GetSize(&thumbnailWidth, &thumbnailHeight));
    } 

    unsigned int maxThumbnailSize = 0;
    if (options && CFDictionaryContainsKey(options, kCGImageSourceThumbnailMaxPixelSize)) {
        maxThumbnailSize = [(id)CFDictionaryGetValue(options, kCGImageSourceThumbnailMaxPixelSize) intValue];
    }

    // Maintain aspect ratio if thumbnail size exceeds maximum thumbnail pixel size
    if (maxThumbnailSize && ((thumbnailWidth > maxThumbnailSize) || (thumbnailHeight > maxThumbnailSize))) {
        if (thumbnailWidth >= thumbnailHeight) {
            thumbnailHeight = thumbnailHeight / thumbnailWidth * maxThumbnailSize;
            thumbnailWidth = maxThumbnailSize;
        } else {
            thumbnailWidth = thumbnailWidth / thumbnailHeight * maxThumbnailSize;
            thumbnailHeight = maxThumbnailSize;
        }
                                    
        if (!thumbnailWidth || !thumbnailHeight) {
            thumbnailWidth = maxThumbnailSize;
            thumbnailHeight = maxThumbnailSize;
        }
    }

    // Scale thumbnail according to the calculated dimensions
    if (!thumbnailExists || (thumbnailExists && 
                             options && 
                             CFDictionaryContainsKey(options, kCGImageSourceCreateThumbnailFromImageAlways))) {
        RETURN_NULL_IF_FAILED(imageScaler->Initialize(imageFrame.Get(),
                                                      thumbnailWidth,
                                                      thumbnailHeight,
                                                      WICBitmapInterpolationModeCubic));    
    } else {
        RETURN_NULL_IF_FAILED(imageScaler->Initialize(imageThumbnail.Get(),
                                                      thumbnailWidth,
                                                      thumbnailHeight,
                                                      WICBitmapInterpolationModeCubic));    
    }

    if (options && CFDictionaryContainsKey(options, kCGImageSourceShouldAllowFloat)) {
        UNIMPLEMENTED_WITH_MSG("kCGImageSourceShouldAllowFloat is not supported in current implementation.");
    }

    RETURN_NULL_IF_FAILED(imageFormatConverter->Initialize(imageScaler.Get(), 
                                                           GUID_WICPixelFormat32bppRGBA,
                                                           WICBitmapDitherTypeNone, 
                                                           nullptr, 
                                                           0.f, 
                                                           WICBitmapPaletteTypeCustom));

    const unsigned int thumbnailSize = thumbnailWidth * thumbnailHeight * 4;
    unsigned char* thumbnailByteArray = static_cast<unsigned char*>(IwMalloc(thumbnailSize));
    if (!thumbnailByteArray) {
        NSTraceInfo(TAG, @"CGImageSourceCreateThumbnailAtIndex cannot allocate memory");
        return nullptr;    
    }

    auto cleanup = wil::ScopeExit([&]() { IwFree(thumbnailByteArray); });
    RETURN_NULL_IF_FAILED(imageFormatConverter->CopyPixels(0, 
                                                           thumbnailWidth * 4, 
                                                           thumbnailSize, 
                                                           thumbnailByteArray));
    cleanup.Dismiss();

    NSData* thumbnailData = [NSData dataWithBytesNoCopy:thumbnailByteArray length:thumbnailSize freeWhenDone:YES];    
    CGDataProviderRef thumbnailDataProvider = CGDataProviderCreateWithCFData((CFDataRef)thumbnailData);
    CGColorSpaceRef colorspaceRgb = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageRef = CGImageCreate(thumbnailWidth, 
                                        thumbnailHeight, 
                                        8, 
                                        32, 
                                        thumbnailWidth * 4, 
                                        colorspaceRgb, 
                                        kCGImageAlphaFirst, 
                                        thumbnailDataProvider, 
                                        nullptr, 
                                        true, 
                                        kCGRenderingIntentDefault);
    CGDataProviderRelease(thumbnailDataProvider);
    CGColorSpaceRelease(colorspaceRgb);                                                
    return imageRef;
}

/**
 @Status Caveat
 @Notes The current implementation supports incremental loading for common image file formats such as JPEG, GIF, TIFF, BMP, PNG and ICO.
        Not all formats are supported.
*/
CGImageSourceRef CGImageSourceCreateIncremental(CFDictionaryRef options) {
    return (CGImageSourceRef)[[ImageSource alloc] init];
}

void CGImageSourceUpdateData(CGImageSourceRef isrc, CFDataRef data, bool final) {
    if (!isrc || !data) {
        return;
    }

    ((ImageSource*)isrc).data = (NSData*)data;
    ((ImageSource*)isrc).isFinalIncrementalSet = final;
}

void CGImageSourceUpdateDataProvider(CGImageSourceRef isrc, CGDataProviderRef provider, bool final) {
    if (!isrc || !provider) {
        return;
    }

    ((ImageSource*)isrc).data = (NSData*)CGDataProviderCopyData(provider);
    ((ImageSource*)isrc).isFinalIncrementalSet = final;
}

/**
 @Status Caveat
 @Notes The CFTypeID for an opaque type differs across releases and has been hard-coded to one possible value in current implementation
*/
CFTypeID CGImageSourceGetTypeID() {
    static const int c_imageSourceTypeID = 286;
    return c_imageSourceTypeID;
}

/**
 @Status Caveat
 @Notes Current release supports JPEG, BMP, PNG, GIF, TIFF & ICO image formats only 
*/
CFStringRef CGImageSourceGetType(CGImageSourceRef isrc) {
    RETURN_NULL_IF(!isrc);
    ImageSource* imageSrc = (ImageSource*)isrc;
    RETURN_NULL_IF(!imageSrc.data);
    return [imageSrc getImageType];
}

/**
 @Status Caveat
 @Notes Current release supports JPEG, BMP, PNG, GIF, TIFF & ICO image formats only 
*/
CFArrayRef CGImageSourceCopyTypeIdentifiers() {
    static const CFStringRef typeIdentifiers[] = {kUTTypePNG, kUTTypeJPEG, kUTTypeGIF, kUTTypeTIFF, kUTTypeICO, kUTTypeBMP};
    CFArrayRef imageTypeIdentifiers = CFArrayCreate(nullptr, (const void**)typeIdentifiers, ARRAYSIZE(typeIdentifiers), &kCFTypeArrayCallBacks);
    return imageTypeIdentifiers;
}

size_t CGImageSourceGetCount(CGImageSourceRef isrc) {
    if (!isrc) {
        return 0;
    }

    NSData* imageData = ((ImageSource*)isrc).data;
    if (!imageData) {
        return 0;
    }

    MULTI_QI imageQueryInterface = {0};
    static const GUID IID_IWICImagingFactory = {0xec5ec8a9,0xc395,0x4314,0x9c,0x77,0x54,0xd7,0xa9,0x35,0xff,0x70};
    imageQueryInterface.pIID = &IID_IWICImagingFactory;
    HRESULT status = CoCreateInstanceFromApp(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, nullptr, 1, &imageQueryInterface);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"CoCreateInstanceFromApp failed with status=%x\n", status);
        return 0;
    } 
    
    ComPtr<IWICImagingFactory> imageFactory = (IWICImagingFactory*)imageQueryInterface.pItf;
    ComPtr<IWICStream> imageStream;        
    status = imageFactory->CreateStream(&imageStream);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"IWICImagingFactory::CreateStream failed with status=%x\n", status);
        return 0;
    } 

    unsigned char* imageByteArray = (unsigned char*)[imageData bytes];
    int imageLength = [imageData length];
    status = imageStream->InitializeFromMemory(imageByteArray, imageLength);
    if (!SUCCEEDED(status)) { 
        NSTraceInfo(TAG, @"IWICStream::InitializeFromMemory failed with status=%x\n", status);
        return 0;
    } 
    
    ComPtr<IWICBitmapDecoder> imageDecoder;        
    status = imageFactory->CreateDecoderFromStream(imageStream.Get(), nullptr, WICDecodeMetadataCacheOnDemand, &imageDecoder);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"IWICImagingFactory::CreateDecoderFromStream failed with status=%x\n", status);
        return 0;
    } 
    
    size_t frameCount = 0;
    status = imageDecoder->GetFrameCount(&frameCount);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"IWICBitmapDecoder::GetFrameCount failed with status=%x\n", status);
    } 

    return frameCount;
}

/**
 @Status Stub
 @Notes
*/
CFDictionaryRef CGImageSourceCopyProperties(CGImageSourceRef isrc, CFDictionaryRef options) {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
CFDictionaryRef CGImageSourceCopyPropertiesAtIndex(CGImageSourceRef isrc, size_t index, CFDictionaryRef options) {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Caveat
 @Notes Current release returns kCGImageStatusComplete, kCGImageStatusIncomplete or kCGImageStatusInvalidData only.
        Other return values are not supported.
*/
CGImageSourceStatus CGImageSourceGetStatus(CGImageSourceRef isrc) {
    if (!isrc) {
        return kCGImageStatusInvalidData;
    }

    ImageSource* imageSrc = (ImageSource*)isrc;
    if (!imageSrc.data || [imageSrc.data length] < c_minDataStreamSize) {
        return kCGImageStatusInvalidData;
    }

    if (imageSrc.isFinalIncrementalSet) {
        return kCGImageStatusComplete;
    } else {
        return kCGImageStatusIncomplete;
    }
}

/**
 @Status Caveat
 @Notes Current release returns kCGImageStatusComplete, kCGImageStatusIncomplete, kCGImageStatusUnknownType, kCGImageStatusUnexpectedEOF or
        kCGImageStatusReadingHeader only. kCGImageStatusInvalidData is not supported. 
*/
CGImageSourceStatus CGImageSourceGetStatusAtIndex(CGImageSourceRef isrc, size_t index) {
    if (!isrc) {
        return kCGImageStatusReadingHeader;
    }

    ImageSource* imageSrc = (ImageSource*)isrc;
    if (!imageSrc.data) {
        return kCGImageStatusUnexpectedEOF;
    }

    if ([imageSrc.data length] < c_minDataStreamSize) {
        return kCGImageStatusReadingHeader;
    }

    CFStringRef imageFormat = CGImageSourceGetType(isrc);
    if (imageFormat == kUTTypeJPEG) {
        return [imageSrc getJPEGStatusAtIndex:index];
    } else if (imageFormat == kUTTypeTIFF) {
        return [imageSrc getTIFFStatusAtIndex:index];
    } else if (imageFormat == kUTTypeGIF) {
        return [imageSrc getGIFStatusAtIndex:index];
    } else if (imageFormat == kUTTypePNG) {
        return [imageSrc getPNGStatusAtIndex:index];
    } else if (imageFormat == kUTTypeBMP) {
        return [imageSrc getBMPStatusAtIndex:index];
    } else if (imageFormat == kUTTypeICO) {
        return [imageSrc getICOStatusAtIndex:index];
    } else {
        return kCGImageStatusUnknownType;
    } 
}
