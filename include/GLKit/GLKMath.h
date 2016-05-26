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

#pragma once

#include <math.h>
#include <float.h>
#include "GLKitExport.h"
#include "GLKMathDefs.h"
#include <memory.h>

#if (!defined(__clang__) && defined(USE_SSE))
#include "GLKMathSse2.h"
#else

// --------------------------------------------------------------------------------

/**
 @Status Interoperable
*/
inline float GLKMathDegreesToRadians(float deg) {
    return deg * (float)M_PI / 180.f;
}

/**
 @Status Interoperable
*/
inline float GLKMathRadiansToDegrees(float rad) {
    return rad * 180.f / (float)M_PI;
}

// --------------------------------------------------------------------------------
// Matrices


/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3Make(float x, float y, float z) {
    GLKVector3 res;

    res.x = x;
    res.y = y;
    res.z = z;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4Make(float x, float y, float z, float w) {
    GLKVector4 res;

    res.x = x;
    res.y = y;
    res.z = z;
    res.w = w;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4MakeFromVec3(GLKVector3 v) {
    GLKVector4 res;

    res.x = v.x;
    res.y = v.y;
    res.z = v.z;
    res.w = 0.f;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3MakeWithArray(float* values) {
    GLKVector3 res;

    res.x = values[0];
    res.y = values[1];
    res.z = values[2];

    return res;
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4MakeWithArray(float* values) {
    GLKVector4 res;

    res.x = values[0];
    res.y = values[1];
    res.z = values[2];
    res.w = values[3];

    return res;
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4MakeWithVector3(GLKVector3 v, float w) {
    GLKVector4 res;

    res.x = v.x;
    res.y = v.y;
    res.z = v.z;
    res.w = w;

    return res;
}

/**
 @Status Interoperable
*/
inline float GLKVector3DotProduct(GLKVector3 v1, GLKVector3 v2) {
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

/**
 @Status Interoperable
*/
inline float GLKVector4DotProduct(GLKVector4 v1, GLKVector4 v2) {
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z + v1.w * v2.w;
}

/**
 @Status Interoperable
*/
inline float GLKVector3Length(GLKVector3 v) {
    return sqrtf(v.x * v.x + v.y * v.y + v.z * v.z);
}

/**
 @Status Interoperable
*/
inline float GLKVector4Length(GLKVector4 v) {
    return sqrtf(v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w);
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3Normalize(GLKVector3 v) {
    float invlen = 1.f / sqrtf(v.x * v.x + v.y * v.y + v.z * v.z);
    return GLKVector3Make(v.x * invlen, v.y * invlen, v.z * invlen);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4Normalize(GLKVector4 v) {
    float invlen = 1.f / sqrtf(v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w);
    return GLKVector4Make(v.x * invlen, v.y * invlen, v.z * invlen, v.w * invlen);
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3Add(GLKVector3 v1, GLKVector3 v2) {
    return GLKVector3Make(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4Add(GLKVector4 v1, GLKVector4 v2) {
    return GLKVector4Make(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z, v1.w + v2.w);
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3AddScalar(GLKVector3 v1, float s) {
    return GLKVector3Make(v1.x + s, v1.y + s, v1.z + s);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4AddScalar(GLKVector4 v1, float s) {
    return GLKVector4Make(v1.x + s, v1.y + s, v1.z + s, v1.w + s);
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3SubtractScalar(GLKVector3 v1, float s) {
    return GLKVector3Make(v1.x - s, v1.y - s, v1.z - s);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4SubtractScalar(GLKVector4 v1, float s) {
    return GLKVector4Make(v1.x - s, v1.y - s, v1.z - s, v1.w - s);
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3MultiplyScalar(GLKVector3 v1, float s) {
    return GLKVector3Make(v1.x * s, v1.y * s, v1.z * s);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4MultiplyScalar(GLKVector4 v1, float s) {
    return GLKVector4Make(v1.x * s, v1.y * s, v1.z * s, v1.w * s);
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3DivideScalar(GLKVector3 v1, float s) {
    return GLKVector3MultiplyScalar(v1, 1.f / s);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4DivideScalar(GLKVector4 v1, float s) {
    return GLKVector4MultiplyScalar(v1, 1.f / s);
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3Subtract(GLKVector3 v1, GLKVector3 v2) {
    return GLKVector3Make(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4Subtract(GLKVector4 v1, GLKVector4 v2) {
    return GLKVector4Make(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z, v1.w - v2.w);
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3Negate(GLKVector3 v) {
    return GLKVector3Make(-v.x, -v.y, -v.z);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4Negate(GLKVector4 v) {
    return GLKVector4Make(-v.x, -v.y, -v.z, -v.w);
}

/**
 @Status Interoperable
*/
inline float GLKVector3Distance(GLKVector3 v1, GLKVector3 v2) {
    GLKVector3 v = GLKVector3Subtract(v1, v2);
    return GLKVector3Length(v);
}

/**
 @Status Interoperable
*/
inline float GLKVector4Distance(GLKVector4 v1, GLKVector4 v2) {
    GLKVector4 v = GLKVector4Subtract(v1, v2);
    return GLKVector4Length(v);
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3Divide(GLKVector3 v1, GLKVector3 v2) {
    return GLKVector3Make(v1.x / v2.x, v1.y / v2.y, v1.z / v2.z);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4Divide(GLKVector4 v1, GLKVector4 v2) {
    return GLKVector4Make(v1.x / v2.x, v1.y / v2.y, v1.z / v2.z, v1.w / v2.w);
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3Multiply(GLKVector3 v1, GLKVector3 v2) {
    return GLKVector3Make(v1.x * v2.x, v1.y * v2.y, v1.z * v2.z);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4Multiply(GLKVector4 v1, GLKVector4 v2) {
    return GLKVector4Make(v1.x * v2.x, v1.y * v2.y, v1.z * v2.z, v1.w * v2.w);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4CrossProduct(GLKVector4 l, GLKVector4 r) {
    return GLKVector4Make(l.y * r.z - l.z * r.y, l.z * r.x - l.x * r.z, l.x * r.y - l.y * r.x, 1.f);
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3CrossProduct(GLKVector3 l, GLKVector3 r) {
    return GLKVector3Make(l.y * r.z - l.z * r.y, l.z * r.x - l.x * r.z, l.x * r.y - l.y * r.x);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4Lerp(GLKVector4 a, GLKVector4 b, float t) {
    float it = (1.f - t);
    GLKVector4 res;

    res.x = t * b.x + it * a.x;
    res.y = t * b.y + it * a.y;
    res.z = t * b.z + it * a.z;
    res.w = t * b.w + it * a.w;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3Lerp(GLKVector3 a, GLKVector3 b, float t) {
    float it = (1.f - t);
    GLKVector3 res;

    res.x = t * b.x + it * a.x;
    res.y = t * b.y + it * a.y;
    res.z = t * b.z + it * a.z;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2Make(float x, float y) {
    GLKVector2 res;

    res.x = x;
    res.y = y;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2MakeWithArray(float* v) {
    GLKVector2 res;

    res.x = v[0];
    res.y = v[1];

    return res;
}

/**
 @Status Interoperable
*/
inline float GLKVector2Length(GLKVector2 v) {
    return sqrtf(v.x * v.x + v.y * v.y);
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2Normalize(GLKVector2 v) {
    float invdist = 1.f / sqrtf(v.x * v.x + v.y * v.y);
    return GLKVector2Make(v.x * invdist, v.y * invdist);
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2Add(GLKVector2 v1, GLKVector2 v2) {
    return GLKVector2Make(v1.x + v2.x, v1.y + v2.y);
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2Subtract(GLKVector2 v1, GLKVector2 v2) {
    return GLKVector2Make(v1.x - v2.x, v1.y - v2.y);
}

/**
 @Status Interoperable
*/
inline float GLKVector2Distance(GLKVector2 v1, GLKVector2 v2) {
    return GLKVector2Length(GLKVector2Subtract(v1, v2));
}

/**
 @Status Interoperable
*/
inline float GLKVector2DotProduct(GLKVector2 v1, GLKVector2 v2) {
    return v1.x * v2.x + v1.y * v2.y;
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2Negate(GLKVector2 v) {
    return GLKVector2Make(-v.x, -v.y);
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2AddScalar(GLKVector2 v, float val) {
    return GLKVector2Make(v.x + val, v.y + val);
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2SubtractScalar(GLKVector2 v, float val) {
    return GLKVector2Make(v.x - val, v.y - val);
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2MultiplyScalar(GLKVector2 v, float val) {
    return GLKVector2Make(v.x * val, v.y * val);
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2DivideScalar(GLKVector2 v, float val) {
    return GLKVector2MultiplyScalar(v, 1.f / val);
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2Multiply(GLKVector2 v1, GLKVector2 v2) {
    return GLKVector2Make(v1.x * v2.x, v1.y * v2.y);
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2Divide(GLKVector2 v1, GLKVector2 v2) {
    return GLKVector2Make(v1.x / v2.x, v1.y / v2.y);
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2Lerp(GLKVector2 v1, GLKVector2 v2, float t) {
    float it = 1.f - t;
    GLKVector2 res;

    res.x = v1.x * it + v2.x * t;
    res.y = v1.y * it + v2.y * t;

    return res;
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector4AllEqualToScalar(GLKVector4 v, float scalar) {
    GLKVector4 o = GLKVector4SubtractScalar(v, scalar);
    if ((fabsf(o.x) + fabsf(o.y) + fabsf(o.z) + fabsf(o.w)) < (4.f * COMPARISON_EPSILON))
        return TRUE;
    return FALSE;
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector3AllEqualToScalar(GLKVector3 v, float scalar) {
    GLKVector3 o = GLKVector3SubtractScalar(v, scalar);
    if ((fabsf(o.x) + fabsf(o.y) + fabsf(o.z)) < (3.f * COMPARISON_EPSILON))
        return TRUE;
    return FALSE;
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector2AllEqualToScalar(GLKVector2 v, float scalar) {
    GLKVector2 o = GLKVector2SubtractScalar(v, scalar);
    if ((fabsf(o.x) + fabsf(o.y)) < (2.f * COMPARISON_EPSILON))
        return TRUE;
    return FALSE;
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector4AllEqualToVector4(GLKVector4 v1, GLKVector4 v2) {
    GLKVector4 o = GLKVector4Subtract(v1, v2);
    if ((fabsf(o.x) + fabsf(o.y) + fabsf(o.z) + fabsf(o.w)) < (4.f * COMPARISON_EPSILON))
        return TRUE;
    return FALSE;
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector3AllEqualToVector3(GLKVector3 v1, GLKVector3 v2) {
    GLKVector3 o = GLKVector3Subtract(v1, v2);
    if ((fabsf(o.x) + fabsf(o.y) + fabsf(o.z)) < (3.f * COMPARISON_EPSILON))
        return TRUE;
    return FALSE;
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector2AllEqualToVector2(GLKVector2 v1, GLKVector2 v2) {
    GLKVector2 o = GLKVector2Subtract(v1, v2);
    if ((fabsf(o.x) + fabsf(o.y)) < (2.f * COMPARISON_EPSILON))
        return TRUE;
    return FALSE;
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector4XYZEqualToScalar(GLKVector4 v, float scalar) {
    GLKVector4 o = GLKVector4SubtractScalar(v, scalar);
    if ((fabsf(o.x) + fabsf(o.y) + fabsf(o.z)) < (3.f * COMPARISON_EPSILON))
        return TRUE;
    return FALSE;
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2Maximum(GLKVector2 a, GLKVector2 b) {
    GLKVector2 res;

    res.x = _GLK_MAX(a.x, b.x);
    res.y = _GLK_MAX(a.y, b.y);

    return res;
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2Minimum(GLKVector2 a, GLKVector2 b) {
    GLKVector2 res;

    res.x = _GLK_MIN(a.x, b.x);
    res.y = _GLK_MIN(a.y, b.y);

    return res;
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3Maximum(GLKVector3 a, GLKVector3 b) {
    GLKVector3 res;

    res.x = _GLK_MAX(a.x, b.x);
    res.y = _GLK_MAX(a.y, b.y);
    res.z = _GLK_MAX(a.z, b.z);

    return res;
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3Minimum(GLKVector3 a, GLKVector3 b) {
    GLKVector3 res;

    res.x = _GLK_MIN(a.x, b.x);
    res.y = _GLK_MIN(a.y, b.y);
    res.z = _GLK_MIN(a.z, b.z);

    return res;
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4Maximum(GLKVector4 a, GLKVector4 b) {
    GLKVector4 res;

    res.x = _GLK_MAX(a.x, b.x);
    res.y = _GLK_MAX(a.y, b.y);
    res.z = _GLK_MAX(a.z, b.z);
    res.w = _GLK_MAX(a.w, b.w);

    return res;
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4Minimum(GLKVector4 a, GLKVector4 b) {
    GLKVector4 res;

    res.x = _GLK_MIN(a.x, b.x);
    res.y = _GLK_MIN(a.y, b.y);
    res.z = _GLK_MIN(a.z, b.z);
    res.w = _GLK_MIN(a.w, b.w);

    return res;
}

/**
 @Status Interoperable
*/
inline GLKVector2 GLKVector2Project(GLKVector2 v, GLKVector2 proj) {
    return GLKVector2MultiplyScalar(proj, GLKVector2DotProduct(v, proj) / GLKVector2Length(proj));
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3Project(GLKVector3 v, GLKVector3 proj) {
    return GLKVector3MultiplyScalar(proj, GLKVector3DotProduct(v, proj) / GLKVector3Length(proj));
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4Project(GLKVector4 v, GLKVector4 proj) {
    return GLKVector4MultiplyScalar(proj, GLKVector4DotProduct(v, proj) / GLKVector4Length(proj));
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector2AllGreaterThanOrEqualToScalar(GLKVector2 v, float scalar) {
    return ((v.x >= scalar) && (v.y >= scalar));
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector3AllGreaterThanOrEqualToScalar(GLKVector3 v, float scalar) {
    return ((v.x >= scalar) && (v.y >= scalar) && (v.z >= scalar));
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector4AllGreaterThanOrEqualToScalar(GLKVector4 v, float scalar) {
    return ((v.x >= scalar) && (v.y >= scalar) && (v.z >= scalar) && (v.w >= scalar));
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector2AllGreaterThanScalar(GLKVector2 v, float scalar) {
    return ((v.x > scalar) && (v.y > scalar));
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector3AllGreaterThanScalar(GLKVector3 v, float scalar) {
    return ((v.x > scalar) && (v.y > scalar) && (v.z > scalar));
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector4AllGreaterThanScalar(GLKVector4 v, float scalar) {
    return ((v.x > scalar) && (v.y > scalar) && (v.z > scalar) && (v.w > scalar));
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector2AllGreaterThanOrEqualToVector2(GLKVector2 v, GLKVector2 v2) {
    return ((v.x >= v2.x) && (v.y >= v2.y));
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector3AllGreaterThanOrEqualToVector3(GLKVector3 v, GLKVector3 v2) {
    return ((v.x >= v2.x) && (v.y >= v2.y) && (v.z >= v2.z));
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector4AllGreaterThanOrEqualToVector4(GLKVector4 v, GLKVector4 v2) {
    return ((v.x >= v2.x) && (v.y >= v2.y) && (v.z >= v2.z) && (v.w >= v2.w));
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector2AllGreaterThanVector2(GLKVector2 v, GLKVector2 v2) {
    return ((v.x > v2.x) && (v.y > v2.y));
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector3AllGreaterThanVector3(GLKVector3 v, GLKVector3 v2) {
    return ((v.x > v2.x) && (v.y > v2.y) && (v.z > v2.z));
}

/**
 @Status Interoperable
*/
inline BOOL GLKVector4AllGreaterThanVector4(GLKVector4 v, GLKVector4 v2) {
    return ((v.x > v2.x) && (v.y > v2.y) && (v.z > v2.z) && (v.w > v2.w));
}

/**
 @Status Interoperable
*/
inline GLKQuaternion GLKQuaternionMake(float x, float y, float z, float w) {
    GLKQuaternion res;

    res.x = x;
    res.y = y;
    res.z = z;
    res.w = w;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKQuaternion GLKQuaternionMakeWithArray(float* vals) {
    GLKQuaternion res;

    res.x = vals[0];
    res.y = vals[1];
    res.z = vals[2];
    res.w = vals[3];

    return res;
}

/**
 @Status Interoperable
*/
inline GLKQuaternion GLKQuaternionMakeWithVector3(GLKVector3 v, float w) {
    GLKQuaternion res;

    res.x = v.x;
    res.y = v.y;
    res.z = v.z;
    res.w = w;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKQuaternion GLKQuaternionMakeWithAngleAndAxis(float angle, float x, float y, float z) {
    GLKQuaternion res;

    float halfAng = angle * 0.5f;
    float sa = sinf(halfAng);
    res.x = sa * x;
    res.y = sa * y;
    res.z = sa * z;
    res.w = cosf(halfAng);

    return res;
}

/**
 @Status Interoperable
*/
inline GLKQuaternion GLKQuaternionMakeWithAngleAndVector3Axis(float angle, GLKVector3 axis) {
    GLKQuaternion res;

    float halfAng = angle * 0.5f;
    float sa = sinf(halfAng);
    res.x = sa * axis.x;
    res.y = sa * axis.y;
    res.z = sa * axis.z;
    res.w = cosf(halfAng);

    return res;
}

/**
 @Status Interoperable
*/
inline float GLKQuaternionLength(GLKQuaternion quat) {
    return sqrtf(quat.x * quat.x + quat.y * quat.y + quat.z * quat.z + quat.w * quat.w);
}

/**
 @Status Interoperable
*/
inline float GLKQuaternionDot(GLKQuaternion q1, GLKQuaternion q2) {
    return q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w;
}

/**
 @Status Interoperable
*/
inline GLKQuaternion GLKQuaternionMultiply(GLKQuaternion q1, GLKQuaternion q2) {
    GLKQuaternion res;

    res.x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y;
    res.y = q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x;
    res.z = q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w;
    res.w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKQuaternion GLKQuaternionMultiplyByScalar(float t, GLKQuaternion q) {
    GLKQuaternion res;

    res.x = t * q.x;
    res.y = t * q.y;
    res.z = t * q.z;
    res.w = t * q.w;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKQuaternion GLKQuaternionAdd(GLKQuaternion q1, GLKQuaternion q2) {
    GLKQuaternion res;

    res.x = q1.x + q2.x;
    res.y = q1.y + q2.y;
    res.z = q1.z + q2.z;
    res.w = q1.w + q2.w;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKQuaternion GLKQuaternionSubtract(GLKQuaternion q1, GLKQuaternion q2) {
    GLKQuaternion res;

    res.x = q1.x - q2.x;
    res.y = q1.y - q2.y;
    res.z = q1.z - q2.z;
    res.w = q1.w - q2.w;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKQuaternion GLKQuaternionConjugate(GLKQuaternion q) {
    GLKQuaternion res;

    res.x = -q.x;
    res.y = -q.y;
    res.z = -q.z;
    res.w = q.w;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKQuaternion GLKQuaternionNormalize(GLKQuaternion q) {
    GLKQuaternion res;

    float invmag = 1.f / GLKQuaternionLength(q);
    res.x = q.x * invmag;
    res.y = q.y * invmag;
    res.z = q.z * invmag;
    res.w = q.w * invmag;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKQuaternion GLKQuaternionInvert(GLKQuaternion q) {
    GLKQuaternion res;

    float lsq = 1.f / (q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);

    res.x = -q.x * lsq;
    res.y = -q.y * lsq;
    res.z = -q.z * lsq;
    res.w = q.w * lsq;

    return res;
}

/**
 @Status Interoperable
*/
inline GLKQuaternion GLKQuaternionSlerp(GLKQuaternion q1, GLKQuaternion q2, float t) {
    float mq1 = GLKQuaternionLength(q1);
    float mq2 = GLKQuaternionLength(q2);
    float dp = GLKQuaternionDot(q1, q2);

    float cang = dp / (mq1 * mq2);
    float ang = acosf(cang);
    float invsang = 1.f / sinf(ang);

    return GLKQuaternionAdd(GLKQuaternionMultiplyByScalar(sinf((1.f - t) * ang) * invsang, q1),
                            GLKQuaternionMultiplyByScalar(sinf(t * ang) * invsang, q2));
}

// --------------------------------------------------------------------------------
// Utilities.

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3Origin() {
    return GLKVector3Make(0.f, 0.f, 0.f);
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3XAxis() {
    return GLKVector3Make(1.f, 0.f, 0.f);
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3YAxis() {
    return GLKVector3Make(0.f, 1.f, 0.f);
}

/**
 @Status Interoperable
*/
inline GLKVector3 GLKVector3ZAxis() {
    return GLKVector3Make(0.f, 0.f, 1.f);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4Black() {
    return GLKVector4Make(0.f, 0.f, 0.f, 1.f);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4White() {
    return GLKVector4Make(1.f, 1.f, 1.f, 1.f);
}

/**
 @Status Interoperable
*/
inline GLKVector4 GLKVector4Origin() {
    return GLKVector4Make(0.f, 0.f, 0.f, 0.f);
}
#endif