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

#import <ImageIO/CGImageDestination.h>
#import <ImageIO/CGImageDestinationInternal.h>
#import <StubReturn.h>
#include <windows.h>
#include <vector>

static const wchar_t* TAG = L"CGImageDestination"; 
const CFStringRef kCGImageDestinationLossyCompressionQuality = static_cast<CFStringRef>(@"kCGImageDestinationLossyCompressionQuality");
const CFStringRef kCGImageDestinationBackgroundColor = static_cast<CFStringRef>(@"kCGImageDestinationBackgroundColor");

const CFStringRef kUTTypeJPEG = static_cast<const CFStringRef>(@"public.jpeg");
const CFStringRef kUTTypeTIFF = static_cast<const CFStringRef>(@"public.tiff");
const CFStringRef kUTTypeGIF = static_cast<const CFStringRef>(@"com.compuserve.gif");
const CFStringRef kUTTypePNG = static_cast<const CFStringRef>(@"public.png");
const CFStringRef kUTTypeBMP = static_cast<const CFStringRef>(@"com.microsoft.bmp");

enum imageTypes { typeJPEG,
                  typeTIFF,
                  typeGIF,
                  typePNG,
                  typeBMP,
                  typeUnknown };

enum destinationTypes { toData,
                        toURL,
                        toConsumer };

@implementation ImageDestination

- (instancetype)initToDestination:(size_t)frames
                             type:(CFStringRef)type
                             data:(CFMutableDataRef)data
                              url:(CFURLRef)url {
    if (self = [super init]) {
        RETURN_NULL_IF(url && ![(NSURL*)url isFileURL]);
        RETURN_NULL_IF(!data && !url);

        self.maxCount = frames;

        MULTI_QI imageQueryInterface = {0};
        static const GUID IID_IWICImagingFactory = {0xec5ec8a9,0xc395,0x4314,0x9c,0x77,0x54,0xd7,0xa9,0x35,0xff,0x70};
        imageQueryInterface.pIID = &IID_IWICImagingFactory;
        RETURN_NULL_IF_FAILED(
            CoCreateInstanceFromApp(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, nullptr, 1, &imageQueryInterface));
        
        _idFactory = (IWICImagingFactory*)imageQueryInterface.pItf;
        RETURN_NULL_IF_FAILED(_idFactory->CreateStream(&_idStream));

        if (CFStringCompare(type, kUTTypeJPEG, NULL) == kCFCompareEqualTo) {
            _type = typeJPEG;
            RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatJpeg, NULL, &_idEncoder));
        } else if (CFStringCompare(type, kUTTypeTIFF, NULL) == kCFCompareEqualTo) {
            _type = typeTIFF;
            RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatTiff, NULL, &_idEncoder));
        } else if (CFStringCompare(type, kUTTypeGIF, NULL) == kCFCompareEqualTo) {
            _type = typeGIF;
            RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatGif, NULL, &_idEncoder));
        } else if (CFStringCompare(type, kUTTypePNG, NULL) == kCFCompareEqualTo) {
            _type = typePNG;
            RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatPng, NULL, &_idEncoder));
        } else if (CFStringCompare(type, kUTTypeBMP, NULL) == kCFCompareEqualTo) {
            _type = typeBMP;
            RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatBmp, NULL, &_idEncoder));
        } else {
            _type = typeUnknown;
            return NULL;
        }

        if (url) {
            NSString* urlNSString = [[(NSURL*)url path] substringFromIndex:1];
            NSData* urlAsData = [urlNSString dataUsingEncoding:NSUTF16StringEncoding];
            std::wstring wideUrl((wchar_t*)[urlAsData bytes], [urlAsData length]/sizeof(wchar_t));
            RETURN_NULL_IF_FAILED(_idStream->InitializeFromFilename(wideUrl.c_str(), GENERIC_WRITE));

            if (![(NSURL*)url checkResourceIsReachableAndReturnError:NULL]) {
                return NULL;
            }
        } else if (data) {
            _outData = data;

            IStream* dataStream;
            CreateStreamOnHGlobal(NULL, true, &dataStream);
            RETURN_NULL_IF_FAILED(_idStream->InitializeFromIStream(dataStream));
        } else {
            // We are not currently handling data consumer as destination because data consumer is not implemented in WinObjC
            UNIMPLEMENTED();
            NSTraceInfo(TAG, @"Destination as Data Consumer is not handled right now");
        }

        RETURN_NULL_IF_FAILED(_idEncoder->Initialize(_idStream.Get(), WICBitmapEncoderNoCache));

        if (_type == typeGIF) {
            RETURN_NULL_IF_FAILED(_idEncoder->GetMetadataQueryWriter(&_idGifEncoderMetadataQueryWriter));
        }
    }

    return self;
}

@end

// Helper function for setting the property write values when formatting image metadata.
// Image metadata stores decimal numbers as an integer divided by another integer.
// The HighPart is a number representing what to divide the LowPart by to get the actual value.
void setHighLowParts(ULARGE_INTEGER* valueLarge, double valueDouble) {
    // Check to see if the value has a decimal component. If not, just divide by 1.
    if (valueDouble == (int)valueDouble) {
        (*valueLarge).LowPart = (int)valueDouble;
        (*valueLarge).HighPart = 1;
    } else {
        (*valueLarge).LowPart = (int)(valueDouble * 100);
        (*valueLarge).HighPart = 100;
    }
}

// Helper function to write properties to image frames
void writePropertyToFrame(PROPVARIANT* propertyToWrite, LPCWSTR path, IWICMetadataQueryWriter* propertyWriter) {
    HRESULT status = propertyWriter->SetMetadataByName(path, propertyToWrite);
    if (!SUCCEEDED(status)) {
        NSString* pathNSString = [[NSString alloc] initWithBytes:path
                                                          length:wcslen(path)*2
                                                        encoding:NSUTF16StringEncoding];
        NSTraceInfo(TAG, @"Set %@ failed with status=%x\n", pathNSString, status);
    }
}

