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

#include "GLKMath.h"
#include <assert.h>
#include <float.h>
#include <math.h>
#include <memory.h>

/// Matrix SSE Types
__declspec(align(16)) struct GLKMatrix4M128 {
    __m128 row[4];
    GLKMatrix4M128() {
    }
    explicit GLKMatrix4M128(_In_reads_(16) const float* pArray);
};

_Use_decl_annotations_ inline GLKMatrix4M128::GLKMatrix4M128(const float* pArray) {
    assert(pArray != nullptr);
    row[0] = _mm_loadu_ps((const float*)pArray);
    row[1] = _mm_loadu_ps((const float*)(pArray + 4));
    row[2] = _mm_loadu_ps((const float*)(pArray + 8));
    row[3] = _mm_loadu_ps((const float*)(pArray + 12));
}

/// Matrix4M128 aliased with GLKMatrix4, GLKMatrix3, GLKMatrix2
/// Note: For matrices with fewer than 4 dimensions, ensure use takes into account packing
__declspec(align(16)) struct GLKUniversalMatrix {
    union {
        __m128 row[4];
        GLKMatrix4M128 matrix4M128;
        GLKMatrix4 glkMatrix4;
        GLKMatrix3 glkMatrix3;
        GLKMatrix2 glkMatrix2;
    };

    GLKUniversalMatrix() {
    }
    explicit GLKUniversalMatrix(_In_reads_(16) const float* pArray);
    GLKUniversalMatrix(_In_reads_(4) const __m128& row0,
                       _In_reads_(4) const __m128& row1,
                       _In_reads_(4) const __m128& row2,
                       _In_reads_(4) const __m128& row3);

    GLKUniversalMatrix& operator=(const GLKUniversalMatrix& m) {
        row[0] = m.row[0];
        row[1] = m.row[1];
        row[2] = m.row[2];
        row[3] = m.row[3];
        return *this;
    }
};

_Use_decl_annotations_ inline GLKUniversalMatrix::GLKUniversalMatrix(const float* pArray) {
    assert(pArray != nullptr);
    row[0] = _mm_loadu_ps((const float*)pArray);
    row[1] = _mm_loadu_ps((const float*)(pArray + 4));
    row[2] = _mm_loadu_ps((const float*)(pArray + 8));
    row[3] = _mm_loadu_ps((const float*)(pArray + 12));
}

_Use_decl_annotations_ inline GLKUniversalMatrix::GLKUniversalMatrix(const __m128& row0,
                                                                     const __m128& row1,
                                                                     const __m128& row2,
                                                                     const __m128& row3) {
    row[0] = row0;
    row[1] = row1;
    row[2] = row2;
    row[3] = row3;
}

/// UniversalVectorUi type
__declspec(align(16)) typedef struct _GLKUniversalVectorUi {
    union {
        unsigned int vector4UInt[4];
        __m128 vectorM128;
        GLKVector4 glkVector4;
        GLKQuaternion glkQuaternion;
        GLKVector3 glkVector3;
        GLKVector2 glkVector2;
    };
    inline operator __m128() const {
        return vectorM128;
    }
} GLKUniversalVectorUi;

/// UniversalVectorFl type
__declspec(align(16)) typedef struct _GLKUniversalVectorFl {
    union {
        float vector4F32[4];
        __m128 vectorM128;
        GLKVector4 glkVector4;
        GLKQuaternion glkQuaternion;
        GLKVector3 glkVector3;
        GLKVector2 glkVector2;
    };
    inline operator __m128() const {
        return vectorM128;
    }
} GLKUniversalVectorFl;

