//******************************************************************************
//
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

static const wchar_t* TAG = L"CGImageDestination"; 
const CFStringRef kCGImageDestinationLossyCompressionQuality = static_cast<CFStringRef>(@"kCGImageDestinationLossyCompressionQuality");
const CFStringRef kCGImageDestinationBackgroundColor = static_cast<CFStringRef>(@"kCGImageDestinationBackgroundColor");

const CFStringRef kUTTypeJPEG = static_cast<const CFStringRef>(@"public.jpeg");
const CFStringRef kUTTypeTIFF = static_cast<const CFStringRef>(@"public.tiff");
const CFStringRef kUTTypeGIF = static_cast<const CFStringRef>(@"com.compuserve.gif");
const CFStringRef kUTTypePNG = static_cast<const CFStringRef>(@"public.png");
const CFStringRef kUTTypeBMP = static_cast<const CFStringRef>(@"com.microsoft.bmp");
const CFStringRef kUTTypeICO = static_cast<const CFStringRef>(@"com.microsoft.ico");
const CFStringRef kUTTypeData = static_cast<const CFStringRef>(@"public.data");

enum imageTypes { typeJPEG,
                  typeTIFF,
                  typeGIF,
                  typePNG,
                  typeBMP,
                  typeICO,
                  typeData,
                  typeError };

@implementation ImageDestination

- (instancetype)initWithData:(CFMutableDataRef)data
                        type:(CFStringRef)type
                      frames:(size_t)frames {
    if (self = [super init]) {
        _maxCount = frames;
        _count = 0;
        _outData = data;

        if (CFStringCompare(type, kUTTypeJPEG, NULL) == kCFCompareEqualTo) {
            _type = typeJPEG;
        } else if (CFStringCompare(type, kUTTypeTIFF, NULL) == kCFCompareEqualTo) {
            _type = typeTIFF;
        } else if (CFStringCompare(type, kUTTypeGIF, NULL) == kCFCompareEqualTo) {
            _type = typeGIF;
        } else if (CFStringCompare(type, kUTTypePNG, NULL) == kCFCompareEqualTo) {
            _type = typePNG;
        } else if (CFStringCompare(type, kUTTypeBMP, NULL) == kCFCompareEqualTo) {
            _type = typeBMP;
        } else if (CFStringCompare(type, kUTTypeICO, NULL) == kCFCompareEqualTo) {
            _type = typeICO;
        } else {
            _type = typeError;
        }

        MULTI_QI imageQueryInterface = {0};
        const GUID IID_IWICImagingFactory = {0xec5ec8a9,0xc395,0x4314,0x9c,0x77,0x54,0xd7,0xa9,0x35,0xff,0x70};
        imageQueryInterface.pIID = &IID_IWICImagingFactory;
        RETURN_NULL_IF_FAILED(
            CoCreateInstanceFromApp(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, nullptr, 1, &imageQueryInterface));
        
        _idFactory = (IWICImagingFactory*)imageQueryInterface.pItf;
        RETURN_NULL_IF_FAILED(_idFactory->CreateStream(&_idStream));

        IStream* dataStream;
        CreateStreamOnHGlobal(NULL, true, &dataStream);
        RETURN_NULL_IF_FAILED(_idStream->InitializeFromIStream(dataStream));
        // Create a stream on the memory to store the image data

        switch (_type) {
            case typeJPEG:
                RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatJpeg, NULL, &_idEncoder));
                break;
            case typeTIFF:
                RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatTiff, NULL, &_idEncoder));
                break;
            case typeGIF:
                RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatGif, NULL, &_idEncoder));
                break;
            case typePNG:
                RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatPng, NULL, &_idEncoder));
                break;
            case typeBMP:
                RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatBmp, NULL, &_idEncoder));
                break;
            case typeICO:
                RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatIco, NULL, &_idEncoder));
                break;
            default:
                return NULL;
        }

        RETURN_NULL_IF_FAILED(_idEncoder->Initialize(_idStream.Get(), WICBitmapEncoderNoCache));
        if (_type == typeGIF) {
            RETURN_NULL_IF_FAILED(_idEncoder->GetMetadataQueryWriter(&_idGifEncoderMetadataQueryWriter));
        }
    }
    
    return self;
}

