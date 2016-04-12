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

const unsigned int minutesPerDegree = 60;
const unsigned int secondsPerMinute = 60;

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

        if (url && [(NSURL*)url path]) { // Make sure that the url path actually resolves to something to avoid causing an exception
            NSString* urlNSString = [[(NSURL*)url path] substringFromIndex:1];
            NSData* urlAsData = [urlNSString dataUsingEncoding:NSUnicodeStringEncoding];
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
            UNIMPLEMENTED_WITH_MSG("Destination as Data Consumer is not handled right now");
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
void setHighLowPartsUnsigned(ULARGE_INTEGER* valueLarge, double valueDouble) {
    if (valueDouble < 0) {
        NSTraceInfo(TAG, @"Tried to pass negative value to set unsigned long!\n");
        return;
    }

    // Check to see if the value has a decimal component. If not, just divide by 1.
    if (valueDouble == (unsigned int)valueDouble) {
        (*valueLarge).LowPart = (unsigned int)valueDouble;
        (*valueLarge).HighPart = 1;
    } else {
        (*valueLarge).LowPart = (unsigned int)(valueDouble * 100);
        (*valueLarge).HighPart = 100;
    }
}

// Signed version of the above
void setHighLowPartsSigned(LARGE_INTEGER* valueLarge, double valueDouble) {
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
                                                          length:wcslen(path)*sizeof(wchar_t)
                                                        encoding:NSUnicodeStringEncoding];
        NSTraceInfo(TAG, @"Set %@ failed with status=%x\n", pathNSString, status);
        [pathNSString release];
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

        if (propertyType == VT_UI1) {
            propertyToWrite.bVal = (unsigned char)[(id)CFDictionaryGetValue(dictionary, key) unsignedCharValue];
        } else if (propertyType == VT_UI2) {
            propertyToWrite.uiVal = (unsigned short)[(id)CFDictionaryGetValue(dictionary, key) unsignedShortValue];
        } else if (propertyType == VT_UI4) {
            propertyToWrite.ulVal = (unsigned long)[(id)CFDictionaryGetValue(dictionary, key) unsignedLongValue];      
        } else if (propertyType == VT_UI8) {
            double doubleOut = [(id)CFDictionaryGetValue(dictionary, key) doubleValue];
            setHighLowPartsUnsigned(&propertyToWrite.uhVal, doubleOut);
        } else if (propertyType == VT_I8) {
            double doubleOut = [(id)CFDictionaryGetValue(dictionary, key) doubleValue];
            setHighLowPartsSigned(&propertyToWrite.hVal, doubleOut);
        } else if (propertyType == VT_LPSTR) {
            propertyToWrite.pszVal = (char*)[(NSString*)CFDictionaryGetValue(dictionary, key) UTF8String];
            PropVariantInit(&propertyToWrite);
        } else if (propertyType == VT_LPWSTR) {
            NSString* wideStringBuffer = (NSString*)CFDictionaryGetValue(dictionary, key);
            propertyToWrite.pwszVal = (wchar_t*)[wideStringBuffer cStringUsingEncoding:NSUnicodeStringEncoding];
        } else if (propertyType == VT_BLOB) {
            NSData* blobData = (NSData*)CFDictionaryGetValue(dictionary, key);
            propertyToWrite.blob.cbSize = [blobData length];
            propertyToWrite.blob.pBlobData = (unsigned char*)[blobData bytes];
        } else {
            NSTraceInfo(TAG, @"Encountered unknown value type when attempting to write property\n");
            return;
        }

        writePropertyToFrame(&propertyToWrite, path, propertyWriter);
    }
}

