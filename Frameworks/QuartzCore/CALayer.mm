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

#import <StubReturn.h>
#include <math.h>
#include "CoreGraphics/CGContext.h"
#include "CGContextInternal.h"

#include "Foundation/NSMutableArray.h"
#include "Foundation/NSMutableDictionary.h"
#include "Foundation/NSNumber.h"
#include "Foundation/NSValue.h"
#include "Foundation/NSNull.h"

#include "UIKit/UIApplication.h"
#include "UIKit/UIColor.h"
#include "UIColorInternal.h"
#include "UIKit/NSValue+UIKitAdditions.h"

#include "QuartzCore/CALayer.h"
#include "QuartzCore/CATransaction.h"
#include "QuartzCore/CAEAGLLayer.h"
#include "CAEAGLLayerInternal.h"

#include "..\include\CACompositor.h"
#include "CAAnimationInternal.h"
#include "CABasicAnimationInternal.h"
#include "CATransactionInternal.h"
#include "Quaternion.h"

#include "LoggingNative.h"
#include "CALayerInternal.h"

static const wchar_t* TAG = L"CALayer";

NSString* const kCAOnOrderIn = @"kCAOnOrderIn";
NSString* const kCAOnOrderOut = @"kCAOnOrderOut";
NSString* const kCATransition = @"kCATransition";
NSString* const kCAGravityCenter = @"kCAGravityCenter";
NSString* const kCAGravityTop = @"kCAGravityTop";
NSString* const kCAGravityBottom = @"kCAGravityBottom";
NSString* const kCAGravityLeft = @"kCAGravityLeft";
NSString* const kCAGravityRight = @"kCAGravityRight";
NSString* const kCAGravityTopLeft = @"kCAGravityTopLeft";
NSString* const kCAGravityTopRight = @"kCAGravityTopRight";
NSString* const kCAGravityBottomLeft = @"kCAGravityBottomLeft";
NSString* const kCAGravityBottomRight = @"kCAGravityBottomRight";
NSString* const kCAGravityResize = @"kCAGravityResize";
NSString* const kCAGravityResizeAspect = @"kCAGravityResizeAspect";
NSString* const kCAGravityResizeAspectFill = @"kCAGravityResizeAspectFill";
NSString* const kCAFilterLinear = @"kCAFilterLinear";
NSString* const kCAFilterNearest = @"kCAFilterNearest";
NSString* const kCAFilterTrilinear = @"kCAFilterTrilinear";

@interface CALayer () {
    WXFrameworkElement* _contentsElement;
@public
    CAPrivateInfo* priv;
}

- (DisplayTexture*)_getDisplayTexture;

@end

// FIXME(DH): Compatibility shim to avoid rewriting parts of CA for libobjc2.
// VSO 6149838
static BOOL object_isMethodFromClass(id object, SEL selector, const char* className) {
    return class_getMethodImplementation(objc_getClass(className), selector) ==
           class_getMethodImplementation(object_getClass(object), selector);
}

@interface NSValue (CATransform3D)
// This is defined in Foundation/NSValue.mm
- (NSValue*)initWithCATransform3D:(CATransform3D)val;
@end

NSString* _opacityAction = @"opacity";
NSString* _positionAction = @"position";
NSString* _boundsAction = @"bounds";
NSString* _boundsOriginAction = @"bounds.origin";
NSString* _boundsSizeAction = @"bounds.size";
NSString* _transformAction = @"transform";
NSString* _orderInAction = @"onOrderIn";
NSString* _orderOutAction = @"orderOut";

CACompositorInterface* _globalCompositor;

template <class T>
class NodeList {
public:
    T** items;
    int count;
    int max;
    int curPos;

    NodeList() {
        items = NULL;
        count = 0;
        max = 0;
        curPos = 0;
    }

    ~NodeList() {
        if (items) {
            IwFree(items);
        }
    }

    inline void AddNode(T* item) {
        if (count + 1 > max) {
            max += 64;
            items = (T**)IwRealloc(items, max * sizeof(T*));
        }
        items[count++] = item;
    }
};

static void GetNeededLayouts(CAPrivateInfo* state, NodeList<CAPrivateInfo>* list, bool doAlwaysLayers) {
    CAPrivateInfo* cur = state;
    if (cur->needsLayout || (doAlwaysLayers && cur->alwaysLayout && !cur->didLayout)) {
        list->AddNode(cur);
    }

    cur = cur->lastChild;
    while (cur) {
        GetNeededLayouts(cur, list, doAlwaysLayers);
        cur = cur->prevSibling;
    }
}

void DoLayerLayouts(CALayer* window, bool doAlwaysLayers) {
    NodeList<CAPrivateInfo> list;
    for (;;) {
        GetNeededLayouts(window->priv, &list, doAlwaysLayers);

        if (list.curPos == list.count) {
            break;
        }
        while (list.curPos < list.count) {
            list.items[list.curPos]->needsLayout = FALSE;
            list.items[list.curPos]->didLayout = TRUE;
            [list.items[list.curPos]->self layoutSublayers];
            list.curPos++;
        }
    }

    for (int i = 0; i < list.count; i++) {
        list.items[i]->didLayout = FALSE;
    }
}

static void GetNeededDisplays(CAPrivateInfo* state, NodeList<CAPrivateInfo>* list) {
    CAPrivateInfo* cur = state;
    if (cur->needsDisplay || cur->hasNewContents) {
        list->AddNode(cur);
    }

    cur = cur->lastChild;
    while (cur) {
        GetNeededDisplays(cur, list);
        cur = cur->prevSibling;
    }
}

static void DoDisplayList(CALayer* layer) {
    NodeList<CAPrivateInfo> list;
    GetNeededDisplays(layer->priv, &list);

    while (list.curPos < list.count) {
        CAPrivateInfo* cur = list.items[list.curPos];

        if (!cur->_textureOverride) {
            if (cur->delegate) {
                TraceVerbose(TAG, L"Getting new texture for %hs", object_getClassName(cur->delegate));
            }
            DisplayTexture* newTexture = (DisplayTexture*)[cur->self _getDisplayTexture];
            cur->needsDisplay = FALSE;
            cur->hasNewContents = FALSE;

            if (cur->maskLayer) {
                CALayer* maskLayer = (CALayer*)cur->maskLayer;
                DisplayTexture* maskTexture = (DisplayTexture*)[cur->maskLayer _getDisplayTexture];
                GetCACompositor()->setNodeTexture([CATransaction _currentDisplayTransaction],
                                                  maskLayer->priv->_presentationNode,
                                                  maskTexture,
                                                  maskLayer->priv->contentsSize,
                                                  maskLayer->priv->contentsScale);
                GetCACompositor()->setNodeMaskNode(cur->_presentationNode, maskLayer->priv->_presentationNode);
                if (maskTexture) {
                    GetCACompositor()->ReleaseDisplayTexture(maskTexture);
                }
            }

            GetCACompositor()->setNodeTexture([CATransaction _currentDisplayTransaction],
                                              cur->_presentationNode,
                                              newTexture,
                                              cur->contentsSize,
                                              cur->contentsScale);
            if (newTexture) {
                GetCACompositor()->ReleaseDisplayTexture(newTexture);
            }
        } else {
            cur->needsDisplay = FALSE;
            cur->hasNewContents = FALSE;

            GetCACompositor()->setNodeTexture([CATransaction _currentDisplayTransaction],
                                              cur->_presentationNode,
                                              cur->_textureOverride,
                                              cur->contentsSize,
                                              cur->contentsScale);
        }

        list.curPos++;
    }
}

static void DiscardLayerContents(CALayer* layer) {
    LLTREE_FOREACH(curLayer, layer->priv) {
        DiscardLayerContents(curLayer->self);

        if ([curLayer->self isKindOfClass:[CAEAGLLayer class]]) {
            [curLayer->self _unlockTexture];
        } else {
            [curLayer->self _releaseContents:TRUE];
        }
    }
}

CAPrivateInfo::CAPrivateInfo(CALayer* self, bool bPresentationLayer) {
    memset(this, 0, sizeof(CAPrivateInfo));
    setSelf(self);

    if (bPresentationLayer) {
        _isPresentationLayer = true;
    } else {
        _isPresentationLayer = false;
        memset(&bounds, 0, sizeof(bounds));
        memset(&position, 0, sizeof(position));
        zPosition = 0.0f;
        anchorPoint.x = 0.5f;
        anchorPoint.y = 0.5f;

        _animations = nil;

        contentsRect.origin.x = 0.0f;
        contentsRect.origin.y = 0.0f;
        contentsRect.size.width = 1.0f;
        contentsRect.size.height = 1.0f;

        contentsCenter.origin.x = 0.0f;
        contentsCenter.origin.y = 0.0f;
        contentsCenter.size.width = 1.0f;
        contentsCenter.size.height = 1.0f;

        contentsScale = 1.0f;

        superlayer = 0;
        opacity = 1.0f;
        hidden = FALSE;
        gravity = 0;
        contents = NULL;
        ownsContents = FALSE;
        savedContext = NULL;
        isOpaque = FALSE;
        delegate = 0;
        needsDisplay = TRUE;
        needsUpdate = FALSE;
        hasNewContents = FALSE;
        backgroundColor.r = 0.0f;
        backgroundColor.g = 0.0f;
        backgroundColor.b = 0.0f;
        backgroundColor.a = 0.0f;
        _backgroundColor = nullptr;
        contentColor.r = 1.0f;
        contentColor.g = 1.0f;
        contentColor.b = 1.0f;
        contentColor.a = 1.0f;
        transform = CATransform3DMakeTranslation(0, 0, 0);
        sublayerTransform = CATransform3DMakeTranslation(0, 0, 0);
        masksToBounds = FALSE;
        isRootLayer = FALSE;
        needsDisplayOnBoundsChange = FALSE;
        drewOpaque = FALSE;
        _name = nil;
        positionSet = FALSE;
        sizeSet = FALSE;
        originSet = FALSE;

        _presentationNode = GetCACompositor()->CreateDisplayNode();
    }
}

