//******************************************************************************
//
// Copyright (c) 2016 Intel Corporation. All rights reserved.
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

#pragma once
#include "GLKitExport.h"
#include <math.h>

#if (!defined(__clang__))
#include <Windows.h>
#else
#import <Foundation/Foundation.h>
#endif

#if (!defined(__clang__) && defined(_MSC_VER) && !defined(__attribute__))
//#define __attribute__(x)
#ifdef STUB_METHOD
#undef STUB_METHOD
#endif
#define STUB_METHOD

#else
#include "StubIncludes.h"
#endif

#if defined(_M_IX86) || defined(_M_X64)
#define USE_SSE 1
#ifndef GLK_GLOBALCONST
#define GLK_GLOBALCONST extern const __declspec(selectany)
#endif
#endif

#if defined(USE_SSE)
#include "immintrin.h"
#include <intrin.h>
#endif

#if defined(_MSC_VER) && !defined(_M_ARM) && (!_MANAGED) && (!_M_CEE) && (!defined(_M_IX86_FP) || (_M_IX86_FP > 1)) && defined(USE_SSE) && \
    !defined(GLK_VECTORCALL)
#if ((_MSC_FULL_VER >= 170065501) && (_MSC_VER < 1800)) || (_MSC_FULL_VER >= 180020418)
#define GLK_VECTORCALL 1
#endif
#endif

#if GLK_VECTORCALL
#define GLK_CALLCONV __vectorcall
#else
#define GLK_CALLCONV __fastcall
#endif

#define COMPARISON_EPSILON 0.0000025f
#define _GLK_MIN(a, b) ((a) < (b) ? (a) : (b))
#define _GLK_MAX(a, b) ((a) > (b) ? (a) : (b))

#if (!defined(__clang__))
#define GLK_PREFIX_ALIGN(x) __declspec(align(x))
#define GLK_POSTFIX_ALIGN(x)
#else
#define GLK_PREFIX_ALIGN(x)
#define GLK_POSTFIX_ALIGN(x) __attribute__((__aligned__(x)))
#endif

typedef struct _GLKVector2 {
    union {
        struct {
            float x, y;
        };
        struct {
            float s, t;
        };
        float v[2];
    };
} GLKVector2;

typedef struct _GLKVector3 {
    union {
        struct {
            float x, y, z;
        };
        struct {
            float s, t, p;
        };
        struct {
            float r, g, b;
        };
        float v[3];
    };
} GLKVector3;

typedef struct _GLKVector4 {
    union {
        struct {
            float x, y, z, w;
        };
        struct {
            float r, g, b, a;
        };
        struct {
            float s, t, p, q;
        };
        float v[4];
    };
} GLK_POSTFIX_ALIGN(16) GLKVector4;

typedef struct _GLKMatrix2 {
    union {
        struct {
            float m00, m01;
            float m10, m11;
        };
        float m[4];
    };
} GLKMatrix2;

typedef struct _GLKMatrix3 {
    union {
        struct {
            float m00, m01, m02;
            float m10, m11, m12;
            float m20, m21, m22;
        };
        float m[9];
    };
} GLK_POSTFIX_ALIGN(16) GLKMatrix3;

typedef struct _GLKMatrix4 {
    union {
        struct {
            float m00, m01, m02, m03;
            float m10, m11, m12, m13;
            float m20, m21, m22, m23;
            float m30, m31, m32, m33;
        };
        float m[16];
    };
} GLK_POSTFIX_ALIGN(16) GLKMatrix4;

typedef struct _GLKQuaternion {
    union {
        struct {
            GLKVector3 v;
            float s;
        };
        struct {
            float x, y, z, w;
        };
        float q[4];
    };
} GLK_POSTFIX_ALIGN(16) GLKQuaternion;

inline float GLKQuaternionAngle(const GLKQuaternion quat) {
    return 2.f * acosf(quat.w);
}

typedef struct _IntOrFloat {
    union {
        float fl32;
        int int32;
    };
} IntOrFloat;

