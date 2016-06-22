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
#import <Accelerate/vImage.h>

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
    const CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    const uint32_t version = 0;
    const CGFloat decode = 0.0f;
    const CGColorRenderingIntent renderingIntent = CGImageGetRenderingIntent(imageRef);
    const uint32_t bitsPerComponent = (uint32_t)CGImageGetBitsPerComponent(imageRef);
    const uint32_t bitsPerPixel =
        bitsPerComponent * (uint32_t)(CGColorSpaceGetNumberOfComponents(colorSpace) + (kCGImageAlphaNone != CGImageGetAlphaInfo(imageRef)));

    vImage_CGImageFormat imageFormatStruct = { bitsPerComponent, bitsPerPixel, colorSpace, bitmapInfo, version, &decode, renderingIntent };

    vImage_Buffer imageBufferRGBA;
    vImageBuffer_InitWithCGImage(&imageBufferRGBA, &imageFormatStruct, nil, imageRef, 0);

    vImage_Buffer imageBufferR;
    vImage_Buffer imageBufferG;
    vImage_Buffer imageBufferB;
    vImage_Buffer imageBufferA;

    vImageBuffer_Init(&imageBufferR, imageBufferRGBA.height, imageBufferRGBA.width, bitsPerComponent, 0);
    vImageBuffer_Init(&imageBufferG, imageBufferR.height, imageBufferR.width, bitsPerComponent, 0);
    vImageBuffer_Init(&imageBufferB, imageBufferR.height, imageBufferR.width, bitsPerComponent, 0);
    vImageBuffer_Init(&imageBufferA, imageBufferR.height, imageBufferR.width, bitsPerComponent, 0);

    // Note: Although the function calls for an ARGB input, RGBA input can be used if the output planes are swizzled
    vImageConvert_ARGB8888toPlanar8(&imageBufferRGBA, &imageBufferR, &imageBufferG, &imageBufferB, &imageBufferA, 0);

    const uint32_t height = imageBufferRGBA.height;
    const uint32_t endOfFirstSlice = height / 3;
    const uint32_t endOfSecondSlice = endOfFirstSlice * 2;
    const uint32_t endOfThirdSlice = height;

    // Divide the image into three slices and remove components to produce strips with different colors
    
    // Slice 0: Remove Red to produce Cyan output
    char* colorData;
    uint32_t rowPitch;

    rowPitch = imageBufferR.rowBytes;
    colorData = (char*)(imageBufferR.data);
    for (uint32_t i = 0; i < endOfFirstSlice; i++) {
        memset(colorData, 0, rowPitch);
        colorData += rowPitch;
    }

    // Slice 1: Remove Green to produce Magenta output
    rowPitch = imageBufferG.rowBytes;
    colorData = (char*)(imageBufferG.data) + endOfFirstSlice * rowPitch;
    for (uint32_t i = endOfFirstSlice; i < endOfSecondSlice; i++) {
        memset(colorData, 0, rowPitch);
        colorData += rowPitch;
    }

    // Slice 2: Remove Blue to produce Yellow output
    rowPitch = imageBufferB.rowBytes;
    colorData = (char*)(imageBufferB.data) + endOfSecondSlice * rowPitch;
    for (uint32_t i = endOfSecondSlice; i < endOfThirdSlice; i++) {
        memset(colorData, 0, rowPitch);
        colorData += rowPitch;
    }

    // Note: To get RGBA output, input planes need to be swizzled
    vImageConvert_Planar8toARGB8888(&imageBufferR, &imageBufferG, &imageBufferB, &imageBufferA, &imageBufferRGBA, 0);

    CGImageRef cgImageFromBuffer = vImageCreateCGImageFromBuffer(&imageBufferRGBA, &imageFormatStruct, nil, nil, 0, nil);
    UIImage* uiImageFromBuffer = [UIImage imageWithCGImage:cgImageFromBuffer];
    CGImageRelease(cgImageFromBuffer);

    free(imageBufferRGBA.data);
    free(imageBufferA.data);
    free(imageBufferR.data);
    free(imageBufferG.data);
    free(imageBufferB.data);

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