CAPrivateInfo::~CAPrivateInfo() {
    _undefinedKeys = nil;
    _actions = nil;
    CGColorRelease(_backgroundColor);
    CGColorRelease(_borderColor);
    _name = nil;
    if (_animations) {
        [_animations release];
    }
    if (contents) {
        CGImageRelease(contents);
    }
    if (savedContext) {
        CGContextRelease(savedContext);
    }
    [maskLayer release];
    maskLayer = nil;

    GetCACompositor()->ReleaseNode(_presentationNode);
    _presentationNode = NULL;
}

class LockingBufferInterface : public DisplayTextureLocking {
public:
    void* LockWritableBitmapTexture(DisplayTexture* tex, int* stride) {
        return GetCACompositor()->LockWritableBitmapTexture(tex, stride);
    }
    void UnlockWritableBitmapTexture(DisplayTexture* tex) {
        GetCACompositor()->UnlockWritableBitmapTexture(tex);
    }

    void RetainDisplayTexture(DisplayTexture* tex) {
        GetCACompositor()->RetainDisplayTexture(tex);
    }

    void ReleaseDisplayTexture(DisplayTexture* tex) {
        GetCACompositor()->ReleaseDisplayTexture(tex);
    }
};

static LockingBufferInterface _globallockingBufferInterface;

CGContextRef CreateLayerContentsBitmapContext32(int width, int height) {
    DisplayTexture* tex = NULL;

    if ([NSThread isMainThread]) {
        tex = GetCACompositor()->CreateWritableBitmapTexture32(width, height);
    }
    CGContextRef ret = CGBitmapContextCreate32(width, height, tex, &_globallockingBufferInterface);
    if (tex) {
        _globallockingBufferInterface.ReleaseDisplayTexture(tex);
    }

    return ret;
}

@implementation CALayer
/**
 @Status Interoperable
*/
- (instancetype)init {
    assert(priv == NULL);
    priv = new CAPrivateInfo(self);

    return self;
}

- (CAPrivateInfo*)_priv {
    return priv;
}

- (bool)_isVisibleOrHitable {
    if (priv->hidden || priv->opacity <= 0.01f) {
        return NO;
    }
    return YES;
}

/**
 @Status Interoperable
*/
- (void)setNeedsDisplay {
    if (priv->needsDisplay == FALSE) {
        priv->needsDisplay = TRUE;
    }

    GetCACompositor()->DisplayTreeChanged();
}

/**
 @Status Interoperable
*/
- (void)displayIfNeeded {
    if (priv->needsDisplay) {
        priv->needsDisplay = FALSE;
        [self display];
    }
}

/**
 @Status Caveat
 @Notes transform properties not supported
*/
- (void)renderInContext:(CGContextRef)ctx {
    // if calayer is hidden or opacity is 0 do not render it.
    if (![self _isVisibleOrHitable]) {
        return;
    }

    [self layoutIfNeeded];

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, priv->position.x, priv->position.y);
    CGContextTranslateCTM(ctx, -priv->bounds.size.width * priv->anchorPoint.x, -priv->bounds.size.height * priv->anchorPoint.y);
    CGRect destRect;

    destRect.origin.x = 0;
    destRect.origin.y = 0;
    destRect.size.width = priv->bounds.size.width;
    destRect.size.height = priv->bounds.size.height;

    if (priv->masksToBounds) {
        CGContextClipToRect(ctx, destRect);
    }
    if (priv->contents == NULL) {
        if ([priv->delegate respondsToSelector:@selector(displayLayer:)]) {
            [priv->delegate displayLayer:self];
        }
    }

    if (priv->contents == NULL) {
        if (priv->_backgroundColor != nil) {
            [static_cast<UIColor*>(priv->_backgroundColor) setFill];
            CGContextFillRect(ctx, destRect);
        }
        [self drawInContext:ctx];
        if (![priv->delegate respondsToSelector:@selector(displayLayer:)]) {
            [priv->delegate drawLayer:self inContext:ctx];
        }
    } else {
        CGRect rect;

        rect.origin.x = 0;
        rect.origin.y = priv->bounds.size.height * priv->contentsScale;
        rect.size.width = priv->bounds.size.width * priv->contentsScale;
        rect.size.height = -priv->bounds.size.height * priv->contentsScale;

        CGContextDrawImageRect(ctx, priv->contents, rect, destRect);
    }

    //  Draw sublayers
    LLTREE_FOREACH(curLayer, priv) {
        [curLayer->self renderInContext:ctx];
    }

    CGContextRestoreGState(ctx);
}

/**
 @Status Interoperable
*/
- (void)drawInContext:(CGContextRef)ctx {
}

/**
 @Status Caveat
 @Notes WinObjC extension method
*/
- (WXFrameworkElement*)contentsElement {
    return _contentsElement;
}

/**
 @Status Caveat
 @Notes WinObjC extension method
*/
- (void)setContentsElement:(WXFrameworkElement*)element {
    [element retain];
    [_contentsElement release];
    _contentsElement = element;

    if (priv->_textureOverride) {
        GetCACompositor()->ReleaseDisplayTexture(priv->_textureOverride);
    }
    priv->_textureOverride = GetCACompositor()->CreateDisplayTextureForElement(element);
    [self setContentsGravity:kCAGravityResize];
    priv->needsDisplay = TRUE;
}

/**
 @Status Interoperable
*/
- (void)display {
    TraceVerbose(TAG,
                 L"Displaying for 0x%08x (%hs, %hs)",
                 priv->delegate,
                 object_getClassName(self),
                 priv->delegate ? object_getClassName(priv->delegate) : "nil");

    if (priv->savedContext != NULL) {
        CGContextRelease(priv->savedContext);
        priv->savedContext = NULL;
    }

    if (priv->contentsInset.origin.x != 0.0f || priv->contentsInset.origin.y != 0.0f || priv->contentsInset.size.width != 0.0f ||
        priv->contentsInset.size.height != 0.0f) {
        memset(&priv->contentsInset, 0, sizeof(CGRect));
    }

    if (priv->contents == NULL || priv->ownsContents || [self isKindOfClass:[CAShapeLayer class]]) {
        if (priv->contents) {
            if (priv->ownsContents) {
                TraceVerbose(TAG, L"Freeing 0x%x with refcount %d", priv->contents, CFGetRetainCount((CFTypeRef)priv->contents));
                CGImageRelease(priv->contents);
            }
            priv->contents = NULL;
        }

        // Update content size, even in case of the early out below.
        int width = (int)(ceilf(priv->bounds.size.width) * priv->contentsScale);
        int height = (int)(ceilf(priv->bounds.size.height) * priv->contentsScale);

        if (width <= 0 || height <= 0) {
            return;
        }

        if (width > 2048) {
            width = 2048;
        }
        if (height > 2048) {
            height = 2048;
        }

        priv->contentsSize.width = (float)width;
        priv->contentsSize.height = (float)height;

        // nothing to do?
        bool hasDrawingMethod = false;
        if (priv->delegate != nil && (!object_isMethodFromClass(priv->delegate, @selector(drawRect:), "UIView") ||
                                      !object_isMethodFromClass(priv->delegate, @selector(drawLayer:inContext:), "UIView") ||
                                      [priv->delegate respondsToSelector:@selector(displayLayer:)])) {
            hasDrawingMethod = true;
        }
        if (!object_isMethodFromClass(self, @selector(drawInContext:), "CALayer")) {
            hasDrawingMethod = true;
        }
        if (!hasDrawingMethod) {
            return;
        }

        bool useVector = false;

        //  Create the contents
        CGImageRef target = NULL;
        CGContextRef drawContext = NULL;
        CGImageRef vectorTarget = NULL;

        if ((priv->isOpaque && priv->_backgroundColor == nil) || priv->backgroundColor.a == 1.0) {
            priv->drewOpaque = TRUE;
        } else {
            priv->drewOpaque = FALSE;
        }

        if (!target) {
            if ((priv->isOpaque && priv->_backgroundColor == nil) || (priv->backgroundColor.a == 1.0 && 0)) {
                /* CGVectorImage is currently in development - not ready for general use */
                if (useVector) {
                    // target = new CGVectorImage(width, height, _ColorRGB);
                } else {
                    drawContext = CGBitmapContextCreate24(width, height);
                }
                priv->drewOpaque = TRUE;
            } else {
                /* CGVectorImage is currently in development - not ready for general use */
                if (useVector) {
                    // target = new CGVectorImage(width, height, _ColorARGB);
                } else {
                    drawContext = CreateLayerContentsBitmapContext32(width, height);
                }
                priv->drewOpaque = FALSE;
            }
            priv->ownsContents = TRUE;
        }
        target = CGBitmapContextGetImage(drawContext);

        CGContextRetain(drawContext);
        CGImageRetain(target);
        priv->savedContext = drawContext;

        if (!vectorTarget) {
            if (priv->_backgroundColor == nil || (int)[static_cast<UIColor*>(priv->_backgroundColor) _type] == solidBrush) {
                CGContextClearToColor(drawContext,
                                      priv->backgroundColor.r,
                                      priv->backgroundColor.g,
                                      priv->backgroundColor.b,
                                      priv->backgroundColor.a);
            } else {
                CGContextClearToColor(drawContext, 0, 0, 0, 0);

                CGContextSaveGState(drawContext);
                CGContextSetFillColorWithColor(drawContext, [static_cast<UIColor*>(priv->_backgroundColor) CGColor]);

                CGRect wholeRect;

                wholeRect.origin.x = 0;
                wholeRect.origin.y = 0;
                wholeRect.size.width = float(width);
                wholeRect.size.height = float(height);

                CGContextFillRect(drawContext, wholeRect);
                CGContextRestoreGState(drawContext);
            }
        }

        if (target->Backing()->Height() != 0) {
            CGContextTranslateCTM(drawContext, 0, float(target->Backing()->Height()));
        }
        if (priv->contentsScale != 1.0f) {
            CGContextScaleCTM(drawContext, priv->contentsScale, priv->contentsScale);
        }

        CGContextScaleCTM(drawContext, 1.0f, -1.0f);
        CGContextTranslateCTM(drawContext, -priv->bounds.origin.x, -priv->bounds.origin.y);

        CGContextSetDirty(drawContext, false);
        [self drawInContext:drawContext];

        if (priv->delegate != 0) {
            // const char *name = ((id) priv->delegate).object_getClassName();
            if ([priv->delegate respondsToSelector:@selector(displayLayer:)]) {
                [priv->delegate displayLayer:self];
            } else {
                [priv->delegate drawLayer:self inContext:drawContext];
            }
        }

        CGContextReleaseLock(drawContext);
        CGContextRelease(drawContext);

        if (!CGContextIsDirty(drawContext)) {
            CGImageRelease(target);
            CGContextRelease(drawContext);
            priv->savedContext = NULL;
            priv->contents = NULL;
        } else {
            if (vectorTarget) {
                /*
                CGVectorImage *vecImg = (CGVectorImage *) target;

                priv->contents = vecImg->Rasterize(&priv->contentsInset);

                priv->contentsInset.origin.x /= priv->contentsScale;
                priv->contentsInset.origin.y /= priv->contentsScale;
                priv->contentsInset.size.width /= priv->contentsScale;
                priv->contentsInset.size.height /= priv->contentsScale;

                CGImageRelease(vecImg);
                */
            } else {
                priv->contents = target;
            }
        }
    } else {
        if (priv->contents) {
            priv->contentsSize.width = float(priv->contents->Backing()->Width());
            priv->contentsSize.height = float(priv->contents->Backing()->Height());

            /*
            if ( priv->contents->_cachedTexture ) {
            priv->contents->_cachedTexture->Release();
            priv->contents->_cachedTexture = NULL;
            }
            */
        }
    }

    //  To signal that we need our context converted into a texture and sent to NativeUI (checked in UIApplication.cpp)
    priv->hasNewContents = TRUE;
}