inline GLKVector3 GLKQuaternionAxis(const GLKQuaternion quat) {
    GLKVector3 res;

    float mf = 1.f / sinf(acosf(quat.w));
    res.x = mf * quat.x;
    res.y = mf * quat.y;
    res.z = mf * quat.z;

    return res;
}

GLKIT_EXPORT GLKVector3 GLKMathProject(GLKVector3 object, GLKMatrix4 model, GLKMatrix4 projection, int* viewport) STUB_METHOD;
GLKIT_EXPORT GLKVector3 GLKMathUnproject(GLKVector3 window, GLKMatrix4 model, GLKMatrix4 projection, int* viewport, bool* success)
    STUB_METHOD;

#if 0
//#if (!defined(USE_SSE))
inline bool IsSseEnabled() { return false; };
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeIdentity();
GLKIT_EXPORT GLKMatrix3 GLKMatrix3Invert(GLKMatrix3 m, bool* isInvertible);
GLKIT_EXPORT GLKMatrix3 GLKMatrix3InvertAndTranspose(GLKMatrix3 m, bool* isInvertible);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeRotation(float rad, float x, float y, float z); //Implemented, not tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeXRotation(float rad); //Implemented, tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeYRotation(float rad); //Implemented, tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeZRotation(float rad); //Implemented, tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeLookAt(float eyeX, float eyeY, float eyeZ, float lookX, float lookY, float lookZ, float upX, float upY, float upZ); // Implemented, tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Multiply(GLKMatrix4 m1, GLKMatrix4 m2); //Implemented, partially tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeFrustum(float left, float right, float bottom, float top, float near, float far); //Implemented, not tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Rotate(GLKMatrix4 m, float rad, float x, float y, float z);   //Implemented, not tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakePerspective(float yrad, float aspect, float near, float far); //Implemented, tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeOrtho(float left, float right, float bot, float top, float near, float far);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4RotateWithVector3(GLKMatrix4 matrix, float radians, GLKVector3 axisVector);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4RotateWithVector4(GLKMatrix4 matrix, float radians, GLKVector4 axisVector);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4RotateX(GLKMatrix4 m, float rad); //Implemented, tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4RotateY(GLKMatrix4 m, float rad); //Implemented, tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4RotateZ(GLKMatrix4 m, float rad); //Implemented, tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Translate(GLKMatrix4 m, float x, float y, float z); //Implemented, not tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4TranslateWithVector3(GLKMatrix4 matrix, GLKVector3 translationVector);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4TranslateWithVector4(GLKMatrix4 matrix, GLKVector4 translationVector);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Scale(GLKMatrix4 m, float x, float y, float z);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4ScaleWithVector3(GLKMatrix4 matrix, GLKVector3 scaleVector);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4ScaleWithVector4(GLKMatrix4 matrix, GLKVector4 scaleVector);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Add(GLKMatrix4 matrixLeft, GLKMatrix4 matrixRight);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Subtract(GLKMatrix4 matrixLeft, GLKMatrix4 matrixRight);
GLKIT_EXPORT GLKVector3 GLKMatrix4MultiplyVector3(GLKMatrix4 m, GLKVector3 vec);
GLKIT_EXPORT GLKVector3 GLKMatrix4MultiplyVector3WithTranslation(GLKMatrix4 m, GLKVector3 vec);
GLKIT_EXPORT void GLKMatrix4MultiplyVector3ArrayWithTranslation(GLKMatrix4 m, GLKVector3* vecs, size_t numVecs);
GLKIT_EXPORT void GLKMatrix4MultiplyVector3Array(GLKMatrix4 m, GLKVector3* vecs, size_t numVecs);
GLKIT_EXPORT void GLKMatrix4MultiplyVector4Array(GLKMatrix4 m, GLKVector4* vecs, size_t numVecs);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Transpose(GLKMatrix4 mat);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4InvertAndTranspose(GLKMatrix4 matrix, bool* isInvertible);
GLKIT_EXPORT GLKVector4 GLKMatrix4MultiplyVector4(GLKMatrix4 m, GLKVector4 vec); //Implemented, partially tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Invert(GLKMatrix4 m, bool* isInvertible); //Implemented, tested
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeTranslation(float x, float y, float z);
#else
bool IsSseEnabled();
/// Constants
GLKIT_EXPORT const GLKMatrix3 GLKMatrix3Identity;
GLKIT_EXPORT const GLKMatrix4 GLKMatrix4Identity;
GLKIT_EXPORT const GLKQuaternion GLKQuaternionIdentity;