- (instancetype)initWithUrl:(CFURLRef)url
                       type:(CFStringRef)type
                     frames:(size_t)frames {
    if (self = [super init]) {
        _maxCount = frames;
        _count = 0;
        _outData = NULL;

        if (CFStringCompare(type, kUTTypeJPEG, NULL) == kCFCompareEqualTo) {
            _type = typeJPEG;
        } else if (CFStringCompare(type, kUTTypeTIFF, NULL) == kCFCompareEqualTo) {
            _type = typeTIFF;
        } else if (CFStringCompare(type, kUTTypeGIF, NULL) == kCFCompareEqualTo) {
            _type = typeGIF;
        } else if (CFStringCompare(type, kUTTypePNG, NULL) == kCFCompareEqualTo) {
            _type = typePNG;
        } else if (CFStringCompare(type, kUTTypeBMP, NULL) == kCFCompareEqualTo) {
            _type = typeBMP;
        } else if (CFStringCompare(type, kUTTypeICO, NULL) == kCFCompareEqualTo) {
            _type = typeICO;
        } else {
            _type = typeError;
        }

        MULTI_QI imageQueryInterface = {0};
        const GUID IID_IWICImagingFactory = {0xec5ec8a9,0xc395,0x4314,0x9c,0x77,0x54,0xd7,0xa9,0x35,0xff,0x70};
        imageQueryInterface.pIID = &IID_IWICImagingFactory;
        RETURN_NULL_IF_FAILED(
            CoCreateInstanceFromApp(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, nullptr, 1, &imageQueryInterface));
        
        _idFactory = (IWICImagingFactory*)imageQueryInterface.pItf;
        RETURN_NULL_IF_FAILED(_idFactory->CreateStream(&_idStream));

        NSString* urlNSString = [[(NSURL*)url path] substringFromIndex:1];
        const char* urlString = [urlNSString UTF8String];
        const size_t urlSize = strlen(urlString) + 1;
        wchar_t* wideUrl = new wchar_t[urlSize];
        mbstowcs(wideUrl, urlString, urlSize);
        RETURN_NULL_IF_FAILED(_idStream->InitializeFromFilename(wideUrl, GENERIC_WRITE));

        switch (_type) {
            case typeJPEG:
                RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatJpeg, NULL, &_idEncoder));
                break;
            case typeTIFF:
                RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatTiff, NULL, &_idEncoder));
                break;
            case typeGIF:
                RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatGif, NULL, &_idEncoder));
                break;
            case typePNG:
                RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatPng, NULL, &_idEncoder));
                break;
            case typeBMP:
                RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatBmp, NULL, &_idEncoder));
                break;
            case typeICO:
                RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(GUID_ContainerFormatIco, NULL, &_idEncoder));
                break;
            default:
                return NULL;
        }

        RETURN_NULL_IF_FAILED(_idEncoder->Initialize(_idStream.Get(), WICBitmapEncoderNoCache));
        if (_type == typeGIF) {
            RETURN_NULL_IF_FAILED(_idEncoder->GetMetadataQueryWriter(&_idGifEncoderMetadataQueryWriter));
        }
    }

    return self;
}

@end

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
    if (!data) {
        return nullptr;
    }
    
    return (CGImageDestinationRef)[[ImageDestination alloc] initWithData:data type:type frames:count];
}

/**
 @Status Caveat
 @Notes The current implementation supports common image file formats such as JPEG, GIF, TIFF, BMP, PNG and ICO. 
        Not all formats are supported.
*/
CGImageDestinationRef CGImageDestinationCreateWithURL(CFURLRef url, CFStringRef type, size_t count, CFDictionaryRef options) {
    if (!url) {
        return nullptr;
    }
    
    return (CGImageDestinationRef)[[ImageDestination alloc] initWithUrl:url type:type frames:count];
}