static void doRecursiveAction(CALayer* layer, NSString* actionName) {
    //  Notify all subviews
    LLTREE_FOREACH(obj, layer->priv) {
        doRecursiveAction(obj->self, actionName);
    }

    id<CAAction> action = [layer actionForKey:actionName];
    if (action != nil) {
        [action runActionForKey:actionName object:layer arguments:nil];
    }

    /* Note: This can causes unnecessary redraws - should be refactored such that the contents are only released
    when the layer is determined to have been removed from the drawing tree after an entire update cycle */
    if (actionName == (NSString*)_orderOutAction) {
        [layer _releaseContents:FALSE];

        if (layer->priv->savedContext) {
            CGContextRelease(layer->priv->savedContext);
            layer->priv->savedContext = NULL;
        }
    }
}

- (BOOL)_isPartOfViewHeiarchy {
    CALayer* curLayer = self;

    while (curLayer != nil) {
        if (curLayer->priv->isRootLayer) {
            return TRUE;
        }

        curLayer = curLayer->priv->superlayer;
    }

    return FALSE;
}

/**
 @Status Interoperable
*/
- (void)addSublayer:(CALayer*)subLayerAddr {
    if (subLayerAddr == self) {
        assert(0);
    }

    [self _setShouldLayout];
    [subLayerAddr _setShouldLayout];

    [subLayerAddr retain];
    [subLayerAddr removeFromSuperlayer];
    [subLayerAddr autorelease];

    //  If our layer is visible, order all subviews in
    bool isVisible = false;

    CALayer* curLayer = self;

    while (curLayer != nil) {
        if (curLayer->priv->isRootLayer) {
            isVisible = true;
            break;
        }

        curLayer = curLayer->priv->superlayer;
    }

    if (isVisible) {
        //  Order in subviews
        doRecursiveAction(subLayerAddr, _orderInAction);
    }

    priv->addChildAfter(subLayerAddr, nil);
    [subLayerAddr retain];

    CALayer* sublayer = (CALayer*)subLayerAddr;
    sublayer->priv->superlayer = self;

    [CATransaction _addSublayerToLayer:self sublayer:sublayer];
}

/**
 @Status Interoperable
*/
- (void)insertSublayer:(CALayer*)layer above:(CALayer*)aboveLayer {
    int curLayerPos = priv->indexOfChild(aboveLayer);
    if (curLayerPos == 0x7fffffff) {
        assert(0);
    }

    [self insertSublayer:layer atIndex:curLayerPos + 1];
}

/**
 @Status Interoperable
*/
- (void)insertSublayer:(CALayer*)layer below:(CALayer*)belowLayer {
    int curLayerPos = priv->indexOfChild(belowLayer);
    if (curLayerPos == 0x7fffffff) {
        assert(0);
    }

    [self insertSublayer:layer atIndex:curLayerPos];
}

/**
 @Status Interoperable
*/
- (void)insertSublayer:(CALayer*)subLayerAddr atIndex:(unsigned)index {
    if (subLayerAddr == self) {
        assert(0);
    }

    [self _setShouldLayout];
    [subLayerAddr _setShouldLayout];

    //  If our layer is visible, order all subviews in
    bool isVisible = false;

    CALayer* curLayer = self;

    while (curLayer != nil) {
        if (curLayer->priv->isRootLayer) {
            isVisible = true;
            break;
        }

        curLayer = curLayer->priv->superlayer;
    }

    if (isVisible) {
        //  Order in subviews
        doRecursiveAction(subLayerAddr, _orderInAction);
    }

    CALayer* insertBefore = nil;

    if (index < (unsigned)priv->childCount) {
        insertBefore = priv->childAtIndex(index)->self;
    } else {
        if (index > (unsigned)priv->childCount) {
            TraceVerbose(TAG, L"Adding sublayer at index %d, count=%d!", index, priv->childCount);
            index = priv->childCount;
        }
    }

    priv->insertChildAtIndex(subLayerAddr, index);
    [subLayerAddr retain];

    CALayer* sublayer = (CALayer*)subLayerAddr;
    sublayer->priv->superlayer = self;

    if (insertBefore != nil) {
        [CATransaction _addSublayerToLayer:self sublayer:sublayer before:insertBefore];
    } else {
        [CATransaction _addSublayerToLayer:self sublayer:sublayer];
    }
}

/**
 @Status Interoperable
*/
- (void)replaceSublayer:(CALayer*)oldLayer with:(CALayer*)newLayer {
    // according to the docs, if oldLayer is not found the behaviour is undefined.
    int index = priv->indexOfChild(oldLayer);
    if (index == NSNotFound) {
        return;
    }

    [self _setShouldLayout];
    [newLayer _setShouldLayout];

    [oldLayer retain];
    [newLayer retain];

    priv->replaceChild(oldLayer, newLayer);

    [CATransaction _replaceInLayer:self sublayer:oldLayer withSublayer:newLayer];

    [oldLayer release];
    [newLayer release];
}

- (void)exchangeSublayer:(CALayer*)layer1 withLayer:(CALayer*)layer2 {
    [layer1 retain];
    [layer2 retain];

    int index1 = priv->indexOfChild(layer1);
    int index2 = priv->indexOfChild(layer2);

    priv->exchangeChild(layer1, layer2);

    //  Special case: adjacent views
    if (index2 == index1 + 1) {
        [CATransaction _moveLayer:layer1 beforeLayer:nil afterLayer:layer2];
    } else if (index1 == index2 + 1) {
        [CATransaction _moveLayer:layer2 beforeLayer:nil afterLayer:layer1];
    } else {
        int dist = index1 - index2;

        dist = dist < 0 ? -dist : dist;

        if (dist > 1) {
            if (index1 > 0) {
                CALayer* node1Before = priv->childAtIndex(index1 - 1)->self;
                [CATransaction _moveLayer:layer2 beforeLayer:nil afterLayer:node1Before];
            } else {
                CALayer* node1After = priv->childAtIndex(index1 + 1)->self;
                [CATransaction _moveLayer:layer2 beforeLayer:node1After afterLayer:nil];
            }

            if (index2 > 0) {
                CALayer* node2Before = priv->childAtIndex(index2 - 1)->self;
                [CATransaction _moveLayer:layer1 beforeLayer:nil afterLayer:node2Before];
            } else {
                CALayer* node2After = priv->childAtIndex(index2 + 1)->self;
                [CATransaction _moveLayer:layer1 beforeLayer:node2After afterLayer:nil];
            }
        } else {
            assert(0);
        }
    }
}

- (void)bringSublayerToFront:(CALayer*)sublayer {
    if (sublayer == self) {
        assert(0);
    }

    if (priv->lastChild->self == sublayer) {
        return;
    }

    CALayer* insertAfter = priv->lastChild->self;
    priv->removeChild(sublayer);
    priv->addChildAfter(sublayer, nil);

    [CATransaction _moveLayer:sublayer beforeLayer:nil afterLayer:insertAfter];
}

- (void)sendSublayerToBack:(CALayer*)sublayer {
    if (sublayer == self) {
        assert(0);
    }

    CALayer* insertBefore = priv->firstChild->self;
    priv->removeChild(sublayer);
    priv->addChildBefore(sublayer, nil);

    [CATransaction _moveLayer:sublayer beforeLayer:insertBefore afterLayer:nil];
}

