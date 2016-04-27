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
        _incrementalSource = false;
    }

    return self;
}

- (instancetype)initWithURL:(CFURLRef)url {
    if (self = [super init]) {
        _data = [NSData dataWithContentsOfURL:(NSURL*)url];
        _incrementalSource = false;
    }

    return self;
}

- (instancetype)initWithDataProvider:(CGDataProviderRef)provider {
    if (self = [super init]) {
        _data = (NSData*)CGDataProviderCopyData(provider);
        _incrementalSource = false;
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

// TIFF helper function to get the size of a specific tag with provided data type and count
uint32_t getTagSize(uint16_t tagDataType, uint32_t tagDataCount) {

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

    return tagTypeSize[tagDataType - 1] * tagDataCount;
}

// TIFF helper function that checks if tag data at the specified position is present in the data stream
// The offset must be set to the start of the required frame's IFD header
// The position flag is to be set to 0 to check for the first tag (Incomplete) and set to 1 to check for the last tag (Complete)
bool tagDataFound(const uint8_t* imageData, NSUInteger imageLength, uint32_t offset, bool position) {
    if (offset + 1 >= imageLength) {
        return false;
    }

    static const size_t c_tagCountSize = 2;
    static const size_t c_tagIDSize = 2;
    static const size_t c_tagDataTypeSize = 2;
    static const size_t c_tagDataCountSize = 4;
    static const size_t c_tagDataOffsetSize = 4;

    uint16_t tagCount = get16BitValue(imageData, offset);

    // Move the offset to point to the TagList (Array of Tags)
    offset += c_tagCountSize;

    uint16_t i;
    uint32_t tagDataSize;
    uint32_t lastTagDataOffset = 0;
    uint32_t lastTagDataSize = 0;

    // Iterate over all the tags until the first tag with data at an offset is loaded (if position is 0), or 
    // the last tag with offset data is loaded (if position is 1).
    for (i = 0; i < tagCount; i++) {
        // Move offset past the Tag ID field
        offset += c_tagIDSize;

        if (offset + 1 >= imageLength) {
            return false;
        } 

        uint16_t tagDataType = get16BitValue(imageData, offset);

        // Move offset past the tag data type
        offset += c_tagDataTypeSize;
        if (offset + 3 >= imageLength) {
            return false;
        } 

        uint32_t tagDataCount = get32BitValue(imageData, offset); 

        // Move offset past the tag data count
        offset += c_tagDataCountSize;

        // Compute the size of the current tag from data type and count
        tagDataSize = getTagSize(tagDataType, tagDataCount);

        // Check if the tag's data is too large for the NextIFDOffset field
        if (tagDataSize > c_tagDataOffsetSize) {
            if (offset + 3 >= imageLength) {
                return false;
            }

            // Make a copy of the Tag Data Size and Tag Data Offset
            lastTagDataOffset = get32BitValue(imageData, offset);
            lastTagDataSize = tagDataSize;

            // Exit the loop if the requested tag is the first one with fully loaded data
            if (position == false) {
                offset = lastTagDataOffset;
                tagDataSize = lastTagDataSize;
                break;
            }
        } 

        // Move the offset past the NextIFDOffset field
         offset += c_tagDataOffsetSize;
    }

    if (position == true && lastTagDataOffset != 0) {
        // The last tag with fully loaded data is present
        return (lastTagDataOffset + lastTagDataSize) <= imageLength ? true : false;
    } else if (position == false && i <= tagCount) {
        // The first tag with fully loaded data is present
        return (offset + tagDataSize) <= imageLength ? true : false;
    } else {
        // No tags with data at offsets are present. Tag data is self contained in the NextIFDOffset field
        return true;
    }
}

// TIFF helper function to identify if a frame is completely loaded
// The offset must be set to the start of the required frame's IFD header
// Apple's implementation returns complete only when the last tag's data is completely loaded. 
// Additionally, the Number of Tag Entries and TagList of the next frame's IFD must be present (if requested frame is not the last).   
bool tiffFrameComplete(const uint8_t* imageData, NSUInteger imageLength, uint32_t offset) {
    static const size_t c_tagCountSize = 2;
    static const size_t c_tagSize = 12;

    if (offset + 1 >= imageLength) {
        return false;
    }

    // Make a copy of the IFD start offset. If the requested frame is the last, would need to check presence of the final tag's data.   
    uint32_t ifdOffset = offset;
    uint16_t tagCount = get16BitValue(imageData, offset);

    // Each tag count size is 2 bytes and each tag is 12 bytes
    offset += c_tagCountSize + (tagCount * c_tagSize);

    if (offset + 3 >= imageLength) {
        return false;
    } 

    // Get the next IFD's offset. Would be zero if the requested frame is the last.
    uint32_t nextIfdOffset = get32BitValue(imageData, offset);

    // Process offset only if the requested frame is not the last
    if (nextIfdOffset != 0) {
        offset = nextIfdOffset;
    } else {
        // Check if the last tag is present in the data stream
        return tagDataFound(imageData, imageLength, ifdOffset, 1);
    }

    if (offset + 1 >= imageLength) {
        return false;
    }

    // Move the offset past the next IFD's Tag Entry Count and TagList. This is needed to be consistent with Apple's implementation
    tagCount = get16BitValue(imageData, offset);
    offset += c_tagCountSize + (tagCount * c_tagSize);
    return offset <= imageLength ? true : false;
}

// TIFF helper function to identify incomplete frames
// The offset must be set to the start of the required frame's IFD header
// Apple's implementation returns incomplete only when the the frame's first tag data is completely loaded at the provided offset   
bool tiffFrameIncomplete(const uint8_t* imageData, NSUInteger imageLength, uint32_t offset) {
    // Check if the first tag is present in the data stream
    return tagDataFound(imageData, imageLength, offset, 0);
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
        if (offset + 1 >= imageLength) {
            return kCGImageStatusUnknownType;
        }

        uint16_t tagCount = get16BitValue(imageData, offset);

        // Each tag is 12 bytes and each tag count size is 2 bytes
        offset += c_tagCountSize + (tagCount * c_tagSize);

        if (offset + 3 >= imageLength) {
            return kCGImageStatusUnknownType;
        }

        offset = get32BitValue(imageData, offset);
    }

    // Check if all image frame data is present in the data stream
    if (tiffFrameComplete(imageData, imageLength, offset)) {
        return kCGImageStatusComplete;
    } else if (tiffFrameIncomplete(imageData, imageLength, offset)) {
        return kCGImageStatusIncomplete;
    } else {
        return kCGImageStatusUnknownType;
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
    static const uint8_t c_gifTrailer = 0x3B;

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

    // Count the number of frames we find by keeping track of the number of image descriptor blocks encountered.
    // Exit loop when the Image Descriptor for a frame beyond the required one is found, or we go past the end of the image data.
    size_t framesLoaded = 0;
    size_t imageBlocks = 0;

    // Flag to check if the previous frame was present in the data stream
    bool frameProcessed = false;

    // Flags for tracking the status of incremental loading
    bool extensionIncomplete = false;
    bool descriptorIncomplete = false;
    bool imageHeaderUnknown = false;
    bool imageDataIncomplete = false;
    bool frameIncomplete = false;
    bool frameComplete = false;

    // Loop continues until the Image Descriptor of the next frame is found or if the trailer for the overall image is encountered
    while (framesLoaded <= index) {
        bool extensionHeaderFound = (imageData[offset] == c_gifExtensionHeader);
        bool descriptorHeaderFound = (imageData[offset] == c_gifDescriptorHeader);

        // Advance Start of Frame offset through various Extensions (Graphic Control, Plain Text, Application & Comment)
        if (extensionHeaderFound) {
            //Advance offset past the extension labels
            offset += c_extensionTypeSize;

            // Iterate over all extension sub-blocks by checking the block length. A block length of 0 marks the end of current extension 
            while (offset < imageLength && imageData[offset] != 0) {
                offset += imageData[offset] + 1;
            }

            // Advance past the block terminator to the start of the next extension or frame
            offset++;
            if (offset >= imageLength) {
                extensionIncomplete = true;
                break;
            }
        } else if (descriptorHeaderFound) {
            // Check for the start of an Image Descriptor
            // An image frame is to be marked complete only if the Image Descriptor of the next frame or the overall image trailer is found
            // Check if the previous frame was present in the data stream and increment the number of frames loaded
            if (frameProcessed) {
                framesLoaded++;
            }

            // Continue to evaluate the loop condition when the needed frame is found
            if (framesLoaded == index + 1) {
                frameComplete = true;
                continue;
            }

            // To replicate Apple's status change sequence, offset is initially moved past only the first (N - 1) bytes of Image Descriptor
            offset += c_imageDescriptorSize - 1;
            if (offset >= imageLength) {
                descriptorIncomplete = true;
                break;
            }

            // Offset moved past the last Image Descriptor byte
            offset ++;
            if (offset >= imageLength) {
                imageHeaderUnknown = true;
                break;
            }

            // Advance offset if local color table exists. Check for existence by reading MSB of packed byte 
            if (imageData[offset - 1] & 0x80) {
                // Extract the last three bits from packed byte to get the Local Color Table Size representation and compute actual size
                offset += 3 << ((imageData[offset - 1] & 0x7) + 1);
            }

            // Advance to the Image Data section
            offset++;
            if (offset >= imageLength) {
                imageHeaderUnknown = true;
                break;
            }

            // Iterate over all image data sub-blocks by checking the block length. A block length of 0 marks the end of current frame
            // Image Blocks are tracked as frame status is marked incomplete only when the beginning of the third block is noticed
            imageBlocks = 0;
            while (offset < imageLength && imageData[offset] != 0) {
                // To replicate Apple's status change sequence, offset is initially moved past only the first (N - 1) data sub-blocks
                offset += imageData[offset];
                if (offset >= imageLength) {
                    imageDataIncomplete = true;
                }

                // Offset is moved past the last data sub-block
                offset++;
                if (offset >= imageLength && !imageDataIncomplete) {
                    frameIncomplete = true;
                }

                if (!imageDataIncomplete && !frameIncomplete) {
                    imageBlocks++;
                }
            }

            if (imageDataIncomplete || frameIncomplete) {
                break;
            }

            // Point offset to either the trailer byte or to the beginning of the next extension or frame 
            offset++;
            if (offset >= imageLength) {
                framesLoaded == index ? frameIncomplete = true : imageHeaderUnknown = true;
                break;
            }

            // Reached end of the image data for current frame
            if (imageData[offset] == c_gifTrailer) {
                frameComplete = true;
                framesLoaded++;
            } else {
                // Marks the end of a processed frame
                frameProcessed = true;
            }
        } else {
            // Neither of the valid block headers were encountered, this means we have an unknown type
            return kCGImageStatusUnknownType;
        }
    }

    if (frameComplete) {
        // Start of the Image Descriptor for the next frame or the Trailer for the overall image was found  
        return kCGImageStatusComplete;
    } else if (frameIncomplete) {
        // Incomplete Image Data sub-blocks
        return kCGImageStatusIncomplete;
    } else if (imageDataIncomplete) {
        // Frame is incomplete only if atleast the third sub-block of Image Data is found
        return (frameProcessed && framesLoaded == index && imageBlocks >= 3) ? kCGImageStatusIncomplete : kCGImageStatusUnknownType;
    } else if (imageHeaderUnknown) {
        // Incomplete Local Color Table or Frame not started
        return kCGImageStatusUnknownType;
    } else if (descriptorIncomplete) {
        // Incomplete Image Descriptor
        if (index == 0) {
            return kCGImageStatusReadingHeader;
        } else {
            return (frameProcessed && framesLoaded == index) ? kCGImageStatusIncomplete : kCGImageStatusUnknownType;
        }        
    } else if (extensionIncomplete) {
        // Missing Block Terminator
        return (frameProcessed && framesLoaded == index) ? kCGImageStatusIncomplete : kCGImageStatusUnknownType;
    } else {
        return kCGImageStatusUnknownType;
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
    if (offset + 1 >= imageLength) {
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

    if (offset + 3 >= imageLength) {
        return kCGImageStatusUnknownType;
    } 

    uint32_t imageDataLength = get32BitValue(imageData, offset); 

    // Move the offset to the image data offset field of the header
    offset += c_dataSize;
    if (offset + 3 >= imageLength) {
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