void writeJPEGProperties(IWICMetadataQueryWriter* propertyWriter, CFDictionaryRef properties, int imageWidth, int imageHeight) {
    PROPVARIANT propertyToWrite;

    // Manually writing constant values to properties when they don't come out of a dictionary
    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI2;
    propertyToWrite.uiVal = 8; // We are always using 8 bits per channel per pixel right now
    writePropertyToFrame(&propertyToWrite, L"/app1/ifd/{ushort=258}", propertyWriter);

    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI2;
    propertyToWrite.uiVal = imageWidth;
    writePropertyToFrame(&propertyToWrite, L"/app1/ifd/{ushort=256}", propertyWriter);

    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI2;
    propertyToWrite.uiVal = imageHeight;
    writePropertyToFrame(&propertyToWrite, L"/app1/ifd/{ushort=257}", propertyWriter);

    // Set Resolutions values to default 72 DPI for X and Y, then overwrite them if they are in Dictionary
    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI8;
    setHighLowPartsUnsigned(&propertyToWrite.uhVal, 72.0);
    writePropertyToFrame(&propertyToWrite, L"/app1/ifd/{ushort=282}", propertyWriter);

    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI8;
    setHighLowPartsUnsigned(&propertyToWrite.uhVal, 72.0);
    writePropertyToFrame(&propertyToWrite, L"/app1/ifd/{ushort=283}", propertyWriter);

    // Resolution Unit: This is set even for JPEG, this should be a shared property between JPEG and TIFF
    // in different locations but Apple only defines it as a TIFF property
    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI2;
    propertyToWrite.uiVal = 2; // 2 = inches, 3 = centimeters
    writePropertyToFrame(&propertyToWrite, L"/app1/ifd/{ushort=296}", propertyWriter);

    setVariantFromDictionary(properties,
                             kCGImagePropertyDPIWidth,
                             VT_UI8,
                             L"/app1/ifd/{ushort=282}",
                             propertyWriter);

    setVariantFromDictionary(properties,
                             kCGImagePropertyDPIHeight,
                             VT_UI8,
                             L"/app1/ifd/{ushort=283}",
                             propertyWriter);

    setVariantFromDictionary(properties,
                             kCGImagePropertyTIFFResolutionUnit,
                             VT_UI2,
                             L"/app1/ifd/{ushort=296}",
                             propertyWriter);

    setVariantFromDictionary(properties,
                             kCGImagePropertyOrientation,
                             VT_UI2,
                             L"/app1/ifd/{ushort=274}",
                             propertyWriter);
            
    // GPS information, must be found in GPS Dictionary
    if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyGPSDictionary)) {
        CFDictionaryRef gpsDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyGPSDictionary);
        
        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSAltitude,
                                 VT_UI8,
                                 L"/app1/ifd/gps/{ushort=6}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSAltitudeRef,
                                 VT_UI1,
                                 L"/app1/ifd/gps/{ushort=5}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSDateStamp,
                                 VT_LPSTR,
                                 L"/app1/ifd/gps/{ushort=29}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSDOP,
                                 VT_UI8,
                                 L"/app1/ifd/gps/{ushort=11}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSImgDirection,
                                 VT_UI8,
                                 L"/app1/ifd/gps/{ushort=17}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSImgDirectionRef,
                                 VT_LPSTR,
                                 L"/app1/ifd/gps/{ushort=16}",
                                 propertyWriter);
            
        // Manually writing VT_VECTOR properties because they are all parsed their own way
        if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLatitude)) {
            PropVariantInit(&propertyToWrite);
            propertyToWrite.vt = VT_VECTOR | VT_UI8;
            double gpsDegrees = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLatitude) doubleValue];
            double gpsMinutes = (gpsDegrees - (int)gpsDegrees)*minutesPerDegree;
            double gpsSeconds = (gpsMinutes - (int)gpsMinutes)*secondsPerMinute;
                
            ULARGE_INTEGER gpsValues[3];
            gpsValues[0].LowPart = (int)gpsDegrees;
            gpsValues[0].HighPart = 1;
            gpsValues[1].LowPart = (int)gpsMinutes;
            gpsValues[1].HighPart = 1;
            setHighLowPartsUnsigned(&gpsValues[2], gpsSeconds);

            propertyToWrite.cauh.cElems = 3;
            propertyToWrite.cauh.pElems = gpsValues;
            writePropertyToFrame(&propertyToWrite, L"/app1/ifd/gps/{ushort=2}", propertyWriter);
            propertyToWrite.cauh.pElems = NULL;
        }

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSLatitudeRef,
                                 VT_LPSTR,
                                 L"/app1/ifd/gps/{ushort=1}",
                                 propertyWriter);

        if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLongitude)) {
            PropVariantInit(&propertyToWrite);
            propertyToWrite.vt = VT_VECTOR | VT_UI8;
            double gpsDegrees = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLongitude) doubleValue];
            double gpsMinutes = (gpsDegrees - (int)gpsDegrees)*minutesPerDegree;
            double gpsSeconds = (gpsMinutes - (int)gpsMinutes)*secondsPerMinute;
                                
            ULARGE_INTEGER gpsValues[3];
            gpsValues[0].LowPart = (int)gpsDegrees;
            gpsValues[0].HighPart = 1;
            gpsValues[1].LowPart = (int)gpsMinutes;
            gpsValues[1].HighPart = 1;
            setHighLowPartsUnsigned(&gpsValues[2], gpsSeconds);

            propertyToWrite.cauh.cElems = 3;
            propertyToWrite.cauh.pElems = gpsValues;
            writePropertyToFrame(&propertyToWrite, L"/app1/ifd/gps/{ushort=4}", propertyWriter);
            propertyToWrite.cauh.pElems = NULL;
        }

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSLongitudeRef,
                                 VT_LPSTR,
                                 L"/app1/ifd/gps/{ushort=3}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSSpeed,
                                 VT_UI8,
                                 L"/app1/ifd/gps/{ushort=13}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSSpeedRef,
                                 VT_LPSTR,
                                 L"/app1/ifd/gps/{ushort=12}",
                                 propertyWriter);

        if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSTimeStamp)) {
            PropVariantInit(&propertyToWrite);
            propertyToWrite.vt = VT_VECTOR | VT_UI8;
            NSString* imageGPSTimeStamp = (NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSTimeStamp);
            NSArray* splitTimeStamp = [imageGPSTimeStamp componentsSeparatedByString:@":"];
            if ([splitTimeStamp count] == 3) { // Expect 3 elements for hours, minutes, seconds, otherwise do nothing
                ULARGE_INTEGER gpsValues[3];
                gpsValues[0].LowPart = (int)[[splitTimeStamp objectAtIndex:0] intValue];
                gpsValues[0].HighPart = 1;
                gpsValues[1].LowPart = (int)[[splitTimeStamp objectAtIndex:1] intValue];
                gpsValues[1].HighPart = 1;
                setHighLowPartsUnsigned(&gpsValues[2], [[splitTimeStamp objectAtIndex:2] doubleValue]);

                propertyToWrite.cauh.cElems = 3;
                propertyToWrite.cauh.pElems = gpsValues;
                writePropertyToFrame(&propertyToWrite, L"/app1/ifd/gps/{ushort=7}", propertyWriter);
                propertyToWrite.cauh.pElems = NULL;
            }
        }

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSTrack,
                                 VT_UI8,
                                 L"/app1/ifd/gps/{ushort=15}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSTrackRef,
                                 VT_LPSTR,
                                 L"/app1/ifd/gps/{ushort=14}",
                                 propertyWriter);

        if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSVersion)) {
            PropVariantInit(&propertyToWrite);
            propertyToWrite.vt = VT_VECTOR | VT_UI1;
            NSString* imageGPSVersion = (NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSVersion);
            const char* versionArray = [imageGPSVersion UTF8String];
            propertyToWrite.caub.cElems = 4;
            for (int index = 0; index < propertyToWrite.cauh.cElems; index++) {
                propertyToWrite.caub.pElems[index] = versionArray[index];
            }
            propertyToWrite.caub.pElems = NULL;
        }
    }

    // The Exif image width and height are part of the Exif dictionary which shouldn't be written if no Exif properties
    // are specified. However, for JPEG only (not Tiff), iOS writes these properties no matter what
    CFDictionaryRef exifDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyExifDictionary);

    // Exif X and Y dimensions, always written
    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI2;
    propertyToWrite.uiVal = imageWidth;
    writePropertyToFrame(&propertyToWrite, L"/app1/ifd/exif/{ushort=40962}", propertyWriter);

    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI2;
    propertyToWrite.uiVal = imageHeight;
    writePropertyToFrame(&propertyToWrite, L"/app1/ifd/exif/{ushort=40963}", propertyWriter);

    // Exif information, must be found in Exif Dictionary
    if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyExifDictionary)) {
        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifExposureTime,
                                 VT_UI8,
                                 L"/app1/ifd/exif/{ushort=33434}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifApertureValue,
                                 VT_UI8,
                                 L"/app1/ifd/exif/{ushort=37378}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifBrightnessValue,
                                 VT_UI8,
                                 L"/app1/ifd/exif/{ushort=37379}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifDateTimeDigitized,
                                 VT_LPSTR,
                                 L"/app1/ifd/exif/{ushort=36868}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifDateTimeOriginal,
                                 VT_LPSTR,
                                 L"/app1/ifd/exif/{ushort=36867}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifDigitalZoomRatio,
                                 VT_UI8,
                                 L"/app1/ifd/exif/{ushort=41988}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifExposureMode,
                                 VT_UI2,
                                 L"/app1/ifd/exif/{ushort=41986}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifExposureProgram,
                                 VT_UI2,
                                 L"/app1/ifd/exif/{ushort=34850}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifFlash,
                                 VT_UI2,
                                 L"/app1/ifd/exif/{ushort=37385}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifFNumber,
                                 VT_UI8,
                                 L"/app1/ifd/exif/{ushort=33437}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifFocalLength,
                                 VT_UI8,
                                 L"/app1/ifd/exif/{ushort=37386}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifISOSpeedRatings,
                                 VT_UI4,
                                 L"/app1/ifd/exif/{ushort=34867}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifLensMake,
                                 VT_LPSTR,
                                 L"/app1/ifd/exif/{ushort=42035}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifLensModel,
                                 VT_LPSTR,
                                 L"/app1/ifd/exif/{ushort=42036}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifMakerNote,
                                 VT_BLOB,
                                 L"/app1/ifd/exif/{ushort=37500}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifMeteringMode,
                                 VT_UI2,
                                 L"/app1/ifd/exif/{ushort=37383}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifSceneCaptureType,
                                 VT_UI2,
                                 L"/app1/ifd/exif/{ushort=41990}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifShutterSpeedValue,
                                 VT_I8,
                                 L"/app1/ifd/exif/{ushort=37377}",
                                 propertyWriter);

        // Apple does not seem to handle non-ASCII characters correctly for user comments. This is not replicated here.
        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifUserComment,
                                 VT_LPWSTR,
                                 L"/app1/ifd/exif/{ushort=37510}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifVersion,
                                 VT_BLOB,
                                 L"/app1/ifd/exif/{ushort=36864}",
                                 propertyWriter);
            
        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifWhiteBalance,
                                 VT_UI2,
                                 L"/app1/ifd/exif/{ushort=41987}",
                                 propertyWriter);
    }
}

