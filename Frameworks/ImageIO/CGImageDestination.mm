//******************************************************************************
//
// Copyright (c) 2016, Intel Corporation
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

enum imageTypes { typeJPEG,
                  typeTIFF,
                  typeGIF,
                  typePNG,
                  typeBMP,
                  typeUnknown };

@implementation ImageDestination

- (REFGUID)initSharedReturnGUID:(CFStringRef)type
                         frames:(size_t)frames {
    self.maxCount = frames;

    if (CFStringCompare(type, kUTTypeJPEG, NULL) == kCFCompareEqualTo) {
        self.type = typeJPEG;
        return GUID_ContainerFormatJpeg;
    } else if (CFStringCompare(type, kUTTypeTIFF, NULL) == kCFCompareEqualTo) {
        self.type = typeTIFF;
        return GUID_ContainerFormatTiff;
    } else if (CFStringCompare(type, kUTTypeGIF, NULL) == kCFCompareEqualTo) {
        self.type = typeGIF;
        return GUID_ContainerFormatGif;
    } else if (CFStringCompare(type, kUTTypePNG, NULL) == kCFCompareEqualTo) {
        self.type = typePNG;
        return GUID_ContainerFormatPng;
    } else if (CFStringCompare(type, kUTTypeBMP, NULL) == kCFCompareEqualTo) {
        self.type = typeBMP;
        return GUID_ContainerFormatBmp;
    } else {
        self.type = typeUnknown;
        return { 0, 0, 0, { 0, 0, 0, 0, 0, 0, 0, 0 } }; // Empty GUID
    }
}

- (instancetype)initWithData:(CFMutableDataRef)data
                        type:(CFStringRef)type
                      frames:(size_t)frames {
    if (self = [super init]) {
        REFGUID containerType = [self initSharedReturnGUID:type frames:frames];
        _outData = data;

        MULTI_QI imageQueryInterface = {0};
        static const GUID IID_IWICImagingFactory = {0xec5ec8a9,0xc395,0x4314,0x9c,0x77,0x54,0xd7,0xa9,0x35,0xff,0x70};
        imageQueryInterface.pIID = &IID_IWICImagingFactory;
        RETURN_NULL_IF_FAILED(
            CoCreateInstanceFromApp(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, nullptr, 1, &imageQueryInterface));
        
        _idFactory = (IWICImagingFactory*)imageQueryInterface.pItf;
        RETURN_NULL_IF_FAILED(_idFactory->CreateStream(&_idStream));

        // Create a stream on the memory to store the image data
        IStream* dataStream;
        CreateStreamOnHGlobal(NULL, true, &dataStream);
        RETURN_NULL_IF_FAILED(_idStream->InitializeFromIStream(dataStream));
        RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(containerType, NULL, &_idEncoder));
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
        REFGUID containerType = [self initSharedReturnGUID:type frames:frames];

        MULTI_QI imageQueryInterface = {0};
        static const GUID IID_IWICImagingFactory = {0xec5ec8a9,0xc395,0x4314,0x9c,0x77,0x54,0xd7,0xa9,0x35,0xff,0x70};
        imageQueryInterface.pIID = &IID_IWICImagingFactory;
        RETURN_NULL_IF_FAILED(
            CoCreateInstanceFromApp(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, nullptr, 1, &imageQueryInterface));
        
        _idFactory = (IWICImagingFactory*)imageQueryInterface.pItf;
        RETURN_NULL_IF_FAILED(_idFactory->CreateStream(&_idStream));

        _outData = NULL;

        NSString* urlNSString = [[(NSURL*)url path] substringFromIndex:1];
        const char* urlString = [urlNSString UTF8String];
        const size_t wideUrlSize = strlen(urlString) + 1;
        wchar_t* wideUrl = new wchar_t[wideUrlSize];
        size_t charactersCopied = mbstowcs(wideUrl, urlString, wideUrlSize);
        RETURN_NULL_IF(charactersCopied != wideUrlSize - 1);
        RETURN_NULL_IF_FAILED(_idStream->InitializeFromFilename(wideUrl, GENERIC_WRITE));
        RETURN_NULL_IF_FAILED(_idFactory->CreateEncoder(containerType, NULL, &_idEncoder));
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
    RETURN_NULL_IF(!data);
    
    return (CGImageDestinationRef)[[ImageDestination alloc] initWithData:data type:type frames:count];
}