/**
 @Status Caveat
 @Notes The current implementation supports common image file formats such as JPEG, TIFF, BMP, GIF, and PNG. 
        Not all formats are supported.
*/
void CGImageDestinationAddImage(CGImageDestinationRef idst, CGImageRef image, CFDictionaryRef properties) {
    if (!idst) {
        return;
    }

    ImageDestination* imageDestination = (ImageDestination*)idst;
    if (imageDestination.count >= imageDestination.maxCount) {
        return;
    }

    ComPtr<IWICBitmapFrameEncode> imageBitmapFrame;
    IPropertyBag2* pPropertybag = NULL;
    ComPtr<IWICBitmap> inputImage;
    ComPtr<IWICFormatConverter> imageFormatConverter;
    ComPtr<IWICBitmapSource> inputBitmapSource;
    ComPtr<IWICImagingFactory> imageFactory = imageDestination.idFactory;
    ComPtr<IWICStream> imageStream = imageDestination.idStream;
    ComPtr<IWICBitmapEncoder> imageEncoder = imageDestination.idEncoder;
    ComPtr<IWICMetadataQueryWriter> imageMetadataQueryWriter = imageDestination.idGifEncoderMetadataQueryWriter;
    PROPVARIANT writePropValue;

    PropVariantInit(&writePropValue);
    
    HRESULT status = imageEncoder->CreateNewFrame(&imageBitmapFrame, &pPropertybag);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"CreateNewFrame failed with status=%x\n", status);
        return;
    }

    if (properties && CFDictionaryContainsKey(properties, kCGImageDestinationLossyCompressionQuality)) {
        PROPBAG2 option = { 0 };
        option.pstrName = L"ImageQuality";
        VARIANT varValue;    
        VariantInit(&varValue);
        varValue.vt = VT_R4;
        varValue.bVal = [(id)CFDictionaryGetValue(properties, kCGImageDestinationLossyCompressionQuality) doubleValue];
        if (varValue.bVal > 0.0 && varValue.bVal < 1.0) {
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

    NSString *pElemsString = @"NETSCAPE2.0";
    // This is specific to gif, but declaring it here because variables can't be initialized in switches

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
            writePropValue.vt = VT_UI1 | VT_VECTOR;
            writePropValue.caub.cElems = 11;
            writePropValue.caub.pElems = (unsigned char*)[pElemsString UTF8String];
            status = imageMetadataQueryWriter->SetMetadataByName(L"/appext/Application", &writePropValue);
            break;
        case typePNG:
            formatGUID = GUID_WICPixelFormat32bppRGBA;
            break;
        case typeBMP:
            formatGUID = GUID_WICPixelFormat32bppRGBA;
            break;
        case typeICO:
            NSTraceInfo(TAG, @"ICO type not implemented\n");
            return;
        default:
            NSTraceInfo(TAG, @"Unknown type encountered");
            return;
    }
    
    status = imageBitmapFrame->SetPixelFormat(&formatGUID);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"Set Pixel Format failed with status=%x\n", status);
        return;
    }

    CGDataProviderRef provider = CGImageGetDataProvider(image);
    NSData* imageByteData = (id)CGDataProviderCopyData(provider);

    unsigned char* pbBuffer = (unsigned char*)[imageByteData bytes];
    // Turn image into a byte array

    status = imageFactory->CreateBitmapFromMemory(uiWidth,
                                                  uiHeight,
                                                  GUID_WICPixelFormat32bppRGBA,
                                                  uiWidth * 4,
                                                  uiHeight * uiWidth * 4,
                                                  pbBuffer,
                                                  &inputImage);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"CreateBitmapFromMemory failed with status=%x\n", status);
        return;
    }
    // All our input coming in from CGImagesource is in 32bppRGBA

    status = imageFactory->CreateFormatConverter(&imageFormatConverter);
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"CreateFormatConverter failed with status=%x\n", status);
        return;
    }

    if (imageDestination.type == typeGIF) {
        ComPtr<IWICPalette> imagePalette;

        if (imagePalette == NULL) {
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
                                                  imagePalette.Get(), 
                                                  0.f, 
                                                  WICBitmapPaletteTypeFixedWebPalette);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Initialize ImageFormatConverter failed with status=%x\n", status);
            return;
        }
    } else {
        status = imageFormatConverter->Initialize(inputImage.Get(), 
                                                  formatGUID,
                                                  WICBitmapDitherTypeNone, 
                                                  nullptr, 
                                                  0.f, 
                                                  WICBitmapPaletteTypeCustom);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Initialize ImageFormatConverter failed with status=%x\n", status);
            return;
        }
    }

    status = imageFormatConverter->QueryInterface(IID_PPV_ARGS(&inputBitmapSource));

    if (pbBuffer != NULL)
    {
        imageDestination.count++;

        status = imageBitmapFrame->WriteSource(inputBitmapSource.Get(), NULL);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Write Source failed with status=%x\n", status);
            return;
        }
        delete[] pbBuffer;
    }
    else
    {
        NSTraceInfo(TAG, @"Set Pixel Format failed with status=%x\n", E_OUTOFMEMORY);
        return;
    }
    
    status = imageBitmapFrame->Commit();
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"Commit Frame failed with status=%x\n", status);
        return;
    }
    
    return;
}