/**
 @Status Interoperable
*/
- (void)removeFromSuperlayer {
    if (priv->superlayer == 0) {
        return;
    }

    CALayer* oursuper = priv->superlayer;

    //  If our layer is visible, order all subviews out
    bool isVisible = false;

    CALayer* curLayer = self;
    CALayer* pSuper = (CALayer*)priv->superlayer;
    CALayer* nextSuper = curLayer->priv->superlayer;
    priv->superlayer = 0;

    while (curLayer != nil) {
        if (curLayer->priv->isRootLayer) {
            isVisible = true;
            break;
        }

        curLayer = nextSuper;

        if (curLayer) {
            nextSuper = curLayer->priv->superlayer;
        }
    }

    if (isVisible) {
        //  Order out subviews
        doRecursiveAction(self, _orderOutAction);
    }

    [CATransaction _removeLayer:self];

    pSuper->priv->removeChild(self);
    [self release];
}

- (BOOL)hidden {
    return priv->hidden;
}

/**
 @Status Interoperable
*/
- (CGRect)frame {
    CGRect ret;

    if (priv->_frameIsCached) {
        return priv->_cachedFrame;
    }

    //  Get transformed bounding box
    CGAffineTransform curTransform, translate, invTranslate;
    curTransform = [self affineTransform];

    translate = CGAffineTransformMakeTranslation(-priv->position.x, -priv->position.y);
    translate = CGAffineTransformConcat(translate, curTransform);
    invTranslate = CGAffineTransformMakeTranslation(priv->position.x, priv->position.y);
    translate = CGAffineTransformConcat(translate, invTranslate);

    ret.origin.x = priv->position.x - priv->bounds.size.width * priv->anchorPoint.x;
    ret.origin.y = priv->position.y - priv->bounds.size.height * priv->anchorPoint.y;
    ret.size = priv->bounds.size;

    ret = CGRectApplyAffineTransform(ret, translate);
    /*
    TraceVerbose(TAG, L"%hs: frame(%d, %d, %d, %d)", object_getClassName(self),
    (int) ret->origin.x, (int) ret->origin.y,
    (int) ret->size.width, (int) ret->size.height);
    */

    memcpy(&priv->_cachedFrame, &ret, sizeof(CGRect));
    priv->_frameIsCached = TRUE;

    return ret;
}

/**
 @Status Interoperable
*/
- (void)setFrame:(CGRect)frame {
    /*
    char szOut[512];
    sprintf_s(szOut, sizeof(szOut), "%s: setFrame(%f, %f, %f, %f)\n", object_getClassName(self),
    frame.origin.x, frame.origin.y,
    frame.size.width, frame.size.height);
    TraceVerbose(TAG, L"%hs", szOut);
    */
    priv->_frameIsCached = FALSE;

    if (memcmp(&frame, &CGRectNull, sizeof(CGRect)) == 0) {
        [self setPosition:frame.origin];

        CGRect curBounds;
        curBounds = [self bounds];
        curBounds.size = frame.size;

        [self setBounds:curBounds];

        return;
    }

    //  Get transformed bounding box
    CGAffineTransform curTransform, translate, invTranslate;
    curTransform = [self affineTransform];

    CGPoint position;

    position.x = frame.origin.x + frame.size.width * priv->anchorPoint.x;
    position.y = frame.origin.y + frame.size.height * priv->anchorPoint.y;

    //  Get transformed bounding box
    translate = CGAffineTransformMakeTranslation(-position.x, -position.y);
    translate = CGAffineTransformConcat(translate, curTransform);
    invTranslate = CGAffineTransformMakeTranslation(position.x, position.y);
    translate = CGAffineTransformConcat(translate, invTranslate);

    translate = CGAffineTransformInvert(translate);
    frame = CGRectApplyAffineTransform(frame, translate);

    CGSize outSize;
    outSize.width = frame.size.width;
    outSize.height = frame.size.height;

    position.x = frame.origin.x + frame.size.width * priv->anchorPoint.x;
    position.y = frame.origin.y + frame.size.height * priv->anchorPoint.y;

    [self setPosition:position];

    CGRect outBounds = [self bounds];
    outBounds.size = outSize;
    [self setBounds:outBounds];
}

/**
 @Status Interoperable
*/
+ (CALayer*)layer {
    return [[self new] autorelease];
}

/**
 @Status Interoperable
*/
- (CGRect)bounds {
    return priv->bounds;
}

/**
 @Status Interoperable
*/
- (CALayer*)superlayer {
    return priv->superlayer;
}

/**
 @Status Interoperable
*/
- (CGAffineTransform)affineTransform {
    CGAffineTransform ret;

    ret.a = priv->transform.m[0][0];
    ret.b = priv->transform.m[0][1];
    ret.c = priv->transform.m[1][0];
    ret.d = priv->transform.m[1][1];
    ret.tx = priv->transform.m[3][0];
    ret.ty = priv->transform.m[3][1];

    return ret;
}

/**
 @Status Interoperable
*/
- (CGPoint)position {
    return priv->position;
}

/**
 @Status Interoperable
*/
- (CGPoint)anchorPoint {
    return priv->anchorPoint;
}

/**
 @Status Interoperable
*/
- (void)setPosition:(CGPoint)pos {
    if (priv->position.x == pos.x && priv->position.y == pos.y) {
        return;
    }

    id<CAAction> action = [self actionForKey:(id)_positionAction];

    priv->position.x = pos.x;
    priv->position.y = pos.y;
    priv->_frameIsCached = FALSE;

    NSValue* newPosValue = [[NSValue alloc] initWithCGPoint:priv->position];
    [CATransaction _setPropertyForLayer:self name:@"position" value:newPosValue];
    [newPosValue release];
    priv->positionSet = TRUE;

    if (action != nil) {
        [action runActionForKey:(id)_positionAction object:self arguments:nil];
    }
}

/**
 @Status Interoperable
*/
- (void)setBounds:(CGRect)bounds {
    CGRect zero = { 0 };
    if (*((DWORD*)&bounds.size.width) == 0xCCCCCCCC) {
        assert(0);
    }

    if (bounds.origin.x != bounds.origin.x || bounds.origin.y != bounds.origin.y || bounds.size.width != bounds.size.width ||
        bounds.size.height != bounds.size.height) {
        TraceWarning(TAG,
                     L"**** Warning: Bad bounds on CALayer - %f, %f, %f, %f *****",
                     bounds.origin.x,
                     bounds.origin.y,
                     bounds.size.width,
                     bounds.size.height);
        memset(&bounds, 0, sizeof(CGRect));
#if defined(_DEBUG) || !defined(WINPHONE)
        assert(0);
#endif
    }
    /*
    if ( bounds.size.height > 16384 || bounds.size.width > 16384 ) {
    TraceWarning(TAG, L"**** Warning: Bad bounds on CALayer - %d, %d, %d, %d *****", (int) bounds.origin.x, (int)
    bounds.origin.y,
    (int) bounds.size.width, (int) bounds.size.height);
    bounds.size.height = 32;
    bounds.size.width = 32;
    //((char *) 0) = 0;
    //assert(0);
    }
    */
    id<CAAction> action = nil;

    if (priv->bounds.size.width != bounds.size.width || priv->bounds.size.height != bounds.size.height ||
        priv->bounds.origin.x != bounds.origin.x || priv->bounds.origin.y != bounds.origin.y) {
        action = [self actionForKey:_boundsAction];
    }

    if (priv->bounds.size.width != bounds.size.width || priv->bounds.size.height != bounds.size.height) {
        priv->bounds.size = bounds.size;

        if (priv->superlayer != 0 && priv->needsDisplayOnBoundsChange) {
            [self setNeedsDisplay];
        }
        [self _setShouldLayout];
        [priv->superlayer _setShouldLayout];

        NSValue* newSizeValue = [[NSValue alloc] initWithCGSize:priv->bounds.size];
        [CATransaction _setPropertyForLayer:self name:@"bounds.size" value:newSizeValue];
        [newSizeValue release];
        priv->_frameIsCached = FALSE;
    }

    if (priv->bounds.origin.x != bounds.origin.x || priv->bounds.origin.y != bounds.origin.y) {
        priv->bounds.origin = bounds.origin;

        NSValue* newOriginValue = [[NSValue alloc] initWithCGPoint:priv->bounds.origin];
        [CATransaction _setPropertyForLayer:self name:@"bounds.origin" value:newOriginValue];
        [newOriginValue release];
    }

    [action runActionForKey:(id)_boundsAction object:self arguments:nil];

    priv->sizeSet = TRUE;
    priv->originSet = TRUE;
}

- (void)setOrigin:(CGPoint)origin {
    if (origin.x != origin.x || origin.y != origin.y) {
        TraceWarning(TAG, L"**** Warning: Bad origin on CALayer - %f, %f *****", origin.x, origin.y);
        memset(&origin, 0, sizeof(CGPoint));
        assert(0);
    }

    if (priv->bounds.origin.x != origin.x || priv->bounds.origin.y != origin.y) {
        id<CAAction> action = nil;
        action = [self actionForKey:_boundsOriginAction];
        priv->bounds.origin = origin;
        [action runActionForKey:(id)_boundsOriginAction object:self arguments:nil];

        NSValue* newOriginValue = [[NSValue alloc] initWithCGPoint:priv->bounds.origin];
        [CATransaction _setPropertyForLayer:self name:@"bounds.origin" value:newOriginValue];
        [newOriginValue release];
        priv->originSet = TRUE;
    }
}