/**
 @Status Caveat
 @Notes The current implementation supports common image file formats such as JPEG, GIF, TIFF, BMP, PNG and ICO. 
        Not all formats are supported.
*/
CGImageDestinationRef CGImageDestinationCreateWithURL(CFURLRef url, CFStringRef type, size_t count, CFDictionaryRef options) {
    RETURN_NULL_IF(!url);
    
    return (CGImageDestinationRef)[[ImageDestination alloc] initWithUrl:url type:type frames:count];
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

    if (imageDestination.type == typeGIF) {
        char loopCountMSB = 0;
        char loopCountLSB = 0;

        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyGIFLoopCount)) {
            int loopCount = [(id)CFDictionaryGetValue(properties, kCGImagePropertyGIFLoopCount) intValue];
            loopCountLSB = loopCount & 0xff;
            loopCountMSB = (loopCount >> 8) & 0xff;
        }
        
        PROPVARIANT writePropValue;
        PropVariantInit(&writePropValue);

        ComPtr<IWICMetadataQueryWriter> imageMetadataQueryWriter = imageDestination.idGifEncoderMetadataQueryWriter;
        writePropValue.vt = VT_UI1 | VT_VECTOR;
        writePropValue.caub.cElems = 11;
        writePropValue.caub.pElems = (unsigned char*)[@"NETSCAPE2.0" UTF8String];
        status = imageMetadataQueryWriter->SetMetadataByName(L"/appext/Application", &writePropValue);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Write global gif metadata failed with status=%x\n", status);
            return;
        }

        writePropValue.vt = VT_UI1 | VT_VECTOR;
        writePropValue.caub.cElems = 5;
        writePropValue.caub.pElems = 
            (unsigned char*)[[NSString stringWithFormat:@"%c%c%c%c%c", 3, 1, loopCountLSB, loopCountMSB, 0] UTF8String];
        status = imageMetadataQueryWriter->SetMetadataByName(L"/appext/Data", &writePropValue);
        if (!SUCCEEDED(status)) {
            NSTraceInfo(TAG, @"Write global gif metadata failed with status=%x\n", status);
            return;
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

    imageDestination.count++;
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
    
    return;
}

/**
 @Status Caveat
 @Notes The current implementation supports common image file formats such as JPEG, TIFF, BMP, GIF, and PNG. 
        Not all formats are supported.
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
    

    // Looping properties for GIFs
    if (imageDestination.type == typeGIF) {
        char loopCountMSB = 0;
        char loopCountLSB = 0;

        if (properties && CFDictionaryContainsKey(properties, kCGImagePropertyGIFLoopCount)) {
            int loopCount = [(id)CFDictionaryGetValue(properties, kCGImagePropertyGIFLoopCount) intValue];
            loopCountLSB = loopCount & 0xff;
            loopCountMSB = (loopCount >> 8) & 0xff;
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

        writePropValue.vt = VT_UI1 | VT_VECTOR;
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
        return false;
    }

    ComPtr<IWICBitmapEncoder> imageEncoder = imageDestination.idEncoder;
    ComPtr<IWICStream> imageStream = imageDestination.idStream;

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

    ComPtr<IWICImagingFactory> imageFactory = imageDestination.idFactory;
    ComPtr<IWICMetadataQueryWriter> metadataQueryWriter = imageDestination.idGifEncoderMetadataQueryWriter;
    imageFactory.Reset();
    imageEncoder.Reset();
    imageStream.Reset();
    
    if (metadataQueryWriter) {
        metadataQueryWriter.Reset();
    }
    
    return true;
}