/// Function definitions
GLKIT_EXPORT GLKMatrix3 GLKMatrix3FromMatrix4(GLKMatrix4 m);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Make(float m00,
                                       float m01,
                                       float m02,
                                       float m03,
                                       float m10,
                                       float m11,
                                       float m12,
                                       float m13,
                                       float m20,
                                       float m21,
                                       float m22,
                                       float m23,
                                       float m30,
                                       float m31,
                                       float m32,
                                       float m33);
GLKIT_EXPORT GLKMatrix3 GLKMatrix3Make(float m00, float m01, float m02, float m10, float m11, float m12, float m20, float m21, float m22);
GLKIT_EXPORT GLKMatrix3 GLKMatrix3Transpose(GLKMatrix3 mat);
GLKIT_EXPORT GLKMatrix3 GLKMatrix3Multiply(GLKMatrix3 matrixLeft, GLKMatrix3 matrixRight) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3Rotate(GLKMatrix3 matrix, float radians, float x, float y, float z) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3RotateWithVector3(GLKMatrix3 matrix, float radians, GLKVector3 axisVector) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3RotateWithVector4(GLKMatrix3 matrix, float radians, GLKVector4 axisVector) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3RotateX(GLKMatrix3 matrix, float radians) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3RotateY(GLKMatrix3 matrix, float radians) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3RotateZ(GLKMatrix3 matrix, float radians) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3Scale(GLKMatrix3 matrix, float sx, float sy, float sz) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3ScaleWithVector3(GLKMatrix3 matrix, GLKVector3 scaleVector) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3ScaleWithVector4(GLKMatrix3 matrix, GLKVector4 scaleVector) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3Add(GLKMatrix3 matrixLeft, GLKMatrix3 matrixRight) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3Subtract(GLKMatrix3 matrixLeft, GLKMatrix3 matrixRight) STUB_METHOD;
GLKIT_EXPORT GLKVector3 GLKMatrix3MultiplyVector3(GLKMatrix3 matrixLeft, GLKVector3 vectorRight);
GLKIT_EXPORT void GLKMatrix3MultiplyVector3Array(GLKMatrix3 matrix, GLKVector3* vectors, size_t vectorCount) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3
GLKMatrix3MakeAndTranspose(float m00, float m01, float m02, float m10, float m11, float m12, float m20, float m21, float m22);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeAndTranspose(float m00,
                                                   float m01,
                                                   float m02,
                                                   float m03,
                                                   float m10,
                                                   float m11,
                                                   float m12,
                                                   float m13,
                                                   float m20,
                                                   float m21,
                                                   float m22,
                                                   float m23,
                                                   float m30,
                                                   float m31,
                                                   float m32,
                                                   float m33);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeWithArray(float* values);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeWithArrayAndTranspose(float* values);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeWithColumns(GLKVector4 r0, GLKVector4 r1, GLKVector4 r2, GLKVector4 r3);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeWithRows(GLKVector4 r0, GLKVector4 r1, GLKVector4 r2, GLKVector4 r3);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeWithQuaternion(GLKQuaternion quaternion) STUB_METHOD;
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeOrthonormalXform(GLKVector3 right, GLKVector3 up, GLKVector3 forward, GLKVector3 pos);
GLKIT_EXPORT GLKMatrix3 GLKMatrix3MakeWithArray(float* values);
GLKIT_EXPORT GLKMatrix3 GLKMatrix3MakeWithArrayAndTranspose(float* values);
GLKIT_EXPORT GLKMatrix3 GLKMatrix3MakeWithColumns(GLKVector3 r0, GLKVector3 r1, GLKVector3 r2);
GLKIT_EXPORT GLKMatrix3 GLKMatrix3MakeWithRows(GLKVector3 r0, GLKVector3 r1, GLKVector3 r2);
GLKIT_EXPORT GLKMatrix3 GLKMatrix3MakeWithQuaternion(GLKQuaternion quaternion) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3MakeScale(float sx, float sy, float sz) STUB_METHOD;
GLKIT_EXPORT GLKMatrix2 GLKMatrix3GetMatrix2(GLKMatrix3 matrix);
GLKIT_EXPORT GLKVector3 GLKMatrix3GetColumn(GLKMatrix3 matrix, int column) STUB_METHOD;
GLKIT_EXPORT GLKVector3 GLKMatrix3GetRow(GLKMatrix3 matrix, int row) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3SetColumn(GLKMatrix3 matrix, int column, GLKVector3 vector) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3SetRow(GLKMatrix3 matrix, int row, GLKVector3 vector) STUB_METHOD;
GLKIT_EXPORT GLKMatrix3 GLKMatrix3MakeRotation(float rad, float x, float y, float z);
GLKIT_EXPORT GLKMatrix3 GLKMatrix3MakeXRotation(float rad);
GLKIT_EXPORT GLKMatrix3 GLKMatrix3MakeYRotation(float rad);
GLKIT_EXPORT GLKMatrix3 GLKMatrix3MakeZRotation(float rad);
GLKIT_EXPORT GLKMatrix2 GLKMatrix4GetMatrix2(GLKMatrix4 m);
GLKIT_EXPORT GLKMatrix3 GLKMatrix4GetMatrix3(GLKMatrix4 m);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4SetColumn(GLKMatrix4 matrix, int column, GLKVector4 vector) STUB_METHOD;
GLKIT_EXPORT GLKMatrix4 GLKMatrix4SetRow(GLKMatrix4 matrix, int row, GLKVector4 vector) STUB_METHOD;
GLKIT_EXPORT GLKVector4 GLKMatrix4GetColumn(GLKMatrix4 matrix, int column) STUB_METHOD;
GLKIT_EXPORT GLKVector4 GLKMatrix4GetRow(GLKMatrix4 matrix, int row) STUB_METHOD;
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeScale(float x, float y, float z);
GLKIT_EXPORT GLKVector3 GLKMatrix4MultiplyAndProjectVector3(GLKMatrix4 matrixLeft, GLKVector3 vectorRight) STUB_METHOD;
GLKIT_EXPORT void GLKMatrix4MultiplyAndProjectVector3Array(GLKMatrix4 matrix, GLKVector3* vectors, size_t vectorCount) STUB_METHOD;

