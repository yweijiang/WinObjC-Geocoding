#include <TestFramework.h>

#import <QuartzCore/QuartzCore.h>

#include <math.h>
#include <windows.h>

struct Dword32 {
    union {
        unsigned int u32;
        float f32;
    };
};

static const float c_ComparisonEpsilon = 0.0000025f;

static void checkMatrixWithinTolerance(
    const char* pStr, const float* pM, const float* pMGolden, int dimension = 4, float tolerance = c_ComparisonEpsilon) {
    const unsigned int* pMUInt = reinterpret_cast<const unsigned int*>(pM);
    const unsigned int* pMGoldenUInt = reinterpret_cast<const unsigned int*>(pMGolden);

    assert(dimension <= 4);

    int index = 0;

    for (int i = 0; i < dimension; i++) {
        for (int j = 0; j < dimension; j++) {
            // Catch cases where element data are identical but ASSERT_NEAR and ASSERT_EQ identifies as different
            // Specifically, ASSERT_NEAR incorrectly marks +/- NaN values as not being identical
            if (pMUInt[index] != pMGoldenUInt[index]) {
                ASSERT_NEAR_MSG(pM[index],
                                pMGolden[index],
                                tolerance,
                                "TEST FAILED: %s \n\tMatrix mismatch at M[%i][%i]\n\t\tGOLDEN: %f\n\t\tACTUAL: %f\n",
                                pStr,
                                i,
                                j,
                                pMGolden[index],
                                pM[index]);
            }

            index++;
        }
    }
}

TEST(QuartzCore, MatrixMath) {
    const float rotAngle = M_PI / 3.0f;
    const float rotAxis[3] = { 1.0f, 0.0f, 0.0f };
    const float trans[3] = { 5.0f, 5.0f, 5.0f };

    const Dword32 transGolden[16] = {
        0x3F800000, 0x00000000, 0x00000000, 0x00000000, 
        0x00000000, 0x3F800000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x3F800000, 0x00000000, 
        0x40a00000, 0x40a00000, 0x40a00000, 0x3F800000,
    };

    const Dword32 rotGolden[16] = {
        0x3F800000, 0x00000000, 0x00000000, 0x00000000, 
        0x00800000, 0x3EFFFFFF, 0x3F5DB3D8, 0x00000000,
        0x00000000, 0xBF5DB3D8, 0x3EFFFFFF, 0x00000000, 
        0x00000000, 0x00000000, 0x00000000, 0x3F800000,
    };

    const Dword32 rotTransGolden[16] = {
        0x3F800000, 0x00000000, 0x00000000, 0x00000000, 
        0x00800000, 0x3EFFFFFF, 0x3F5DB3D8, 0x00000000,
        0x00000000, 0xBF5DB3D8, 0x3EFFFFFF, 0x00000000, 
        0x40a00000, 0x40a00000, 0x40a00000, 0x3F800000,
    };

    const size_t matrixSizeBytes = 16 * sizeof(float);

    // Generate rotation matrix
    CATransform3D rotMatrix = CATransform3DMakeRotation(rotAngle, rotAxis[0], rotAxis[1], rotAxis[2]);
    checkMatrixWithinTolerance("FAILED: CATransform3DMakeRotation", rotMatrix.m[0], &rotGolden[0].f32);

    // Generate translation matrix
    CATransform3D transMatrix = CATransform3DMakeTranslation(trans[0], trans[1], trans[2]);
    checkMatrixWithinTolerance("FAILED: CATransform3DMakeTranslation", transMatrix.m[0], &transGolden[0].f32);

    // Rotation + Translation via Concat of above matrices
    CATransform3D rotTransMatrixConcat = CATransform3DConcat(rotMatrix, transMatrix);
    checkMatrixWithinTolerance("FAILED: CATransform3DConcat", rotTransMatrixConcat.m[0], &rotTransGolden[0].f32);

    // Rotation + Translation via premultiply methods CATransform3DTranslate and CATransform3DRotate
    CATransform3D rotTransMatrixPreMul = CATransform3DTranslate(CATransform3DIdentity, trans[0], trans[1], trans[2]);
    // Pre-multiply rotation matrix to get matrix which rotates then translates
    rotTransMatrixPreMul = CATransform3DRotate(rotTransMatrixPreMul, rotAngle, rotAxis[0], rotAxis[1], rotAxis[2]);
    checkMatrixWithinTolerance("FAILED: CATransform3DTranslate and CATransform3dRotate", rotTransMatrixPreMul.m[0], &rotTransGolden[0].f32);
}