void setVariantFromDictionary(CFDictionaryRef dictionary,
                              CFStringRef key,
                              VARTYPE propertyType,
                              LPCWSTR path,
                              IWICMetadataQueryWriter* propertyWriter) {
    if (!dictionary) {
        return;
    }
    
    if (CFDictionaryContainsKey(dictionary, key)) {
        PROPVARIANT propertyToWrite;
        PropVariantInit(&propertyToWrite);
        propertyToWrite.vt = propertyType;

        if (propertyType == VT_UI2) {
            propertyToWrite.uiVal = (unsigned short)[(id)CFDictionaryGetValue(dictionary, key) unsignedShortValue];
            writePropertyToFrame(&propertyToWrite, path, propertyWriter);
        } else if (propertyType == VT_UI8) {
            double doubleOut = [(id)CFDictionaryGetValue(dictionary, key) doubleValue];
            setHighLowParts(&propertyToWrite.uhVal, doubleOut);
            writePropertyToFrame(&propertyToWrite, path, propertyWriter);
        }
    }
}

/**
 @Status Stub
 @Notes
*/
CGImageDestinationRef CGImageDestinationCreateWithDataConsumer(CGDataConsumerRef consumer,
                                                               CFStringRef type,
                                                               size_t count,
                                                               CFDictionaryRef options) {
    
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Caveat
 @Notes The current implementation supports common image file formats such as JPEG, GIF, TIFF, BMP, PNG and ICO. 
        Not all formats are supported. For CreateWithData, the CFMutableDataRef is not modified until finalize.
*/
CGImageDestinationRef CGImageDestinationCreateWithData(CFMutableDataRef data, CFStringRef type, size_t count, CFDictionaryRef options) {
    RETURN_NULL_IF(!data);
    
    return (CGImageDestinationRef)[[ImageDestination alloc] initToDestination:count type:type data:data url:NULL];
}

/**
 @Status Caveat
 @Notes The current implementation supports common image file formats such as JPEG, GIF, TIFF, BMP, PNG and ICO. 
        Not all formats are supported.
*/
CGImageDestinationRef CGImageDestinationCreateWithURL(CFURLRef url, CFStringRef type, size_t count, CFDictionaryRef options) {
    RETURN_NULL_IF(!url);
    
    return (CGImageDestinationRef)[[ImageDestination alloc] initToDestination:count type:type data:NULL url:url];
}

/**
 @Status Caveat
 @Notes The current implementation supports common image file formats such as JPEG, TIFF, BMP, GIF, and PNG. 
        Not all formats are supported. Also, the option for kCGImageDestinationBackgroundColor is currently not supported.
*/
void CGImageDestinationAddImage(CGImageDestinationRef idst, CGImageRef image, CFDictionaryRef properties) {
    if (!idst) {
        return;
    }

    ImageDestination* imageDestination = (ImageDestination*)idst;
    if (imageDestination.count >= imageDestination.maxCount) {
        NSTraceInfo(TAG, @"Max number of images in destination exceeded");
        return;
    }

    ComPtr<IWICBitmapFrameEncode> imageBitmapFrame;
    IPropertyBag2* propertyBag = NULL;
    
    ComPtr<IWICBitmapEncoder> imageEncoder = imageDestination.idEncoder;

    // If there is no Encoder, the destination has either been already finalized or not initialized yet, so return
    if (!imageEncoder) {
        NSTraceInfo(TAG, @"Destination object has no Encoder");
        return;
    }

    HRESULT status = imageEncoder->CreateNewFrame(&imageBitmapFrame, &propertyBag);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"CreateNewFrame failed with status=%x\n", status);
        return;
    }

    // JPEG lossy compression property
    if (properties && CFDictionaryContainsKey(properties, kCGImageDestinationLossyCompressionQuality) &&
            imageDestination.type == typeJPEG) {
        PROPBAG2 option = { 0 };
        option.pstrName = L"ImageQuality";
        VARIANT varValue;    
        VariantInit(&varValue);
        varValue.vt = VT_R4;
        varValue.bVal = [(id)CFDictionaryGetValue(properties, kCGImageDestinationLossyCompressionQuality) doubleValue];
        if (varValue.bVal >= 0.0 && varValue.bVal <= 1.0) {
            status = propertyBag->Write(1, &option, &varValue);
            if (!SUCCEEDED(status)) {
                NSTraceInfo(TAG, @"Property Bag Write failed with status=%x\n", status);
                return;
            }
        }
    }

    status = imageBitmapFrame->Initialize(propertyBag);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"Frame Initialize failed with status=%x\n", status);
        return;
    }

    unsigned int imageWidth = CGImageGetWidth(image);
    unsigned int imageHeight = CGImageGetHeight(image);

    // Set size and resolution of the image frame
    status = imageBitmapFrame->SetSize(imageWidth, imageHeight);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"Set Frame Size failed with status=%x\n", status);
        return;
    }

    // Using resolution of 72 dpi as standard for now, this seems to only affect metadata and not the image itself
    status = imageBitmapFrame->SetResolution(72.0, 72.0);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"Set Frame Resolution failed with status=%x\n", status);
        return;
    }

    // Set the pixel format based on file format
    WICPixelFormatGUID formatGUID;
    switch (imageDestination.type) {
        case typeJPEG:
            formatGUID = GUID_WICPixelFormat24bppBGR;
            break;
        case typeTIFF:
            formatGUID = GUID_WICPixelFormat32bppRGBA;
            break;
        case typeGIF:
            formatGUID = GUID_WICPixelFormat8bppIndexed;
            break;
        case typePNG:
            formatGUID = GUID_WICPixelFormat32bppRGBA;
            break;
        case typeBMP:
            formatGUID = GUID_WICPixelFormat32bppRGBA;
            break;
        default:
            NSTraceInfo(TAG, @"Unknown type encountered");
            return;
    }

    // Setting up writing properties to individual image frame, bitmaps cannot have metadata
    ComPtr<IWICMetadataQueryWriter> imageFrameMetadataWriter;
    if (imageDestination.type != typeBMP) {
        status = imageBitmapFrame->GetMetadataQueryWriter(&imageFrameMetadataWriter);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Get Frame Metadata Writer failed with status=%x\n", status);
            return;
        }
    }

    PROPVARIANT propertyToWrite;

    // Image metadata for JPEG images
    if (imageDestination.type == typeJPEG) {
        PropVariantInit(&propertyToWrite);
        propertyToWrite.vt = VT_UI2;
        propertyToWrite.uiVal = 8; // We are always using 8 bits per channel per pixel right now
        writePropertyToFrame(&propertyToWrite, L"/app1/ifd/{ushort=258}", imageFrameMetadataWriter.Get());

        PropVariantInit(&propertyToWrite);
        propertyToWrite.vt = VT_UI2;
        propertyToWrite.uiVal = imageWidth;
        writePropertyToFrame(&propertyToWrite, L"/app1/ifd/{ushort=256}", imageFrameMetadataWriter.Get());

        PropVariantInit(&propertyToWrite);
        propertyToWrite.vt = VT_UI2;
        propertyToWrite.uiVal = imageHeight;
        writePropertyToFrame(&propertyToWrite, L"/app1/ifd/{ushort=257}", imageFrameMetadataWriter.Get());

        setVariantFromDictionary(properties,
                                 kCGImagePropertyOrientation,
                                 VT_UI2,
                                 L"/app1/ifd/{ushort=274}",
                                 imageFrameMetadataWriter.Get());
            
        // GPS information, must be found in GPS Dictionary
        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyGPSDictionary)) {
            CFDictionaryRef gpsDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyGPSDictionary);
        
            setVariantFromDictionary(gpsDictionary,
                                     kCGImagePropertyGPSAltitude,
                                     VT_UI8,
                                     L"/app1/ifd/gps/{ushort=6}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSAltitudeRef)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_UI1;
                propertyToWrite.bVal = (unsigned char)[(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSAltitudeRef) intValue];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/gps/{ushort=5}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSDateStamp)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSDateStamp) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/gps/{ushort=29}", imageFrameMetadataWriter.Get());
            }

            setVariantFromDictionary(gpsDictionary,
                                     kCGImagePropertyGPSDOP,
                                     VT_UI8,
                                     L"/app1/ifd/gps/{ushort=11}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(gpsDictionary,
                                     kCGImagePropertyGPSImgDirection,
                                     VT_UI8,
                                     L"/app1/ifd/gps/{ushort=17}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSImgDirectionRef)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSImgDirectionRef) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/gps/{ushort=16}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLatitude)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_VECTOR | VT_UI8;
                double gpsDegrees = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLatitude) doubleValue];
                double gpsMinutes = (gpsDegrees - (int)gpsDegrees)*60;
                double gpsSeconds = (gpsMinutes - (int)gpsMinutes)*60;
                
                ULARGE_INTEGER gpsValues[3];
                gpsValues[0].LowPart = (int)gpsDegrees;
                gpsValues[0].HighPart = 1;
                gpsValues[1].LowPart = (int)gpsMinutes;
                gpsValues[1].HighPart = 1;
                setHighLowParts(&gpsValues[2], gpsSeconds);

                propertyToWrite.cauh.cElems = 3;
                propertyToWrite.cauh.pElems = gpsValues;
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/gps/{ushort=2}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLatitudeRef)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLatitudeRef) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/gps/{ushort=1}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLongitude)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_VECTOR | VT_UI8;
                double gpsDegrees = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLongitude) doubleValue];
                double gpsMinutes = (gpsDegrees - (int)gpsDegrees)*60;
                double gpsSeconds = (gpsMinutes - (int)gpsMinutes)*6000;
                                
                ULARGE_INTEGER gpsValues[3];
                gpsValues[0].LowPart = (int)gpsDegrees;
                gpsValues[0].HighPart = 1;
                gpsValues[1].LowPart = (int)gpsMinutes;
                gpsValues[1].HighPart = 1;
                setHighLowParts(&gpsValues[2], gpsSeconds);

                propertyToWrite.cauh.cElems = 3;
                propertyToWrite.cauh.pElems = gpsValues;
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/gps/{ushort=4}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLongitudeRef)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLongitudeRef) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/gps/{ushort=3}", imageFrameMetadataWriter.Get());
            }

            setVariantFromDictionary(gpsDictionary,
                                     kCGImagePropertyGPSSpeed,
                                     VT_UI8,
                                     L"/app1/ifd/gps/{ushort=13}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSSpeedRef)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSSpeedRef) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/gps/{ushort=12}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSTimeStamp)) {
                // Not handling this property at the moment
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = (VT_VECTOR | VT_UI8);
                NSString* imageGPSVersion = (NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSTimeStamp);
                propertyToWrite.cauh.cElems = 0;
                for (int timeStampIndex = 0; timeStampIndex < propertyToWrite.cauh.cElems; timeStampIndex++) {
                    propertyToWrite.cauh.pElems[timeStampIndex].QuadPart = 0;
                }
                UNIMPLEMENTED();
                // Metadata name is L"/app1/ifd/gps/{ushort=7}", not writing at the moment
            }

            setVariantFromDictionary(gpsDictionary,
                                     kCGImagePropertyGPSTrack,
                                     VT_UI8,
                                     L"/app1/ifd/gps/{ushort=15}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSTrackRef)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSTrackRef) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/gps/{ushort=14}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSVersion)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = (VT_VECTOR | VT_UI1);
                NSString* imageGPSVersion = (NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSVersion);
                const char* versionArray = [imageGPSVersion UTF8String];
                propertyToWrite.caub.cElems = 4;
                for (int index = 0; index < propertyToWrite.cauh.cElems; index++) {
                    propertyToWrite.caub.pElems[index] = versionArray[index];
                }
            }
        }

        // Exif information, must be found in Exif Dictionary
        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyExifDictionary)) {
            CFDictionaryRef exifDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyExifDictionary);
        
            // Exif X and Y dimensions, always written
            PropVariantInit(&propertyToWrite);
            propertyToWrite.vt = VT_UI2;
            propertyToWrite.uiVal = imageWidth;
            writePropertyToFrame(&propertyToWrite, L"/app1/ifd/exif/{ushort=40962}", imageFrameMetadataWriter.Get());

            PropVariantInit(&propertyToWrite);
            propertyToWrite.vt = VT_UI2;
            propertyToWrite.uiVal = imageHeight;
            writePropertyToFrame(&propertyToWrite, L"/app1/ifd/exif/{ushort=40963}", imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifExposureTime,
                                     VT_UI8,
                                     L"/app1/ifd/exif/{ushort=33434}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifApertureValue,
                                     VT_UI8,
                                     L"/app1/ifd/exif/{ushort=37378}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifBrightnessValue,
                                     VT_UI8,
                                     L"/app1/ifd/exif/{ushort=37379}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifDateTimeDigitized)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifDateTimeDigitized) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/exif/{ushort=36868}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifDateTimeOriginal)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifDateTimeOriginal) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/exif/{ushort=36867}", imageFrameMetadataWriter.Get());
            }

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifDigitalZoomRatio,
                                     VT_UI8,
                                     L"/app1/ifd/exif/{ushort=41988}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifExposureMode,
                                     VT_UI2,
                                     L"/app1/ifd/exif/{ushort=41986}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifExposureProgram,
                                     VT_UI2,
                                     L"/app1/ifd/exif/{ushort=34850}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifFlash,
                                     VT_UI2,
                                     L"/app1/ifd/exif/{ushort=37385}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifFNumber,
                                     VT_UI8,
                                     L"/app1/ifd/exif/{ushort=33437}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifFocalLength,
                                     VT_UI8,
                                     L"/app1/ifd/exif/{ushort=37386}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifISOSpeedRatings)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_UI4;
                propertyToWrite.ulVal = (unsigned long)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifISOSpeedRatings) intValue];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/exif/{ushort=34867}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifLensMake)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifLensMake) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/exif/{ushort=42035}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifLensModel)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifLensModel) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/exif/{ushort=42036}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifMakerNote)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_BLOB;
                NSData* exifMakerNote = (NSData*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifMakerNote);
                propertyToWrite.blob.cbSize = [exifMakerNote length];
                propertyToWrite.blob.pBlobData = (unsigned char*)[exifMakerNote bytes];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/exif/{ushort=37500}", imageFrameMetadataWriter.Get());
            }

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifMeteringMode,
                                     VT_UI2,
                                     L"/app1/ifd/exif/{ushort=37383}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifSceneCaptureType,
                                     VT_UI2,
                                     L"/app1/ifd/exif/{ushort=41990}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifShutterSpeedValue)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_I8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifShutterSpeedValue) doubleValue];
                setHighLowParts(&propertyToWrite.uhVal, doubleOut);
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/exif/{ushort=37377}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifUserComment)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPWSTR;
                NSString* exifUserComment = (NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifUserComment);
                propertyToWrite.pwszVal = (wchar_t*)[exifUserComment cStringUsingEncoding:NSUTF16StringEncoding];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/exif/{ushort=37510}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifVersion)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_BLOB;
                NSData* exifVersion = (NSData*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifVersion);
                propertyToWrite.blob.cbSize = [exifVersion length];
                propertyToWrite.blob.pBlobData = (unsigned char*)[exifVersion bytes];
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/exif/{ushort=36864}", imageFrameMetadataWriter.Get());
            }
            
            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifWhiteBalance,
                                     VT_UI2,
                                     L"/app1/ifd/exif/{ushort=41987}",
                                     imageFrameMetadataWriter.Get());
        }
    }

    if (imageDestination.type == typeGIF) {
        PropVariantInit(&propertyToWrite);
        propertyToWrite.vt = VT_UI2;
        propertyToWrite.uiVal = imageWidth;
        writePropertyToFrame(&propertyToWrite, L"/imgdesc/Width", imageFrameMetadataWriter.Get());

        PropVariantInit(&propertyToWrite);
        propertyToWrite.vt = VT_UI2;
        propertyToWrite.uiVal = imageHeight;
        writePropertyToFrame(&propertyToWrite, L"/imgdesc/Height", imageFrameMetadataWriter.Get());

        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyGIFDictionary)) {
            CFDictionaryRef gifDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
            
            setVariantFromDictionary(gifDictionary,
                                     kCGImagePropertyGIFDelayTime,
                                     VT_UI2,
                                     L"/grctlext/Delay",
                                     imageFrameMetadataWriter.Get());
        }
    }

    // Image metadata for TIFF images
    if (imageDestination.type == typeTIFF) {
        PropVariantInit(&propertyToWrite);
        propertyToWrite.vt = VT_UI2;
        propertyToWrite.uiVal = 8; // We are always using 8 bits per channel per pixel right now
        writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=258}", imageFrameMetadataWriter.Get());

        PropVariantInit(&propertyToWrite);
        propertyToWrite.vt = VT_UI2;
        propertyToWrite.uiVal = imageWidth;
        writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=256}", imageFrameMetadataWriter.Get());

        PropVariantInit(&propertyToWrite);
        propertyToWrite.vt = VT_UI2;
        propertyToWrite.uiVal = imageHeight;
        writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=257}", imageFrameMetadataWriter.Get());

        setVariantFromDictionary(properties,
                                 kCGImagePropertyOrientation,
                                 VT_UI2,
                                 L"/ifd/{ushort=274}",
                                 imageFrameMetadataWriter.Get());

        // GPS information, must be found in GPS Dictionary
        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyGPSDictionary)) {
            CFDictionaryRef gpsDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyGPSDictionary);
        
            setVariantFromDictionary(gpsDictionary,
                                     kCGImagePropertyGPSAltitude,
                                     VT_UI8,
                                     L"/ifd/gps/{ushort=6}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSAltitudeRef)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_UI1;
                propertyToWrite.bVal = (unsigned char)[(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSAltitudeRef) intValue];
                writePropertyToFrame(&propertyToWrite, L"/ifd/gps/{ushort=5}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSDateStamp)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSDateStamp) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/gps/{ushort=29}", imageFrameMetadataWriter.Get());
            }

            setVariantFromDictionary(gpsDictionary,
                                     kCGImagePropertyGPSDOP,
                                     VT_UI8,
                                     L"/ifd/gps/{ushort=11}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(gpsDictionary,
                                     kCGImagePropertyGPSImgDirection,
                                     VT_UI8,
                                     L"/ifd/gps/{ushort=17}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSImgDirectionRef)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSImgDirectionRef) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/gps/{ushort=16}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLatitude)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_VECTOR | VT_UI8;
                double gpsDegrees = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLatitude) doubleValue];
                double gpsMinutes = (gpsDegrees - (int)gpsDegrees)*60;
                double gpsSeconds = (gpsMinutes - (int)gpsMinutes)*6000;
                
                ULARGE_INTEGER gpsValues[3];
                gpsValues[0].LowPart = (int)gpsDegrees;
                gpsValues[0].HighPart = 1;
                gpsValues[1].LowPart = (int)gpsMinutes;
                gpsValues[1].HighPart = 1;
                setHighLowParts(&gpsValues[2], gpsSeconds);

                propertyToWrite.cauh.cElems = 3;
                propertyToWrite.cauh.pElems = gpsValues;
                writePropertyToFrame(&propertyToWrite, L"/ifd/gps/{ushort=2}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLatitudeRef)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLatitudeRef) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/gps/{ushort=1}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLongitude)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_VECTOR | VT_UI8;
                double gpsDegrees = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLongitude) doubleValue];
                double gpsMinutes = (gpsDegrees - (int)gpsDegrees)*60;
                double gpsSeconds = (gpsMinutes - (int)gpsMinutes)*6000;
                
                ULARGE_INTEGER gpsValues[3];
                gpsValues[0].LowPart = (int)gpsDegrees;
                gpsValues[0].HighPart = 1;
                gpsValues[1].LowPart = (int)gpsMinutes;
                gpsValues[1].HighPart = 1;
                setHighLowParts(&gpsValues[2], gpsSeconds);

                propertyToWrite.cauh.cElems = 3;
                propertyToWrite.cauh.pElems = gpsValues;
                writePropertyToFrame(&propertyToWrite, L"/ifd/gps/{ushort=4}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLongitudeRef)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLongitudeRef) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/gps/{ushort=3}", imageFrameMetadataWriter.Get());
            }

            setVariantFromDictionary(gpsDictionary,
                                     kCGImagePropertyGPSSpeed,
                                     VT_UI8,
                                     L"/ifd/gps/{ushort=13}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSSpeedRef)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSSpeedRef) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/gps/{ushort=12}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSTimeStamp)) {
                // Not handling this property at the moment
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = (VT_VECTOR | VT_UI8);
                NSString* imageGPSVersion = (NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSTimeStamp);
                propertyToWrite.cauh.cElems = 0;
                for (int timeStampIndex = 0; timeStampIndex < propertyToWrite.cauh.cElems; timeStampIndex++) {
                    propertyToWrite.cauh.pElems[timeStampIndex].QuadPart = 0;
                }
                UNIMPLEMENTED();
                // Metadata name is L"/ifd/gps/{ushort=7}", not writing at the moment
            }

            setVariantFromDictionary(gpsDictionary,
                                     kCGImagePropertyGPSTrack,
                                     VT_UI8,
                                     L"/ifd/gps/{ushort=15}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSTrackRef)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSTrackRef) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/gps/{ushort=14}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSVersion)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = (VT_VECTOR | VT_UI1);
                NSString* imageGPSVersion = (NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSVersion);
                const char* versionArray = [imageGPSVersion UTF8String];
                propertyToWrite.caub.cElems = 4;
                for (int index = 0; index < propertyToWrite.cauh.cElems; index++) {
                    propertyToWrite.caub.pElems[index] = versionArray[index];
                }
                writePropertyToFrame(&propertyToWrite, L"/ifd/gps/{ushort=0}", imageFrameMetadataWriter.Get());
            }
        }

        // Exif information, must be found in Exif Dictionary
        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyExifDictionary)) {
            CFDictionaryRef exifDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyExifDictionary);
        
            // Exif X and Y dimensions, always written
            PropVariantInit(&propertyToWrite);
            propertyToWrite.vt = VT_UI2;
            propertyToWrite.uiVal = imageWidth;
            writePropertyToFrame(&propertyToWrite, L"/ifd/exif/{ushort=40962}", imageFrameMetadataWriter.Get());

            PropVariantInit(&propertyToWrite);
            propertyToWrite.vt = VT_UI2;
            propertyToWrite.uiVal = imageHeight;
            writePropertyToFrame(&propertyToWrite, L"/ifd/exif/{ushort=40963}", imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifExposureTime,
                                     VT_UI8,
                                     L"/ifd/exif/{ushort=33434}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifApertureValue,
                                     VT_UI8,
                                     L"/ifd/exif/{ushort=37378}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifBrightnessValue,
                                     VT_UI8,
                                     L"/ifd/exif/{ushort=37379}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifDateTimeDigitized)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifDateTimeDigitized) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/exif/{ushort=36868}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifDateTimeOriginal)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifDateTimeOriginal) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/exif/{ushort=36867}", imageFrameMetadataWriter.Get());
            }

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifDigitalZoomRatio,
                                     VT_UI8,
                                     L"/ifd/exif/{ushort=41988}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifExposureMode)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_UI2;
                propertyToWrite.uiVal = (unsigned short)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifExposureMode) intValue];
                writePropertyToFrame(&propertyToWrite, L"/ifd/exif/{ushort=41986}", imageFrameMetadataWriter.Get());
            }

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifExposureMode,
                                     VT_UI2,
                                     L"/ifd/exif/{ushort=41986}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifExposureProgram,
                                     VT_UI2,
                                     L"/ifd/exif/{ushort=34850}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifFlash,
                                     VT_UI2,
                                     L"/ifd/exif/{ushort=37385}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifFNumber,
                                     VT_UI8,
                                     L"/ifd/exif/{ushort=33437}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifFocalLength,
                                     VT_UI8,
                                     L"/ifd/exif/{ushort=37386}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifISOSpeedRatings)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_UI4;
                propertyToWrite.ulVal = (unsigned long)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifISOSpeedRatings) intValue];
                writePropertyToFrame(&propertyToWrite, L"/ifd/exif/{ushort=34867}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifLensMake)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifLensMake) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/exif/{ushort=42035}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifLensModel)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifLensModel) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/exif/{ushort=42036}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifMakerNote)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_BLOB;
                NSData* exifMakerNote = (NSData*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifMakerNote);
                propertyToWrite.blob.cbSize = [exifMakerNote length];
                propertyToWrite.blob.pBlobData = (unsigned char*)[exifMakerNote bytes];
                writePropertyToFrame(&propertyToWrite, L"/ifd/exif/{ushort=37500}", imageFrameMetadataWriter.Get());
            }

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifMeteringMode,
                                     VT_UI2,
                                     L"/ifd/exif/{ushort=37383}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifSceneCaptureType,
                                     VT_UI2,
                                     L"/ifd/exif/{ushort=41990}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifShutterSpeedValue)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_I8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifShutterSpeedValue) doubleValue];
                setHighLowParts(&propertyToWrite.uhVal, doubleOut);
                writePropertyToFrame(&propertyToWrite, L"/ifd/exif/{ushort=37377}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifUserComment)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPWSTR;
                NSString* exifUserComment = (NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifUserComment);
                propertyToWrite.pwszVal = (wchar_t*)[exifUserComment cStringUsingEncoding:NSUTF16StringEncoding];
                writePropertyToFrame(&propertyToWrite, L"/ifd/exif/{ushort=37510}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifVersion)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_BLOB;
                NSData* exifVersion = (NSData*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifVersion);
                propertyToWrite.blob.cbSize = [exifVersion length];
                propertyToWrite.blob.pBlobData = (unsigned char*)[exifVersion bytes];
                writePropertyToFrame(&propertyToWrite, L"/ifd/exif/{ushort=36864}", imageFrameMetadataWriter.Get());
            }

            setVariantFromDictionary(exifDictionary,
                                     kCGImagePropertyExifWhiteBalance,
                                     VT_UI2,
                                     L"/ifd/exif/{ushort=41987}",
                                     imageFrameMetadataWriter.Get());
        }

        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyTIFFDictionary)) {
            CFDictionaryRef tiffDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyTIFFDictionary);
            
            setVariantFromDictionary(tiffDictionary,
                                     kCGImagePropertyTIFFCompression,
                                     VT_UI2,
                                     L"/ifd/{ushort=259}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(tiffDictionary,
                                     kCGImagePropertyTIFFPhotometricInterpretation,
                                     VT_UI2,
                                     L"/ifd/{ushort=262}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFImageDescription)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFImageDescription) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=270}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFMake)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFMake) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=271}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFModel)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFModel) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=272}", imageFrameMetadataWriter.Get());
            }

            setVariantFromDictionary(tiffDictionary,
                                     kCGImagePropertyTIFFOrientation,
                                     VT_UI2,
                                     L"/ifd/{ushort=274}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(tiffDictionary,
                                     kCGImagePropertyTIFFXResolution,
                                     VT_UI8,
                                     L"/ifd/{ushort=282}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(tiffDictionary,
                                     kCGImagePropertyTIFFYResolution,
                                     VT_UI8,
                                     L"/ifd/{ushort=283}",
                                     imageFrameMetadataWriter.Get());

            setVariantFromDictionary(tiffDictionary,
                                     kCGImagePropertyTIFFResolutionUnit,
                                     VT_UI2,
                                     L"/ifd/{ushort=296}",
                                     imageFrameMetadataWriter.Get());

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFSoftware)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFSoftware) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=305}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFDateTime)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFDateTime) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=306}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFArtist)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFArtist) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=315}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFCopyright)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFCopyright) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=33432}", imageFrameMetadataWriter.Get());
            }

            setVariantFromDictionary(tiffDictionary,
                                     kCGImagePropertyTIFFWhitePoint,
                                     VT_UI2,
                                     L"/ifd/{ushort=41987}",
                                     imageFrameMetadataWriter.Get());
        }
    }

    if (imageDestination.type == typePNG) {
        /*
        // The following 3 properties are listed in CGImageSource as common PNG properties but writing to these causes
        // the image to be corrupt and I cannot find MSDN documentation listing these. The paths seem wrong as well.
        PropVariantInit(&propertyToWrite);
        propertyToWrite.vt = VT_UI2;
        propertyToWrite.uiVal = imageWidth;
        writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=256}", imageFrameMetadataWriter.Get());

        PropVariantInit(&propertyToWrite);
        propertyToWrite.vt = VT_UI2;
        propertyToWrite.uiVal = imageHeight;
        writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=257}", imageFrameMetadataWriter.Get());

        setVariantFromDictionary(properties,
                                 kCGImagePropertyOrientation,
                                 VT_UI2,
                                 L"/ifd/{ushort=274}",
                                 imageFrameMetadataWriter.Get());
        */

        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyProfileName)) {
            PropVariantInit(&propertyToWrite);
            propertyToWrite.vt = VT_LPSTR;
            propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(properties, kCGImagePropertyProfileName) UTF8String];
            writePropertyToFrame(&propertyToWrite, L"/iCCP/ProfileName", imageFrameMetadataWriter.Get());
        }

        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyPNGDictionary)) {
            CFDictionaryRef pngDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyPNGDictionary);

            if (CFDictionaryContainsKey(pngDictionary, kCGImagePropertyPNGGamma)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_UI4;
                propertyToWrite.ulVal = (unsigned long)[(id)CFDictionaryGetValue(pngDictionary, kCGImagePropertyPNGGamma) intValue];
                writePropertyToFrame(&propertyToWrite, L"/gAMA/ImageGamma", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(pngDictionary, kCGImagePropertyPNGsRGBIntent)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_UI1;
                propertyToWrite.bVal = (unsigned char)[(id)CFDictionaryGetValue(pngDictionary, kCGImagePropertyPNGsRGBIntent) intValue];
                writePropertyToFrame(&propertyToWrite, L"/sRGB/RenderingIntent", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(pngDictionary, kCGImagePropertyPNGChromaticities)) {
                // Not handling this property at the moment
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = (VT_VECTOR | VT_UI1);
                NSString* pngChromaticities = (NSString*)CFDictionaryGetValue(pngDictionary, kCGImagePropertyPNGChromaticities);
                propertyToWrite.caub.cElems = 0;
                for (int timeStampIndex = 0; timeStampIndex < propertyToWrite.cauh.cElems; timeStampIndex++) {
                    propertyToWrite.caub.pElems[timeStampIndex] = 0;
                }
                UNIMPLEMENTED();
                // Metadata name is L"/chrominance/TableEntry", not writing at the moment
            }

            if (CFDictionaryContainsKey(pngDictionary, kCGImagePropertyPNGCopyright)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(pngDictionary, kCGImagePropertyPNGCopyright) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=33432}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(pngDictionary, kCGImagePropertyPNGDescription)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(pngDictionary, kCGImagePropertyPNGDescription) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=270}", imageFrameMetadataWriter.Get());
            }

            if (CFDictionaryContainsKey(pngDictionary, kCGImagePropertyPNGSoftware)) {
                PropVariantInit(&propertyToWrite);
                propertyToWrite.vt = VT_LPSTR;
                propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(pngDictionary, kCGImagePropertyPNGSoftware) UTF8String];
                writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=305}", imageFrameMetadataWriter.Get());
            }
        }
    }

    status = imageBitmapFrame->SetPixelFormat(&formatGUID);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"Set Pixel Format failed with status=%x\n", status);
        return;
    }

    CGDataProviderRef provider = CGImageGetDataProvider(image);
    NSData* imageByteData = (id)CGDataProviderCopyData(provider);

    // Turn image into a WIC Bitmap
    ComPtr<IWICBitmap> inputImage;

    // All our input coming in from CGImagesource is in 32bppRGBA
    ComPtr<IWICImagingFactory> imageFactory = imageDestination.idFactory;
    status = imageFactory->CreateBitmapFromMemory(imageWidth,
                                                  imageHeight,
                                                  GUID_WICPixelFormat32bppRGBA,
                                                  imageWidth * 4,
                                                  imageHeight * imageWidth * 4,
                                                  (unsigned char*)[imageByteData bytes],
                                                  &inputImage);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"CreateBitmapFromMemory failed with status=%x\n", status);
        return;
    }

    CGDataProviderRelease(provider);

    ComPtr<IWICBitmapSource> inputBitmapSource;
    status = WICConvertBitmapSource(formatGUID, inputImage.Get(), &inputBitmapSource);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"Convert Bitmap Source failed with status=%x\n", status);
        return;
    }

    status = imageBitmapFrame->WriteSource(inputBitmapSource.Get(), NULL);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"Write Source failed with status=%x\n", status);
        return;
    }
    
    status = imageBitmapFrame->Commit();
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"Commit Frame failed with status=%x\n", status);
        return;
    }
    imageDestination.count++;
    
    return;
}