void writeGIFProperties(IWICMetadataQueryWriter* propertyWriter, CFDictionaryRef properties, int imageWidth, int imageHeight) {
    PROPVARIANT propertyToWrite;

    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI2;
    propertyToWrite.uiVal = imageWidth;
    writePropertyToFrame(&propertyToWrite, L"/imgdesc/Width", propertyWriter);

    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI2;
    propertyToWrite.uiVal = imageHeight;
    writePropertyToFrame(&propertyToWrite, L"/imgdesc/Height", propertyWriter);

    if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyGIFDictionary)) {
        CFDictionaryRef gifDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
            
        setVariantFromDictionary(gifDictionary,
                                 kCGImagePropertyGIFDelayTime,
                                 VT_UI2,
                                 L"/grctlext/Delay",
                                 propertyWriter);
    }
}

void writeTIFFProperties(IWICMetadataQueryWriter* propertyWriter, CFDictionaryRef properties, int imageWidth, int imageHeight) {
    PROPVARIANT propertyToWrite;

    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI2;
    propertyToWrite.uiVal = 8; // We are always using 8 bits per channel per pixel right now
    writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=258}", propertyWriter);

    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI2;
    propertyToWrite.uiVal = imageWidth;
    writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=256}", propertyWriter);

    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI2;
    propertyToWrite.uiVal = imageHeight;
    writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=257}", propertyWriter);

    // TIFF Compression, will get overwritten by property dictionary if needed
    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI2;
    propertyToWrite.uiVal = 1; // No compression
    writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=259}", propertyWriter);

    // Photometric Interpretation, will get overwritten by property dictionary if needed
    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI2;
    propertyToWrite.uiVal = 2; // RGB
    writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=262}", propertyWriter);

    // Set Resolutions values to default 72 DPI for X and Y, then overwrite them if they are in Dictionary
    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI8;
    setHighLowPartsUnsigned(&propertyToWrite.uhVal, 72.0);
    writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=282}", propertyWriter);

    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI8;
    setHighLowPartsUnsigned(&propertyToWrite.uhVal, 72.0);
    writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=283}", propertyWriter);

    PropVariantInit(&propertyToWrite);
    propertyToWrite.vt = VT_UI2;
    propertyToWrite.uiVal = 2; // 2 = inches, 3 = centimeters
    writePropertyToFrame(&propertyToWrite, L"/ifd/{ushort=296}", propertyWriter);

    setVariantFromDictionary(properties,
                             kCGImagePropertyDPIWidth,
                             VT_UI8,
                             L"/ifd/{ushort=282}",
                             propertyWriter);

    setVariantFromDictionary(properties,
                             kCGImagePropertyDPIHeight,
                             VT_UI8,
                             L"/ifd/{ushort=283}",
                             propertyWriter);

    setVariantFromDictionary(properties,
                             kCGImagePropertyTIFFResolutionUnit,
                             VT_UI2,
                             L"/ifd/{ushort=296}",
                             propertyWriter);

    setVariantFromDictionary(properties,
                             kCGImagePropertyOrientation,
                             VT_UI2,
                             L"/ifd/{ushort=274}",
                             propertyWriter);

    // GPS information, must be found in GPS Dictionary
    if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyGPSDictionary)) {
        CFDictionaryRef gpsDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyGPSDictionary);
        
        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSAltitude,
                                 VT_UI8,
                                 L"/ifd/gps/{ushort=6}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSAltitudeRef,
                                 VT_UI1,
                                 L"/app1/ifd/gps/{ushort=5}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSDateStamp,
                                 VT_LPSTR,
                                 L"/ifd/gps/{ushort=29}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSDOP,
                                 VT_UI8,
                                 L"/ifd/gps/{ushort=11}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSImgDirection,
                                 VT_UI8,
                                 L"/ifd/gps/{ushort=17}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSImgDirectionRef,
                                 VT_LPSTR,
                                 L"/ifd/gps/{ushort=16}",
                                 propertyWriter);

        if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLatitude)) {
            PropVariantInit(&propertyToWrite);
            propertyToWrite.vt = VT_VECTOR | VT_UI8;
            double gpsDegrees = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLatitude) doubleValue];
            double gpsMinutes = (gpsDegrees - (int)gpsDegrees)*minutesPerDegree;
            double gpsSeconds = (gpsMinutes - (int)gpsMinutes)*secondsPerMinute;
                
            ULARGE_INTEGER gpsValues[3];
            gpsValues[0].LowPart = (int)gpsDegrees;
            gpsValues[0].HighPart = 1;
            gpsValues[1].LowPart = (int)gpsMinutes;
            gpsValues[1].HighPart = 1;
            setHighLowPartsUnsigned(&gpsValues[2], gpsSeconds);

            propertyToWrite.cauh.cElems = 3;
            propertyToWrite.cauh.pElems = gpsValues;
            writePropertyToFrame(&propertyToWrite, L"/ifd/gps/{ushort=2}", propertyWriter);
            propertyToWrite.cauh.pElems = NULL;
        }

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSLatitudeRef,
                                 VT_LPSTR,
                                 L"/ifd/gps/{ushort=1}",
                                 propertyWriter);

        if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSLongitude)) {
            PropVariantInit(&propertyToWrite);
            propertyToWrite.vt = VT_VECTOR | VT_UI8;
            double gpsDegrees = [(id)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSLongitude) doubleValue];
            double gpsMinutes = (gpsDegrees - (int)gpsDegrees)*minutesPerDegree;
            double gpsSeconds = (gpsMinutes - (int)gpsMinutes)*secondsPerMinute;
                
            ULARGE_INTEGER gpsValues[3];
            gpsValues[0].LowPart = (int)gpsDegrees;
            gpsValues[0].HighPart = 1;
            gpsValues[1].LowPart = (int)gpsMinutes;
            gpsValues[1].HighPart = 1;
            setHighLowPartsUnsigned(&gpsValues[2], gpsSeconds);

            propertyToWrite.cauh.cElems = 3;
            propertyToWrite.cauh.pElems = gpsValues;
            writePropertyToFrame(&propertyToWrite, L"/ifd/gps/{ushort=4}", propertyWriter);
            propertyToWrite.cauh.pElems = NULL;
        }

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSLongitudeRef,
                                 VT_LPSTR,
                                 L"/ifd/gps/{ushort=3}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSSpeed,
                                 VT_UI8,
                                 L"/ifd/gps/{ushort=13}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSSpeedRef,
                                 VT_LPSTR,
                                 L"/ifd/gps/{ushort=12}",
                                 propertyWriter);

        if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSTimeStamp)) {
            PropVariantInit(&propertyToWrite);
            propertyToWrite.vt = VT_VECTOR | VT_UI8;
            NSString* imageGPSTimeStamp = (NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSTimeStamp);
            NSArray* splitTimeStamp = [imageGPSTimeStamp componentsSeparatedByString:@":"];
            if ([splitTimeStamp count] == 3) { // Expect 3 elements for hours, minutes, seconds, otherwise do nothing
                ULARGE_INTEGER gpsValues[3];
                gpsValues[0].LowPart = (int)[[splitTimeStamp objectAtIndex:0] intValue];
                gpsValues[0].HighPart = 1;
                gpsValues[1].LowPart = (int)[[splitTimeStamp objectAtIndex:1] intValue];
                gpsValues[1].HighPart = 1;
                setHighLowPartsUnsigned(&gpsValues[2], [[splitTimeStamp objectAtIndex:2] doubleValue]);

                propertyToWrite.cauh.cElems = 3;
                propertyToWrite.cauh.pElems = gpsValues;
                writePropertyToFrame(&propertyToWrite, L"/ifd/gps/{ushort=7}", propertyWriter);
                propertyToWrite.cauh.pElems = NULL;
            }
        }

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSTrack,
                                 VT_UI8,
                                 L"/ifd/gps/{ushort=15}",
                                 propertyWriter);

        setVariantFromDictionary(gpsDictionary,
                                 kCGImagePropertyGPSTrackRef,
                                 VT_LPSTR,
                                 L"/ifd/gps/{ushort=14}",
                                 propertyWriter);

        if (CFDictionaryContainsKey(gpsDictionary, kCGImagePropertyGPSVersion)) {
            PropVariantInit(&propertyToWrite);
            propertyToWrite.vt = VT_VECTOR | VT_UI1;
            NSString* imageGPSVersion = (NSString*)CFDictionaryGetValue(gpsDictionary, kCGImagePropertyGPSVersion);
            const char* versionArray = [imageGPSVersion UTF8String];
            propertyToWrite.caub.cElems = 4;
            for (int index = 0; index < propertyToWrite.cauh.cElems; index++) {
                propertyToWrite.caub.pElems[index] = versionArray[index];
            }
            writePropertyToFrame(&propertyToWrite, L"/ifd/gps/{ushort=0}", propertyWriter);
            propertyToWrite.caub.pElems = NULL;
        }
    }

    // Exif information, must be found in Exif Dictionary
    if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyExifDictionary)) {
        CFDictionaryRef exifDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyExifDictionary);
        
        // Exif X and Y dimensions, always written when other Exif information is present
        PropVariantInit(&propertyToWrite);
        propertyToWrite.vt = VT_UI2;
        propertyToWrite.uiVal = imageWidth;
        writePropertyToFrame(&propertyToWrite, L"/ifd/exif/{ushort=40962}", propertyWriter);

        PropVariantInit(&propertyToWrite);
        propertyToWrite.vt = VT_UI2;
        propertyToWrite.uiVal = imageHeight;
        writePropertyToFrame(&propertyToWrite, L"/ifd/exif/{ushort=40963}", propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifExposureTime,
                                 VT_UI8,
                                 L"/ifd/exif/{ushort=33434}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifApertureValue,
                                 VT_UI8,
                                 L"/ifd/exif/{ushort=37378}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifBrightnessValue,
                                 VT_UI8,
                                 L"/ifd/exif/{ushort=37379}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifDateTimeDigitized,
                                 VT_LPSTR,
                                 L"/ifd/exif/{ushort=36868}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifDateTimeOriginal,
                                 VT_LPSTR,
                                 L"/ifd/exif/{ushort=36867}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifDigitalZoomRatio,
                                 VT_UI8,
                                 L"/ifd/exif/{ushort=41988}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifExposureMode,
                                 VT_UI2,
                                 L"/ifd/exif/{ushort=41986}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifExposureProgram,
                                 VT_UI2,
                                 L"/ifd/exif/{ushort=34850}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifFlash,
                                 VT_UI2,
                                 L"/ifd/exif/{ushort=37385}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifFNumber,
                                 VT_UI8,
                                 L"/ifd/exif/{ushort=33437}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifFocalLength,
                                 VT_UI8,
                                 L"/ifd/exif/{ushort=37386}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifISOSpeedRatings,
                                 VT_UI4,
                                 L"/ifd/exif/{ushort=34867}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifLensMake,
                                 VT_LPSTR,
                                 L"/ifd/exif/{ushort=42035}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifLensModel,
                                 VT_LPSTR,
                                 L"/ifd/exif/{ushort=42036}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifMakerNote,
                                 VT_BLOB,
                                 L"/ifd/exif/{ushort=37500}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifMeteringMode,
                                 VT_UI2,
                                 L"/ifd/exif/{ushort=37383}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifSceneCaptureType,
                                 VT_UI2,
                                 L"/ifd/exif/{ushort=41990}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifShutterSpeedValue,
                                 VT_I8,
                                 L"/ifd/exif/{ushort=37377}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifUserComment,
                                 VT_LPWSTR,
                                 L"/ifd/exif/{ushort=37510}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifVersion,
                                 VT_BLOB,
                                 L"/ifd/exif/{ushort=36864}",
                                 propertyWriter);

        setVariantFromDictionary(exifDictionary,
                                 kCGImagePropertyExifWhiteBalance,
                                 VT_UI2,
                                 L"/ifd/exif/{ushort=41987}",
                                 propertyWriter);
    }

    if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyTIFFDictionary)) {
        CFDictionaryRef tiffDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyTIFFDictionary);
            
        setVariantFromDictionary(tiffDictionary,
                                 kCGImagePropertyTIFFCompression,
                                 VT_UI2,
                                 L"/ifd/{ushort=259}",
                                 propertyWriter);

        setVariantFromDictionary(tiffDictionary,
                                 kCGImagePropertyTIFFPhotometricInterpretation,
                                 VT_UI2,
                                 L"/ifd/{ushort=262}",
                                 propertyWriter);

        setVariantFromDictionary(tiffDictionary,
                                 kCGImagePropertyTIFFImageDescription,
                                 VT_LPSTR,
                                 L"/ifd/{ushort=270}",
                                 propertyWriter);

        setVariantFromDictionary(tiffDictionary,
                                 kCGImagePropertyTIFFMake,
                                 VT_LPSTR,
                                 L"/ifd/{ushort=271}",
                                 propertyWriter);

        setVariantFromDictionary(tiffDictionary,
                                 kCGImagePropertyTIFFModel,
                                 VT_LPSTR,
                                 L"/ifd/{ushort=272}",
                                 propertyWriter);

        setVariantFromDictionary(tiffDictionary,
                                 kCGImagePropertyTIFFOrientation,
                                 VT_UI2,
                                 L"/ifd/{ushort=274}",
                                 propertyWriter);

        setVariantFromDictionary(tiffDictionary,
                                 kCGImagePropertyTIFFXResolution,
                                 VT_UI8,
                                 L"/ifd/{ushort=282}",
                                 propertyWriter);

        setVariantFromDictionary(tiffDictionary,
                                 kCGImagePropertyTIFFYResolution,
                                 VT_UI8,
                                 L"/ifd/{ushort=283}",
                                 propertyWriter);

        setVariantFromDictionary(tiffDictionary,
                                 kCGImagePropertyTIFFResolutionUnit,
                                 VT_UI2,
                                 L"/ifd/{ushort=296}",
                                 propertyWriter);

        setVariantFromDictionary(tiffDictionary,
                                 kCGImagePropertyTIFFSoftware,
                                 VT_LPSTR,
                                 L"/ifd/{ushort=305}",
                                 propertyWriter);

        setVariantFromDictionary(tiffDictionary,
                                 kCGImagePropertyTIFFDateTime,
                                 VT_LPSTR,
                                 L"/ifd/{ushort=306}",
                                 propertyWriter);

        setVariantFromDictionary(tiffDictionary,
                                 kCGImagePropertyTIFFArtist,
                                 VT_LPSTR,
                                 L"/ifd/{ushort=315}",
                                 propertyWriter);

        setVariantFromDictionary(tiffDictionary,
                                 kCGImagePropertyTIFFCopyright,
                                 VT_LPSTR,
                                 L"/ifd/{ushort=33432}",
                                 propertyWriter);

        setVariantFromDictionary(tiffDictionary,
                                 kCGImagePropertyTIFFWhitePoint,
                                 VT_UI2,
                                 L"/ifd/{ushort=41987}",
                                 propertyWriter);
    }
}