/**
 @Status Interoperable
*/
- (void)setAnchorPoint:(CGPoint)point {
    priv->anchorPoint = point;
    priv->_frameIsCached = FALSE;

    NSValue* newAnchorValue = [[NSValue alloc] initWithCGPoint:priv->anchorPoint];
    [CATransaction _setPropertyForLayer:self name:@"anchorPoint" value:newAnchorValue];
    [newAnchorValue release];
}

- (CGRect)contentsRect {
    return priv->contentsRect;
}

- (void)setContentsRect:(CGRect)rect {
    memcpy(&priv->contentsRect, &rect, sizeof(CGRect));

    NSValue* newRect = [[NSValue alloc] initWithCGRect:priv->contentsRect];
    [CATransaction _setPropertyForLayer:self name:@"contentsRect" value:newRect];
    [newRect release];
}

/**
 @Status Interoperable
*/

- (CGRect)contentsCenter {
    return priv->contentsCenter;
}

/**
 @Status Interoperable
*/
- (void)setContentsCenter:(CGRect)rect {
    memcpy(&priv->contentsCenter, &rect, sizeof(CGRect));

    NSValue* newRect = [[NSValue alloc] initWithCGRect:priv->contentsCenter];
    [CATransaction _setPropertyForLayer:self name:@"contentsCenter" value:newRect];
    [newRect release];
}

/**
 @Status Interoperable
*/
- (void)setContentsGravity:(NSString*)gravity {
    if ([gravity isEqual:kCAGravityCenter]) {
        priv->gravity = kGravityCenter;
    } else if ([gravity isEqual:kCAGravityResize]) {
        priv->gravity = kGravityResize;
    } else if ([gravity isEqual:kCAGravityTop]) {
        priv->gravity = kGravityTop;
    } else if ([gravity isEqual:kCAGravityResizeAspect]) {
        priv->gravity = kGravityResizeAspect;
    } else if ([gravity isEqual:kCAGravityTopLeft]) {
        priv->gravity = kGravityTopLeft;
    } else if ([gravity isEqual:kCAGravityTopRight]) {
        priv->gravity = kGravityTopRight;
    } else if ([gravity isEqual:kCAGravityBottomLeft]) {
        priv->gravity = kGravityBottomLeft;
    } else if ([gravity isEqual:kCAGravityLeft]) {
        priv->gravity = kGravityLeft;
    } else if ([gravity isEqual:kCAGravityResizeAspectFill]) {
        priv->gravity = kGravityAspectFill;
    } else if ([gravity isEqual:kCAGravityBottom]) {
        priv->gravity = kGravityBottom;
    } else if ([gravity isEqual:kCAGravityRight]) {
        priv->gravity = kGravityRight;
    } else if ([gravity isEqual:kCAGravityBottomRight]) {
        priv->gravity = kGravityBottomRight;
    } else {
        assert(0);
    }

    NSNumber* newGravity = [[NSNumber alloc] initWithInt:priv->gravity];
    [CATransaction _setPropertyForLayer:self name:@"gravity" value:newGravity];
    [newGravity release];
}

/**
 @Status Interoperable
*/
- (NSString*)contentsGravity {
    if (priv->gravity == kGravityCenter) {
        return kCAGravityCenter;
    } else if (priv->gravity == kGravityResize) {
        return kCAGravityResize;
    } else if (priv->gravity == kGravityTop) {
        return kCAGravityTop;
    } else if (priv->gravity == kGravityResizeAspect) {
        return kCAGravityResizeAspect;
    } else if (priv->gravity == kGravityTopLeft) {
        return kCAGravityTopLeft;
    } else if (priv->gravity == kGravityTopRight) {
        return kCAGravityTopRight;
    } else if (priv->gravity == kGravityBottomLeft) {
        return kCAGravityBottomLeft;
    } else if (priv->gravity == kGravityLeft) {
        return kCAGravityLeft;
    } else if (priv->gravity == kGravityAspectFill) {
        return kCAGravityResizeAspectFill;
    } else if (priv->gravity == kGravityBottom) {
        return kCAGravityBottom;
    } else if (priv->gravity == kGravityRight) {
        return kCAGravityRight;
    } else if (priv->gravity == kGravityBottomRight) {
        return kCAGravityBottomRight;
    } else {
        assert(0);
    }
    return nil;
}

/**
 @Status Interoperable
*/
- (void)setHidden:(BOOL)hidden {
    if (priv->hidden == hidden) {
        return;
    }

    priv->hidden = hidden;

    NSNumber* newHidden = [[NSNumber alloc] initWithInt:priv->hidden];
    [CATransaction _setPropertyForLayer:self name:@"hidden" value:newHidden];
    [newHidden release];
}

/**
 @Status Interoperable
*/
- (BOOL)isHidden {
    return priv->hidden;
}

/**
 @Status Interoperable
*/
- (void)setDelegate:(id)delegateAddr {
    priv->delegate = delegateAddr;

    if ([delegateAddr respondsToSelector:@selector(drawRect:)]) {
        if (!object_isMethodFromClass(priv->delegate, @selector(drawRect:), "UIView") &&
            ![priv->delegate isKindOfClass:[CAEAGLLayer class]]) {
            priv->contentsScale = GetCACompositor()->screenScale();
        }
    }
}

/**
 @Status Interoperable
*/
- (id)delegate {
    return priv->delegate;
}

/**
 @Status Interoperable
*/
- (void)setContents:(id)pImg {
    CGImageRef oldContents = priv->contents;

    if (pImg != NULL) {
        priv->contents = static_cast<CGImageRef>(pImg);
        CGImageRetain(static_cast<CGImageRef>(pImg));
        priv->ownsContents = FALSE;

        priv->contentsSize.width = float(priv->contents->Backing()->Width());
        priv->contentsSize.height = float(priv->contents->Backing()->Height());
    } else {
        priv->contents = NULL;
        priv->ownsContents = FALSE;
    }

    priv->needsDisplay = TRUE;

    if (oldContents) {
        CGImageRelease(oldContents);
    }
    if (priv->savedContext) {
        CGContextRelease(priv->savedContext);
        priv->savedContext = NULL;
    }

    GetCACompositor()->DisplayTreeChanged();
}

/**
 @Status Interoperable
*/
- (id)contents {
    if (!priv->ownsContents) {
        return (id)priv->contents;
    }

    return nil;
}

- (UIImageOrientation)contentsOrientation {
    return priv->contentsOrientation;
}

- (void)setContentsOrientation:(UIImageOrientation)orientation {
    priv->contentsOrientation = orientation;
    NSNumber* newOrientation = [[NSNumber alloc] initWithInt:priv->contentsOrientation];
    [CATransaction _setPropertyForLayer:self name:@"contentsOrientation" value:newOrientation];
    [newOrientation release];
}

- (void)_releaseContents:(BOOL)immediately {
    if (priv->ownsContents) {
        if (priv->contents) {
            CGImageRelease(priv->contents);
            priv->contents = NULL;
            priv->needsDisplay = TRUE;
        }
        if (priv->savedContext) {
            CGContextRelease(priv->savedContext);
            priv->savedContext = NULL;
        }
    }
    GetCACompositor()->setNodeTexture([CATransaction _currentDisplayTransaction], priv->_presentationNode, NULL, CGSizeMake(0, 0), 0.0f);
    priv->needsDisplay = TRUE;

    GetCACompositor()->DisplayTreeChanged();
}

- (BOOL)isOpaque {
    return priv->isOpaque;
}

/**
 @Status Interoperable
*/
- (BOOL)opaque {
    return priv->isOpaque;
}

/**
 @Status Interoperable
*/
- (void)setOpaque:(BOOL)isOpaque {
    priv->isOpaque = isOpaque;
}

/**
 @Status Interoperable
*/
- (void)setZPosition:(float)pos {
    priv->zPosition = pos;

    NSNumber* newZPos = [[NSNumber alloc] initWithFloat:priv->zPosition];
    [CATransaction _setPropertyForLayer:self name:@"zPosition" value:newZPos];
    [newZPos release];
}

/**
 @Status Interoperable
*/
- (float)zPosition {
    return priv->zPosition;
}

/**
 @Status Interoperable
*/
- (void)setMasksToBounds:(BOOL)mask {
    priv->masksToBounds = mask;

    NSNumber* newMask = [[NSNumber alloc] initWithInt:priv->masksToBounds];
    [CATransaction _setPropertyForLayer:self name:@"masksToBounds" value:newMask];
    [newMask release];
}

/**
 @Status Interoperable
*/
- (BOOL)masksToBounds {
    return priv->masksToBounds;
}

/**
 @Status Interoperable
 @Notes For CABasicAnimation when all three animation properties are nil, our behavior (i.e. no animation)
        remains consistent with what happens on Mac, but varies from Apple Documentation.
*/
- (void)addAnimation:(CAAnimation*)anim forKey:(NSString*)key {
    if (priv->_animations == nil) {
        priv->_animations = [NSMutableDictionary new];
    }

    if (key == nil) {
        static int curId = 0;
        char szName[255];
        sprintf_s(szName, sizeof(szName), "Undefined_%d", curId);
        curId++;
        key = [NSString stringWithCString:szName];
    }

    CAAnimation* curAnim = [priv->_animations objectForKey:key];
    if (curAnim == anim) {
        return;
    }

    if (curAnim != nil) {
        [curAnim _abortAnimation];
    }

    CAAnimation* animCopy = [anim copy];
    animCopy->_keyName = [key copy];
    [priv->_animations setObject:(id)animCopy forKey:(id)animCopy->_keyName];

    [CATransaction _addAnimationToLayer:self animation:animCopy forKey:key];
    [animCopy release];
}