/**
 @Status Caveat
 @Notes The current implementation supports common image file formats such as JPEG, TIFF, BMP, GIF, and PNG. 
        Not all formats are supported. Also, the option for kCGImageDestinationBackgroundColor is currently not supported.
*/
void CGImageDestinationAddImageFromSource(CGImageDestinationRef idst, CGImageSourceRef isrc, size_t index, CFDictionaryRef properties) {
    // Pull image reference from the image source using CGImageSource API, then calls AddImage
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(isrc, index, properties);
    CGImageDestinationAddImage(idst, imageRef, properties);
    CGImageRelease(imageRef);
}

/**
 @Status Caveat
 @Notes Current release supports JPEG, BMP, PNG, GIF, & TIFF image formats only 
*/
CFArrayRef CGImageDestinationCopyTypeIdentifiers() {
    static const CFStringRef typeIdentifiers[] = {kUTTypePNG, kUTTypeJPEG, kUTTypeGIF, kUTTypeTIFF, kUTTypeBMP};
    CFArrayRef imageTypeIdentifiers = CFArrayCreate(nullptr, (const void**)typeIdentifiers, ARRAYSIZE(typeIdentifiers), &kCFTypeArrayCallBacks);
    return imageTypeIdentifiers;
}

/**
 @Status Caveat
 @Notes The CFTypeID for an opaque type changes from release to release and so has been hard-coded in current implementation
*/
CFTypeID CGImageDestinationGetTypeID() {
    CFTypeID imageTypeID = 269;
    return imageTypeID;
}