GLK_GLOBALCONST GLKUniversalVectorFl c_vec4IdMatrixRow0 = { 1.0f, 0.0f, 0.0f, 0.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4IdMatrixRow1 = { 0.0f, 1.0f, 0.0f, 0.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4IdMatrixRow2 = { 0.0f, 0.0f, 1.0f, 0.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4IdMatrixRow3 = { 0.0f, 0.0f, 0.0f, 1.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4NegateIdMatrixRow0 = { -1.0f, 0.0f, 0.0f, 0.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4NegateIdMatrixRow1 = { 0.0f, -1.0f, 0.0f, 0.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4NegateIdMatrixRow2 = { 0.0f, 0.0f, -1.0f, 0.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4NegateIdMatrixRow3 = { 0.0f, 0.0f, 0.0f, -1.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4AllOnes = { 1.0f, 1.0f, 1.0f, 1.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4AllZeros = { 0.0f, 0.0f, 0.0f, 0.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4NegateX = { -1.0f, 1.0f, 1.0f, 1.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4NegateY = { 1.0f, -1.0f, 1.0f, 1.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4NegateZ = { 1.0f, 1.0f, -1.0f, 1.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4NegateW = { 1.0f, 1.0f, 1.0f, -1.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4NegateXYZ = { -1.0f, -1.0f, -1.0f, 1.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4IdMatrix3Rows012 = { 1.0f, 0.0f, 0.0f, 0.0f };
GLK_GLOBALCONST GLKUniversalVectorFl c_vec4QuatIdentity = { 0.0f, 0.0f, 0.0f, 1.0f };

GLK_GLOBALCONST GLKUniversalVectorUi c_vec4Infinity = { 0x7F800000, 0x7F800000, 0x7F800000, 0x7F800000 };
GLK_GLOBALCONST GLKUniversalVectorUi c_vec4Nan = { 0x7FC00000, 0x7FC00000, 0x7FC00000, 0x7FC00000 };
GLK_GLOBALCONST GLKUniversalVectorUi c_vec4MaskXYZ = { 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0x00000000 };
GLK_GLOBALCONST GLKUniversalVectorUi c_vec4MaskX = { 0xFFFFFFFF, 0x00000000, 0x00000000, 0x00000000 };
GLK_GLOBALCONST GLKUniversalVectorUi c_vec4MaskY = { 0x00000000, 0xFFFFFFFF, 0x00000000, 0x00000000 };
GLK_GLOBALCONST GLKUniversalVectorUi c_vec4MaskZ = { 0x00000000, 0x00000000, 0xFFFFFFFF, 0x00000000 };
GLK_GLOBALCONST GLKUniversalVectorUi c_vec4MaskW = { 0x00000000, 0x00000000, 0x00000000, 0xFFFFFFFF };

GLK_GLOBALCONST GLKUniversalMatrix c_matrix4Identity = { c_vec4IdMatrixRow0.vectorM128,
                                                         c_vec4IdMatrixRow1.vectorM128,
                                                         c_vec4IdMatrixRow2.vectorM128,
                                                         c_vec4IdMatrixRow3.vectorM128 };
GLK_GLOBALCONST GLKUniversalMatrix c_matrix3Identity = { c_vec4IdMatrix3Rows012.vectorM128,
                                                         c_vec4IdMatrix3Rows012.vectorM128,
                                                         c_vec4IdMatrix3Rows012.vectorM128,
                                                         c_vec4AllZeros.vectorM128 };

/// Inline function definitions
inline GLKMatrix4M128 GLK_CALLCONV GLKMatrixSseTranspose(GLKMatrix4M128 m);
inline __m128 GLK_CALLCONV GLKSSE2NormalizeVector3FailSafe(__m128 v);
inline __m128 GLK_CALLCONV GLKSSE2NormalizeVector3(__m128 v);
inline __m128 GLK_CALLCONV GLKSSE2CrossVector3(__m128 v1, __m128 v2);
inline __m128 GLK_CALLCONV GLKSSE2NegateVector4(__m128 v);
inline __m128 GLK_CALLCONV GLKSSE2DotVector3(__m128 v1, __m128 v2);
inline __m128 GLK_CALLCONV GLKSSE2DotVector4(__m128 v1, __m128 v2);
inline __m128 GLK_CALLCONV GLKSSE2Select(__m128 v1, __m128 v2, __m128 control);
inline __m128 GLK_CALLCONV GLKSSE2Set(float x, float y, float z, float w);
inline __m128 GLK_CALLCONV GLKSSE2QuaternionAxis(__m128 quat, const float& w);
inline __m128 GLK_CALLCONV GLKSSE2MultiplyMatrix4Vector4(const GLKMatrix4M128 m, const __m128 v);
inline __m128 GLK_CALLCONV GLKSSE2MultiplyMatrix4Vector3(const GLKMatrix4M128 m, const __m128 v);
inline __m128 GLK_CALLCONV GLKSSE2MultiplyMatrix4Vector3Translate(const GLKMatrix4M128 m, const __m128 v);

inline void GLK_CALLCONV GLKSSE2Matrix4MultiplyVector3Array(GLKMatrix4M128 m, GLKVector3* vecs, size_t numVecs);
inline void GLK_CALLCONV GLKSSE2Matrix4MultiplyVector4Array(GLKMatrix4M128 m, GLKVector4* vecs, size_t numVecs);

inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix4MakeXRotation(float rad);
inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix4MakeYRotation(float rad);
inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix4MakeZRotation(float rad);
inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix4MakeRotation(__m128 axisVector, float rad);
inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix4MultiplyMatrix4(GLKMatrix4M128 m1, GLKMatrix4M128& m2);
inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix4Invert(GLKMatrix4M128 mT, BOOL* isInvertible);
inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix3Invert(GLKMatrix4M128 mT, BOOL* isInvertible);

inline void GLK_CALLCONV GLKSSE2Matrix4TranslateVector4(GLKMatrix4M128& m, __m128 v);
inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix4ScaleVector4(GLKMatrix4M128 m, __m128 scaleVector);

inline GLKMatrix4M128 GLK_CALLCONV GLKMatrixSseTranspose(GLKMatrix4M128 m) {
    GLKMatrix4M128 res;
    __m128 tempVector1 = _mm_shuffle_ps(m.row[0], m.row[1], _MM_SHUFFLE(1, 0, 1, 0));
    __m128 tempVector3 = _mm_shuffle_ps(m.row[0], m.row[1], _MM_SHUFFLE(3, 2, 3, 2));
    __m128 tempVector2 = _mm_shuffle_ps(m.row[2], m.row[3], _MM_SHUFFLE(1, 0, 1, 0));
    __m128 tempVector4 = _mm_shuffle_ps(m.row[2], m.row[3], _MM_SHUFFLE(3, 2, 3, 2));

    res.row[0] = _mm_shuffle_ps(tempVector1, tempVector2, _MM_SHUFFLE(2, 0, 2, 0));
    res.row[1] = _mm_shuffle_ps(tempVector1, tempVector2, _MM_SHUFFLE(3, 1, 3, 1));
    res.row[2] = _mm_shuffle_ps(tempVector3, tempVector4, _MM_SHUFFLE(2, 0, 2, 0));
    res.row[3] = _mm_shuffle_ps(tempVector3, tempVector4, _MM_SHUFFLE(3, 1, 3, 1));

    // Note: This is an in-place transpose. Would need to be copied to result or M would have to be the input.
    //_MM_TRANSPOSE4_PS(m.row[0], m.row[1], m.row[2], m.row[3]);

    return res;
}

inline __m128 GLK_CALLCONV GLKSSE2NormalizeVector3FailSafe(__m128 v) {
    // Perform the dot product on x,y and z only

    __m128 lengthSqVector = _mm_mul_ps(v, v);
    __m128 tmpVector = _mm_shuffle_ps(lengthSqVector, lengthSqVector, _MM_SHUFFLE(2, 1, 2, 1));
    lengthSqVector = _mm_add_ss(lengthSqVector, tmpVector);
    tmpVector = _mm_shuffle_ps(tmpVector, tmpVector, _MM_SHUFFLE(1, 1, 1, 1));
    lengthSqVector = _mm_add_ss(lengthSqVector, tmpVector);
    lengthSqVector = _mm_shuffle_ps(lengthSqVector, lengthSqVector, _MM_SHUFFLE(0, 0, 0, 0));
    // Prepare for the division
    __m128 res = _mm_sqrt_ps(lengthSqVector);
    // Create zero with a single instruction
    __m128 zeroMask = _mm_setzero_ps();
    // Test for a divide by zero (Must be FP to detect -0.0)
    zeroMask = _mm_cmpneq_ps(zeroMask, res);
    // Failsafe on zero (Or epsilon) length planes
    // If the length is infinity, set the elements to zero
    lengthSqVector = _mm_cmpneq_ps(lengthSqVector, c_vec4Infinity.vectorM128);
    // Divide to perform the normalization
    res = _mm_div_ps(v, res);
    // Any that are infinity, set to zero
    res = _mm_and_ps(res, zeroMask);
    // Select qnan or result based on infinite length
    __m128 tmpVector1 = _mm_andnot_ps(lengthSqVector, c_vec4Nan.vectorM128);
    __m128 tmpVector2 = _mm_and_ps(res, lengthSqVector);
    res = _mm_or_ps(tmpVector1, tmpVector2);
    return res;
}

inline __m128 GLK_CALLCONV GLKSSE2NormalizeVector3(__m128 v) {
    // Perform the dot product on x,y and z only
    __m128 lengthSqVector = _mm_mul_ps(v, v);
    __m128 tmpVector = _mm_shuffle_ps(lengthSqVector, lengthSqVector, _MM_SHUFFLE(2, 1, 2, 1));
    lengthSqVector = _mm_add_ss(lengthSqVector, tmpVector);
    tmpVector = _mm_shuffle_ps(tmpVector, tmpVector, _MM_SHUFFLE(1, 1, 1, 1));
    lengthSqVector = _mm_add_ss(lengthSqVector, tmpVector);
    lengthSqVector = _mm_shuffle_ps(lengthSqVector, lengthSqVector, _MM_SHUFFLE(0, 0, 0, 0));

    __m128 res = _mm_sqrt_ps(lengthSqVector);
    res = _mm_div_ps(v, res);

    return res;
}

inline __m128 GLK_CALLCONV GLKSSE2CrossVector3(__m128 v1, __m128 v2) {
    // y1,z1,x1,w1

    __m128 tmpVector1 = _mm_shuffle_ps(v1, v1, _MM_SHUFFLE(3, 0, 2, 1));
    // z2,x2,y2,w2
    __m128 tmpVector2 = _mm_shuffle_ps(v2, v2, _MM_SHUFFLE(3, 1, 0, 2));
    // Perform the left operation
    __m128 result = _mm_mul_ps(tmpVector1, tmpVector2);
    // z1,x1,y1,w1
    tmpVector1 = _mm_shuffle_ps(tmpVector1, tmpVector1, _MM_SHUFFLE(3, 0, 2, 1));
    // y2,z2,x2,w2
    tmpVector2 = _mm_shuffle_ps(tmpVector2, tmpVector2, _MM_SHUFFLE(3, 1, 0, 2));
    // Perform the right operation
    tmpVector1 = _mm_mul_ps(tmpVector1, tmpVector2);
    // Subract the right from left, and return answer
    result = _mm_sub_ps(result, tmpVector1);
    // Set w to zero

    return _mm_and_ps(result, c_vec4MaskXYZ.vectorM128);
}

inline __m128 GLK_CALLCONV GLKSSE2NegateVector4(__m128 v) {
    __m128 result;

    result = _mm_setzero_ps();

    return _mm_sub_ps(result, v);
}

inline __m128 GLK_CALLCONV GLKSSE2DotVector3(__m128 v1, __m128 v2) {
    // Perform the dot product
    __m128 dotProd = _mm_mul_ps(v1, v2);
    // x=Dot.vector4_f32[1], y=Dot.vector4_f32[2]
    __m128 tmpVector = _mm_shuffle_ps(dotProd, dotProd, _MM_SHUFFLE(2, 1, 2, 1));
    // Result.vector4_f32[0] = x+y
    dotProd = _mm_add_ss(dotProd, tmpVector);
    // x=Dot.vector4_f32[2]
    tmpVector = _mm_shuffle_ps(tmpVector, tmpVector, _MM_SHUFFLE(1, 1, 1, 1));
    // Result.vector4_f32[0] = (x+y)+z
    dotProd = _mm_add_ss(dotProd, tmpVector);
    // Splat x
    return _mm_shuffle_ps(dotProd, dotProd, _MM_SHUFFLE(0, 0, 0, 0));
}

inline __m128 GLK_CALLCONV GLKSSE2DotVector4(__m128 v1, __m128 v2) {
    __m128 tmpVector2 = v2;
    __m128 tmpVector = _mm_mul_ps(v1, tmpVector2);
    tmpVector2 = _mm_shuffle_ps(tmpVector2, tmpVector, _MM_SHUFFLE(1, 0, 0, 0)); // Copy X to the Z position and Y to the W position
    tmpVector2 = _mm_add_ps(tmpVector2, tmpVector); // Add Z = X+Z; W = Y+W;
    tmpVector = _mm_shuffle_ps(tmpVector, tmpVector2, _MM_SHUFFLE(0, 3, 0, 0)); // Copy W to the Z position
    tmpVector = _mm_add_ps(tmpVector, tmpVector2); // Add Z and W together
    return _mm_shuffle_ps(tmpVector, tmpVector, _MM_SHUFFLE(2, 2, 2, 2)); // Splat Z and return
}

inline __m128 GLK_CALLCONV GLKSSE2Select(__m128 v1, __m128 v2, __m128 control) {
    __m128 tmpVector1 = _mm_andnot_ps(control, v1);
    __m128 tmpVector2 = _mm_and_ps(v2, control);
    return _mm_or_ps(tmpVector1, tmpVector2);
}

inline __m128 GLK_CALLCONV GLKSSE2Set(float x, float y, float z, float w) {
    return _mm_set_ps(w, z, y, x);
}

inline __m128 GLK_CALLCONV GLKSSE2QuaternionAxis(__m128 quat, const float& w) {
    __declspec(align(16)) const float mf = 1.f / sinf(acosf(w));
    __m128 mfVector = _mm_load_ps1(&mf);

    return _mm_mul_ps(quat, mfVector);
}

inline __m128 GLK_CALLCONV GLKSSE2MultiplyMatrix4Vector4(const GLKMatrix4M128 m, const __m128 v) {
    __m128 tmpVectorX = _mm_shuffle_ps(v, v, _MM_SHUFFLE(0, 0, 0, 0));
    __m128 tmpVectorY = _mm_shuffle_ps(v, v, _MM_SHUFFLE(1, 1, 1, 1));
    __m128 tmpVectorZ = _mm_shuffle_ps(v, v, _MM_SHUFFLE(2, 2, 2, 2));
    __m128 tmpVectorW = _mm_shuffle_ps(v, v, _MM_SHUFFLE(3, 3, 3, 3));
    // Mul by the matrix
    tmpVectorX = _mm_mul_ps(tmpVectorX, m.row[0]);
    tmpVectorY = _mm_mul_ps(tmpVectorY, m.row[1]);
    tmpVectorZ = _mm_mul_ps(tmpVectorZ, m.row[2]);
    tmpVectorW = _mm_mul_ps(tmpVectorW, m.row[3]);
    // Add them all together
    tmpVectorX = _mm_add_ps(tmpVectorX, tmpVectorY);
    tmpVectorZ = _mm_add_ps(tmpVectorZ, tmpVectorW);
    return _mm_add_ps(tmpVectorX, tmpVectorZ);
}

inline __m128 GLK_CALLCONV GLKSSE2MultiplyMatrix4Vector3(const GLKMatrix4M128 m, const __m128 v) {
    __m128 res = _mm_shuffle_ps(v, v, _MM_SHUFFLE(0, 0, 0, 0));
    res = _mm_mul_ps(res, m.row[0]);
    __m128 tmpVector = _mm_shuffle_ps(v, v, _MM_SHUFFLE(1, 1, 1, 1));
    tmpVector = _mm_mul_ps(tmpVector, m.row[1]);
    res = _mm_add_ps(res, tmpVector);
    tmpVector = _mm_shuffle_ps(v, v, _MM_SHUFFLE(2, 2, 2, 2));
    tmpVector = _mm_mul_ps(tmpVector, m.row[2]);
    res = _mm_add_ps(res, tmpVector);
    // res = _mm_add_ps(res, m.row[3]);
    return res;
}

inline __m128 GLK_CALLCONV GLKSSE2MultiplyMatrix4Vector3Translate(const GLKMatrix4M128 m, const __m128 v) {
    __m128 res = _mm_shuffle_ps(v, v, _MM_SHUFFLE(0, 0, 0, 0));
    res = _mm_mul_ps(res, m.row[0]);
    __m128 tmpVector = _mm_shuffle_ps(v, v, _MM_SHUFFLE(1, 1, 1, 1));
    tmpVector = _mm_mul_ps(tmpVector, m.row[1]);
    res = _mm_add_ps(res, tmpVector);
    tmpVector = _mm_shuffle_ps(v, v, _MM_SHUFFLE(2, 2, 2, 2));
    tmpVector = _mm_mul_ps(tmpVector, m.row[2]);
    res = _mm_add_ps(res, tmpVector);
    res = _mm_add_ps(res, m.row[3]);
    return res;
}

inline void GLK_CALLCONV GLKSSE2Matrix4MultiplyVector3Array(GLKMatrix4M128 m, GLKVector3* vecs, size_t numVecs) {
    __m128 vector;
    // assert((uintptr_t(vecs) & 15) == 0);
    int i;
    int numVectors = static_cast<int>(numVecs);

    // Transform all but the last vector
    for (i = 0; i < (numVectors - 2); i++) {
        vector = _mm_loadu_ps((const float*)vecs[i].v);
        vector = GLKSSE2MultiplyMatrix4Vector3(m, vector);
        _mm_storeu_ps(vecs[i].v, vector);
    }

    // Transform the last vector
    __m128 lastVector = { vecs[i].x, vecs[i].y, vecs[i].z, 0.0f };
    lastVector = GLKSSE2MultiplyMatrix4Vector3(m, lastVector);

    if (numVectors > 1) {
        // Move value in f32[3] to f32[0]
        vector = _mm_shuffle_ps(vector, vector, _MM_SHUFFLE(0, 0, 0, 3));
        // Shift values down to make room in register for z component of 2nd last vector
        lastVector = _mm_shuffle_ps(lastVector, lastVector, _MM_SHUFFLE(2, 1, 0, 3));

        // Copy z element of 2nd last vector to start of register
        // lastVector = <secondLastVector.z, lastVector.x, lastVector.y, lastVector.z>
        lastVector = _mm_move_ss(vector, lastVector);

        // Copy lastVector to end of stream
        _mm_storeu_ps(&vecs[i - 1].v[3], lastVector);
    } else {
        vecs[i].v[0] = lastVector.m128_f32[0];
        vecs[i].v[1] = lastVector.m128_f32[1];
        vecs[i].v[2] = lastVector.m128_f32[2];
    }
}

inline void GLK_CALLCONV GLKSSE2Matrix4MultiplyVector4Array(GLKMatrix4M128 m, GLKVector4* vecs, size_t numVecs) {
    __m128 vector;
    assert((uintptr_t(vecs) & 15) == 0);

    for (size_t i = 0; i < numVecs; i++) {
        vector = _mm_loadu_ps((const float*)vecs[i].v);
        vector = GLKSSE2MultiplyMatrix4Vector4(m, vector);
        _mm_storeu_ps(vecs[i].v, vector);
    }
}

inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix4MakeXRotation(float rad) {
    GLKMatrix4M128 res;
    float sinRad = sinf(rad);
    float cosRad = cosf(rad);

    __m128 sinVector = _mm_set_ss(sinRad); // <sinRad, 0, 0, 0>
    __m128 cosVector = _mm_set_ss(cosRad); // <cosRad, 0, 0, 0>

    res.row[0] = c_vec4IdMatrixRow0.vectorM128;
    // x = 0,y = cos,z = sin, w = 0
    cosVector = _mm_shuffle_ps(cosVector, sinVector, _MM_SHUFFLE(1, 0, 0, 1));

    res.row[1] = cosVector;
    // x = 0,y = sin,z = cos, w = 0
    cosVector = _mm_shuffle_ps(cosVector, cosVector, _MM_SHUFFLE(3, 1, 2, 0));
    cosVector = _mm_mul_ps(cosVector, c_vec4NegateY.vectorM128);

    res.row[2] = cosVector;

    res.row[3] = c_vec4IdMatrixRow3.vectorM128;

    return res;
}

inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix4MakeYRotation(float rad) {
    GLKMatrix4M128 matrix;
    float sinRad = sinf(rad);
    float cosRad = cosf(rad);
    __m128 sinVector = _mm_set_ss(sinRad); // <sinR, 0, 0, 0>
    __m128 cosVector = _mm_set_ss(cosRad); // <cosR, 0, 0, 0>

    // x = sin,y = 0,z = cos, w = 0
    sinVector = _mm_shuffle_ps(sinVector, cosVector, _MM_SHUFFLE(3, 0, 3, 0));

    matrix.row[2] = sinVector;
    matrix.row[1] = c_vec4IdMatrixRow1.vectorM128;
    // x = cos,y = 0,z = sin, w = 0
    sinVector = _mm_shuffle_ps(sinVector, sinVector, _MM_SHUFFLE(3, 0, 1, 2));
    // x = cos,y = 0,z = -sin, w = 0
    sinVector = _mm_mul_ps(sinVector, c_vec4NegateZ.vectorM128);
    matrix.row[0] = sinVector;
    matrix.row[3] = c_vec4IdMatrixRow3.vectorM128;

    return matrix;
}

inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix4MakeZRotation(float rad) {
    GLKMatrix4M128 matrix;
    float sinRad = sinf(rad);
    float cosRad = cosf(rad);
    __m128 sinVector = _mm_set_ss(sinRad);
    __m128 cosVector = _mm_set_ss(cosRad);
    // x = cos,y = sin,z = 0, w = 0
    cosVector = _mm_unpacklo_ps(cosVector, sinVector);
    matrix.row[0] = cosVector;
    // x = sin,y = cos,z = 0, w = 0
    cosVector = _mm_shuffle_ps(cosVector, cosVector, _MM_SHUFFLE(3, 2, 0, 1));
    // x = cos,y = -sin,z = 0, w = 0
    cosVector = _mm_mul_ps(cosVector, c_vec4NegateX.vectorM128);
    matrix.row[1] = cosVector;
    matrix.row[2] = c_vec4IdMatrixRow2.vectorM128;
    matrix.row[3] = c_vec4IdMatrixRow3.vectorM128;

    return matrix;
}

inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix4MakeRotation(__m128 axisVector, float rad) {
    GLKMatrix4M128 res;
    float sinRad = sinf(rad);
    float cosRad = cosf(rad);

    __m128 c2 = _mm_set_ps1(1.0f - cosRad);
    __m128 c1 = _mm_set_ps1(cosRad);
    __m128 c0 = _mm_set_ps1(sinRad);

    __m128 n0 = _mm_shuffle_ps(axisVector, axisVector, _MM_SHUFFLE(3, 0, 2, 1));
    __m128 n1 = _mm_shuffle_ps(axisVector, axisVector, _MM_SHUFFLE(3, 1, 0, 2));

    __m128 v0 = _mm_mul_ps(c2, n0);
    v0 = _mm_mul_ps(v0, n1);

    __m128 r0 = _mm_mul_ps(c2, axisVector);
    r0 = _mm_mul_ps(r0, axisVector);
    r0 = _mm_add_ps(r0, c1);

    __m128 r1 = _mm_mul_ps(c0, axisVector);
    r1 = _mm_add_ps(r1, v0);
    __m128 r2 = _mm_mul_ps(c0, axisVector);
    r2 = _mm_sub_ps(v0, r2);

    v0 = _mm_and_ps(r0, c_vec4MaskXYZ.vectorM128);
    __m128 v1 = _mm_shuffle_ps(r1, r2, _MM_SHUFFLE(2, 1, 2, 0));
    v1 = _mm_shuffle_ps(v1, v1, _MM_SHUFFLE(0, 3, 2, 1));
    __m128 v2 = _mm_shuffle_ps(r1, r2, _MM_SHUFFLE(0, 0, 1, 1));
    v2 = _mm_shuffle_ps(v2, v2, _MM_SHUFFLE(2, 0, 2, 0));

    r2 = _mm_shuffle_ps(v0, v1, _MM_SHUFFLE(1, 0, 3, 0));
    r2 = _mm_shuffle_ps(r2, r2, _MM_SHUFFLE(1, 3, 2, 0));

    res.row[0] = r2;

    r2 = _mm_shuffle_ps(v0, v1, _MM_SHUFFLE(3, 2, 3, 1));
    r2 = _mm_shuffle_ps(r2, r2, _MM_SHUFFLE(1, 3, 0, 2));
    res.row[1] = r2;

    v2 = _mm_shuffle_ps(v2, v0, _MM_SHUFFLE(3, 2, 1, 0));
    res.row[2] = v2;
    res.row[3] = c_vec4IdMatrixRow3.vectorM128;
    return res;
}

inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix4MultiplyMatrix4(GLKMatrix4M128 m1, GLKMatrix4M128& m2) {
    GLKMatrix4M128 res;
    // Use tmpW to hold the original row
    __m128 tmpW = m1.row[0];
    // Splat the component X,Y,Z then W
    __m128 tmpX = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(0, 0, 0, 0));
    __m128 tmpY = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(1, 1, 1, 1));
    __m128 tmpZ = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(2, 2, 2, 2));
    tmpW = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(3, 3, 3, 3));
    // Perform the operation on the first row

    tmpX = _mm_mul_ps(tmpX, m2.row[0]);
    tmpY = _mm_mul_ps(tmpY, m2.row[1]);
    tmpZ = _mm_mul_ps(tmpZ, m2.row[2]);
    tmpW = _mm_mul_ps(tmpW, m2.row[3]);
    // Perform a binary add to reduce cumulative errors
    tmpX = _mm_add_ps(tmpX, tmpZ);
    tmpY = _mm_add_ps(tmpY, tmpW);
    tmpX = _mm_add_ps(tmpX, tmpY);
    res.row[0] = tmpX;
    // Repeat for the other 3 rows
    tmpW = m1.row[1];
    tmpX = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(0, 0, 0, 0));
    tmpY = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(1, 1, 1, 1));
    tmpZ = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(2, 2, 2, 2));
    tmpW = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(3, 3, 3, 3));
    tmpX = _mm_mul_ps(tmpX, m2.row[0]);
    tmpY = _mm_mul_ps(tmpY, m2.row[1]);
    tmpZ = _mm_mul_ps(tmpZ, m2.row[2]);
    tmpW = _mm_mul_ps(tmpW, m2.row[3]);
    tmpX = _mm_add_ps(tmpX, tmpZ);
    tmpY = _mm_add_ps(tmpY, tmpW);
    tmpX = _mm_add_ps(tmpX, tmpY);
    res.row[1] = tmpX;
    tmpW = m1.row[2];
    tmpX = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(0, 0, 0, 0));
    tmpY = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(1, 1, 1, 1));
    tmpZ = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(2, 2, 2, 2));
    tmpW = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(3, 3, 3, 3));
    tmpX = _mm_mul_ps(tmpX, m2.row[0]);
    tmpY = _mm_mul_ps(tmpY, m2.row[1]);
    tmpZ = _mm_mul_ps(tmpZ, m2.row[2]);
    tmpW = _mm_mul_ps(tmpW, m2.row[3]);
    tmpX = _mm_add_ps(tmpX, tmpZ);
    tmpY = _mm_add_ps(tmpY, tmpW);
    tmpX = _mm_add_ps(tmpX, tmpY);
    res.row[2] = tmpX;
    tmpW = m1.row[3];
    tmpX = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(0, 0, 0, 0));
    tmpY = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(1, 1, 1, 1));
    tmpZ = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(2, 2, 2, 2));
    tmpW = _mm_shuffle_ps(tmpW, tmpW, _MM_SHUFFLE(3, 3, 3, 3));
    tmpX = _mm_mul_ps(tmpX, m2.row[0]);
    tmpY = _mm_mul_ps(tmpY, m2.row[1]);
    tmpZ = _mm_mul_ps(tmpZ, m2.row[2]);
    tmpW = _mm_mul_ps(tmpW, m2.row[3]);
    tmpX = _mm_add_ps(tmpX, tmpZ);
    tmpY = _mm_add_ps(tmpY, tmpW);
    tmpX = _mm_add_ps(tmpX, tmpY);
    res.row[3] = tmpX;

    return res;
}