/// SSE Optimized functions
GLKIT_EXPORT GLKMatrix3 GLKMatrix3MakeIdentity();
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeIdentity();
GLKIT_EXPORT GLKQuaternion GLKQuaternionMakeIdentity();
GLKIT_EXPORT GLKMatrix4
GLKMatrix4MakeLookAt(float eyeX, float eyeY, float eyeZ, float lookX, float lookY, float lookZ, float upX, float upY, float upZ);
GLKIT_EXPORT GLKVector4 GLKMatrix4MultiplyVector4(const GLKMatrix4 m, const GLKVector4 vec);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Transpose(const GLKMatrix4 mat);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4InvertAndTranspose(const GLKMatrix4 matrix, BOOL* isInvertible);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Invert(const GLKMatrix4 m, BOOL* isInvertible);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeXRotation(float rad);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeYRotation(float rad);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeZRotation(float rad);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeTranslation(float x, float y, float z);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4RotateX(const GLKMatrix4 m, float rad);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4RotateY(const GLKMatrix4 m, float rad);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4RotateZ(const GLKMatrix4 m, float rad);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Rotate(const GLKMatrix4 m, float rad, float x, float y, float z);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeOrtho(float left, float right, float bot, float top, float near, float far);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4RotateWithVector3(const GLKMatrix4 matrix, float radians, const GLKVector3 axisVector);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4RotateWithVector4(const GLKMatrix4 matrix, float radians, const GLKVector4 axisVector);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Multiply(const GLKMatrix4 m2, const GLKMatrix4 m1);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeFrustum(float left, float right, float bottom, float top, float near, float far);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakeRotation(float rad, float x, float y, float z);
GLKIT_EXPORT GLKVector3 GLKMatrix4MultiplyVector3(const GLKMatrix4 m, const GLKVector3 vec);
GLKIT_EXPORT GLKVector3 GLKMatrix4MultiplyVector3WithTranslation(const GLKMatrix4 m, const GLKVector3 vec);
GLKIT_EXPORT void GLKMatrix4MultiplyVector4Array(const GLKMatrix4 m, GLKVector4* vecs, size_t numVecs);
GLKIT_EXPORT void GLKMatrix4MultiplyVector3ArrayWithTranslation(const GLKMatrix4 m, GLKVector3* vecs, size_t numVecs);
GLKIT_EXPORT void GLKMatrix4MultiplyVector3Array(const GLKMatrix4 m, GLKVector3* vecs, size_t numVecs);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4MakePerspective(float yrad, float aspect, float near, float far);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4TranslateWithVector3(const GLKMatrix4 matrix, const GLKVector3 translationVector);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4TranslateWithVector4(const GLKMatrix4 matrix, const GLKVector4 translationVector);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Scale(const GLKMatrix4 m, float x, float y, float z);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4ScaleWithVector3(const GLKMatrix4 matrix, const GLKVector3 scaleVector);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4ScaleWithVector4(const GLKMatrix4 matrix, const GLKVector4 scaleVector);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Add(const GLKMatrix4 matrixLeft, const GLKMatrix4 matrixRight);
GLKIT_EXPORT GLKMatrix4 GLKMatrix4Subtract(const GLKMatrix4 matrixLeft, const GLKMatrix4 matrixRight);
GLKIT_EXPORT GLKMatrix3 GLKMatrix3Invert(const GLKMatrix3 m, BOOL* isInvertible);
GLKIT_EXPORT GLKMatrix3 GLKMatrix3InvertAndTranspose(const GLKMatrix3 m, BOOL* isInvertible);

