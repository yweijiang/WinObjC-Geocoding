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

- (instancetype)initIncremental {
    if (self = [super init]) {
        _incrementalSource = true;
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
    return data[offset] | (data[offset + 1] << 8);
}

uint32_t get32BitValue(const uint8_t* data, size_t offset) {
    return data[offset] | (data[offset + 1] << 8) | (data[offset + 2] << 16) | (data[offset + 3] << 24);
}

uint32_t get32BitValueBigEndian(const uint8_t* data, size_t offset) {
    return (data[offset] << 24) | (data[offset + 1] << 16) | (data[offset + 2] << 8) | data[offset + 3];
}

uint32_t get16BitValueBigEndian(const uint8_t* data, size_t offset) {
    return (data[offset] << 8) | data[offset + 1];
}

/**
 @Notes      Helper function to get the status of JPEG images at the provided index.
             Progressively encoded JPEG images are not supported by Apple APIs and the current implementation does not support it.

 @References https://en.wikipedia.org/wiki/JPEG
             https://en.wikipedia.org/wiki/JPEG_File_Interchange_Format                    
*/
- (CGImageSourceStatus)getJPEGStatusAtIndex:(size_t)index {
    static const uint8_t c_imageEndIdentifier[2] = {0xFF, 0xD9};
    static const uint8_t c_scanStartIdentifier[2] = {0xFF, 0xDA};

    // Return if requesting for invalid frames
    if (index != 0) {
        return kCGImageStatusUnknownType;
    }

    const uint8_t* imageData = static_cast<const uint8_t*>([self.data bytes]);
    NSUInteger imageLength = [self.data length];
    
    if (imageLength < c_minDataStreamSize) {
        return kCGImageStatusReadingHeader;
    }

    // Check if the End Of Image marker is present in the data stream
    if (imageData[imageLength - 2] == c_imageEndIdentifier[0] && imageData[imageLength - 1] == c_imageEndIdentifier[1]) {
        return kCGImageStatusComplete;
    } 

    // Check if the Start Of Scan marker is present in the data stream
    for (size_t offset = 2, blockLength = 0; offset < imageLength - 3; offset += blockLength + 2) {
        blockLength = get16BitValueBigEndian(imageData, offset + 2);

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

// TIFF helper function to get the size of a specific tag given the offset of its tag block
// Assumes that imageData has already been confirmed to contain all of the tag block at the offset
uint32_t getTiffTagSize(const uint8_t* imageData, uint32_t offset) {
    static const size_t c_tagIDOffset = 2;
    static const size_t c_tagDataTypeOffset = 4;

    // Data store that fetches the size of an incoming data type  
    static const uint8_t tagTypeSize[] = {
        1, // BYTE 8-bit unsigned integer
        1, // ASCII 8-bit, NULL-terminated string
        2, // SHORT 16-bit unsigned integer
        4, // LONG 32-bit unsigned integer
        8, // RATIONAL Two 32-bit unsigned integers
        1, // SBYTE 8-bit signed integer
        1, // UNDEFINE 8-bit byte
        2, // SSHORT 16-bit signed integer
        4, // SLONG 32-bit signed integer
        8, // SRATIONAL Two 32-bit signed integers
        4, // FLOAT 4-byte single-precision IEEE floating-point value
        8  // DOUBLE 8-byte double-precision IEEE floating-point value    
    };

    uint16_t tagDataType = get16BitValue(imageData, offset + c_tagIDOffset);
    uint32_t tagDataCount = get32BitValue(imageData, offset + c_tagDataTypeOffset);
    
    return tagTypeSize[tagDataType - 1] * tagDataCount;
}

/**
 @Notes      Helper function to get the status of TIFF images at the provided index
             Current release supports TIFF sources with little-endian byte ordering only

 @References http://www.fileformat.info/format/tiff/egff.htm
             https://partners.adobe.com/public/developer/en/tiff/TIFF6.pdf
             http://www.awaresystems.be/imaging/tiff/faq.html
*/
- (CGImageSourceStatus)getTIFFStatusAtIndex:(size_t)index {
    static const size_t c_ifdOffset = 4;
    static const size_t c_tagCountSize = 2;
    static const size_t c_tagIDSize = 2;
    static const size_t c_tagDataTypeSize = 2;
    static const size_t c_tagDataCountSize = 4;
    static const size_t c_tagDataOffsetSize = 4;
    static const size_t c_tagSize = 12;

    const uint8_t* imageData = static_cast<const uint8_t*>([self.data bytes]);
    NSUInteger imageLength = [self.data length];

    if (imageLength < c_minDataStreamSize) {
        return kCGImageStatusReadingHeader;
    }
    
    // Offset into the first Image File Directory (IFD) starts at byte offset 4
    uint32_t offset = get32BitValue(imageData, c_ifdOffset);

    // Check if data for previous image frames is present 
    for (size_t currentFrameIndex = 0; currentFrameIndex < index; currentFrameIndex++) {
        if (offset + 2 > imageLength) {
            return kCGImageStatusUnknownType;
        }

        uint16_t tagCount = get16BitValue(imageData, offset);

        // Each tag is 12 bytes and each tag count size is 2 bytes
        offset += c_tagCountSize + (tagCount * c_tagSize);

        if (offset + 4 > imageLength) {
            return kCGImageStatusUnknownType;
        }

        // Fetch the IFD offset for the next frame
        offset = get32BitValue(imageData, offset);
    }
    
    if (offset + 2 > imageLength) {
        return kCGImageStatusUnknownType;
    }

    // Make a copy of the IFD start offset. If the requested frame is the last, we need to check presence of the final tag's data.   
    uint32_t startOffset = offset;
    uint16_t tagCount = get16BitValue(imageData, offset);

    // Each tag count size is 2 bytes and each tag is 12 bytes
    offset += c_tagCountSize + (tagCount * c_tagSize);

    if (offset + 4 > imageLength) {
        return kCGImageStatusUnknownType;
    } 

    // Get the next IFD's offset. Would be zero if the requested frame is the last.
    uint32_t nextOffset = get32BitValue(imageData, offset);

    // If the requested frame is either the last frame of the image or the next frame has not been loaded, check current frame
    if (nextOffset == 0 || nextOffset > imageLength) {
        // Reset the offset to point to the TagList without advancing past all the tags
        offset = startOffset + c_tagCountSize;
        
        bool completeTagFound = false;
        bool incompleteTagFound = false;

        // Iterate over all the tags until the first tag with data at an offset is loaded (if lastTagLoadCheck is false), or 
        // the last tag with offset data is loaded (if lastTagLoadCheck is true).
        for (uint16_t i = 0; i < tagCount; i++) {
            uint32_t tagDataSize;
            uint32_t tagDataOffset;

            // Check to make sure that the tag ID, DataType, and Count fields are all present.
            // Each tag block is 12 bytes, 2 bytes for tag ID, 2 bytes for data type of tag, 4 bytes for data size,
            // and 4 bytes for data offset, which is a pointer to where the tag data is stored.
            // If the tag list is not fully loaded, then we automatically return UnknownType.
            if (offset + 8 > imageLength) {
                return kCGImageStatusUnknownType;
            }

            // Compute the size of the current tag
            tagDataSize = getTiffTagSize(imageData, offset);

            // Move offset to the beginning of the tag offset field
            offset += c_tagIDSize + c_tagDataTypeSize + c_tagDataCountSize;

            // If the tagDataSize is small enough, the tag data is stored in the tag offset field
            // Otherwise, it contains an index to where the data is stored
            if (tagDataSize > c_tagDataOffsetSize) {
                if (offset + 4 > imageLength) {
                    return kCGImageStatusUnknownType;
                }

                // Check the data pointed to by the tag data offset. If fully there, then at least some of the tag data is loaded.
                tagDataOffset = get32BitValue(imageData, offset);
                if (tagDataOffset + tagDataSize <= imageLength) {
                    completeTagFound = true;
                } else {
                    incompleteTagFound = true;
                }
            } 

            // Move the offset past the NextIFDOffset field
             offset += c_tagDataOffsetSize;
        }

        if (completeTagFound && incompleteTagFound) {
            // Some tag data present, but also some tag data incomplete
            return kCGImageStatusIncomplete;
        } else if (completeTagFound && !incompleteTagFound) {
            // All tags with data offsets are complete, so all data in current frame is there
            return kCGImageStatusComplete;
        } else if (!completeTagFound && incompleteTagFound) {
            // No tags with data offsets are loaded, so this is considered UnknownType
            return kCGImageStatusUnknownType;
        }

        // If no complete or incomplete tag data was found, that means that the IFD only contained data small enough to fit
        // in DataOffset fields, and since we confirmed that all the tags were loaded, this means the frame is complete.
        return kCGImageStatusComplete;
    }
    
    // If the requested frame is not the last frame and the next frame has been partially loaded, check the IFD of the next frame.
    offset = nextOffset;

    if (offset + 2 > imageLength) {
        return kCGImageStatusIncomplete;
    }

    // Move the offset past the next IFD's Tag Entry Count and TagList. This is needed to be consistent with Apple's implementation
    tagCount = get16BitValue(imageData, offset);
    offset += c_tagCountSize + (tagCount * c_tagSize);
    return offset <= imageLength ? kCGImageStatusComplete : kCGImageStatusIncomplete;
}

// GIF helper function to parse various Extensions - Graphic Control, Plain Text, Application & Comment
// The offset to an extension is to be passed
// Returns the offset to an Image Descriptor or to the next extension
size_t parseGIFExtension(const uint8_t* data, NSUInteger length, size_t offset) {
    static const size_t c_extensionTypeSize = 2;

    //Advance offset past the extension labels
    offset += c_extensionTypeSize;

    // Iterate over all extension sub-blocks by checking the block length. A block length of 0 marks the end of current extension 
    while (offset < length && data[offset] != 0) {
        offset += data[offset] + 1;
    }

    // Advance past the block terminator to the start of the next extension or frame
    offset++;
    return offset;    
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
    static const uint8_t c_gifExtensionHeader = 0x21;
    static const uint8_t c_gifDescriptorHeader = 0x2C;
    static const uint8_t c_gifTrailer = 0x3B;
    static const size_t c_imageDescriptorSize = 10;
    static const size_t c_minDataBlocks = 3;

    const uint8_t* imageData = static_cast<const uint8_t*>([self.data bytes]);
    NSUInteger imageLength = [self.data length];
        
    if (imageLength < c_minDataStreamSize) {
        return kCGImageStatusReadingHeader;
    }

    size_t offset = c_headerSize + c_logicalDescriptorSize;

    // Advance offset if global color table exists. Check for existence by reading MSB of packed byte 
    if (imageData[c_packedFieldOffset] & 0x80) {
        // Extract the last three bits from packed byte to get the Global Color Table Size representation and compute actual size
        offset += 3 << ((imageData[c_packedFieldOffset] & 0x7) + 1);

        // Return unknown if offset is somewhere past the end of the image data before any image frames are found
        if (offset >= imageLength) {
            return kCGImageStatusUnknownType;
        }
    }

    size_t currentFrame = 0;
    bool blocksFound = false;
    CGImageSourceStatus status;

    // Parse all available Extensions before any of the Image Data is found 
    while (imageData[offset] == c_gifExtensionHeader) {
        offset = parseGIFExtension(imageData, imageLength, offset);

        if (offset >= imageLength) {
            if (currentFrame == index) {
                return blocksFound ? kCGImageStatusIncomplete : kCGImageStatusUnknownType;
            } else {
                return kCGImageStatusUnknownType;
            }
        }
    }

    for (currentFrame = 0; currentFrame <= index; currentFrame++) {
        // Parse through the current frame
        if (imageData[offset] == c_gifDescriptorHeader) {

            // To replicate Apple's status change sequence, offset is initially moved past only the first (N - 1) bytes of Image Descriptor
            // A reading header status (for first frame), incomplete status (for other requested frames) or 
            // unknown status (for non-requested frames) returned on stream interruption
            offset += c_imageDescriptorSize - 1;
            if (offset >= imageLength) {
                if (index == 0) {
                    return kCGImageStatusReadingHeader;
                } else {
                    return currentFrame == index ? kCGImageStatusIncomplete : kCGImageStatusUnknownType;
                }
            }

            // Offset moved past the last Image Descriptor byte
            // An unknown type status returned on stream interruption
            offset++;
            if (offset >= imageLength) {
                return kCGImageStatusUnknownType;
            }

            // Advance offset if local color table exists. Check for existence by reading MSB of packed byte 
            if (imageData[offset - 1] & 0x80) {
                // Extract the last three bits from packed byte to get the Local Color Table Size representation and compute actual size
                offset += 3 << ((imageData[offset - 1] & 0x7) + 1);
            }

            // Advance to the Image Data section
            // An unknown type status returned on stream interruption
            offset++;
            if (offset >= imageLength) {
                return kCGImageStatusUnknownType;
            }

            // Iterate over all image data sub-blocks by checking the block length. A block length of 0 marks the end of current frame
            size_t imageBlocks = 0;
            while (imageData[offset] != 0) {
                // Move offset initially past the first (N - 1) data sub-blocks. This is done to match Apple's implementation. 
                // An unknown status is returned until the sub-block after the fourth length field is reached. 
                // An incomplete status is returned later.
                offset += imageData[offset]; 
                if (offset >= imageLength) {
                    return (currentFrame == index && imageBlocks >= c_minDataBlocks) ? kCGImageStatusIncomplete : kCGImageStatusUnknownType;
                }

                // Offset is made to point to the length field of the next block
                // An unknown status is returned until the sub-block after the fourth length field is found. 
                // An incomplete status is returned later.
                offset++;
                imageBlocks++;            
                if (offset >= imageLength) {
                    return (currentFrame == index && imageBlocks >= c_minDataBlocks) ? kCGImageStatusIncomplete : kCGImageStatusUnknownType;
                }
            }

            // Point offset to either the trailer byte or to the beginning of the next extension or frame 
            // An incomplete status (for requested frames) or an UnknownType status (for non-requested frames) is returned on interruption
            offset++;
            if (offset >= imageLength) {
                return currentFrame == index ? kCGImageStatusIncomplete : kCGImageStatusUnknownType;
            }

            // All blocks have been found since the frame has been completely parsed
            if (currentFrame == index) {
                blocksFound = true;
            }
        } else {
            // Image data not found
            return kCGImageStatusUnknownType;
        }

        // Parse all available Extensions before reaching the trailer or the next frame 
        while (imageData[offset] == c_gifExtensionHeader) {
            offset = parseGIFExtension(imageData, imageLength, offset);

            if (offset >= imageLength) {
                if (currentFrame == index) {
                    return blocksFound ? kCGImageStatusIncomplete : kCGImageStatusUnknownType;
                } else {
                    return kCGImageStatusUnknownType;
                }
            }
        }
    }

    // The frame is completely loaded if either a GIF trailer or the Image Descriptor of the next frame are present.   
    if (imageData[offset] == c_gifTrailer || imageData[offset] == c_gifDescriptorHeader) {
        return kCGImageStatusComplete;
    } else {
        return kCGImageStatusIncomplete;
    }
}

/**
 @Notes      Helper function to get the status of BMP images at the provided index

 @References https://en.wikipedia.org/wiki/BMP_file_format
             http://www.fileformat.info/format/bmp/egff.htm
*/
- (CGImageSourceStatus)getBMPStatusAtIndex:(size_t)index {
    static const size_t c_fileSizeIndex = 2;

    // Return if requesting for invalid frames
    if (index != 0) {
        return kCGImageStatusUnknownType;
    }

    const uint8_t* imageData = static_cast<const uint8_t*>([self.data bytes]);
    NSUInteger imageLength = [self.data length];

    if (imageLength < c_minDataStreamSize) {
        return kCGImageStatusReadingHeader;
    }

    // Check if incoming data stream size matches image file size 
    if (imageLength == get32BitValue(imageData, c_fileSizeIndex)) {
        return kCGImageStatusComplete;
    } else {
        // Apple's implementation doesn't return kCGImageStatusIncomplete for BMP images
        return kCGImageStatusUnknownType;
    }
}

/**
 @Notes      Helper function to get the status of PNG images at the provided index
             Interlaced PNG images are not supported by Apple APIs and the current implementation does not support it.
             The PLTE chunk is mandatory for color type 3, optional for types 2 and 6, and absent for types 0 and 4. 
             Apple verifies these requirements. The current release does not support this.

 @References https://www.w3.org/TR/PNG/
             https://en.wikipedia.org/wiki/Portable_Network_Graphics
*/
- (CGImageSourceStatus)getPNGStatusAtIndex:(size_t)index {
    static const size_t c_imageEndIdentifierReverseIndex = 8;
    static const size_t c_headerSize = 8;
    static const size_t c_lengthSize = 4;
    static const size_t c_chunkTypeSize = 4;
    static const size_t c_chunkDataOffset = 7;
    static const size_t c_CRCSize = 4;
    static const uint8_t c_imageEndIdentifier[] = {'I', 'E', 'N', 'D'};
    static const uint8_t c_frameStartIdentifier[] = {'I', 'D', 'A', 'T'};
    
    // Return if requesting for invalid frames
    if (index != 0) {
        return kCGImageStatusUnknownType;
    }
     
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
    size_t offset = c_headerSize;
    while (offset + c_chunkDataOffset < imageLength) {        
        uint32_t chunkLength = get32BitValueBigEndian(imageData, offset);
        offset += c_lengthSize;
        if (imageData[offset] == c_frameStartIdentifier[0] &&
            imageData[offset + 1] == c_frameStartIdentifier[1] && 
            imageData[offset + 2] == c_frameStartIdentifier[2] && 
            imageData[offset + 3] == c_frameStartIdentifier[3]) {
            return kCGImageStatusIncomplete;
        }
        
        offset += c_chunkTypeSize + chunkLength + c_CRCSize;
    }

    return kCGImageStatusUnknownType;
}

/**
 @Notes      Helper function to get the status of ICO images at the provided index

 @References https://msdn.microsoft.com/en-us/library/ms997538.aspx 
             https://en.wikipedia.org/wiki/ICO_(file_format)
*/
- (CGImageSourceStatus)getICOStatusAtIndex:(size_t)index {
    static const size_t c_reservedOffset = 4;
    static const size_t c_imageCountOffset = 2;
    static const size_t c_sizeOffset = 8;
    static const size_t c_dataSize = 4;
    static const size_t c_offsetSize = 4;
    
    const uint8_t* imageData = static_cast<const uint8_t*>([self.data bytes]);
    NSUInteger imageLength = [self.data length];
    
    if (imageLength < c_minDataStreamSize) {
        return kCGImageStatusReadingHeader;
    }
        
    // Move the offset through 4 of the header bytes to point to the number of images in the file 
    size_t offset = c_reservedOffset;
    if (offset + 2 > imageLength) {
        return kCGImageStatusUnknownType;
    }
    
    size_t imageCount = get16BitValue(imageData, offset);

    // Move the offset to point to the header for the first image
    offset += c_imageCountOffset;

    // The offset is moved to the image data size field of the last frame header 
    // This is consistent with Apple's implementation that refers to the last frame irrespective of the one requested for
    for (size_t currentFrameIndex = 0; currentFrameIndex < imageCount; currentFrameIndex++) {

        // Move the offset to point to the image data size field
        offset += c_sizeOffset;

        // Move the offset to the beginning of the next frame's header if available
        if (currentFrameIndex != imageCount - 1) {
            offset += c_dataSize + c_offsetSize;
        }
    }

    if (offset + 4 > imageLength) {
        return kCGImageStatusUnknownType;
    } 

    uint32_t imageDataLength = get32BitValue(imageData, offset); 

    // Move the offset to the image data offset field of the header
    offset += c_dataSize;
    if (offset + 4 > imageLength) {
        return kCGImageStatusUnknownType;
    } 

    uint32_t imagePixelOffset = get32BitValue(imageData, offset);

    // Check if all of the image data is present in the stream
    // Apple does not return kCGImageStatusIncomplete for the ICO format
    if (imageDataLength + imagePixelOffset <= imageLength) {
        return kCGImageStatusComplete;
    } else {
        return kCGImageStatusUnknownType;
    }
}

- (CGImageSourceStatus)getStatusAtIndex:(size_t)index {
    if (!self.data) {
        return kCGImageStatusUnexpectedEOF;
    }

    static const int c_minDataStreamSize = 96;
    if ([self.data length] < c_minDataStreamSize) {
        return kCGImageStatusReadingHeader;
    }

    CFStringRef imageFormat = [self getImageType];
    if (imageFormat == kUTTypeJPEG) {
        return [self getJPEGStatusAtIndex:index];
    } else if (imageFormat == kUTTypeTIFF) {
        return [self getTIFFStatusAtIndex:index];
    } else if (imageFormat == kUTTypeGIF) {
        return [self getGIFStatusAtIndex:index];
    } else if (imageFormat == kUTTypePNG) {
        return [self getPNGStatusAtIndex:index];
    } else if (imageFormat == kUTTypeBMP) {
        return [self getBMPStatusAtIndex:index];
    } else if (imageFormat == kUTTypeICO) {
        return [self getICOStatusAtIndex:index];
    } else {
        return kCGImageStatusUnknownType;
    } 
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
        During incremental loading of PNG images, decoder creation succeeds only when all image data is available
*/
CGImageRef CGImageSourceCreateImageAtIndex(CGImageSourceRef isrc, size_t index, CFDictionaryRef options) {
    RETURN_NULL_IF(!isrc);
    ImageSource* source = (ImageSource*)isrc;
    NSData* imageData = source.data;
    RETURN_NULL_IF(!imageData);

    source.loadStatus = [source getStatusAtIndex:index];
    source.loadIndex = index + 1;
    RETURN_NULL_IF(source.loadStatus != kCGImageStatusIncomplete && source.loadStatus != kCGImageStatusComplete);
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
    return (CGImageSourceRef)[[ImageSource alloc] initIncremental];
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
    if (!imageSrc.data) {
        return kCGImageStatusInvalidData;
    }

    if (!imageSrc.incrementalSource) {
        return kCGImageStatusComplete;
    }

    if ([imageSrc.data length] < c_minDataStreamSize) {
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
 @Notes The kCGImageStatusInvalidData status is not supported.
        Only Baseline DCT-based JPEG sources are supported by Apple and the current implementation. 
        Progressive DCT-based JPEG sources are not supported. 
        TIFF sources with big-endian byte ordering are not supported.
        Interlaced GIF and PNG sources are not supported by Apple and the current implementation.
        The PLTE chunk is mandatory for color type 3, optional for types 2 and 6, and absent for types 0 and 4. 
        This verification of PLTE presence is not supported. 
*/
CGImageSourceStatus CGImageSourceGetStatusAtIndex(CGImageSourceRef isrc, size_t index) {
    if (!isrc) {
        return kCGImageStatusReadingHeader;
    }

    ImageSource* imageSrc = (ImageSource*)isrc;
    if (!imageSrc.data) {
        return kCGImageStatusUnexpectedEOF;
    }

    if (!imageSrc.incrementalSource) {
        if (index == imageSrc.loadIndex - 1 && index < CGImageSourceGetCount(isrc)) {
            return kCGImageStatusComplete;
        } else {
            return kCGImageStatusUnknownType;
        }
    }

    if ([imageSrc.data length] < c_minDataStreamSize) {
        return kCGImageStatusReadingHeader;
    }

    CFStringRef imageFormat = CGImageSourceGetType(isrc);
    if (index == imageSrc.loadIndex - 1) {
        return imageSrc.loadStatus;
    } else {
        return kCGImageStatusUnknownType;
    } 
}
