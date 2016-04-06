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
    if (valueDouble - (int)valueDouble == 0) {
        (*valueLarge).LowPart = (int)valueDouble;
        (*valueLarge).HighPart = 1;
    } else {
        (*valueLarge).LowPart = (int)(valueDouble * 100);
        (*valueLarge).HighPart = 100;
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
    IPropertyBag2* pPropertybag = NULL;
    
    ComPtr<IWICBitmapEncoder> imageEncoder = imageDestination.idEncoder;

    // If there is no Encoder, the destination has either been already finalized or not initialized yet, so return
    if (!imageEncoder) {
        NSTraceInfo(TAG, @"Destination object has no Encoder");
        return;
    }

    HRESULT status = imageEncoder->CreateNewFrame(&imageBitmapFrame, &pPropertybag);
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
            status = pPropertybag->Write(1, &option, &varValue);
            if (!SUCCEEDED(status)) {
                NSTraceInfo(TAG, @"Property Bag Write failed with status=%x\n", status);
                return;
            }
        }
    }

    status = imageBitmapFrame->Initialize(pPropertybag);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"Frame Initialize failed with status=%x\n", status);
        return;
    }

    unsigned int uiWidth = CGImageGetWidth(image);
    unsigned int uiHeight = CGImageGetHeight(image);

    status = imageBitmapFrame->SetSize(uiWidth, uiHeight);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"Set Frame Size failed with status=%x\n", status);
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

    // Setting up writing properties to individual image frame
    ComPtr<IWICMetadataQueryWriter> imageFrameMetadataWriter;
    if (properties) {
        status = imageBitmapFrame->GetMetadataQueryWriter(&imageFrameMetadataWriter);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Get Frame Metadata Writer failed with status=%x\n", status);
            return;
        }
    }
    
    // Image metadata for JPEG images
    if (imageDestination.type == typeJPEG) {
        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyOrientation)) {
            PROPVARIANT value;
            PropVariantInit(&value);
            value.vt = VT_UI2;
            value.iVal = [(id)CFDictionaryGetValue(properties, kCGImagePropertyOrientation) intValue];
            status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/{ushort=274}", &value);
            if (!SUCCEEDED(status)) {
                NSTraceInfo(TAG, @"Set Image Orientation property failed with status=%x\n", status);
                return;
            }
        }

        // GPS information, must be found in GPS Dictionary
        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyGPSDictionary)) {
            CFDictionaryRef gpsDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyGPSDictionary);
        
            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSAltitude)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSAltitude) doubleValue];
                
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=6}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Altitude property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSAltitudeRef)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI1;
                value.bVal = (unsigned char)[(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSAltitudeRef) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=5}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Altitude Reference property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSDateStamp)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSDateStamp) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=29}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Date Stamp property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSDOP)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSDOP) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=11}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS DOP property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSImgDirection)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSImgDirection) doubleValue];
                
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=17}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Image Direction property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSImgDirectionRef)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSImgDirectionRef) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=16}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Image Direction Reference property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLatitude)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_VECTOR | VT_UI8;
                double gpsDegrees = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLatitude) doubleValue];
                double gpsMinutes = (gpsDegrees - (int)gpsDegrees)*60;
                double gpsSeconds = (gpsMinutes - (int)gpsMinutes)*60;
                
                ULARGE_INTEGER gpsValues[3];
                gpsValues[0].LowPart = (int)gpsDegrees;
                gpsValues[0].HighPart = 1;
                gpsValues[1].LowPart = (int)gpsMinutes;
                gpsValues[1].HighPart = 1;
                setHighLowParts(&gpsValues[2], gpsSeconds);

                value.cauh.cElems = 3;
                value.cauh.pElems = gpsValues;
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=2}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Latitude property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLatitudeRef)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLatitudeRef) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=1}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Latitude Reference property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLongitude)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_VECTOR | VT_UI8;
                double gpsDegrees = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLongitude) doubleValue];
                double gpsMinutes = (gpsDegrees - (int)gpsDegrees)*60;
                double gpsSeconds = (gpsMinutes - (int)gpsMinutes)*6000;
                                
                ULARGE_INTEGER gpsValues[3];
                gpsValues[0].LowPart = (int)gpsDegrees;
                gpsValues[0].HighPart = 1;
                gpsValues[1].LowPart = (int)gpsMinutes;
                gpsValues[1].HighPart = 1;
                setHighLowParts(&gpsValues[2], gpsSeconds);

                value.cauh.cElems = 3;
                value.cauh.pElems = gpsValues;
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=4}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Longitude property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLongitudeRef)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLongitudeRef) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=3}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Longitude Reference property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSSpeed)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSSpeed) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=13}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Speed property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSSpeedRef)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSSpeedRef) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=12}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Speed Reference property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSTimeStamp)) {
                // Not handling this property at the moment
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = (VT_VECTOR | VT_UI8);
                NSString* imageGPSVersion = (NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSTimeStamp);
                value.cauh.cElems = 0;
                for (int timeStampIndex = 0; timeStampIndex < value.cauh.cElems; timeStampIndex++) {
                    value.cauh.pElems[timeStampIndex].QuadPart = 0;
                }
                // Metadata name is L"/app1/ifd/gps/{ushort=7}", not writing at the moment
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSTrack)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSTrack) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=15}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Track property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSTrackRef)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSTrackRef) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=14}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Track Reference property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSVersion)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = (VT_VECTOR | VT_UI1);
                NSString* imageGPSVersion = (NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSVersion);
                const char* versionArray = [imageGPSVersion UTF8String];
                value.caub.cElems = 4;
                for (int index = 0; index < value.cauh.cElems; index++) {
                    value.caub.pElems[index] = versionArray[index];
                }
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/gps/{ushort=0}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Version property failed with status=%x\n", status);
                    return;
                }
            }
        }

        // Exif information, must be found in Exif Dictionary
        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyExifDictionary)) {
            CFDictionaryRef exifDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyExifDictionary);
        
            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifExposureTime)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifExposureTime) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=33434}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Exposure Time property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifApertureValue)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifApertureValue) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=37378}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Aperture Value property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifBrightnessValue)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifBrightnessValue) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=37379}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Brightness Value property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifDateTimeDigitized)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifDateTimeDigitized) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=36868}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Date and Time Digitized property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifDateTimeOriginal)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifDateTimeOriginal) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=36867}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Date and Time Original property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifDigitalZoomRatio)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifDigitalZoomRatio) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=41988}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Digital Zoom Ratio property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifExposureMode)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifExposureMode) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=41986}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Exposure Mode property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifExposureProgram)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifExposureProgram) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=34850}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Exposure Program property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifFlash)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifFlash) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=37385}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Flash property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifFNumber)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifFNumber) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=33437}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif F-Number property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifFocalLength)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifFocalLength) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=37386}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Focal Length property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifISOSpeedRatings)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI4;
                value.ulVal = (unsigned long)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifISOSpeedRatings) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=34867}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif ISO Speed Ratings property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifLensMake)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifLensMake) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=42035}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Lens Make property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifLensModel)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifLensModel) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=42036}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Model property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifMakerNote)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_BLOB;
                NSData* exifMakerNote = (NSData*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifMakerNote);
                value.blob.cbSize = [exifMakerNote length];
                value.blob.pBlobData = (unsigned char*)[exifMakerNote bytes];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=37500}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Maker Note property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifMeteringMode)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifMeteringMode) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=37383}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Metering Mode property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifSceneCaptureType)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifSceneCaptureType) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=41990}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Scene Capture Type property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifShutterSpeedValue)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_I8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifShutterSpeedValue) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=37377}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Shutter Speed Value property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifUserComment)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPWSTR;
                NSString* exifUserComment = (NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifUserComment);
                value.pwszVal = (wchar_t*)[exifUserComment cStringUsingEncoding:NSUTF16StringEncoding];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=37510}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif User Comment property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifVersion)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_BLOB;
                NSData* exifVersion = (NSData*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifVersion);
                value.blob.cbSize = [exifVersion length];
                value.blob.pBlobData = (unsigned char*)[exifVersion bytes];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=36864}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Version property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifWhiteBalance)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifWhiteBalance) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/app1/ifd/exif/{ushort=41987}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif White Balance property failed with status=%x\n", status);
                    return;
                }
            }
        }
    }

    if (imageDestination.type == typeGIF) {
        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyGIFDictionary)) {
            CFDictionaryRef gifDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
            
            if (CFDictionaryContainsKey(gifDictionary, kCGImagePropertyGIFDelayTime)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(gifDictionary, kCGImagePropertyGIFDelayTime) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/grctlext/Delay", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Gif Delay Time property failed with status=%x\n", status);
                    return;
                }
            }
        }
    }

    if (imageDestination.type == typeTIFF) {
        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyOrientation)) {
            PROPVARIANT value;
            PropVariantInit(&value);
            value.vt = VT_UI2;
            value.iVal = [(id)CFDictionaryGetValue(properties, kCGImagePropertyOrientation) intValue];
            status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=274}", &value);
            if (!SUCCEEDED(status)) {
                NSTraceInfo(TAG, @"Set Image Orientation property failed with status=%x\n", status);
                return;
            }
        }

        // GPS information, must be found in GPS Dictionary
        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyGPSDictionary)) {
            CFDictionaryRef gpsDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyGPSDictionary);
        
            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSAltitude)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSAltitude) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=6}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Altitude property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSAltitudeRef)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI1;
                value.bVal = (unsigned char)[(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSAltitudeRef) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=5}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Altitude Reference property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSDateStamp)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSDateStamp) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=29}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Date Stamp property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSDOP)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSDOP) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=11}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS DOP property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSImgDirection)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSImgDirection) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=17}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Image Direction property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSImgDirectionRef)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSImgDirectionRef) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=16}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Image Direction Reference property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLatitude)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_VECTOR | VT_UI8;
                double gpsDegrees = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLatitude) doubleValue];
                double gpsMinutes = (gpsDegrees - (int)gpsDegrees)*60;
                double gpsSeconds = (gpsMinutes - (int)gpsMinutes)*6000;
                
                ULARGE_INTEGER gpsValues[3];
                gpsValues[0].LowPart = (int)gpsDegrees;
                gpsValues[0].HighPart = 1;
                gpsValues[1].LowPart = (int)gpsMinutes;
                gpsValues[1].HighPart = 1;
                setHighLowParts(&gpsValues[2], gpsSeconds);

                value.cauh.cElems = 3;
                value.cauh.pElems = gpsValues;
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=2}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Latitude property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLatitudeRef)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLatitudeRef) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=1}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Latitude Reference property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLongitude)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_VECTOR | VT_UI8;
                double gpsDegrees = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLongitude) doubleValue];
                double gpsMinutes = (gpsDegrees - (int)gpsDegrees)*60;
                double gpsSeconds = (gpsMinutes - (int)gpsMinutes)*6000;
                
                ULARGE_INTEGER gpsValues[3];
                gpsValues[0].LowPart = (int)gpsDegrees;
                gpsValues[0].HighPart = 1;
                gpsValues[1].LowPart = (int)gpsMinutes;
                gpsValues[1].HighPart = 1;
                setHighLowParts(&gpsValues[2], gpsSeconds);

                value.cauh.cElems = 3;
                value.cauh.pElems = gpsValues;
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=4}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Longitude property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLongitudeRef)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLongitudeRef) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=3}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Longitude Reference property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSSpeed)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSSpeed) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=13}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Speed property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSSpeedRef)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSSpeedRef) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=12}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Speed Reference property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSTimeStamp)) {
                // Not handling this property at the moment
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = (VT_VECTOR | VT_UI8);
                NSString* imageGPSVersion = (NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSTimeStamp);
                value.cauh.cElems = 0;
                for (int timeStampIndex = 0; timeStampIndex < value.cauh.cElems; timeStampIndex++) {
                    value.cauh.pElems[timeStampIndex].QuadPart = 0;
                }
                // Metadata name is L"/ifd/gps/{ushort=7}", not writing at the moment
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSTrack)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSDOP) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=15}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Track property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSTrackRef)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSTrackRef) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=14}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Track Reference property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSVersion)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = (VT_VECTOR | VT_UI1);
                NSString* imageGPSVersion = (NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSVersion);
                const char* versionArray = [imageGPSVersion UTF8String];
                value.caub.cElems = 4;
                for (int index = 0; index < value.cauh.cElems; index++) {
                    value.caub.pElems[index] = versionArray[index];
                }
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/gps/{ushort=0}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set GPS Version property failed with status=%x\n", status);
                    return;
                }
            }
        }

        // Exif information, must be found in Exif Dictionary
        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyExifDictionary)) {
            CFDictionaryRef exifDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyExifDictionary);
        
            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifExposureTime)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifExposureTime) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=33434}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Exposure Time property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifApertureValue)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifApertureValue) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=37378}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Aperture Value property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifBrightnessValue)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifExposureTime) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=37379}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Brightness Value property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifDateTimeDigitized)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifDateTimeDigitized) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=36868}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Date and Time Digitized property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifDateTimeOriginal)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifDateTimeOriginal) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=36867}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Date and Time Original property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifDigitalZoomRatio)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifDigitalZoomRatio) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=41988}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Digital Zoom Ratio property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifExposureMode)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifExposureMode) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=41986}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Exposure Mode property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifExposureProgram)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifExposureProgram) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=34850}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Exposure Program property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifFlash)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifFlash) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=37385}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Flash property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifFNumber)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifFNumber) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=33437}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif F-Number property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifFocalLength)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifFocalLength) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=37386}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Focal Length property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifISOSpeedRatings)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI4;
                value.ulVal = (unsigned long)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifISOSpeedRatings) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=34867}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif ISO Speed Ratings property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifLensMake)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifLensMake) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=42035}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Lens Make property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifLensModel)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifLensModel) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=42036}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Model property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifMakerNote)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_BLOB;
                NSData* exifMakerNote = (NSData*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifMakerNote);
                value.blob.cbSize = [exifMakerNote length];
                value.blob.pBlobData = (unsigned char*)[exifMakerNote bytes];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=37500}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Maker Note property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifMeteringMode)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifMeteringMode) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=37383}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Metering Mode property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifSceneCaptureType)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifSceneCaptureType) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=41990}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Scene Capture Type property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifShutterSpeedValue)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_I8;
                double doubleOut = [(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifShutterSpeedValue) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=37377}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Shutter Speed Value property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifUserComment)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPWSTR;
                NSString* exifUserComment = (NSString*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifUserComment);
                value.pwszVal = (wchar_t*)[exifUserComment cStringUsingEncoding:NSUTF16StringEncoding];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=37510}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif User Comment property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifVersion)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_BLOB;
                NSData* exifVersion = (NSData*)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifVersion);
                value.blob.cbSize = [exifVersion length];
                value.blob.pBlobData = (unsigned char*)[exifVersion bytes];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=36864}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif Version property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(exifDictionary, kCGImagePropertyExifWhiteBalance)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(exifDictionary, kCGImagePropertyExifWhiteBalance) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/exif/{ushort=41987}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set Exif White Balance property failed with status=%x\n", status);
                    return;
                }
            }
        }

        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyTIFFDictionary)) {
            CFDictionaryRef tiffDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyTIFFDictionary);
            
            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFCompression)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFCompression) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=259}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set TIFF Compression property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFPhotometricInterpretation)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(tiffDictionary,
                                                                        kCGImagePropertyTIFFPhotometricInterpretation) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=262}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set TIFF Photometric Interpretation property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFImageDescription)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFImageDescription) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=270}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set TIFF Image Description property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFMake)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFMake) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=271}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set TIFF Make property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFModel)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFModel) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=272}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set TIFF Model property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFOrientation)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFOrientation) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=274}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set TIFF Orientation property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFXResolution)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFXResolution) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=282}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set TIFF X Resolution property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFYResolution)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI8;
                double doubleOut = [(id)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFYResolution) doubleValue];
                setHighLowParts(&value.uhVal, doubleOut);
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=283}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set TIFF Y Resolution property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFResolutionUnit)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFResolutionUnit) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=296}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set TIFF Resolution Unit property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFSoftware)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFSoftware) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=305}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set TIFF Software property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFDateTime)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFDateTime) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=306}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set TIFF Date and Time property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFArtist)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFArtist) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=315}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set TIFF Artist property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFCopyright)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFCopyright) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=33432}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set TIFF Copyright property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(tiffDictionary, kCGImagePropertyTIFFWhitePoint)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI2;
                value.uiVal = (unsigned short)[(id)CFDictionaryGetValue(tiffDictionary, kCGImagePropertyTIFFWhitePoint) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=41987}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set TIFF White Point property failed with status=%x\n", status);
                    return;
                }
            }
        }
    }

    if (imageDestination.type == typePNG) {
        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyOrientation)) {
            PROPVARIANT value;
            PropVariantInit(&value);
            value.vt = VT_UI2;
            value.iVal = [(id)CFDictionaryGetValue(properties, kCGImagePropertyOrientation) intValue];
            status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=274}", &value);
            if (!SUCCEEDED(status)) {
                NSTraceInfo(TAG, @"Set Image Orientation property failed with status=%x\n", status);
                return;
            }
        }

        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyProfileName)) {
            PROPVARIANT value;
            PropVariantInit(&value);
            value.vt = VT_LPSTR;
            value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(properties, kCGImagePropertyProfileName) UTF8String];
            status = imageFrameMetadataWriter->SetMetadataByName(L"/iCCP/ProfileName", &value);
            if (!SUCCEEDED(status)) {
                NSTraceInfo(TAG, @"Set PNG Property Profile Name property failed with status=%x\n", status);
                return;
            }
        }

        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyPNGDictionary)) {
            CFDictionaryRef pngDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyPNGDictionary);

            if (CFDictionaryContainsKey(pngDictionary, kCGImagePropertyPNGGamma)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI4;
                value.ulVal = (unsigned long)[(id)CFDictionaryGetValue(pngDictionary, kCGImagePropertyPNGGamma) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/gAMA/ImageGamma", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set PNG Gamma property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(pngDictionary, kCGImagePropertyPNGsRGBIntent)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_UI1;
                value.bVal = (unsigned char)[(id)CFDictionaryGetValue(pngDictionary, kCGImagePropertyPNGsRGBIntent) intValue];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/sRGB/RenderingIntent", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set PNG sRGB Intent property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(pngDictionary, kCGImagePropertyPNGChromaticities)) {
                // Not handling this property at the moment
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = (VT_VECTOR | VT_UI1);
                NSString* imageGPSVersion = (NSString*)CFDictionaryGetValue(pngDictionary, kCGImagePropertyPNGChromaticities);
                value.caub.cElems = 0;
                for (int timeStampIndex = 0; timeStampIndex < value.cauh.cElems; timeStampIndex++) {
                    value.caub.pElems[timeStampIndex] = 0;
                }
                // Metadata name is L"/chrominance/TableEntry", not writing at the moment
            }

            if (CFDictionaryContainsKey(pngDictionary, kCGImagePropertyPNGCopyright)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(pngDictionary, kCGImagePropertyPNGCopyright) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=33432}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set PNG Copyright property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(pngDictionary, kCGImagePropertyPNGDescription)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(pngDictionary, kCGImagePropertyPNGDescription) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=270}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set PNG Description property failed with status=%x\n", status);
                    return;
                }
            }

            if (CFDictionaryContainsKey(pngDictionary, kCGImagePropertyPNGSoftware)) {
                PROPVARIANT value;
                PropVariantInit(&value);
                value.vt = VT_LPSTR;
                value.pszVal = (char*)[(NSString*)CFDictionaryGetValue(pngDictionary, kCGImagePropertyPNGSoftware) UTF8String];
                status = imageFrameMetadataWriter->SetMetadataByName(L"/ifd/{ushort=305}", &value);
                if (!SUCCEEDED(status)) {
                    NSTraceInfo(TAG, @"Set PNG Software property failed with status=%x\n", status);
                    return;
                }
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
    status = imageFactory->CreateBitmapFromMemory(uiWidth,
                                                  uiHeight,
                                                  GUID_WICPixelFormat32bppRGBA,
                                                  uiWidth * 4,
                                                  uiHeight * uiWidth * 4,
                                                  (unsigned char*)[imageByteData bytes],
                                                  &inputImage);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"CreateBitmapFromMemory failed with status=%x\n", status);
        return;
    }

    CGDataProviderRelease(provider);
    /*
    ComPtr<IWICFormatConverter> imageFormatConverter;
    status = imageFactory->CreateFormatConverter(&imageFormatConverter);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"CreateFormatConverter failed with status=%x\n", status);
        return;
    }

    ComPtr<IWICPalette> imagePalette = NULL;
    if (imageDestination.type == typeGIF) {
        status = imageFactory->CreatePalette(&imagePalette);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"CreatePalette failed with status=%x\n", status);
            return;
        }
        imagePalette->InitializeFromBitmap((IWICBitmapSource*)inputImage.Get(), 256, TRUE);
    }

    status = imageFormatConverter->Initialize(inputImage.Get(), 
                                              formatGUID,
                                              WICBitmapDitherTypeNone, 
                                              imagePalette ? imagePalette.Get() : NULL, 
                                              0.f, 
                                              WICBitmapPaletteTypeFixedWebPalette);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"Init Image Format Converter failed with status=%x\n", status);
        return;
    }

    ComPtr<IWICBitmapSource> inputBitmapSource;
    status = imageFormatConverter->QueryInterface(IID_PPV_ARGS(&inputBitmapSource));
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"QueryInterface for inputBitmapSource failed with status=%x\n", status);
        return;
    }
    */

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