- (void)_removeAnimation:(CAAnimation*)animation {
    CAAnimation* objForKey = [priv->_animations objectForKey:animation->_keyName];
    [priv->_animations setObject:nil forKey:animation->_keyName];
}

/**
 @Status Interoperable
*/
- (CAAnimation*)animationForKey:(NSString*)key {
    if (priv->_animations == nil) {
        priv->_animations = [NSMutableDictionary new];
    }

    if (key == nil) {
        key = @"";
    }

    return [priv->_animations objectForKey:key];
}

/**
 @Status Interoperable
*/
- (NSArray*)animationKeys {
    if (priv->_animations == nil) {
        priv->_animations = [NSMutableDictionary new];
    }

    return [priv->_animations allKeys];
}

/**
 @Status Interoperable
*/
- (void)removeAllAnimations {
    if (priv->_animations) {
        int count = CFDictionaryGetCount((CFDictionaryRef)priv->_animations);
        id* vals = (id*)IwMalloc(sizeof(id) * count);
        CFDictionaryGetKeysAndValues((CFDictionaryRef)priv->_animations, NULL, (const void**)vals);
        for (int i = 0; i < count; i++) {
            [vals[i] _removeAnimationsFromLayer];
        }
        IwFree(vals);

        [priv->_animations removeAllObjects];
    }
}

/**
 @Status Interoperable
*/
- (void)removeAnimationForKey:(NSString*)key {
    CAAnimation* anim = [priv->_animations objectForKey:key];

    if (anim != nil) {
        [anim _removeAnimationsFromLayer];
    }
    [priv->_animations removeObjectForKey:key];
}

/**
 @Status Interoperable
*/
- (void)setAffineTransform:(CGAffineTransform)transform {
    CATransform3D newTransform;

    newTransform = CATransform3DMakeTranslation(0, 0, 0);
    newTransform.m[0][0] = transform.a;
    newTransform.m[0][1] = transform.b;
    newTransform.m[1][0] = transform.c;
    newTransform.m[1][1] = transform.d;
    newTransform.m[3][0] = transform.tx;
    newTransform.m[3][1] = transform.ty;

    if (memcmp(priv->transform.m, newTransform.m, sizeof(newTransform.m)) == 0) {
        return;
    }

    id<CAAction> action = [self actionForKey:_transformAction];

    memcpy(&priv->transform, &newTransform, sizeof(CATransform3D));
    priv->_frameIsCached = FALSE;

    [action runActionForKey:(id)_transformAction object:self arguments:nil];

    NSValue* transformValue = [[NSValue alloc] initWithCATransform3D:priv->transform];
    [CATransaction _setPropertyForLayer:self name:@"transform" value:transformValue];
    [transformValue release];
}

/**
 @Status Interoperable
*/
- (void)setTransform:(CATransform3D)transform {
    if (memcmp(priv->transform.m, transform.m, sizeof(transform.m)) == 0) {
        return;
    }

    id<CAAction> action = [self actionForKey:_transformAction];

    memcpy(priv->transform.m, transform.m, sizeof(transform.m));
    priv->_frameIsCached = FALSE;

    [action runActionForKey:(id)_transformAction object:self arguments:nil];

    NSValue* transformValue = [[NSValue alloc] initWithCATransform3D:priv->transform];
    [CATransaction _setPropertyForLayer:self name:@"transform" value:transformValue];
    [transformValue release];
}

/**
 @Status Interoperable
*/
- (void)setSublayerTransform:(CATransform3D)transform {
    memcpy(priv->sublayerTransform.m, transform.m, sizeof(transform.m));

    NSValue* newTransform = [[NSValue alloc] initWithCATransform3D:priv->sublayerTransform];
    [CATransaction _setPropertyForLayer:self name:@"sublayerTransform" value:newTransform];
    [newTransform release];
}

/**
 @Status Interoperable
*/
- (CATransform3D)sublayerTransform {
    return priv->sublayerTransform;
}

/**
 @Status Interoperable
*/
- (CATransform3D)transform {
    return priv->transform;
}

/**
 @Status Interoperable
*/
- (void)setBackgroundColor:(CGColorRef)color {
    if (color != nil) {
        priv->backgroundColor = *[static_cast<UIColor*>(color) _getColors];
    } else {
        _ClearColorQuad(priv->backgroundColor);
    }

    [CATransaction _setPropertyForLayer:self name:@"backgroundColor" value:(NSObject*)color];
    CGColorRef old = priv->_backgroundColor;
    priv->_backgroundColor = CGColorRetain(color);
    CGColorRelease(old);

    [self setNeedsDisplay];
}

/**
 @Status Interoperable
*/
- (CGColorRef)backgroundColor {
    return priv->_backgroundColor;
}

- (void)_setContentColor:(CGColorRef)newColor {
    if (newColor != nil) {
        priv->contentColor = *[static_cast<UIColor*>(newColor) _getColors];
    } else {
        _ClearColorQuad(priv->contentColor);
    }
    [CATransaction _setPropertyForLayer:self name:@"contentColor" value:static_cast<UIColor*>(newColor)];
}

/**
 @Status Stub
*/
- (void)setBorderColor:(CGColorRef)color {
    UNIMPLEMENTED();
    if (color != nil) {
        priv->borderColor = *[static_cast<UIColor*>(color) _getColors];
    } else {
        _ClearColorQuad(priv->borderColor);
    }

    CGColorRef old = priv->_borderColor;
    priv->_borderColor = CGColorRetain(color);
    CGColorRelease(old);
}

/**
 @Status Stub
*/
- (CGColorRef)borderColor {
    UNIMPLEMENTED();
    return priv->_borderColor;
}

/**
 @Status Stub
*/
- (void)setBorderWidth:(float)width {
    UNIMPLEMENTED();
    priv->borderWidth = width;
}

/**
 @Status Stub
*/
- (float)borderWidth {
    UNIMPLEMENTED();
    return priv->borderWidth;
}

/**
 @Status Stub
*/
- (void)setCornerRadius:(float)radius {
    UNIMPLEMENTED();
    priv->cornerRadius = radius;
}

/**
 @Status Stub
*/
- (float)cornerRadius {
    UNIMPLEMENTED();
    return priv->cornerRadius;
}

/**
 @Status Interoperable
*/
- (void)setContentsScale:(float)scale {
    priv->contentsScale = scale;

    NSNumber* newScale = [[NSNumber alloc] initWithFloat:priv->contentsScale];
    [CATransaction _setPropertyForLayer:self name:@"contentsScale" value:newScale];
    [newScale release];
}

/**
 @Status Stub
*/
- (void)setShadowOffset:(CGSize)size {
    UNIMPLEMENTED();
}

/**
 @Status Stub
*/
- (CGSize)shadowOffset {
    UNIMPLEMENTED();
    CGSize ret;
    ret.width = 0.0f;
    ret.height = -3.0f;
    return ret;
}

/**
 @Status Stub
*/
- (void)setShadowOpacity:(float)opacity {
    UNIMPLEMENTED();
}

/**
 @Status Stub
*/
- (float)shadowOpacity {
    UNIMPLEMENTED();
    return 0.0f;
}

/**
 @Status Stub
*/
- (void)setShadowColor:(CGColorRef)color {
    UNIMPLEMENTED();
}

/**
 @Status Stub
*/
- (CGColorRef)shadowColor {
    UNIMPLEMENTED();
    return CGColorGetConstantColor((CFStringRef) @"BLACK");
}

/**
 @Status Stub
*/
- (void)setShadowRadius:(float)radius {
    UNIMPLEMENTED();
}

/**
 @Status Stub
*/
- (float)shadowRadius {
    UNIMPLEMENTED();
    return 3.0f;
}

/**
 @Status Interoperable
*/
- (BOOL)shouldRasterize {
    return priv->_shouldRasterize;
}

/**
   @Status Interoperable
*/
- (void)setShouldRasterize:(BOOL)shouldRasterize {
    priv->_shouldRasterize = shouldRasterize;
    GetCACompositor()->SetShouldRasterize(priv->_presentationNode, shouldRasterize);
}

/**
 @Status Interoperable
*/
- (float)contentsScale {
    return priv->contentsScale;
}

/**
 @Status Interoperable
*/
- (void)setOpacity:(float)value {
    if (priv->opacity == value) {
        return;
    }

    id<CAAction> action = [self actionForKey:_opacityAction];

    priv->opacity = value;

    if (action != nil) {
        [action runActionForKey:(id)_opacityAction object:self arguments:nil];
    }

    NSNumber* newOpacity = [[NSNumber alloc] initWithFloat:priv->opacity];
    [CATransaction _setPropertyForLayer:self name:@"opacity" value:newOpacity];
    [newOpacity release];
}

/**
 @Status Interoperable
*/
- (float)opacity {
    return priv->opacity;
}

/**
 @Status Interoperable
*/
- (void)setName:(NSString*)name {
    priv->_name.attach([name copy]);
}

/**
 @Status Interoperable
*/
- (NSString*)name {
    return static_cast<NSString*>(priv->_name);
}

/**
 @Status Stub
*/
- (void)setSublayers:(NSArray*)sublayers {
    UNIMPLEMENTED();
}

/**
 @Status Interoperable
*/
- (NSArray*)sublayers {
    return priv->subnodesArray();
}