/**
 @Status Stub
 @Notes
*/
void CGImageDestinationSetProperties(CGImageDestinationRef idst, CFDictionaryRef properties) {
    if (!idst) {
        return;
    }

    ImageDestination* imageDestination = (ImageDestination*)idst;

    // If Encoder or is missing, the destination has either been already finalized or not initialized yet, so return
    if (!imageDestination.idEncoder) {
        NSTraceInfo(TAG, @"CGImageDestinationFinalize did not find an Encoder");
        return;
    }

    // Looping properties for GIFs
    if (imageDestination.type == typeGIF) {
        char loopCountMSB = 0;
        char loopCountLSB = 0;

        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyGIFDictionary)) {
            CFDictionaryRef gifDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
            if (CFDictionaryContainsKey(gifDictionary, kCGImagePropertyGIFLoopCount)) {
                int loopCount = [(id)CFDictionaryGetValue(gifDictionary, kCGImagePropertyGIFLoopCount) intValue];
                loopCountLSB = loopCount & 0xff;
                loopCountMSB = (loopCount >> 8) & 0xff;
            }
        }

        ComPtr<IWICMetadataQueryWriter> imageMetadataQueryWriter = imageDestination.idGifEncoderMetadataQueryWriter;
        PROPVARIANT writePropValue;

        PropVariantInit(&writePropValue);
        writePropValue.vt = VT_UI1 | VT_VECTOR;
        writePropValue.caub.cElems = 11;
        writePropValue.caub.pElems = (unsigned char*)[@"NETSCAPE2.0" UTF8String];
        HRESULT status = imageMetadataQueryWriter->SetMetadataByName(L"/appext/Application", &writePropValue);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Write global gif metadata failed with status=%x\n", status);
            return;
        }

        writePropValue.caub.cElems = 5;
        writePropValue.caub.pElems =
            (unsigned char*)[[NSString stringWithFormat:@"%c%c%c%c%c", 3, 1, loopCountLSB, loopCountMSB, 0] UTF8String];
        status = imageMetadataQueryWriter->SetMetadataByName(L"/appext/Data", &writePropValue);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Write global gif metadata failed with status=%x\n", status);
            return;
        }
    }
}

