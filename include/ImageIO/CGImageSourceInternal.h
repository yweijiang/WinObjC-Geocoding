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
#pragma once

#import <Foundation/NSObject.h>
#import <CoreFoundation/CFData.h>
#import <CoreFoundation/CFURL.h>
#import <CoreGraphics/CoreGraphicsExport.h>

@class NSData;

@interface ImageSource : NSObject
@property (atomic) NSData* data;
@property (atomic) CGImageSourceStatus loadStatus;
@property (atomic) int loadIndex;
@property (atomic) bool isFinalIncrementalSet;
- (instancetype)initWithData:(CFDataRef)data;
- (instancetype)initWithURL:(CFURLRef)url;
- (instancetype)initWithDataProvider:(CGDataProviderRef)provider;
- (CFStringRef)getImageType;
- (CGImageSourceStatus)getJPEGStatusAtIndex:(size_t)index;
- (CGImageSourceStatus)getTIFFStatusAtIndex:(size_t)index;
- (CGImageSourceStatus)getGIFStatusAtIndex:(size_t)index;
- (CGImageSourceStatus)getBMPStatusAtIndex:(size_t)index;
- (CGImageSourceStatus)getPNGStatusAtIndex:(size_t)index;
- (CGImageSourceStatus)getICOStatusAtIndex:(size_t)index;
- (CGImageSourceStatus)getStatusAtIndex:(size_t)index;
@end
