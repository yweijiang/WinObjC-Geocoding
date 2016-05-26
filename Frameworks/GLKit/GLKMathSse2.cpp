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

#define _USE_MATH_DEFINES // for C++
//#include "GLKit\GLKMathSse2.h"
#include "GLKit\GLKMath.h"

#if defined(USE_SSE)

const GLKMatrix3 GLKMatrix3Identity = GLKMatrix3MakeIdentity();
const GLKMatrix4 GLKMatrix4Identity = GLKMatrix4MakeIdentity();
const GLKQuaternion GLKQuaternionIdentity = GLKQuaternionMakeIdentity();

bool IsSseEnabled() {
    return true;
}

/**
@Status Interoperable
*/
GLKMatrix3 GLKMatrix3MakeIdentity() {
    return matrix3Identity.matrix3;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4MakeIdentity() {
    return matrix4Identity.matrix4;
}

/**
@Status Interoperable
*/
GLKQuaternion GLKQuaternionMakeIdentity() {
    return quatIdentity.glkQuaternion;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4MakeRotation(float rad, float x, float y, float z) {
    GLKMatrix4SSE result;
    __m128 axisVector = { x, y, z, 0.0f };
    __m128 normalizedAxis = GLKSSE2NormalizeVector3(axisVector);

    result.vectors = GLKSSE2Matrix4MakeRotation(normalizedAxis, rad);

    return result.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4MakeXRotation(float rad) {
    GLKMatrix4SSE res;
    res.vectors = GLKSSE2Matrix4MakeXRotation(rad);

    return res.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4MakeYRotation(float rad) {
    GLKMatrix4SSE res;
    res.vectors = GLKSSE2Matrix4MakeYRotation(rad);

    return res.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4MakeZRotation(float rad) {
    GLKMatrix4SSE res;

    res.vectors = GLKSSE2Matrix4MakeZRotation(rad);

    return res.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4Rotate(GLKMatrix4 m, float rad, float x, float y, float z) {
    GLKMatrixSSE originalMatrix = GLKMatrixSSE(m.m);
    GLKMatrix4SSE result;
    __m128 axisVector = { x, y, z, 0.0f };
    __m128 normalizedAxis = GLKSSE2NormalizeVector3(axisVector);

    GLKMatrixSSE rotMatrix = GLKSSE2Matrix4MakeRotation(normalizedAxis, rad);

    result.vectors = GLKSSE2Matrix4MultiplyMatrix4(rotMatrix, originalMatrix);

    return result.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4MakeTranslation(float x, float y, float z) {
    GLKMatrix4SSE res;

    res.row[0] = vectorIdMatrixRow0;
    res.row[1] = vectorIdMatrixRow1;
    res.row[2] = vectorIdMatrixRow2;
    res.row[3] = GLKSSE2Set(x, y, z, 1.0f);

    return res.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4RotateX(GLKMatrix4 m, float rad) {
    GLKMatrix4SSE result;
    GLKMatrixSSE rot = GLKSSE2Matrix4MakeXRotation(rad);
    GLKMatrixSSE matrix = GLKMatrixSSE(m.m);
    result.vectors = GLKSSE2Matrix4MultiplyMatrix4(rot, matrix);

    return result.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4RotateY(GLKMatrix4 m, float rad) {
    GLKMatrix4SSE result;
    GLKMatrixSSE rot = GLKSSE2Matrix4MakeYRotation(rad);
    GLKMatrixSSE matrix = GLKMatrixSSE(m.m);
    result.vectors = GLKSSE2Matrix4MultiplyMatrix4(rot, matrix);

    return result.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4RotateZ(GLKMatrix4 m, float rad) {
    GLKMatrix4SSE result;
    GLKMatrixSSE rot = GLKSSE2Matrix4MakeZRotation(rad);
    GLKMatrixSSE matrix = GLKMatrixSSE(m.m);
    result.vectors = GLKSSE2Matrix4MultiplyMatrix4(rot, matrix);

    return result.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4Translate(GLKMatrix4 m, float x, float y, float z) {
#if 0
    GLKMatrixSSE translation;
    translation.row[0] = vectorIdMatrixRow0;
    translation.row[1] = vectorIdMatrixRow1;
    translation.row[2] = vectorIdMatrixRow2;
    translation.row[3] = GLKSSE2Set(x, y, z, 0.0f);
    GLKMatrixSSE matrix = GLKMatrixSSE(m.m);
    result.vectors = GLKSSE2Matrix4MultiplyMatrix4(translation, matrix);
#else
    GLKMatrix4SSE result = GLKMatrix4SSE(m.m);
    __m128 translateVector = { x, y, z, 1.0f };
    GLKSSE2Matrix4TranslateVector4(result.vectors, translateVector);
#endif

    return result.matrix4;
}

// Verify original and this one with iOS output
// Based on XMMatrixPerspectiveOffCenterRH written by Chuck Walbourn.
/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4MakeFrustum(float left, float right, float bottom, float top, float nearZ, float farZ) {
    GLKMatrix4SSE m;
    const float TwoNearZ = nearZ + nearZ;
    const float FarPlusNear = nearZ + farZ;
    const float ReciprocalWidth = 1.0f / (right - left);
    const float ReciprocalHeight = 1.0f / (top - bottom);
    const float ReciprocalDepth = 1.0f / (nearZ - farZ);
    // Note: This is recorded on the stack
    // TODO: Do multiplication by TwoNearZ after loading values into SSE reg
    __m128 rMem = { TwoNearZ * ReciprocalWidth, TwoNearZ * ReciprocalHeight, TwoNearZ * farZ * ReciprocalDepth, 0 };
    // Copy from memory to SSE register
    __m128 values = rMem;
    __m128 tmpVector = _mm_setzero_ps();
    // Copy x only
    tmpVector = _mm_move_ss(tmpVector, values);
    // TwoNearZ*ReciprocalWidth,0,0,0
    m.row[0] = tmpVector;
    // 0,TwoNearZ*ReciprocalHeight,0,0
    tmpVector = values;
    tmpVector = _mm_and_ps(tmpVector, vectorUiMaskY);
    m.row[1] = tmpVector;
    // 0,0,fRange,1.0f
    m.row[2] = GLKSSE2Set((left + right) * ReciprocalWidth, (top + bottom) * ReciprocalHeight, (farZ + nearZ) * ReciprocalDepth, -1.0f);
    // 0,0,-fRange * NearZ,0.0f
    values = _mm_and_ps(values, vectorUiMaskZ);
    m.row[3] = values;
    return m.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4MakePerspective(float yrad, float aspect, float nearZ, float farZ) {
    float Height = 1.0f / tanf(yrad * 0.5f);

    float ReciprocalZ = 1.0f / (nearZ - farZ);
    float TwoNearZFarZ = 2 * nearZ * farZ;

    // Note: This is recorded on the stack
    __m128 rMem = { Height / aspect, Height, ReciprocalZ * (nearZ + farZ), ReciprocalZ * TwoNearZFarZ };
    // Copy from memory to SSE register
    __m128 values = rMem;
    __m128 tmpVector = _mm_setzero_ps();
    // Copy x only
    tmpVector = _mm_move_ss(tmpVector, values);
    // cosAngle / sinAngle,0,0,0
    GLKMatrix4SSE m;
    m.row[0] = tmpVector;
    // 0,Height / AspectHByW,0,0
    tmpVector = values;
    tmpVector = _mm_and_ps(tmpVector, vectorUiMaskY);
    m.row[1] = tmpVector;
    // x=fRange,y=fRange * NearZ,0,-1.0f
    tmpVector = _mm_setzero_ps();
    values = _mm_shuffle_ps(values, vectorNegateIdMatrixRow3, _MM_SHUFFLE(3, 2, 3, 2));
    // 0,0,fRange,-1.0f
    tmpVector = _mm_shuffle_ps(tmpVector, values, _MM_SHUFFLE(3, 0, 0, 0));
    m.row[2] = tmpVector;
    // 0,0,fRange * NearZ,0.0f
    tmpVector = _mm_shuffle_ps(tmpVector, values, _MM_SHUFFLE(2, 1, 0, 0));
    m.row[3] = tmpVector;
    return m.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4MakeLookAt(
    float eyeX, float eyeY, float eyeZ, float centerX, float centerY, float centerZ, float upX, float upY, float upZ) {
    GLKMatrix4SSE lookAtMatrix;

    __m128 centerVector = { centerX, centerY, centerZ, 0.0f };
    __m128 upVector = { upX, upY, upZ, 0.0f };
    __m128 eyePosVector = { eyeX, eyeY, eyeZ, 0.0f };
    // Really negative eye direction
    __m128 eyeDirVector = _mm_sub_ps(eyePosVector, centerVector);

    // r2 ~ Forward
    __m128 r2 = GLKSSE2NormalizeVector3FailSafe(eyeDirVector);

    // r0 ~ Side
    __m128 r0 = GLKSSE2CrossVector3(upVector, r2);
    r0 = GLKSSE2NormalizeVector3FailSafe(r0);

    // Up recomputed
    __m128 r1 = GLKSSE2CrossVector3(r2, r0);

    __m128 NegEyePosition = GLKSSE2NegateVector4(eyePosVector);

    __m128 D0 = GLKSSE2DotVector3(r0, NegEyePosition);
    __m128 D1 = GLKSSE2DotVector3(r1, NegEyePosition);
    __m128 D2 = GLKSSE2DotVector3(r2, NegEyePosition);

    GLKMatrixSSE m;
    m.row[0] = GLKSSE2Select(D0, r0, vectorUiMaskXYZ.vectorM128);
    m.row[1] = GLKSSE2Select(D1, r1, vectorUiMaskXYZ.vectorM128);
    m.row[2] = GLKSSE2Select(D2, r2, vectorUiMaskXYZ.vectorM128);
    m.row[3] = vectorIdMatrixRow3;

    m = GLKMatrixSseTranspose(m);

    // Todo: Use only one temp matrix
    GLKMatrix4SSE mm;

    mm.row[0] = m.row[0];
    mm.row[1] = m.row[1];
    mm.row[2] = m.row[2];
    mm.row[3] = m.row[3];

    return mm.matrix4;
}

/**
@Status Interoperable
*/
void GLKMatrix4MultiplyVector4Array(GLKMatrix4 m, GLKVector4* vecs, size_t numVecs) {
    GLKMatrixSSE matrix;
    __m128 vector;

    // Load M
    matrix.row[0] = _mm_loadu_ps((const float*)&m.m[0]);
    matrix.row[1] = _mm_loadu_ps((const float*)&m.m[4]);
    matrix.row[2] = _mm_loadu_ps((const float*)&m.m[8]);
    matrix.row[3] = _mm_loadu_ps((const float*)&m.m[12]);

    assert((uintptr_t(vecs) & 15) == 0);

    for (size_t i = 0; i < numVecs; i++) {
        vector = _mm_loadu_ps((const float*)vecs[i].v);
        vector = GLKSSE2MultiplyMatrix4Vector4(matrix, vector);
        _mm_storeu_ps(vecs[i].v, vector);
    }
}

/**
@Status Interoperable
*/
GLKVector4 GLKMatrix4MultiplyVector4(GLKMatrix4 m, GLKVector4 vec) {
    const __m128 vector = _mm_loadu_ps((const float*)vec.v);
    GLKMatrixSSE matrix;
    GLKVectorSSE result;

    // Load M
    matrix.row[0] = _mm_loadu_ps((const float*)&m.m[0]);
    matrix.row[1] = _mm_loadu_ps((const float*)&m.m[4]);
    matrix.row[2] = _mm_loadu_ps((const float*)&m.m[8]);
    matrix.row[3] = _mm_loadu_ps((const float*)&m.m[12]);

    // TODO: Determine if there is a benefit of having helper function return GLKVector4 instead of __m128 portion of union struct
    result.vectorM128 = GLKSSE2MultiplyMatrix4Vector4(matrix, vector);
    return result.glkVector4;
}

/**
@Status Interoperable
*/
GLKVector3 GLKMatrix4MultiplyVector3(GLKMatrix4 m, GLKVector3 vec) {
    const __m128 vector = GLKSSE2Set(vec.x, vec.y, vec.z, 0.0f);
    GLKMatrixSSE matrix;
    GLKVectorSSE result;

    // Load M
    matrix.row[0] = _mm_loadu_ps((const float*)&m.m[0]);
    matrix.row[1] = _mm_loadu_ps((const float*)&m.m[4]);
    matrix.row[2] = _mm_loadu_ps((const float*)&m.m[8]);
    matrix.row[3] = _mm_loadu_ps((const float*)&m.m[12]);

    // TODO: Determine if there is a benefit of having helper function return GLKVector3 instead of __m128 portion of union struct
    result.vectorM128 = GLKSSE2MultiplyMatrix4Vector3(matrix, vector);
    return result.glkVector3;
}

/**
@Status Interoperable
*/
GLKVector3 GLKMatrix4MultiplyVector3WithTranslation(GLKMatrix4 m, GLKVector3 vec) {
    const __m128 vector = GLKSSE2Set(vec.x, vec.y, vec.z, 1.0f);
    GLKMatrixSSE matrix;
    GLKVectorSSE result;

    // Load M
    matrix.row[0] = _mm_loadu_ps((const float*)&m.m[0]);
    matrix.row[1] = _mm_loadu_ps((const float*)&m.m[4]);
    matrix.row[2] = _mm_loadu_ps((const float*)&m.m[8]);
    matrix.row[3] = _mm_loadu_ps((const float*)&m.m[12]);

    // TODO: Determine if there is a benefit of having helper function return GLKVector3 instead of __m128 portion of union struct
    result.vectorM128 = GLKSSE2MultiplyMatrix4Vector3Translate(matrix, vector);
    return result.glkVector3;
}

/**
@Status Interoperable
*/
void GLKMatrix4MultiplyVector3ArrayWithTranslation(GLKMatrix4 m, GLKVector3* vecs, size_t numVecs) {
    GLKMatrixSSE matrix = GLKMatrixSSE(m.m);
    __m128 transFormedVector;
    __m128 originalVector;
    originalVector = _mm_loadu_ps((const float*)vecs[0].v);
    int numVectors = static_cast<int>(numVecs);
    int i = 0;

    for (i = 0; i < (numVectors - 1); i++) {
        transFormedVector = GLKSSE2MultiplyMatrix4Vector3Translate(matrix, originalVector);
        // fetch next vector before writing transformed vector to avoid overwriting the first component of the next vector
        originalVector = _mm_loadu_ps((const float*)vecs[i + 1].v);
        _mm_storeu_ps(vecs[i].v, transFormedVector);
    }

    transFormedVector = GLKSSE2MultiplyMatrix4Vector3Translate(matrix, originalVector);
    vecs[i].x = transFormedVector.m128_f32[0];
    vecs[i].y = transFormedVector.m128_f32[1];
    vecs[i].z = transFormedVector.m128_f32[2];
}

/**
@Status Interoperable
*/
void GLKMatrix4MultiplyVector3Array(GLKMatrix4 m, GLKVector3* vecs, size_t numVecs) {
    GLKMatrixSSE matrix = GLKMatrixSSE(m.m);

    GLKSSE2Matrix4MultiplyVector3Array(matrix, vecs, numVecs);
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4Multiply(GLKMatrix4 matrix2, GLKMatrix4 matrix1) {
    GLKMatrixSSE m1 = GLKMatrixSSE(matrix1.m);
    GLKMatrixSSE m2 = GLKMatrixSSE(matrix2.m);

    GLKMatrix4SSE res;
    // Use wSplat to hold the original row
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

    return res.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4Transpose(GLKMatrix4 mat) {
    GLKMatrix4SSE res = GLKMatrix4SSE(mat.m);

    res.vectors = GLKMatrixSseTranspose(res.vectors);

    return res.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4InvertAndTranspose(GLKMatrix4 m, BOOL* isInvertible) {
    GLKMatrixSSE matrix = GLKMatrixSSE(m.m);

    GLKMatrix4SSE res;

    // Output of GLKSSE2Matrix4Invert is already transposed so we are done
    res.vectors = GLKSSE2Matrix4Invert(matrix, isInvertible);

    return res.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4Invert(GLKMatrix4 m, BOOL* isInvertible) {
    GLKMatrixSSE matrix = GLKMatrixSSE(m.m);
    GLKMatrix4SSE res;

    // Get the transposed inverse
    res.vectors = GLKSSE2Matrix4Invert(matrix, isInvertible);

    // If invertible, transpose to get inverse
    if ((isInvertible != nullptr) && (*isInvertible == TRUE)) {
#if 0
        res.vectors = GLKMatrixSseTranspose(res.vectors);
#else
        _MM_TRANSPOSE4_PS(res.row[0], res.row[1], res.row[2], res.row[3]);
#endif
    }

    return res.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix3 GLKMatrix3Invert(GLKMatrix3 m, BOOL* isInvertible) {
    GLKMatrixSSE matrix;
    GLKMatrixSSE matrixInv;
    GLKMatrix4SSE res;

    // Unpack Matrix3 in Matrix4
    matrix.row[0] = _mm_loadu_ps(&m.m[0]);
    matrix.row[1] = _mm_loadu_ps(&m.m[3]);
    matrix.row[2] = { m.m[6], m.m[7], m.m[8], 0.0f };

    // Invert
    matrixInv = GLKSSE2Matrix3Invert(matrix, isInvertible);

    // Output of inversion is transposed so transpose it to get the expected result
    matrixInv = GLKMatrixSseTranspose(matrixInv);

    // Pack output into matrix3
    _mm_storeu_ps(&res.matrix4.m[0], matrixInv.row[0]);
    _mm_storeu_ps(&res.matrix4.m[3], matrixInv.row[1]);
    _mm_storeu_ps(&res.matrix4.m[6], matrixInv.row[2]);

    return res.matrix3;
}

/**
@Status Interoperable
*/
GLKMatrix3 GLKMatrix3InvertAndTranspose(GLKMatrix3 m, BOOL* isInvertible) {
    GLKMatrixSSE matrix;
    GLKMatrixSSE matrixInv;
    GLKMatrix4SSE res;

    // Unpack Matrix3 in Matrix4
    matrix.row[0] = _mm_loadu_ps(&m.m[0]);
    matrix.row[1] = _mm_loadu_ps(&m.m[3]);
    matrix.row[2] = { m.m[6], m.m[7], m.m[8], 0.0f };

    // Since output is transposed, we are done
    matrixInv = GLKSSE2Matrix3Invert(matrix, isInvertible);

    // Pack output into matrix3
    _mm_storeu_ps(&res.matrix4.m[0], matrixInv.row[0]);
    _mm_storeu_ps(&res.matrix4.m[3], matrixInv.row[1]);
    _mm_storeu_ps(&res.matrix4.m[6], matrixInv.row[2]);

    return res.matrix3;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4MakeOrtho(float left, float right, float bot, float top, float nearZ, float farZ) {
    GLKMatrix4SSE result;
    float fReciprocalWidth = 1.0f / (right - left);
    float fReciprocalHeight = 1.0f / (top - bot);
    float fRange = 1.0f / (farZ - nearZ);
    // Note: This is recorded on the stack
    __m128 rMem = { fReciprocalWidth, fReciprocalHeight, fRange, 1.0f };
    __m128 rMem2 = { -(left + right), -(top + bot), -(nearZ + farZ), 1.0f };
    // Copy from memory to SSE register
    __m128 values = rMem;
    __m128 tmpVector = _mm_setzero_ps();
    // Copy x only
    tmpVector = _mm_move_ss(tmpVector, values);
    // fReciprocalWidth*2,0,0,0
    tmpVector = _mm_add_ss(tmpVector, tmpVector);
    result.row[0] = tmpVector;
    // 0,fReciprocalHeight*2,0,0
    tmpVector = values;
    tmpVector = _mm_and_ps(tmpVector, vectorUiMaskY);
    tmpVector = _mm_add_ps(tmpVector, tmpVector);
    result.row[1] = tmpVector;
    // 0,0,fRange,0.0f
    // Implementation1:
    tmpVector = GLKSSE2NegateVector4(values);
    tmpVector = _mm_and_ps(tmpVector, vectorUiMaskZ);
    tmpVector = _mm_add_ps(tmpVector, tmpVector);
    // Implementation2:
    // tmpVector = _mm_setzero_ps();
    // tmpVector = _mm_sub_ps(tmpVector, values);
    // tmpVector = _mm_and_ps(tmpVector, vectorUiMaskZ);
    // tmpVector = _mm_add_ps(tmpVector, tmpVector);

    result.row[2] = tmpVector;
    // -(left + right)*fReciprocalWidth,-(top + bot)*fReciprocalHeight,fRange*-(near + far),1.0f
    values = _mm_mul_ps(values, rMem2);
    result.row[3] = values;

    return result.matrix4;
}

/**
@Status Interoperable
*/
GLKVector3 GLKQuaternionRotateVector3(GLKQuaternion q, GLKVector3 v) {
    __m128 quatVector = _mm_loadu_ps(q.q);
    __m128 axisVector = GLKSSE2QuaternionAxis(quatVector, q.w);
    float angle = GLKQuaternionAngle(q);
    GLKMatrixSSE m = GLKSSE2Matrix4MakeRotation(axisVector, angle);
    GLKSSE2Matrix4MultiplyVector3Array(m, &v, 1);

    return v;
}

/**
@Status Interoperable
*/
void GLKQuaternionRotateVector3Array(GLKQuaternion q, GLKVector3* vecs, size_t numVecs) {
    __m128 quatVector = _mm_loadu_ps(q.q);
    __m128 axisVector = GLKSSE2QuaternionAxis(quatVector, q.w);
    float angle = GLKQuaternionAngle(q);
    GLKMatrixSSE m = GLKSSE2Matrix4MakeRotation(axisVector, angle);
    GLKSSE2Matrix4MultiplyVector3Array(m, vecs, numVecs);
}

/**
@Status Interoperable
*/
void GLKQuaternionRotateVector4Array(GLKQuaternion q, GLKVector4* vecs, size_t numVecs) {
    __m128 quatVector = _mm_loadu_ps(q.q);
    __m128 axisVector = GLKSSE2QuaternionAxis(quatVector, q.w);
    float angle = GLKQuaternionAngle(q);
    GLKMatrixSSE m = GLKSSE2Matrix4MakeRotation(axisVector, angle);
    GLKSSE2Matrix4MultiplyVector4Array(m, vecs, numVecs);
}

/**
@Status Interoperable
*/
GLKQuaternion GLKQuaternionMakeWithMatrix3(GLKMatrix3 mat) {
    GLKQuaternion res;

    float trace = mat.m00 + mat.m11 + mat.m22;
    if (trace > COMPARISON_EPSILON) {
        trace = trace + 1.f;
        float inv2SqrtTrace = 0.5f / sqrtf(trace);

        res.x = (mat.m12 - mat.m21) * inv2SqrtTrace;
        res.y = (mat.m20 - mat.m02) * inv2SqrtTrace;
        res.z = (mat.m01 - mat.m10) * inv2SqrtTrace;
        res.w = trace * inv2SqrtTrace;
    } else if ((mat.m00 > mat.m11) && (mat.m00 > mat.m22)) {
        trace = 1.f + mat.m00 - mat.m11 - mat.m22;
        float inv2SqrtTrace = 0.5f / sqrtf(trace);

        res.x = trace * inv2SqrtTrace;
        res.y = (mat.m10 + mat.m01) * inv2SqrtTrace;
        res.z = (mat.m02 + mat.m20) * inv2SqrtTrace;
        res.w = (mat.m12 - mat.m21) * inv2SqrtTrace;
    } else if (mat.m11 > mat.m22) {
        trace = 1.f + mat.m11 - mat.m00 - mat.m22;
        float inv2SqrtTrace = 0.5f / sqrtf(trace);

        res.x = (mat.m10 + mat.m01) * inv2SqrtTrace;
        res.y = trace * inv2SqrtTrace;
        res.z = (mat.m21 + mat.m12) * inv2SqrtTrace;
        res.w = (mat.m20 - mat.m02) * inv2SqrtTrace;
    } else {
        trace = 1.f + mat.m22 - mat.m00 - mat.m11;
        float inv2SqrtTrace = 0.5f / sqrtf(trace);

        res.x = (mat.m02 + mat.m20) * inv2SqrtTrace;
        res.y = (mat.m21 + mat.m12) * inv2SqrtTrace;
        res.z = trace * inv2SqrtTrace;
        res.w = (mat.m01 - mat.m10) * inv2SqrtTrace;
    }

    return res;
}

/**
@Status Interoperable
*/
GLKQuaternion GLKQuaternionMakeWithMatrix4(GLKMatrix4 mat) {
    GLKQuaternion res = { 0 };

    return res;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4RotateWithVector3(GLKMatrix4 m, float radians, GLKVector3 axis) {
    GLKMatrixSSE matrix = GLKMatrixSSE(m.m);
    GLKMatrix4SSE result;
    __m128 axisVector = { axis.x, axis.y, axis.z, 0.0f };
    __m128 normalizedAxis = GLKSSE2NormalizeVector3(axisVector);

    GLKMatrixSSE rot = GLKSSE2Matrix4MakeRotation(normalizedAxis, radians);

    result.vectors = GLKSSE2Matrix4MultiplyMatrix4(rot, matrix);

    return result.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4RotateWithVector4(GLKMatrix4 m, float radians, GLKVector4 axis) {
    GLKMatrixSSE matrix = GLKMatrixSSE(m.m);
    GLKMatrix4SSE result;
    __m128 axisVector = _mm_loadu_ps(axis.v);
    __m128 normalizedAxis = GLKSSE2NormalizeVector3(axisVector);

    GLKMatrixSSE rot = GLKSSE2Matrix4MakeRotation(normalizedAxis, radians);

    result.vectors = GLKSSE2Matrix4MultiplyMatrix4(rot, matrix);

    return result.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4TranslateWithVector3(GLKMatrix4 m, GLKVector3 v) {
    // TODO: Consider using GLKSSE2MultiplyMatrix4Vector3Translate instead to generate row 4
    GLKMatrix4SSE res = GLKMatrix4SSE(m.m);
    __m128 translateVector = { v.x, v.y, v.z, 1.0f };

    GLKSSE2Matrix4TranslateVector4(res.vectors, translateVector);

    return res.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4TranslateWithVector4(GLKMatrix4 m, GLKVector4 v) {
    // TODO: Consider using something similar to GLKSSE2MultiplyMatrix4Vector3Translate but use a vec4 to generate row 4
    GLKMatrix4SSE res = GLKMatrix4SSE(m.m);
    __m128 translateVector = _mm_load_ps1(v.v);

    GLKSSE2Matrix4TranslateVector4(res.vectors, translateVector);

    return res.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4Scale(GLKMatrix4 m, float x, float y, float z) {
    GLKMatrix4SSE res = GLKMatrix4SSE(m.m);
    __m128 scaleVector = { x, y, z, 1.0f };

    res.vectors = GLKSSE2Matrix4ScaleVector4(res.vectors, scaleVector);

    return res.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4ScaleWithVector3(GLKMatrix4 m, GLKVector3 v) {
    GLKMatrix4SSE res = GLKMatrix4SSE(m.m);
    __m128 scaleVector = { v.x, v.y, v.z, 1.0f };

    res.vectors = GLKSSE2Matrix4ScaleVector4(res.vectors, scaleVector);

    return res.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4ScaleWithVector4(GLKMatrix4 m, GLKVector4 v) {
    GLKMatrix4SSE res = GLKMatrix4SSE(m.m);
    __m128 scaleVector = _mm_loadu_ps(v.v);

    res.vectors = GLKSSE2Matrix4ScaleVector4(res.vectors, scaleVector);

    return res.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4Add(GLKMatrix4 matrixLeft, GLKMatrix4 matrixRight) {
    GLKMatrix4SSE m1 = GLKMatrix4SSE(matrixLeft.m);
    GLKMatrix4SSE m2 = GLKMatrix4SSE(matrixRight.m);

    m1.row[0] = _mm_add_ps(m1.row[0], m2.row[0]);
    m1.row[1] = _mm_add_ps(m1.row[1], m2.row[1]);
    m1.row[2] = _mm_add_ps(m1.row[2], m2.row[2]);
    m1.row[3] = _mm_add_ps(m1.row[3], m2.row[3]);

    return m1.matrix4;
}

/**
@Status Interoperable
*/
GLKMatrix4 GLKMatrix4Subtract(GLKMatrix4 matrixLeft, GLKMatrix4 matrixRight) {
    GLKMatrix4SSE m1 = GLKMatrix4SSE(matrixLeft.m);
    GLKMatrix4SSE m2 = GLKMatrix4SSE(matrixRight.m);

    m1.row[0] = _mm_sub_ps(m1.row[0], m2.row[0]);
    m1.row[1] = _mm_sub_ps(m1.row[1], m2.row[1]);
    m1.row[2] = _mm_sub_ps(m1.row[2], m2.row[2]);
    m1.row[3] = _mm_sub_ps(m1.row[3], m2.row[3]);

    return m1.matrix4;
}
#endif