/**
 @Status Caveat
 @Notes All data is not finalized until CFRelease is called on the idst object
        because the idst object contains pointers for the stream and encoder.
*/
bool CGImageDestinationFinalize(CGImageDestinationRef idst) {
    if (!idst) {
        return false;
    }

    ImageDestination* imageDestination = (ImageDestination*)idst;

    if (imageDestination.count != imageDestination.maxCount) {
        NSTraceInfo(TAG, @"CGImageDestinationFinalize image destination does not have enough images");
        return false;
    }

    ComPtr<IWICBitmapEncoder> imageEncoder = imageDestination.idEncoder;
    ComPtr<IWICStream> imageStream = imageDestination.idStream;

    // If Encoder or Stream are missing, the destination has either been already finalized or not initialized yet, so return
    if (!imageEncoder || !imageStream) {
        NSTraceInfo(TAG, @"CGImageDestinationFinalize did not find an Encoder or Stream");
        return false;
    }

    HRESULT status = imageEncoder->Commit();
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"Encoder Commit failed with status=%x\n", status);
        return false;
    }

    if (imageDestination.outData) {
        NSMutableData* dataNSPointer = static_cast<NSMutableData*>(imageDestination.outData);

        // Seek to beginning of stream after image data all written
        status = imageStream->Seek({0}, STREAM_SEEK_SET, NULL);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Stream Seek failed with status=%x\n", status);
            return false;
        }

        // Get stream stats in order to determine number of bytes that were written
        STATSTG streamStats;
        status = imageStream->Stat(&streamStats, STATFLAG_NONAME);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Fetch stream stats failed with status=%x\n", status);
            return false;
        }

        // Copy stream into the mutable data
        [dataNSPointer increaseLengthBy:streamStats.cbSize.QuadPart];
        unsigned long readBytes;
        status = imageStream->Read([dataNSPointer mutableBytes], (unsigned long)[dataNSPointer length], &readBytes);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Copy Stream into MutableData stats failed with status=%x\n", status);
            return false;
        }
    }

    imageDestination.idEncoder = nullptr;
    imageDestination.idStream = nullptr;
    imageDestination.idFactory = nullptr;
    imageDestination.idGifEncoderMetadataQueryWriter = nullptr;
    
    return true;
}