GLKIT_EXPORT GLKVector3 GLKQuaternionRotateVector3(GLKQuaternion q, GLKVector3 v);
GLKIT_EXPORT void GLKQuaternionRotateVector3Array(GLKQuaternion q, GLKVector3* vecs, size_t numVecs);
GLKIT_EXPORT void GLKQuaternionRotateVector4Array(GLKQuaternion q, GLKVector4* vecs, size_t numVecs);
GLKIT_EXPORT GLKQuaternion GLKQuaternionMakeWithMatrix3(GLKMatrix3 mat);
GLKIT_EXPORT GLKQuaternion GLKQuaternionMakeWithMatrix4(GLKMatrix4 mat);
#endif

/// Objective C exports
#if (defined(__clang__))
GLKIT_EXPORT NSString* NSStringFromGLKMatrix2(GLKMatrix2 matrix) STUB_METHOD;
GLKIT_EXPORT NSString* NSStringFromGLKMatrix3(GLKMatrix3 matrix) STUB_METHOD;
GLKIT_EXPORT NSString* NSStringFromGLKMatrix4(GLKMatrix4 matrix) STUB_METHOD;

GLKIT_EXPORT NSString* NSStringFromGLKVector2(GLKVector2 vector) STUB_METHOD;
GLKIT_EXPORT NSString* NSStringFromGLKVector3(GLKVector3 vector) STUB_METHOD;
GLKIT_EXPORT NSString* NSStringFromGLKVector4(GLKVector4 vector) STUB_METHOD;

GLKIT_EXPORT NSString* NSStringFromGLKQuaternion(GLKQuaternion quaternion) STUB_METHOD;
#endif