/**
 @Status Interoperable
*/
- (id<CAAction>)actionForKey:(NSString*)key {
    id<CAAction> ret = nil;

    if ([priv->delegate respondsToSelector:@selector(actionForLayer:forKey:)]) {
        ret = [priv->delegate actionForLayer:self forKey:key];
    }

    if (ret == nil) {
        ret = (id<CAAction>)[priv->_actions objectForKey:key];
    }

    if (ret == nil) {
        ret = (id<CAAction>)[[self class] defaultActionForKey:key];
    }

    if (ret == nil) {
        //  Implicit animation
        bool shouldAnimate = false;

        if (key == _positionAction) {
            if (priv->positionSet) {
                shouldAnimate = true;
            }
        } else if (key == _boundsOriginAction) {
            if (priv->originSet) {
                shouldAnimate = true;
            }
        } else if (key == _boundsSizeAction) {
            if (priv->sizeSet) {
                shouldAnimate = true;
            }
        } else if (key == _boundsAction) {
            if (priv->sizeSet) {
                shouldAnimate = true;
            }
        } else if (key == _transformAction) {
            shouldAnimate = true;
        } else if (key == _opacityAction) {
            shouldAnimate = true;
        }

        if (priv->superlayer == nil) {
            shouldAnimate = false;
        }

        if (shouldAnimate) {
            ret = [CATransaction _implicitAnimationForKey:key];
            if (ret != nil) {
                NSObject* value = GetCACompositor()->getDisplayProperty(priv->_presentationNode, [key UTF8String]);
                [static_cast<CABasicAnimation*>(ret) setFromValue:value];
            }
        }
    }

    if ([static_cast<NSObject*>(ret) isKindOfClass:[NSNull class]]) {
        return nil;
    }

    return ret;
}

/**
 @Status Interoperable
 @Notes Intended override point for subclasses.
*/
+ (id<CAAction>)defaultActionForKey:(NSString*)key {
    return nil;
}

- (DisplayTexture*)_getDisplayTexture {
    //  Update if needed
    [self displayIfNeeded];

    DisplayTexture* ourTexture = NULL;

    //  Create a texture
    if (priv->contents) {
        ourTexture = GetCACompositor()->GetDisplayTextureForCGImage(priv->contents, true);
    }

    return ourTexture;
}

/**
 @Status Stub
*/
- (CALayer*)presentationLayer {
    UNIMPLEMENTED();
    return nil;
}

/**
 @Status Stub
*/
- (instancetype)initWithLayer:(CALayer*)layerToCopy {
    UNIMPLEMENTED();
    return self;
}

/**
 @Status Interoperable
*/
- (void)setNeedsDisplayOnBoundsChange:(BOOL)needsDisplayOnBoundsChange {
    priv->needsDisplayOnBoundsChange = needsDisplayOnBoundsChange;
}

/**
 @Status Interoperable
*/
- (BOOL)needsDisplayOnBoundsChange {
    return priv->needsDisplayOnBoundsChange;
}

/**
 @Status Interoperable
*/
- (CALayer*)hitTest:(CGPoint)point {
    if (![self _isVisibleOrHitable]) {
        return nil;
    }

    //  Convert point to our locality
    CAPoint3D pt;
    pt.x = point.x;
    pt.y = point.y;
    pt.z = 0.0f;

    CATransform3D curTransform;
    curTransform = CATransform3DMakeTranslation(0, 0, 0);

    curTransform = CATransform3DTranslate(curTransform,
                                          -(priv->position.x - priv->bounds.size.width * priv->anchorPoint.x),
                                          -(priv->position.y - priv->bounds.size.height * priv->anchorPoint.y),
                                          0.0f);
    curTransform = CATransform3DConcat(curTransform, priv->transform);
    // curTransform.Translate(-priv->bounds.origin.x, -priv->bounds.origin.y, 0.0f);

    CATransform3DTransformPoints(curTransform, &pt, 1);

    point.x = pt.x;
    point.y = pt.y;

    //  Check sublayers
    LLTREE_FOREACH_REVERSE(curSublayer, priv) {
        CALayer* ret = [curSublayer->self hitTest:point];

        if (ret != nil) {
            return ret;
        }
    }

    if (point.x >= priv->bounds.origin.x && point.y >= priv->bounds.origin.y && point.x < priv->bounds.origin.x + priv->bounds.size.width &&
        point.y < priv->bounds.origin.x + priv->bounds.size.height) {
        return self;
    }

    return nil;
}

/**
 @Status Interoperable
*/
- (BOOL)containsPoint:(CGPoint)point {
    if (point.x >= priv->bounds.origin.x && point.y >= priv->bounds.origin.y && point.x < priv->bounds.origin.x + priv->bounds.size.width &&
        point.y < priv->bounds.origin.x + priv->bounds.size.height) {
        return TRUE;
    }

    return FALSE;
}

- (void)dealloc {
    TraceVerbose(TAG, L"CALayer dealloced");
    [self removeAllAnimations];
    [self removeFromSuperlayer];
    while (priv->firstChild) {
        [priv->firstChild->self removeFromSuperlayer];
    }

    [_contentsElement release];

    delete priv;
    priv = NULL;
    [super dealloc];
}

/**
 @Status Interoperable
 @Public No
*/
- (id)valueForUndefinedKey:(NSString*)keyPath {
    return [priv->_undefinedKeys valueForKey:keyPath];
}

/**
 @Status Interoperable
 @Public No
*/
- (id)valueForKeyPath:(NSString*)keyPath {
    char* pPath = (char*)[keyPath UTF8String];
    if (strcmp(pPath, "position.x") == 0) {
        return [NSNumber numberWithFloat:priv->position.x];
    } else if (strcmp(pPath, "position.y") == 0) {
        return [NSNumber numberWithFloat:priv->position.y];
    } else if (strcmp(pPath, "transform.rotation.z") == 0 || strcmp(pPath, "transform.rotation") == 0) {
        CATransform3D curTransform = [self transform];
        Quaternion qval;
        qval.CreateFromMatrix(reinterpret_cast<float*>(&curTransform));
        return [NSNumber numberWithFloat:(float)-qval.roll() * 180.0f / M_PI];
    } else if (strcmp(pPath, "transform.rotation.x") == 0 || strcmp(pPath, "transform.rotation.y") == 0) {
        TraceVerbose(TAG, L"Should get rotation");
        return [NSNumber numberWithFloat:0.0f];
    } else if (strcmp(pPath, "transform.scale") == 0) {
        CATransform3D curTransform = [self transform];
        float scale[3];
        CATransform3DGetScale(curTransform, scale);
        return [NSNumber numberWithFloat:(scale[0] + scale[1] + scale[2]) / 3.0f];
    } else if (strcmp(pPath, "transform.scale.x") == 0) {
        CATransform3D curTransform = [self transform];
        float scale[3];
        CATransform3DGetScale(curTransform, scale);
        return [NSNumber numberWithFloat:scale[0]];
    } else if (strcmp(pPath, "transform.scale.y") == 0) {
        CATransform3D curTransform = [self transform];
        float scale[3];
        CATransform3DGetScale(curTransform, scale);
        return [NSNumber numberWithFloat:scale[1]];
    } else if (strcmp(pPath, "transform.scale.z") == 0) {
        CATransform3D curTransform = [self transform];
        float scale[3];
        CATransform3DGetScale(curTransform, scale);
        return [NSNumber numberWithFloat:scale[2]];
    } else if (strcmp(pPath, "transform.translation") == 0) {
        CATransform3D curTransform = [self transform];
        float translation[3];
        CATransform3DGetPosition(curTransform, translation);
        return [NSValue valueWithCGSize:CGSizeMake(translation[0] - priv->position.x, translation[1] - priv->position.y)];
    } else if (strcmp(pPath, "transform.translation.x") == 0) {
        CATransform3D curTransform = [self transform];
        float translation[3];
        CATransform3DGetPosition(curTransform, translation);
        return [NSNumber numberWithFloat:translation[0]];
    } else if (strcmp(pPath, "transform.translation.y") == 0) {
        CATransform3D curTransform = [self transform];
        float translation[3];
        CATransform3DGetPosition(curTransform, translation);
        return [NSNumber numberWithFloat:translation[1]];
    } else if (strcmp(pPath, "transform.translation.z") == 0) {
        CATransform3D curTransform = [self transform];
        float translation[3];
        CATransform3DGetPosition(curTransform, translation);
        return [NSNumber numberWithFloat:translation[2]];
    } else if (strcmp(pPath, "bounds.origin") == 0) {
        CGRect bounds = [self bounds];
        return [NSValue valueWithCGPoint:bounds.origin];
    } else if (strcmp(pPath, "bounds.size") == 0) {
        CGRect bounds = [self bounds];
        return [NSValue valueWithCGSize:bounds.size];
    } else if (strcmp(pPath, "bounds.size.width") == 0) {
        CGRect bounds = [self bounds];
        return [NSNumber numberWithFloat:bounds.size.width];
    } else if (strcmp(pPath, "bounds.size.height") == 0) {
        CGRect bounds = [self bounds];
        return [NSNumber numberWithFloat:bounds.size.height];
    } else if (strcmp(pPath, "bounds.origin.x") == 0) {
        CGRect bounds = [self bounds];
        return [NSNumber numberWithFloat:bounds.origin.x];
    } else if (strcmp(pPath, "bounds.origin.y") == 0) {
        CGRect bounds = [self bounds];
        return [NSNumber numberWithFloat:bounds.origin.y];
    }

    return [super valueForKeyPath:keyPath];
}

/**
 @Status Interoperable
 @Public No
*/
- (void)setValue:(id)value forUndefinedKey:(NSString*)key {
    if (priv->_undefinedKeys == nil) {
        priv->_undefinedKeys.attach([NSMutableDictionary new]);
    }
    [priv->_undefinedKeys setObject:value forKey:key];
}

/**
 @Status Interoperable
 @Public No
*/
- (void)setValue:(id)value forKeyPath:(NSString*)keyPath {
    if ([keyPath isEqual:@"transform.scale"]) {
        CATransform3D curTransform;
        float scale = [value floatValue];

        curTransform = [self transform];

        curTransform.m11 = scale;
        curTransform.m22 = scale;
        curTransform.m33 = 1.0f;
        curTransform.m44 = 1.0f;

        [self setTransform:curTransform];
    } else {
        [super setValue:value forKeyPath:keyPath];
    }
}