/**
 @Status Caveat
 @Notes The current implementation supports common image file formats such as JPEG, TIFF, BMP, GIF, and PNG. 
        Not all formats are supported.
*/
void CGImageDestinationAddImageFromSource(CGImageDestinationRef idst, CGImageSourceRef isrc, size_t index, CFDictionaryRef properties) {
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(isrc, index, properties);
    CGImageDestinationAddImage(idst, imageRef, properties);
    // Pulls image reference from the image source using CGImageSource API, then calls AddImage
}

/**
 @Status Caveat
 @Notes Current release supports JPEG, BMP, PNG, GIF, & TIFF image formats only 
*/
CFArrayRef CGImageDestinationCopyTypeIdentifiers() {
    CFIndex formatsSupported = 5;
    CFStringRef typeIdentifiers[] = {kUTTypePNG, kUTTypeJPEG, kUTTypeTIFF, kUTTypeGIF, kUTTypeBMP};
    CFArrayRef imageTypeIdentifiers = CFArrayCreate(nullptr, (const void**)typeIdentifiers, formatsSupported, &kCFTypeArrayCallBacks);
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
    if (imageDestination.count >= imageDestination.maxCount) {
        return;
    }

    ComPtr<IWICImagingFactory> imageFactory = imageDestination.idFactory;
    ComPtr<IWICStream> imageStream = imageDestination.idStream;
    ComPtr<IWICBitmapEncoder> imageEncoder = imageDestination.idEncoder;
    ComPtr<IWICMetadataQueryWriter> imageMetadataQueryWriter = imageDestination.idGifEncoderMetadataQueryWriter;


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
        return false;
    }

    ComPtr<IWICImagingFactory> imageFactory = imageDestination.idFactory;
    ComPtr<IWICStream> imageStream = imageDestination.idStream;
    ComPtr<IWICBitmapEncoder> imageEncoder = imageDestination.idEncoder;

    HRESULT status = imageEncoder->Commit();
    if (!SUCCEEDED(status)) {
        NSTraceInfo(TAG, @"Encoder Commit failed with status=%x\n", status);
        return false;
    }

    if (imageDestination.outData) {
        NSMutableData* dataNSPointer = static_cast<NSMutableData*>(imageDestination.outData);

        LARGE_INTEGER li;
        li.QuadPart = 0;
        status = imageStream->Seek(li, STREAM_SEEK_SET, NULL);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Stream Seek failed with status=%x\n", status);
            return false;
        }
        // Seek to beginning of stream after image data all written

        STATSTG streamStats;
        status = imageStream->Stat(&streamStats, STATFLAG_NONAME);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Fetch stream stats failed with status=%x\n", status);
            return false;
        }
        // Get stream stats in order to determine number of bytes that were written

        [dataNSPointer increaseLengthBy:streamStats.cbSize.QuadPart];
        unsigned long readBytes;
        status = imageStream->Read([dataNSPointer mutableBytes], (unsigned long)[dataNSPointer length], &readBytes);
        // Copy stream into the mutable data
    }
    
    return true;
}
