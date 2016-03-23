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
#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGDataProvider.h>
#import <ImageIO/ImageIO.h>
#import <ImageIO/CGImageDestination.h>
#import <objc/runtime.h>
#include <NSLogging.h>
#import <Starboard.h>

#include "COMIncludes.h"
#include "Wincodec.h"
#include <wrl/client.h>
#include "COMIncludes_End.h"

using namespace Microsoft::WRL;

@interface ImageDestination : NSObject
@property (nonatomic)enum imageTypes type;
@property (nonatomic)size_t count;
@property (nonatomic)size_t maxCount;
@property (nonatomic)CFMutableDataRef outData;
@property (nonatomic)ComPtr<IWICImagingFactory> idFactory;
@property (nonatomic)ComPtr<IWICStream> idStream;
@property (nonatomic)ComPtr<IWICBitmapEncoder> idEncoder;

-(instancetype)initWithDataConsumer:(CGDataConsumerRef)imgConsumer type : (CFStringRef)imgType frames : (size_t)numFrames;
-(instancetype)initWithData:(CFMutableDataRef)imgData type : (CFStringRef)imgType frames : (size_t)numFrames;
-(instancetype)initWithUrl:(CFURLRef)url type : (CFStringRef)imgType frames : (size_t)numFrames;
@end