//******************************************************************************
//
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

#import "ImagesViewController.h"
#import <CoreImage/CIImage.h>
#import <CoreImage/CIContext.h>
#import <CoreGraphics/CGImage.h>
#import <Accelerate/Accelerate.h>

@implementation ImagesViewController

+ (UIImage*)scaleImage:(CGImageRef)imageRef scaledRect:(CGRect)rect quality:(CGInterpolationQuality)quality {
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetInterpolationQuality(context, quality);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, rect.size.height);
    CGContextConcatCTM(context, flipVertical);  
    CGContextDrawImage(context, rect, imageRef);
    CGImageRef scaledImageRef = CGBitmapContextCreateImage(context);
    UIImage* scaledImage = [UIImage imageWithCGImage:scaledImageRef];
    CGImageRelease(scaledImageRef);

    UIGraphicsEndImageContext();

    return scaledImage;
}

+ (UIImage*)filterImage:(CGImageRef)imageRef {
    const CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    const uint32_t bitmapInfo = CGImageGetBitmapInfo(imageRef);
    const uint32_t alphaInfo = CGImageGetAlphaInfo(imageRef);
    const uint32_t byteOrder = bitmapInfo & kCGBitmapByteOrderMask;
    const uint32_t bitsPerComponent = (uint32_t)CGImageGetBitsPerComponent(imageRef);
    const uint32_t numColorComponents = CGColorSpaceGetNumberOfComponents(colorSpace);
    const uint32_t numAlphaOrPaddingComponents = (kCGImageAlphaNone != alphaInfo) ? 1 : 0;
    const bool imageIsARGB =
        (alphaInfo == kCGImageAlphaFirst) && ((byteOrder == kCGBitmapByteOrderDefault) || byteOrder == kCGBitmapByteOrder32Big);
    const bool imageIsABGR = (alphaInfo == kCGImageAlphaLast) && (byteOrder == kCGBitmapByteOrder32Little);
    const bool imageIsXRGB =
        (alphaInfo == kCGImageAlphaNoneSkipFirst) && ((byteOrder == kCGBitmapByteOrderDefault) || byteOrder == kCGBitmapByteOrder32Big);
    const bool imageIsXBGR = (alphaInfo == kCGImageAlphaNoneSkipLast) && (byteOrder == kCGBitmapByteOrder32Little);

    assert(bitsPerComponent == 8);
    assert(CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelRGB);
    assert(alphaInfo == (bitmapInfo & kCGBitmapAlphaInfoMask));
    assert((numColorComponents == 3) && (numAlphaOrPaddingComponents == 1));
    assert((byteOrder != kCGBitmapByteOrder16Little) && (byteOrder != kCGBitmapByteOrder16Big));
    assert(imageIsARGB || imageIsABGR || imageIsXRGB || imageIsXBGR);

    vImage_CGImageFormat format = {
        .bitsPerComponent = bitsPerComponent,
        .bitsPerPixel = bitsPerComponent * (numColorComponents + numAlphaOrPaddingComponents),
        .bitmapInfo = bitmapInfo,
        .colorSpace = colorSpace,
    };

    vImage_Error result;
    vImage_Buffer imageBuffer8888;
    result = vImageBuffer_InitWithCGImage(&imageBuffer8888, &format, nil, imageRef, 0);

    assert(result == kvImageNoError);

    vImage_Buffer imageBufferR;
    vImage_Buffer imageBufferG;
    vImage_Buffer imageBufferB;
    vImage_Buffer imageBufferA;

    result = vImageBuffer_Init(&imageBufferR, imageBuffer8888.height, imageBuffer8888.width, bitsPerComponent, 0);
    assert(result == kvImageNoError);
    result = vImageBuffer_Init(&imageBufferG, imageBufferR.height, imageBufferR.width, bitsPerComponent, 0);
    assert(result == kvImageNoError);
    result = vImageBuffer_Init(&imageBufferB, imageBufferR.height, imageBufferR.width, bitsPerComponent, 0);
    assert(result == kvImageNoError);
    result = vImageBuffer_Init(&imageBufferA, imageBufferR.height, imageBufferR.width, bitsPerComponent, 0);
    assert(result == kvImageNoError);

    // Note: 16byte aligned formats with no alpha component (ex: XRGB and XBGR) pass in an alpha buffer even though it is ignored
    if ((imageIsARGB == true) || (imageIsXRGB == true)) {
        result = vImageConvert_ARGB8888toPlanar8(&imageBuffer8888, &imageBufferA, &imageBufferR, &imageBufferG, &imageBufferB, 0);
    } else if ((imageIsABGR == true) || (imageIsXBGR == true)) {
        // Note: Although the function calls for ARGB input, ABGR or XBGR input can be used if the output planes are swizzled
        result = vImageConvert_ARGB8888toPlanar8(&imageBuffer8888, &imageBufferA, &imageBufferB, &imageBufferG, &imageBufferR, 0);
    }

    assert(result == kvImageNoError);
    // Divide the image into three slices and remove components to produce strips with different colors
    const uint32_t height = imageBuffer8888.height;
    const uint32_t endOfFirstSlice = height / 3;
    const uint32_t endOfSecondSlice = endOfFirstSlice * 2;
    const uint32_t endOfThirdSlice = height;
    
    // Slice 0: Remove Red to produce Cyan output
    unsigned char* colorData;
    uint32_t rowPitch;

    rowPitch = imageBufferR.rowBytes;
    colorData = (unsigned char*)(imageBufferR.data);
    for (uint32_t i = 0; i < endOfFirstSlice; i++) {
        memset(colorData, 0, rowPitch);
        colorData += rowPitch;
    }

    // Slice 1: Remove Green to produce Magenta output
    rowPitch = imageBufferG.rowBytes;
    colorData = (unsigned char*)(imageBufferG.data) + endOfFirstSlice * rowPitch;
    for (uint32_t i = endOfFirstSlice; i < endOfSecondSlice; i++) {
        memset(colorData, 0, rowPitch);
        colorData += rowPitch;
    }

    // Slice 2: Remove Blue to produce Yellow output
    rowPitch = imageBufferB.rowBytes;
    colorData = (unsigned char*)(imageBufferB.data) + endOfSecondSlice * rowPitch;
    for (uint32_t i = endOfSecondSlice; i < endOfThirdSlice; i++) {
        memset(colorData, 0, rowPitch);
        colorData += rowPitch;
    }

    vImage_Buffer imageBufferUnPremultiplied8888;
    result = vImageBuffer_Init(&imageBufferUnPremultiplied8888, imageBuffer8888.height, imageBuffer8888.width, 32, 0);
    assert(result == kvImageNoError);

    vImageUnpremultiplyData_ARGB8888(&imageBuffer8888, &imageBufferUnPremultiplied8888, 0);
    assert(result == kvImageNoError);

    if ((imageIsARGB == true) || (imageIsXRGB == true)) {
        result = vImageConvert_Planar8toARGB8888(&imageBufferA, &imageBufferR, &imageBufferG, &imageBufferB, &imageBuffer8888, 0);
    } else if ((imageIsABGR == true) || (imageIsXBGR == true)) {
        // Note: To get ABGR or XBGR output, input planes are swizzled
        result = vImageConvert_Planar8toARGB8888(&imageBufferA, &imageBufferB, &imageBufferG, &imageBufferR, &imageBuffer8888, 0);
    }

    assert(result == kvImageNoError);
    CGImageRef cgImageFromBuffer = vImageCreateCGImageFromBuffer(&imageBuffer8888, &format, nil, nil, 0, nil);
    UIImage* uiImageFromBuffer = [UIImage imageWithCGImage:cgImageFromBuffer];

    CGColorSpaceRelease(colorSpace);
    CGImageRelease(cgImageFromBuffer);

    free(imageBuffer8888.data);
    free(imageBufferA.data);
    free(imageBufferR.data);
    free(imageBufferG.data);
    free(imageBufferB.data);
    free(imageBufferUnPremultiplied8888.data);

    return uiImageFromBuffer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    UIImageView* imagesView = [[UIImageView alloc] initWithFrame: rect];
    UIImage* photo = [UIImage imageNamed:@"photo9.jpg"];
    UIImage* scaledPhotoHighInterpolation = [ImagesViewController scaleImage:
                                                photo.CGImage
                                                scaledRect:rect
                                                quality:kCGInterpolationHigh];
    UIImage* scaledPhotoNoInterpolation = [ImagesViewController scaleImage:
                                                photo.CGImage 
                                                scaledRect:rect
                                                quality:kCGInterpolationNone];

    CIContext* context = [CIContext contextWithOptions:nil];
    photo = [UIImage imageNamed:@"photo2.jpg"];
    CIImage* ciImage = [CIImage imageWithCGImage:photo.CGImage];
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:CGRectMake(300, 600, 200, 200)];

    UIImage* filteredImage = [ImagesViewController filterImage : photo.CGImage];

    imagesView.animationImages = [NSArray arrayWithObjects:
                            scaledPhotoHighInterpolation,
                            scaledPhotoNoInterpolation,
                            [UIImage imageNamed:@"photo1.jpg"],
                            [UIImage imageNamed:@"photo2.jpg"],
                            filteredImage,
                            [UIImage imageWithCGImage:cgImage],
                            [UIImage imageNamed:@"photo3.jpg"],
                            [UIImage imageNamed:@"photo4.jpg"],
                            [UIImage imageNamed:@"photo5.jpg"],
                            [UIImage imageNamed:@"photo6.jpg"],
                            [UIImage imageNamed:@"photo7.gif"],
                            [UIImage imageNamed:@"photo8.tif"],
                            nil];

    imagesView.animationDuration = 10.0;

    [imagesView setContentMode:UIViewContentModeScaleAspectFit];
    [imagesView startAnimating];
    imagesView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [[self view] addSubview: imagesView];
}

@end