// Note: If input matrix isn't transposed, output will be a transpose of the inverse.
// Similarly, if input is transposed, output will be the inverse
// Example:
//    Input: M
//    Output: Transpose(MInverse)
//    Input: Transpose(M)
//    Output: MInverse
inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix4Invert(GLKMatrix4M128 mT, BOOL* isInvertible) {
    __m128 v00 = _mm_shuffle_ps(mT.row[2], mT.row[2], _MM_SHUFFLE(1, 1, 0, 0));
    __m128 v10 = _mm_shuffle_ps(mT.row[3], mT.row[3], _MM_SHUFFLE(3, 2, 3, 2));
    __m128 v01 = _mm_shuffle_ps(mT.row[0], mT.row[0], _MM_SHUFFLE(1, 1, 0, 0));
    __m128 v11 = _mm_shuffle_ps(mT.row[1], mT.row[1], _MM_SHUFFLE(3, 2, 3, 2));
    __m128 v02 = _mm_shuffle_ps(mT.row[2], mT.row[0], _MM_SHUFFLE(2, 0, 2, 0));
    __m128 v12 = _mm_shuffle_ps(mT.row[3], mT.row[1], _MM_SHUFFLE(3, 1, 3, 1));

    __m128 d0 = _mm_mul_ps(v00, v10);
    __m128 d1 = _mm_mul_ps(v01, v11);
    __m128 d2 = _mm_mul_ps(v02, v12);

    v00 = _mm_shuffle_ps(mT.row[2], mT.row[2], _MM_SHUFFLE(3, 2, 3, 2));
    v10 = _mm_shuffle_ps(mT.row[3], mT.row[3], _MM_SHUFFLE(1, 1, 0, 0));
    v01 = _mm_shuffle_ps(mT.row[0], mT.row[0], _MM_SHUFFLE(3, 2, 3, 2));
    v11 = _mm_shuffle_ps(mT.row[1], mT.row[1], _MM_SHUFFLE(1, 1, 0, 0));
    v02 = _mm_shuffle_ps(mT.row[2], mT.row[0], _MM_SHUFFLE(3, 1, 3, 1));
    v12 = _mm_shuffle_ps(mT.row[3], mT.row[1], _MM_SHUFFLE(2, 0, 2, 0));

    v00 = _mm_mul_ps(v00, v10);
    v01 = _mm_mul_ps(v01, v11);
    v02 = _mm_mul_ps(v02, v12);
    d0 = _mm_sub_ps(d0, v00);
    d1 = _mm_sub_ps(d1, v01);
    d2 = _mm_sub_ps(d2, v02);
    // v11 = d0Y,d0W,d2Y,d2Y
    v11 = _mm_shuffle_ps(d0, d2, _MM_SHUFFLE(1, 1, 3, 1));
    v00 = _mm_shuffle_ps(mT.row[1], mT.row[1], _MM_SHUFFLE(1, 0, 2, 1));
    v10 = _mm_shuffle_ps(v11, d0, _MM_SHUFFLE(0, 3, 0, 2));
    v01 = _mm_shuffle_ps(mT.row[0], mT.row[0], _MM_SHUFFLE(0, 1, 0, 2));
    v11 = _mm_shuffle_ps(v11, d0, _MM_SHUFFLE(2, 1, 2, 1));
    // v13 = d1Y,d1W,d2W,d2W
    __m128 v13 = _mm_shuffle_ps(d1, d2, _MM_SHUFFLE(3, 3, 3, 1));
    v02 = _mm_shuffle_ps(mT.row[3], mT.row[3], _MM_SHUFFLE(1, 0, 2, 1));
    v12 = _mm_shuffle_ps(v13, d1, _MM_SHUFFLE(0, 3, 0, 2));
    __m128 v03 = _mm_shuffle_ps(mT.row[2], mT.row[2], _MM_SHUFFLE(0, 1, 0, 2));
    v13 = _mm_shuffle_ps(v13, d1, _MM_SHUFFLE(2, 1, 2, 1));

    __m128 c0 = _mm_mul_ps(v00, v10);
    __m128 c2 = _mm_mul_ps(v01, v11);
    __m128 c4 = _mm_mul_ps(v02, v12);
    __m128 c6 = _mm_mul_ps(v03, v13);

    // v11 = d0X,d0Y,d2X,d2X
    v11 = _mm_shuffle_ps(d0, d2, _MM_SHUFFLE(0, 0, 1, 0));
    v00 = _mm_shuffle_ps(mT.row[1], mT.row[1], _MM_SHUFFLE(2, 1, 3, 2));
    v10 = _mm_shuffle_ps(d0, v11, _MM_SHUFFLE(2, 1, 0, 3));
    v01 = _mm_shuffle_ps(mT.row[0], mT.row[0], _MM_SHUFFLE(1, 3, 2, 3));
    v11 = _mm_shuffle_ps(d0, v11, _MM_SHUFFLE(0, 2, 1, 2));
    // v13 = d1X,d1Y,d2Z,d2Z
    v13 = _mm_shuffle_ps(d1, d2, _MM_SHUFFLE(2, 2, 1, 0));
    v02 = _mm_shuffle_ps(mT.row[3], mT.row[3], _MM_SHUFFLE(2, 1, 3, 2));
    v12 = _mm_shuffle_ps(d1, v13, _MM_SHUFFLE(2, 1, 0, 3));
    v03 = _mm_shuffle_ps(mT.row[2], mT.row[2], _MM_SHUFFLE(1, 3, 2, 3));
    v13 = _mm_shuffle_ps(d1, v13, _MM_SHUFFLE(0, 2, 1, 2));

    v00 = _mm_mul_ps(v00, v10);
    v01 = _mm_mul_ps(v01, v11);
    v02 = _mm_mul_ps(v02, v12);
    v03 = _mm_mul_ps(v03, v13);
    c0 = _mm_sub_ps(c0, v00);
    c2 = _mm_sub_ps(c2, v01);
    c4 = _mm_sub_ps(c4, v02);
    c6 = _mm_sub_ps(c6, v03);

    v00 = _mm_shuffle_ps(mT.row[1], mT.row[1], _MM_SHUFFLE(0, 3, 0, 3));
    // v10 = d0Z,d0Z,d2X,d2Y
    v10 = _mm_shuffle_ps(d0, d2, _MM_SHUFFLE(1, 0, 2, 2));
    v10 = _mm_shuffle_ps(v10, v10, _MM_SHUFFLE(0, 2, 3, 0));
    v01 = _mm_shuffle_ps(mT.row[0], mT.row[0], _MM_SHUFFLE(2, 0, 3, 1));
    // v11 = d0X,d0W,d2X,d2Y
    v11 = _mm_shuffle_ps(d0, d2, _MM_SHUFFLE(1, 0, 3, 0));
    v11 = _mm_shuffle_ps(v11, v11, _MM_SHUFFLE(2, 1, 0, 3));
    v02 = _mm_shuffle_ps(mT.row[3], mT.row[3], _MM_SHUFFLE(0, 3, 0, 3));
    // v12 = d1Z,d1Z,d2Z,d2W
    v12 = _mm_shuffle_ps(d1, d2, _MM_SHUFFLE(3, 2, 2, 2));
    v12 = _mm_shuffle_ps(v12, v12, _MM_SHUFFLE(0, 2, 3, 0));
    v03 = _mm_shuffle_ps(mT.row[2], mT.row[2], _MM_SHUFFLE(2, 0, 3, 1));
    // v13 = d1X,d1W,d2Z,d2W
    v13 = _mm_shuffle_ps(d1, d2, _MM_SHUFFLE(3, 2, 3, 0));
    v13 = _mm_shuffle_ps(v13, v13, _MM_SHUFFLE(2, 1, 0, 3));

    v00 = _mm_mul_ps(v00, v10);
    v01 = _mm_mul_ps(v01, v11);
    v02 = _mm_mul_ps(v02, v12);
    v03 = _mm_mul_ps(v03, v13);
    __m128 c1 = _mm_sub_ps(c0, v00);
    c0 = _mm_add_ps(c0, v00);
    __m128 c3 = _mm_add_ps(c2, v01);
    c2 = _mm_sub_ps(c2, v01);
    __m128 c5 = _mm_sub_ps(c4, v02);
    c4 = _mm_add_ps(c4, v02);
    __m128 c7 = _mm_add_ps(c6, v03);
    c6 = _mm_sub_ps(c6, v03);

    c0 = _mm_shuffle_ps(c0, c1, _MM_SHUFFLE(3, 1, 2, 0));
    c2 = _mm_shuffle_ps(c2, c3, _MM_SHUFFLE(3, 1, 2, 0));
    c4 = _mm_shuffle_ps(c4, c5, _MM_SHUFFLE(3, 1, 2, 0));
    c6 = _mm_shuffle_ps(c6, c7, _MM_SHUFFLE(3, 1, 2, 0));
    c0 = _mm_shuffle_ps(c0, c0, _MM_SHUFFLE(3, 1, 2, 0));
    c2 = _mm_shuffle_ps(c2, c2, _MM_SHUFFLE(3, 1, 2, 0));
    c4 = _mm_shuffle_ps(c4, c4, _MM_SHUFFLE(3, 1, 2, 0));
    c6 = _mm_shuffle_ps(c6, c6, _MM_SHUFFLE(3, 1, 2, 0));
    // Get the determinate
    __m128 detVector = GLKSSE2DotVector4(c0, mT.row[0]);
    GLKMatrix4M128 res;

    __m128 tmpVector = _mm_cmpeq_ps(detVector, c_vec4AllZeros.vectorM128);
    int comparisonMask = _mm_movemask_ps(tmpVector);

    if (comparisonMask != 0xf) {
        if (isInvertible != nullptr) {
            *isInvertible = true;
        }
        __m128 detInvVector = _mm_div_ps(c_vec4AllOnes.vectorM128, detVector);
        res.row[0] = _mm_mul_ps(c0, detInvVector);
        res.row[1] = _mm_mul_ps(c2, detInvVector);
        res.row[2] = _mm_mul_ps(c4, detInvVector);
        res.row[3] = _mm_mul_ps(c6, detInvVector);
    } else {
        assert(comparisonMask == 0xf);
        if (isInvertible != nullptr) {
            *isInvertible = false;
        }

        res = c_matrix4Identity.matrix4M128;
    }

    return res;
}

inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix3Invert(GLKMatrix4M128 mT, BOOL* isInvertible) {
    // Row1Sh1 = <m12, m10, m11, #>
    __m128 tmpVector1 = _mm_shuffle_ps(mT.row[1], mT.row[1], _MM_SHUFFLE(0, 1, 0, 2));

    // Row1Sh2 = <m11, m12, m10, #>
    __m128 tmpVector2 = _mm_shuffle_ps(mT.row[1], mT.row[1], _MM_SHUFFLE(0, 0, 2, 1));

    // Row2Sh1 = <m22, m20, m21, #>
    __m128 tmpVector3 = _mm_shuffle_ps(mT.row[2], mT.row[2], _MM_SHUFFLE(0, 1, 0, 2));

    __m128 tmpVector4 = _mm_shuffle_ps(mT.row[2], mT.row[2], _MM_SHUFFLE(0, 0, 2, 1));

    // -Row2Sh1
    __m128 tmpVector5;

    // Row2Sh2 = <m21, m22, m20, #>
    __m128 tmpVector6 = tmpVector4;

    // Generate all products and rotate vecs holding right side products so that they
    // match with the left sided ones

    // V1 = <m00m12, m01m10, m02m11>
    tmpVector1 = _mm_mul_ps(mT.row[0], tmpVector1);
    // Rotate components towards lower bytes here to match with tmpVector2
    // <m01m10, m02m11, m00m12>
    tmpVector1 = _mm_shuffle_ps(tmpVector1, tmpVector1, _MM_SHUFFLE(0, 0, 2, 1));

    // v2 = <m00m11, m01m12, m02m10>
    tmpVector2 = _mm_mul_ps(mT.row[0], tmpVector2);

    // <m10m22, m11m20, m12m21>
    tmpVector5 = _mm_mul_ps(mT.row[1], tmpVector3);
    // Rotate components towards lower bytes here to match with tmpVector6
    // v5 = <m11m20, m12m21, m10m22>
    tmpVector5 = _mm_shuffle_ps(tmpVector5, tmpVector5, _MM_SHUFFLE(0, 0, 2, 1));

    // v3 = <m00m22, m01m20, m02m21>
    tmpVector3 = _mm_mul_ps(mT.row[0], tmpVector3);

    // <m00m21, m01m22, m02m20>
    tmpVector4 = _mm_mul_ps(mT.row[0], tmpVector4);
    // Rotate components towards higher bytes here to match with tmpVector3
    // v4 = <m02m20, m00m12, m01m22>
    tmpVector4 = _mm_shuffle_ps(tmpVector4, tmpVector4, _MM_SHUFFLE(0, 1, 0, 2));

    // v6 = <m10m21, m11m22, m12m20>
    tmpVector6 = _mm_mul_ps(mT.row[1], tmpVector6);

    // Subtract vecs
    tmpVector1 = _mm_sub_ps(tmpVector2, tmpVector1);
    tmpVector2 = _mm_sub_ps(tmpVector3, tmpVector4);
    tmpVector3 = _mm_sub_ps(tmpVector6, tmpVector5);

    // Reorder
    tmpVector1 = _mm_shuffle_ps(tmpVector1, tmpVector1, _MM_SHUFFLE(0, 0, 2, 1));
    tmpVector2 = _mm_shuffle_ps(tmpVector2, tmpVector2, _MM_SHUFFLE(0, 1, 0, 2));
    tmpVector3 = _mm_shuffle_ps(tmpVector3, tmpVector3, _MM_SHUFFLE(0, 0, 2, 1));

    // Determinant
    tmpVector4 = GLKSSE2DotVector3(mT.row[0], tmpVector3);

    // Use union since vector4 writes must be in 16byte chunks and thus last row requires an additional 4 bytes
    GLKMatrix4M128 res;

    __m128 comp = _mm_cmpeq_ps(tmpVector4, c_vec4AllZeros.vectorM128);
    int comparisonMask = _mm_movemask_ps(comp);

    // if (tmpVector4.m128_f32[0] == 0.0f) {
    if (comparisonMask == 0xf) {
        if (isInvertible != nullptr) {
            *isInvertible = false;
        }

        // Output is unpacked so the first 3 rows of the matrix4 identity matrix are the same as those of the matrix3 identity matrix
        res.row[0] = c_vec4IdMatrixRow0.vectorM128;
        res.row[1] = c_vec4IdMatrixRow1.vectorM128;
        res.row[2] = c_vec4IdMatrixRow2.vectorM128;
    } else {
        if (isInvertible != nullptr) {
            *isInvertible = true;
        }

        // DeterminantInv
        tmpVector5 = _mm_div_ps(c_vec4AllOnes.vectorM128, tmpVector4);

        // Multiply by determinantInv
        tmpVector1 = _mm_mul_ps(tmpVector1, tmpVector5);
        tmpVector2 = _mm_mul_ps(tmpVector2, tmpVector5);
        tmpVector3 = _mm_mul_ps(tmpVector3, tmpVector5);

        // Note: Use GLKMatrix4 union to store in order to avoid potential false positive of a buffer overflow
        res.row[0] = tmpVector1;
        res.row[1] = tmpVector2;
        res.row[2] = tmpVector3;
    }

    return res;
}