void writePNGProperties(IWICMetadataQueryWriter* propertyWriter, CFDictionaryRef properties, int imageWidth, int imageHeight) {
    PROPVARIANT propertyToWrite;

    // General note for PNG: Apple writes a lot of properties for PNG that are not defined in the w3 PNG specifications.
    // This includes the entire GPS dictionary, Exif information, and DPI information. Apple APIs will read these back
    // properly, but external metadata readers don't seem to pick up on the information and the location of this metadata is
    // not well specified. This behavior is not replicated here.

    setVariantFromDictionary(properties,
                             kCGImagePropertyProfileName,
                             VT_LPSTR,
                             L"/iCCP/ProfileName",
                             propertyWriter);

    if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyPNGDictionary)) {
        CFDictionaryRef pngDictionary = (CFDictionaryRef)CFDictionaryGetValue(properties, kCGImagePropertyPNGDictionary);

        setVariantFromDictionary(pngDictionary,
                                 kCGImagePropertyPNGGamma,
                                 VT_UI4,
                                 L"/gAMA/ImageGamma",
                                 propertyWriter);

        setVariantFromDictionary(pngDictionary,
                                 kCGImagePropertyPNGsRGBIntent,
                                 VT_UI1,
                                 L"/sRGB/RenderingIntent",
                                 propertyWriter);

        if (CFDictionaryContainsKey(pngDictionary, kCGImagePropertyPNGChromaticities)) {
            // Not handling this property at the moment
            PropVariantInit(&propertyToWrite);
            propertyToWrite.vt = VT_VECTOR | VT_UI1;
            NSString* pngChromaticities = (NSString*)CFDictionaryGetValue(pngDictionary, kCGImagePropertyPNGChromaticities);
            propertyToWrite.caub.cElems = 0;
            for (int timeStampIndex = 0; timeStampIndex < propertyToWrite.cauh.cElems; timeStampIndex++) {
                propertyToWrite.caub.pElems[timeStampIndex] = 0;
            }
            UNIMPLEMENTED_WITH_MSG("PNG Chromaticities are not supported right now.");
            // Metadata name is L"/chrominance/TableEntry", not writing at the moment
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
        Not all image properties for all images are supported, and Apple writes many PNG properties that are not actually
        part of the PNG specification to image metadata, which is not reproduced.
*/
void CGImageDestinationAddImage(CGImageDestinationRef idst, CGImageRef image, CFDictionaryRef properties) {
    if (!idst || !image) {
        return;
    }

    ImageDestination* imageDestination = (ImageDestination*)idst;
    if (imageDestination.count >= imageDestination.maxCount) {
        NSTraceInfo(TAG, @"Max number of images in destination exceeded\n");
        return;
    }

    ComPtr<IWICBitmapFrameEncode> imageBitmapFrame;
    IPropertyBag2* propertyBag = NULL;
    
    ComPtr<IWICBitmapEncoder> imageEncoder = imageDestination.idEncoder;

    // If there is no Encoder, the destination has either been already finalized or not initialized yet, so return
    if (!imageEncoder) {
        NSTraceInfo(TAG, @"Destination object has no Encoder\n");
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
        std::wstring quality(L"ImageQuality");
        option.pstrName = (wchar_t*)quality.c_str();
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

    // Setting up writing properties to individual image frame, bitmaps cannot have metadata
    ComPtr<IWICMetadataQueryWriter> imageFrameMetadataWriter;
    if (imageDestination.type != typeBMP) {
        status = imageBitmapFrame->GetMetadataQueryWriter(&imageFrameMetadataWriter);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Get Frame Metadata Writer failed with status=%x\n", status);
            return;
        }
    }

    IWICMetadataQueryWriter* propertyWriter = imageFrameMetadataWriter.Get();

    // Set the pixel format based on file format and write necessary metadata
    WICPixelFormatGUID formatGUID;
    switch (imageDestination.type) {
        case typeJPEG:
            formatGUID = GUID_WICPixelFormat24bppBGR;
            writeJPEGProperties(propertyWriter, properties, imageWidth, imageHeight);
            break;
        case typeTIFF:
            formatGUID = GUID_WICPixelFormat32bppRGBA;
            writeTIFFProperties(propertyWriter, properties, imageWidth, imageHeight);
            break;
        case typeGIF:
            formatGUID = GUID_WICPixelFormat8bppIndexed;
            writeGIFProperties(propertyWriter, properties, imageWidth, imageHeight);
            break;
        case typePNG:
            formatGUID = GUID_WICPixelFormat32bppRGBA;
            writePNGProperties(propertyWriter, properties, imageWidth, imageHeight);
            break;
        case typeBMP:
            formatGUID = GUID_WICPixelFormat32bppRGBA;
            break;
        default:
            NSTraceInfo(TAG, @"Unknown type encountered\n");
            return;
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
    [imageByteData release];
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
    if (!idst || !isrc) {
        return;
    }
    
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
        NSTraceInfo(TAG, @"CGImageDestinationFinalize did not find an Encoder\n");
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
        PROPVARIANT propertyToWrite;

        PropVariantInit(&propertyToWrite);
        propertyToWrite.vt = VT_UI1 | VT_VECTOR;
        propertyToWrite.caub.cElems = 11;
        propertyToWrite.caub.pElems = (unsigned char*)[@"NETSCAPE2.0" UTF8String];
        writePropertyToFrame(&propertyToWrite, L"/appext/Application", imageMetadataQueryWriter.Get());

        propertyToWrite.caub.cElems = 5;
        propertyToWrite.caub.pElems =
            (unsigned char*)[[NSString stringWithFormat:@"%c%c%c%c%c", 3, 1, loopCountLSB, loopCountMSB, 0] UTF8String];
        writePropertyToFrame(&propertyToWrite, L"/appext/Data", imageMetadataQueryWriter.Get());
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
        NSTraceInfo(TAG, @"CGImageDestinationFinalize image destination does not have enough images\n");
        return false;
    }

    ComPtr<IWICBitmapEncoder> imageEncoder = imageDestination.idEncoder;
    ComPtr<IWICStream> imageStream = imageDestination.idStream;

    // If Encoder or Stream are missing, the destination has either been already finalized or not initialized yet, so return
    if (!imageEncoder || !imageStream) {
        NSTraceInfo(TAG, @"CGImageDestinationFinalize did not find an Encoder or Stream\n");
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