/**
 @Status Stub
*/
- (void)setMask:(CALayer*)mask {
    UNIMPLEMENTED();
    id oldLayer = priv->maskLayer;
    priv->maskLayer = [mask retain];
    [oldLayer release];
    [mask removeFromSuperlayer];
    priv->hasNewContents = TRUE;
}

/**
 @Status Stub
*/
- (CALayer*)mask {
    UNIMPLEMENTED();
    TraceVerbose(TAG, L"mask not supported");
    return nil;
}

/**
 @Status Stub
*/
- (void)setShadowPath:(CGPathRef)path {
    UNIMPLEMENTED();
    TraceVerbose(TAG, L"setShadowPath not supported");
}

/**
 @Status Stub
*/
- (CGPathRef)shadowPath {
    UNIMPLEMENTED();
    return nil;
}

/**
 @Status Interoperable
*/
- (NSArray*)actions {
    return static_cast<NSArray*>(priv->_actions);
}

/**
 @Status Interoperable
*/
- (void)setActions:(NSArray*)actions {
    priv->_actions.attach([actions copy]);
}

/**
 @Status Interoperable
*/
- (CGPoint)convertPoint:(CGPoint)point toLayer:(CALayer*)toLayer {
    return [CALayer convertPoint:point fromLayer:self toLayer:toLayer];
}

/**
 @Status Interoperable
*/
- (CGRect)convertRect:(CGRect)rect toLayer:(CALayer*)toLayer {
    return [CALayer convertRect:rect fromLayer:self toLayer:toLayer];
}

/**
 @Status Interoperable
*/
- (CGPoint)convertPoint:(CGPoint)point fromLayer:(CALayer*)fromLayer {
    return [CALayer convertPoint:point fromLayer:fromLayer toLayer:self];
}

/**
 @Status Interoperable
*/
- (CGRect)convertRect:(CGRect)rect fromLayer:(CALayer*)fromLayer {
    return [CALayer convertRect:rect fromLayer:fromLayer toLayer:self];
}

/**
 @Status Interoperable
*/
- (void)layoutIfNeeded {
    CALayer* curLayer = self;

    while (curLayer != nil) {
        if (curLayer->priv->superlayer == nil || ((CALayer*)curLayer->priv->superlayer)->priv->needsLayout == FALSE) {
            DoLayerLayouts(curLayer, false);
            return;
        }

        curLayer = curLayer->priv->superlayer;
    }
}

- (void)validateDisplayHierarchy {
    DoLayerLayouts(self, true);
    DoDisplayList(self);
}

- (void)discardDisplayHierarchy {
    DiscardLayerContents(self);
}

/**
 @Status Interoperable
*/
- (void)setNeedsLayout {
    priv->needsLayout = TRUE;
    GetCACompositor()->DisplayTreeChanged();
}

- (void)_setShouldLayout {
    //  Ensure that we don't repeatedly call layoutSubviews if view sizes start arguing
    if (priv->didLayout) {
        return;
    }
    [self setNeedsLayout];
}

/**
 @Status Interoperable
*/
- (void)layoutSublayers {
    if ([priv->delegate respondsToSelector:@selector(layoutSublayersOfLayer:)]) {
        [priv->delegate layoutSublayersOfLayer:self];
    }
}

- (DisplayNode*)_presentationNode {
    return priv->_presentationNode;
}

- (int)_pixelWidth {
    return (int)priv->bounds.size.width * priv->contentsScale;
}

- (int)_pixelHeight {
    return (int)priv->bounds.size.height * priv->contentsScale;
}

- (void)_setRootLayer:(BOOL)isRootLayer {
    priv->isRootLayer = isRootLayer;
}

#define MAX_DEPTH 32

void GetLayerTransform(CALayer* layer, CGAffineTransform* outTransform) {
    //  Work backwards to its root layer
    CALayer* layerList[MAX_DEPTH];
    int layerListLen = 0;

    CALayer* curLayer = (CALayer*)layer;

    while (curLayer != nil) {
        assert(layerListLen < MAX_DEPTH);
        layerList[layerListLen++] = curLayer;

        curLayer = (CALayer*)curLayer->priv->superlayer;
    }

    //  Build transform
    CGPoint origin;

    *outTransform = CGAffineTransformMakeTranslation(0.0f, 0.0f);

    origin.x = 0;
    origin.y = 0;

    for (int i = layerListLen - 1; i >= 0; i--) {
        curLayer = layerList[i];

        *outTransform =
            CGAffineTransformTranslate(*outTransform, curLayer->priv->position.x - origin.x, curLayer->priv->position.y - origin.y);

        CGAffineTransform transform;

        transform.a = curLayer->priv->transform.m[0][0];
        transform.b = curLayer->priv->transform.m[0][1];
        transform.c = curLayer->priv->transform.m[1][0];
        transform.d = curLayer->priv->transform.m[1][1];
        transform.tx = curLayer->priv->transform.m[3][0];
        transform.ty = curLayer->priv->transform.m[3][1];

        *outTransform = CGAffineTransformConcat(transform, *outTransform);
        *outTransform = CGAffineTransformTranslate(*outTransform, -curLayer->priv->bounds.origin.x, -curLayer->priv->bounds.origin.y);

        //  Calculate new center point
        origin.x = curLayer->priv->bounds.size.width * curLayer->priv->anchorPoint.x;
        origin.y = curLayer->priv->bounds.size.height * curLayer->priv->anchorPoint.y;
    }
}

/**
 @Status Interoperable
*/
+ (CGPoint)convertPoint:(CGPoint)point fromLayer:(CALayer*)fromLayer toLayer:(CALayer*)toLayer {
    if (fromLayer) {
        //  Convert the point to center-based position
        point.x -= fromLayer->priv->bounds.size.width * fromLayer->priv->anchorPoint.x;
        point.y -= fromLayer->priv->bounds.size.height * fromLayer->priv->anchorPoint.y;

        //  Convert to world-view
        CGAffineTransform fromTransform;
        GetLayerTransform(fromLayer, &fromTransform);
        point = CGPointApplyAffineTransform(point, fromTransform);
    }

    if (toLayer) {
        CGAffineTransform toTransform;
        GetLayerTransform(toLayer, &toTransform);
        toTransform = CGAffineTransformInvert(toTransform);
        point = CGPointApplyAffineTransform(point, toTransform);

        //  Convert the point from center-based position
        point.x += toLayer->priv->bounds.size.width * toLayer->priv->anchorPoint.x;
        point.y += toLayer->priv->bounds.size.height * toLayer->priv->anchorPoint.y;
    }

    return point;
}

+ (CGRect)convertRect:(CGRect)pos fromLayer:(CALayer*)fromLayer toLayer:(CALayer*)toLayer {
    CGRect ret;

    CGPoint pt1 = pos.origin;
    CGPoint pt2;

    pt2 = pos.origin;
    pt2.x += pos.size.width;
    pt2.y += pos.size.height;

    pt1 = [self convertPoint:pt1 fromLayer:fromLayer toLayer:toLayer];
    pt2 = [self convertPoint:pt2 fromLayer:fromLayer toLayer:toLayer];

    ret.origin.x = pt1.x < pt2.x ? pt1.x : pt2.x;
    ret.origin.y = pt1.y < pt2.y ? pt1.y : pt2.y;
    ret.size.width = fabsf(pt1.x - pt2.x);
    ret.size.height = fabsf(pt1.y - pt2.y);

    return ret;
}

- (NSObject*)presentationValueForKey:(NSString*)key {
    return GetCACompositor()->getDisplayProperty(priv->_presentationNode, [key UTF8String]);
}

- (void)_setZIndex:(int)zIndex {
    NSNumber* newZIndex = [[NSNumber alloc] initWithInt:zIndex];
    [CATransaction _setPropertyForLayer:self name:@"zIndex" value:newZIndex];
    [newZIndex release];
}

/**
 @Status Stub
 @Notes
*/
- (BOOL)needsDisplay {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
+ (BOOL)needsDisplayForKey:(NSString*)key {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
- (void)setNeedsDisplayInRect:(CGRect)theRect {
    UNIMPLEMENTED();
}

/**
 @Status Stub
 @Notes
*/
- (CFTimeInterval)convertTime:(CFTimeInterval)timeInterval fromLayer:(CALayer*)layer {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
- (BOOL)needsLayout {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
- (instancetype)initWithCoder:(NSCoder*)decoder {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
- (void)encodeWithCoder:(NSCoder*)encoder {
    UNIMPLEMENTED();
}

/**
 @Status Stub
 @Notes
*/
- (id)modelLayer {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
- (BOOL)contentsAreFlipped {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
- (CGSize)preferredFrameSize {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
- (CFTimeInterval)convertTime:(CFTimeInterval)timeInterval toLayer:(CALayer*)layer {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
- (void)scrollPoint:(CGPoint)thePoint {
    UNIMPLEMENTED();
}

/**
 @Status Stub
 @Notes
*/
- (void)scrollRectToVisible:(CGRect)theRect {
    UNIMPLEMENTED();
}

/**
 @Status Stub
 @Notes
*/
- (BOOL)shouldArchiveValueForKey:(NSString*)key {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
 @Notes
*/
+ (id)defaultValueForKey:(NSString*)key {
    UNIMPLEMENTED();
    return StubReturn();
}

@end

void SetCACompositor(CACompositorInterface* compositorInterface) {
    _globalCompositor = compositorInterface;
}

CACompositorInterface* GetCACompositor() {
    return _globalCompositor;
}