inline void GLK_CALLCONV GLKSSE2Matrix4TranslateVector4(GLKMatrix4M128& m, __m128 translateVector) {
    // m.m30 = transX * m.m00 + transY * m.m10 + transZ * m.m20 + transW * m.m30;
    // m.m31 = transX * m.m01 + transY * m.m11 + transZ * m.m21 + transW * m.m31;
    // m.m32 = transX * m.m02 + transY * m.m12 + transZ * m.m22 + transW * m.m32;
    // m.m33 = transX * m.m03 + transY * m.m13 + transZ * m.m23 + transW * m.m33;
    __m128 transXSplat = _mm_shuffle_ps(translateVector, translateVector, _MM_SHUFFLE(0, 0, 0, 0));
    __m128 transYSplat = _mm_shuffle_ps(translateVector, translateVector, _MM_SHUFFLE(1, 1, 1, 1));
    __m128 transZSplat = _mm_shuffle_ps(translateVector, translateVector, _MM_SHUFFLE(2, 2, 2, 2));
    __m128 transWSplat = _mm_shuffle_ps(translateVector, translateVector, _MM_SHUFFLE(3, 3, 3, 3));

    __m128 tmpVector0 = _mm_mul_ps(transXSplat, m.row[0]);
    __m128 tmpVector1 = _mm_mul_ps(transYSplat, m.row[1]);
    __m128 tmpVector2 = _mm_mul_ps(transZSplat, m.row[2]);
    __m128 tmpVector3 = _mm_mul_ps(transWSplat, m.row[3]);
    tmpVector0 = _mm_add_ps(tmpVector0, tmpVector1);
    tmpVector2 = _mm_add_ps(tmpVector2, tmpVector3);

    m.row[3] = _mm_add_ps(tmpVector0, tmpVector2);
}

inline GLKMatrix4M128 GLK_CALLCONV GLKSSE2Matrix4ScaleVector4(GLKMatrix4M128 m, __m128 scaleVector) {
    GLKMatrix4M128 res;
    __m128 scaleXSplat = _mm_shuffle_ps(scaleVector, scaleVector, _MM_SHUFFLE(0, 0, 0, 0));
    __m128 scaleYSplat = _mm_shuffle_ps(scaleVector, scaleVector, _MM_SHUFFLE(1, 1, 1, 1));
    __m128 scaleZSplat = _mm_shuffle_ps(scaleVector, scaleVector, _MM_SHUFFLE(2, 2, 2, 2));
    __m128 scaleWSplat = _mm_shuffle_ps(scaleVector, scaleVector, _MM_SHUFFLE(3, 3, 3, 3));

    res.row[0] = _mm_mul_ps(scaleXSplat, m.row[0]);
    res.row[1] = _mm_mul_ps(scaleYSplat, m.row[1]);
    res.row[2] = _mm_mul_ps(scaleZSplat, m.row[2]);
    res.row[3] = _mm_mul_ps(scaleWSplat, m.row[3]);
    return res;
}