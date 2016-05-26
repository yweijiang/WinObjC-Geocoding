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
#include <TestFramework.h>

#import <GLKit/GLKit.h>

#include <math.h>
#include "Frameworks/GLKit/ShaderGen.h"
#include "Frameworks/GLKit/ShaderInfo.h"
#import <mach/mach_defs.h>
#import <mach/mach_time.h>

#include <windows.h>

using namespace GLKitShader;

struct OutputData {
    union {
        GLKQuaternion quat;
        GLKVector3 vec3;
        GLKVector4 vec4;
        GLKMatrix3 mat3;
        GLKMatrix4 mat4;
    };
};

#define X_FUNCLIST                                                                                            \
    X(GLKFuncEnumMatrix4MakeIdentity,                        "GLKMatrix4MakeIdentity")                        \
    X(GLKFuncEnumQuaternionMakeIdentity,                     "GLKQuaternionMakeIdentity")                     \
    X(GLKFuncEnumMatrix4MakeLookAt,                          "GLKMatrix4MakeLookAt")                          \
    X(GLKFuncEnumMatrix4MultiplyVector4,                     "GLKMatrix4MultiplyVector4")                     \
    X(GLKFuncEnumMatrix4Transpose,                           "GLKMatrix4Transpose")                           \
    X(GLKFuncEnumMatrix4InvertAndTranspose,                  "GLKMatrix4InvertAndTranspose")                  \
    X(GLKFuncEnumMatrix4Invert,                              "GLKMatrix4Invert")                              \
    X(GLKFuncEnumMatrix4MakeXRotation,                       "GLKMatrix4MakeXRotation")                       \
    X(GLKFuncEnumMatrix4MakeYRotation,                       "GLKMatrix4MakeYRotation")                       \
    X(GLKFuncEnumMatrix4MakeZRotation,                       "GLKMatrix4MakeZRotation")                       \
    X(GLKFuncEnumMatrix4MakeTranslation,                     "GLKMatrix4MakeTranslation")                     \
    X(GLKFuncEnumMatrix4RotateX,                             "GLKMatrix4RotateX")                             \
    X(GLKFuncEnumMatrix4RotateY,                             "GLKMatrix4RotateY")                             \
    X(GLKFuncEnumMatrix4RotateZ,                             "GLKMatrix4RotateZ")                             \
    X(GLKFuncEnumMatrix4Rotate,                              "GLKMatrix4Rotate")                              \
    X(GLKFuncEnumMatrix4MakeOrtho,                           "GLKMatrix4MakeOrtho")                           \
    X(GLKFuncEnumMatrix4RotateWithVector3,                   "GLKMatrix4RotateWithVector3")                   \
    X(GLKFuncEnumMatrix4RotateWithVector4,                   "GLKMatrix4RotateWithVector4")                   \
    X(GLKFuncEnumMatrix4Multiply,                            "GLKMatrix4Multiply")                            \
    X(GLKFuncEnumMatrix4MakeFrustum,                         "GLKMatrix4MakeFrustum")                         \
    X(GLKFuncEnumQuaternionRotateVector3Array,               "GLKQuaternionRotateVector3Array")               \
    X(GLKFuncEnumMatrix4MakeRotation,                        "GLKMatrix4MakeRotation")                        \
    X(GLKFuncEnumMatrix4MultiplyVector3,                     "GLKMatrix4MultiplyVector3")                     \
    X(GLKFuncEnumMatrix4MultiplyVector3WithTranslation,      "GLKMatrix4MultiplyVector3WithTranslation")      \
    X(GLKFuncEnumMatrix4MultiplyVector4Array,                "GLKMatrix4MultiplyVector4Array")                \
    X(GLKFuncEnumMatrix4MultiplyVector3ArrayWithTranslation, "GLKMatrix4MultiplyVector3ArrayWithTranslation") \
    X(GLKFuncEnumMatrix4MultiplyVector3Array,                "GLKMatrix4MultiplyVector3Array")                \
    X(GLKFuncEnumMatrix4MakePerspective,                     "GLKMatrix4MakePerspective")                     \
    X(GLKFuncEnumQuaternionRotateVector4Array,               "GLKQuaternionRotateVector4Array")               \
    X(GLKFuncEnumQuaternionMakeWithMatrix3,                  "GLKQuaternionMakeWithMatrix3")                  \
    X(GLKFuncEnumQuaternionMakeWithMatrix4,                  "GLKQuaternionMakeWithMatrix4")                  \
    X(GLKFuncEnumMatrix4TranslateWithVector3,                "GLKMatrix4TranslateWithVector3")                \
    X(GLKFuncEnumMatrix4TranslateWithVector4,                "GLKMatrix4TranslateWithVector4")                \
    X(GLKFuncEnumMatrix4Scale,                               "GLKMatrix4Scale")                               \
    X(GLKFuncEnumMatrix4ScaleWithVector3,                    "GLKMatrix4ScaleWithVector3")                    \
    X(GLKFuncEnumMatrix4ScaleWithVector4,                    "GLKMatrix4ScaleWithVector4")                    \
    X(GLKFuncEnumMatrix4Add,                                 "GLKMatrix4Add")                                 \
    X(GLKFuncEnumMatrix4Subtract,                            "GLKMatrix4Subtract")                            \
    X(GLKFuncEnumMatrix3Invert,                              "GLKMatrix3Invert")                              \
    X(GLKFuncEnumMatrix3InvertAndTranspose,                  "GLKMatrix3InvertAndTranspose")

enum GLKFunctionEnums {
#define X(Enum, String) Enum,
    X_FUNCLIST
#undef X
    GLKFuncEnumMax
};

static const char* glkFunctionNames[GLKFuncEnumMax] = {
#define X(Enum, String) String,
    X_FUNCLIST
#undef X
};

NSString* stripSource(NSString* s, NSString* searchStr) {
    NSRange r;
    while ((r = [s rangeOfString:searchStr]).location != NSNotFound) {
        NSRange searchRange;
        searchRange.location = r.location + r.length;
        searchRange.length = s.length;
        NSRange endRange = [s rangeOfString:@"\n" options:0 range:searchRange];
        if (endRange.location != NSNotFound) {
            r.length = endRange.location - r.location;
        } else {
            r.length = s.length - r.location;
        }
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    }

    return s;
}

int countOccurrences(NSString* s, NSString* searchStr) {
    int count = 0;

    NSRange r;
    r.location = 0;
    r.length = s.length;

    while ((r = [s rangeOfString:searchStr options:0 range:r]).location != NSNotFound) {
        count++;

        r.location = r.location + r.length;
        r.length = s.length - r.location;
    }

    return count;
}

void printShader(GLKShaderPair* p) {
    LOG_INFO(
        "\n\n-[ VERTEX SHADER ]----------------------\n%s"
        "\n\n-[ PIXEL SHADER ]-----------------------\n%s\n\n",
        [p.vertexShader UTF8String],
        [p.pixelShader UTF8String]);
}

bool hasVariable(GLKShaderPair* p, const char* varName, bool checkVS = true, bool checkPS = true) {
    if (checkVS) {
        if ([p.vertexShader rangeOfString:[NSString stringWithCString:varName]].location != NSNotFound) {
            return true;
        }
    }

    if (checkPS) {
        if ([p.pixelShader rangeOfString:[NSString stringWithCString:varName]].location != NSNotFound) {
            return true;
        }
    }

    return false;
}

TEST(GLKit, DeadCodeElimination) {
    GLKVector4 clr = GLKVector4White();

    // Simple shader.
    ShaderDef vsh(
        { { "output1",
            new ShaderAdditiveCombiner(
                { new ShaderVarRef("input1"), new ShaderVarRef("input2"), new ShaderVarRef("input3"), new ShaderVarRef("input4") }) } });
    ShaderDef psh({ { "gl_FragColor", new ShaderVarRef("output1") } });
    ShaderContext ctx(vsh, psh);

    // Some materials (nothing in m4).
    ShaderMaterial m, m2, m3, m4;
    m.addMaterialVar("input1", clr);
    m.addMaterialVar("input2", clr);
    m.addMaterialVar("input3", clr);
    m.addMaterialVar("input4", clr);

    m2.addMaterialVar("input2", clr);
    m2.addMaterialVar("input4", clr);

    m3.addMaterialVar("input3", clr);

    // Generate
    GLKShaderPair* p = [[GLKShaderPair alloc] init];
    ctx.generate(m, p);
    GLKShaderPair* p2 = [[GLKShaderPair alloc] init];
    ctx.generate(m2, p2);
    GLKShaderPair* p3 = [[GLKShaderPair alloc] init];
    ctx.generate(m3, p3);
    GLKShaderPair* p4 = [[GLKShaderPair alloc] init];
    ctx.generate(m4, p4);

    EXPECT_EQ_MSG(ctx.numVSTempFuncs(), 0, "No vertex shader temporary functions should be present.");
    EXPECT_EQ_MSG(ctx.numPSTempFuncs(), 0, "No pixel shader temporary functions should be present.");

    // Check results.
    EXPECT_TRUE_MSG(hasVariable(p, "input1"), "Variable must be present");
    EXPECT_TRUE_MSG(hasVariable(p, "input2"), "Variable must be present");
    EXPECT_TRUE_MSG(hasVariable(p, "input3"), "Variable must be present");
    EXPECT_TRUE_MSG(hasVariable(p, "input4"), "Variable must be present");

    EXPECT_FALSE_MSG(hasVariable(p2, "input1"), "Variable should be optimized away");
    EXPECT_TRUE_MSG(hasVariable(p2, "input2"), "Variable must be present");
    EXPECT_FALSE_MSG(hasVariable(p2, "input3"), "Variable should be optimized away");
    EXPECT_TRUE_MSG(hasVariable(p2, "input4"), "Variable must be present");

    EXPECT_FALSE_MSG(hasVariable(p3, "input1"), "Variable should be optimized away");
    EXPECT_FALSE_MSG(hasVariable(p3, "input2"), "Variable should be optimized away");
    EXPECT_TRUE_MSG(hasVariable(p3, "input3"), "Variable must be present");
    EXPECT_FALSE_MSG(hasVariable(p3, "input4"), "Variable should be optimized away");

    EXPECT_FALSE_MSG(hasVariable(p4, "input1"), "Variable should be optimized away");
    EXPECT_FALSE_MSG(hasVariable(p4, "input2"), "Variable should be optimized away");
    EXPECT_FALSE_MSG(hasVariable(p4, "input3"), "Variable should be optimized away");
    EXPECT_FALSE_MSG(hasVariable(p4, "input4"), "Variable should be optimized away");
}

TEST(GLKit, DeadCodeElimination2) {
    GLKVector4 clr = GLKVector4White();

    // Simple shader -- generates opName(input1, input2).
    ShaderDef vsh({ { "output1", new ShaderOp(new ShaderVarRef("input1"), new ShaderVarRef("input2"), "opName", false) } });
    ShaderDef psh({ { "gl_FragColor", new ShaderVarRef("output1") } });
    ShaderContext ctx(vsh, psh);

    ShaderMaterial m, m2, m3, m4;
    m.addMaterialVar("input1", clr);
    m.addMaterialVar("input2", clr);

    m2.addMaterialVar("input1", clr);

    m3.addMaterialVar("input2", clr);

    // add nothing to m4.

    // Generate
    GLKShaderPair* p = [[GLKShaderPair alloc] init];
    ctx.generate(m, p);
    GLKShaderPair* p2 = [[GLKShaderPair alloc] init];
    ctx.generate(m2, p2);
    GLKShaderPair* p3 = [[GLKShaderPair alloc] init];
    ctx.generate(m3, p3);
    GLKShaderPair* p4 = [[GLKShaderPair alloc] init];
    ctx.generate(m4, p4);

    EXPECT_EQ_MSG(ctx.numVSTempFuncs(), 0, "No vertex shader temporary functions should be present.");
    EXPECT_EQ_MSG(ctx.numPSTempFuncs(), 0, "No pixel shader temporary functions should be present.");

    EXPECT_TRUE_MSG(hasVariable(p, "opName"), "Operator must be present if both inputs are present");
    EXPECT_TRUE_MSG(hasVariable(p, "input1"), "Input must be present.");
    EXPECT_TRUE_MSG(hasVariable(p, "input2"), "Input must be present.");

    EXPECT_FALSE_MSG(hasVariable(p2, "opName"), "Operator must not be present if an input is missing");
    EXPECT_TRUE_MSG(hasVariable(p2, "input1"), "Input must be present.");
    EXPECT_FALSE_MSG(hasVariable(p2, "input2"), "Input is not used and must not be present.");

    EXPECT_FALSE_MSG(hasVariable(p3, "opName"), "Operator must not be present if an input is missing");
    EXPECT_FALSE_MSG(hasVariable(p3, "input1"), "Input is not used and must not be present.");
    EXPECT_TRUE_MSG(hasVariable(p3, "input2"), "Input must be present.");

    EXPECT_FALSE_MSG(hasVariable(p4, "opName"), "Operator must not be present if an input is missing");
    EXPECT_FALSE_MSG(hasVariable(p4, "input1"), "Input is not used and must not be present.");
    EXPECT_FALSE_MSG(hasVariable(p4, "input2"), "Input is not used and must not be present.");
}

TEST(GLKit, TextureCheck) {
    ShaderDef vsh({
        { "output1", new ShaderTexRef("tex1", "modeVar", new ShaderCustom("float2(1, 1"), new ShaderCustom("float4(1, 1, 1, 1)")) },
    });
    ShaderDef psh(
        { { "gl_FragColor", new ShaderTexRef("tex2", "modeVar", new ShaderCustom("float2(1, 1"), new ShaderVarRef("output1")) } });
    ShaderContext ctx(vsh, psh);

    // Textures should just pass through in vertex shader mode.
    ShaderMaterial m;
    m.addTexture("tex1", 1);
    m.addTexture("tex2", 2);

    GLKShaderPair* p = [[GLKShaderPair alloc] init];
    ctx.generate(m, p);

    EXPECT_EQ_MSG(ctx.numVSTempFuncs(), 0, "No vertex shader temporary functions should be present.");
    EXPECT_EQ_MSG(ctx.numPSTempFuncs(), 0, "No pixel shader temporary functions should be present.");

    EXPECT_FALSE_MSG(hasVariable(p, "texture2D", true, false), "Texturing call must not be in vertex shader");
    EXPECT_TRUE_MSG(hasVariable(p, "texture2D", false, true), "Texturing call expected in pixel shader");
}

TEST(GLKit, TextureCheckCube) {
    ShaderDef vsh({
        { "output1",
          new ShaderCubeRef("tex1",
                            "modeVar",
                            new ShaderCustom("float4(1, 1, 1, 1)"),
                            new ShaderCustom("float3(1, 1, 1)"),
                            new ShaderCustom("float4(1, 1, 1, 1)"),
                            new ShaderCustom("float4(1, 1, 1, 1)")) },
    });
    ShaderDef psh({ { "gl_FragColor",
                      new ShaderCubeRef("tex2",
                                        "modeVar",
                                        new ShaderCustom("float4(1, 1, 1, 1)"),
                                        new ShaderCustom("float3(1, 1, 1)"),
                                        new ShaderCustom("float4(1, 1, 1, 1)"),
                                        new ShaderVarRef("output1")) } });
    ShaderContext ctx(vsh, psh);

    // Textures should just pass through in vertex shader mode.
    ShaderMaterial m;
    m.addTexCube("tex1", 1);
    m.addTexCube("tex2", 2);

    GLKShaderPair* p = [[GLKShaderPair alloc] init];
    ctx.generate(m, p);

    EXPECT_EQ_MSG(ctx.numVSTempFuncs(), 0, "No vertex shader temporary functions should be present.");
    EXPECT_EQ_MSG(ctx.numPSTempFuncs(), 0, "No pixel shader temporary functions should be present.");

    EXPECT_FALSE_MSG(hasVariable(p, "textureCube", true, false), "Texturing call must not be in vertex shader");
    EXPECT_TRUE_MSG(hasVariable(p, "textureCube", false, true), "Texturing call expected in pixel shader");
}

TEST(GLKit, TextureCheckSpecular) {
    ShaderDef vsh({
        { "output1", new ShaderSpecularTex("tex1", new ShaderCustom("float2(1, 1"), new ShaderCustom("float4(1, 1, 1, 1)")) },
    });
    ShaderDef psh({ { "gl_FragColor", new ShaderSpecularTex("tex2", new ShaderCustom("float2(1, 1"), new ShaderVarRef("output1")) } });
    ShaderContext ctx(vsh, psh);

    // Textures should just pass through in vertex shader mode.
    ShaderMaterial m;
    m.addTexture("tex1", 1);
    m.addTexture("tex2", 2);

    GLKShaderPair* p = [[GLKShaderPair alloc] init];
    ctx.generate(m, p);

    EXPECT_EQ_MSG(ctx.numVSTempFuncs(), 0, "No vertex shader temporary functions should be present.");
    EXPECT_EQ_MSG(ctx.numPSTempFuncs(), 0, "No pixel shader temporary functions should be present.");

    EXPECT_FALSE_MSG(hasVariable(p, "texture2D", true, false), "Texturing call must not be in vertex shader");
    EXPECT_TRUE_MSG(hasVariable(p, "texture2D", false, true), "Texturing call expected in pixel shader");
}

TEST(GLKit, DeadCodeBackPropagation) {
    ShaderDef vsh({
        { "output1", new ShaderCustom("float4(1, 1, 1, 1)") },
        { "output2", new ShaderCustom("float4(1, 1, 1, 1)") },
        { "output3", new ShaderCustom("float4(1, 1, 1, 1)") },
        { "output4", new ShaderCustom("float4(1, 1, 1, 1)") },
    });
    ShaderDef psh({ { "gl_FragColor",
                      new ShaderAdditiveCombiner({
                          new ShaderVarRef("output1"), new ShaderVarRef("output3"),
                      }) } });
    ShaderContext ctx(vsh, psh);

    ShaderMaterial m;
    GLKShaderPair* p = [[GLKShaderPair alloc] init];
    ctx.generate(m, p);

    EXPECT_EQ_MSG(ctx.numVSTempFuncs(), 0, "No vertex shader temporary functions should be present.");
    EXPECT_EQ_MSG(ctx.numPSTempFuncs(), 0, "No pixel shader temporary functions should be present.");

    // Remove comments and intermediate variables.
    p.vertexShader = stripSource(stripSource(p.vertexShader, @"//"), @"varying");
    p.pixelShader = stripSource(stripSource(p.pixelShader, @"//"), @"varying");

    EXPECT_TRUE_MSG(hasVariable(p, "output1"), "Variable is used in pixel shader and must be present in vertex shader.");
    EXPECT_FALSE_MSG(hasVariable(p, "output2"), "Variable is not used in pixel shader and must be eliminated in vertex shader.");
    EXPECT_TRUE_MSG(hasVariable(p, "output3"), "Variable is used in pixel shader and must be present in vertex shader.");
    EXPECT_FALSE_MSG(hasVariable(p, "output4"), "Variable is not used in pixel shader and must be eliminated in vertex shader.");
}

TEST(GLKit, ConditionalShaderNodes) {
    ShaderDef vsh({ { "output1",
                      new ShaderAdditiveCombiner({ new ShaderPixelOnly(new ShaderCustom("pixelOnly")),
                                                   new ShaderVertexOnly(new ShaderCustom("vertexOnly")),
                                                   new ShaderCustom("float4(1, 1, 1, 1)"),
                                                   new ShaderInputVarCheck("generateThis", new ShaderCustom("inputVarOK")) }) } });

    ShaderDef psh({ { "gl_FragColor",
                      new ShaderAdditiveCombiner({ new ShaderVarRef("output1"),
                                                   new ShaderPixelOnly(new ShaderCustom("pixelOnly")),
                                                   new ShaderVertexOnly(new ShaderCustom("vertexOnly")),
                                                   new ShaderInputVarCheck("generateThis", new ShaderCustom("inputVarOK")) }) } });
    ShaderContext ctx(vsh, psh);

    ShaderMaterial m, m2;
    m.addInputVar("generateThis", 1);

    GLKShaderPair* p = [[GLKShaderPair alloc] init];
    ctx.generate(m, p);
    GLKShaderPair* p2 = [[GLKShaderPair alloc] init];
    ctx.generate(m2, p2);

    EXPECT_EQ_MSG(ctx.numVSTempFuncs(), 0, "No vertex shader temporary functions should be present.");
    EXPECT_EQ_MSG(ctx.numPSTempFuncs(), 0, "No pixel shader temporary functions should be present.");

    // Check input var.
    EXPECT_TRUE_MSG(hasVariable(p, "inputVarOK", true, false), "Input variable must be present in vertex shader");
    EXPECT_TRUE_MSG(hasVariable(p, "inputVarOK", false, true), "Input variable must be present in pixel shader");
    EXPECT_FALSE_MSG(hasVariable(p2, "inputVarOK", true, false), "Input variable should not be generated when disabled");
    EXPECT_FALSE_MSG(hasVariable(p2, "inputVarOK", false, true), "Input variable should not be generated when disabled");

    // Check VS/PS specific stuff.
    EXPECT_FALSE_MSG(hasVariable(p, "pixelOnly", true, false), "Pixel-only nodes must not appear in vertex shader");
    EXPECT_TRUE_MSG(hasVariable(p, "pixelOnly", false, true), "Pixel-only nodes must appear in pixel shader");
    EXPECT_TRUE_MSG(hasVariable(p, "vertexOnly", true, false), "Vertex-only nodes must appear in vertex shader");
    EXPECT_FALSE_MSG(hasVariable(p, "vertexOnly", false, true), "Vertex-only nodes must not appear in the pixel shader");
}

static bool fallbackContextTest(ShaderContext& ctx) {
    GLKVector4 clr = GLKVector4White();

    const int numVars = 4;
    const char* varNames[numVars] = { "var1", "var2", "var3", "var4" };

    for (int i = 0; i < numVars; i++) {
        ShaderMaterial m;
        m.addMaterialVar(varNames[i], clr);
        GLKShaderPair* p = [[GLKShaderPair alloc] init];
        ctx.generate(m, p);

        if (ctx.numVSTempFuncs() != 0 || ctx.numPSTempFuncs() != 0) {
            return false;
        }

        for (int j = 0; j < numVars; j++) {
            if (i == j) {
                if (!hasVariable(p, varNames[j])) {
                    return false;
                }
            } else {
                if (hasVariable(p, varNames[j])) {
                    return false;
                }
            }
        }
    }

    return true;
}

TEST(GLKit, FallbackShaderNodes) {
    ShaderDef vsh({ { "output1", new ShaderFallbackRef({ "var1", "var2", "var3", "var4" }) } });
    ShaderDef vsh2({ { "output1",
                       new ShaderFallbackNode(
                           { new ShaderVarRef("var1"), new ShaderVarRef("var2"), new ShaderVarRef("var3"), new ShaderVarRef("var4") }) } });
    ShaderDef psh({ { "gl_FragColor", new ShaderVarRef("output1") } });

    ShaderContext ctx(vsh, psh);
    ShaderContext ctx2(vsh2, psh);

    EXPECT_TRUE_MSG(fallbackContextTest(ctx), "FallbackRef node not correctly falling back.");
    EXPECT_TRUE_MSG(fallbackContextTest(ctx2), "FallbackNode node not correctly falling back.");
}

TEST(GLKit, TemporaryShaderNodes) {
    ShaderDef vsh({ { "output1",
                      new ShaderAdditiveCombiner({ new ShaderTempRef(GLKS_FLOAT4, "tempResult", new ShaderCustom("commonResult")),
                                                   new ShaderTempRef(GLKS_FLOAT4, "tempResult", new ShaderCustom("commonResult")),
                                                   new ShaderTempRef(GLKS_FLOAT4, "tempResult", new ShaderCustom("commonResult")) }) } });

    ShaderDef psh({ { "gl_FragColor", new ShaderVarRef("output1") } });
    ShaderContext ctx(vsh, psh);

    ShaderMaterial m;
    GLKShaderPair* p = [[GLKShaderPair alloc] init];
    ctx.generate(m, p);

    EXPECT_EQ_MSG(ctx.numVSTempFuncs(), 0, "No vertex shader temporary functions should be present.");
    EXPECT_EQ_MSG(ctx.numPSTempFuncs(), 0, "No pixel shader temporary functions should be present.");

    EXPECT_EQ_MSG(countOccurrences(p.vertexShader, @"commonResult"), 1, "The common result variable should only be used once.");
    EXPECT_EQ_MSG(countOccurrences(p.vertexShader, @"tempResult"),
                  4,
                  "The temporary result is not being reused the correct number of times.");
}

TEST(GLKit, BasicMath) {
    bool invertible = false;

    GLKVector4 v = GLKVector4Make(3.f, 2.f, 1.f, 1.f);

    GLKMatrix4 rot = GLKMatrix4MakeXRotation(2.f);
    GLKMatrix4 trans = GLKMatrix4MakeTranslation(5.f, 5.f, 5.f);

    auto mc = GLKMatrix4Multiply(trans, rot);
    auto mcInverse = GLKMatrix4Invert(mc, &invertible);
    EXPECT_TRUE_MSG(invertible, "Expected to be able to calculate matrix inverse.");

    auto v2 = GLKMatrix4MultiplyVector4(mcInverse, GLKMatrix4MultiplyVector4(mc, v));
    EXPECT_TRUE_MSG(GLKVector4AllEqualToVector4(v, v2), "Matrix multiplication yielded unexpected result.");

    float values[16] = { 0.f, 1.f, 2.f, 3.f, 4.f, 5.f, 6.f, 7.f, 8.f, 9.f, 10.f, 11.f, 12.f, 13.f, 14.f, 15.f };
    GLKMatrix4 m = GLKMatrix4MakeWithArray(values);
    EXPECT_TRUE_MSG(m.m[0] == values[0] && m.m[1] == values[1] && m.m[2] == values[2] && m.m[3] == values[3] && m.m[4] == values[4] &&
                        m.m[5] == values[5] && m.m[6] == values[6] && m.m[7] == values[7] && m.m[8] == values[8] && m.m[9] == values[9] &&
                        m.m[10] == values[10] && m.m[11] == values[11] && m.m[12] == values[12] && m.m[13] == values[13] &&
                        m.m[14] == values[14] && m.m[15] == values[15],
                    "GLKMatrix4MakeWithArray yielded unexpected result.");

    m = GLKMatrix4MakeWithArrayAndTranspose(values);
    EXPECT_TRUE_MSG(m.m[0] == values[0] && m.m[1] == values[4] && m.m[2] == values[8] && m.m[3] == values[12] && m.m[4] == values[1] &&
                        m.m[5] == values[5] && m.m[6] == values[9] && m.m[7] == values[13] && m.m[8] == values[2] && m.m[9] == values[6] &&
                        m.m[10] == values[10] && m.m[11] == values[14] && m.m[12] == values[3] && m.m[13] == values[7] &&
                        m.m[14] == values[11] && m.m[15] == values[15],
                    "GLKMatrix4MakeWithArrayAndTranspose yielded unexpected result.");

    m = GLKMatrix4MakeWithRows(GLKVector4Make(0.f, 1.f, 2.f, 3.f),
                               GLKVector4Make(4.f, 5.f, 6.f, 7.f),
                               GLKVector4Make(8.f, 9.f, 10.f, 11.f),
                               GLKVector4Make(12.f, 13.f, 14.f, 15.f));
    EXPECT_TRUE_MSG(m.m[0] == values[0] && m.m[1] == values[4] && m.m[2] == values[8] && m.m[3] == values[12] && m.m[4] == values[1] &&
                        m.m[5] == values[5] && m.m[6] == values[9] && m.m[7] == values[13] && m.m[8] == values[2] && m.m[9] == values[6] &&
                        m.m[10] == values[10] && m.m[11] == values[14] && m.m[12] == values[3] && m.m[13] == values[7] &&
                        m.m[14] == values[11] && m.m[15] == values[15],
                    "GLKMatrix4MakeWithRows yielded unexpected result.");

    m = GLKMatrix4MakeWithColumns(GLKVector4Make(0.f, 1.f, 2.f, 3.f),
                                  GLKVector4Make(4.f, 5.f, 6.f, 7.f),
                                  GLKVector4Make(8.f, 9.f, 10.f, 11.f),
                                  GLKVector4Make(12.f, 13.f, 14.f, 15.f));
    EXPECT_TRUE_MSG(m.m[0] == values[0] && m.m[1] == values[1] && m.m[2] == values[2] && m.m[3] == values[3] && m.m[4] == values[4] &&
                        m.m[5] == values[5] && m.m[6] == values[6] && m.m[7] == values[7] && m.m[8] == values[8] && m.m[9] == values[9] &&
                        m.m[10] == values[10] && m.m[11] == values[11] && m.m[12] == values[12] && m.m[13] == values[13] &&
                        m.m[14] == values[14] && m.m[15] == values[15],
                    "GLKMatrix4MakeWithColumns yielded unexpected result.");

    GLKMatrix3 m3 = GLKMatrix3MakeWithRows(GLKVector3Make(0.f, 1.f, 2.f), GLKVector3Make(3.f, 4.f, 5.f), GLKVector3Make(6.f, 7.f, 8.f));
    EXPECT_TRUE_MSG(m3.m[0] == values[0] && m3.m[1] == values[3] && m3.m[2] == values[6] && m3.m[3] == values[1] && m3.m[4] == values[4] &&
                        m3.m[5] == values[7] && m3.m[6] == values[2] && m3.m[7] == values[5] && m3.m[8] == values[8],
                    "GLKMatrix3MakeWithRows yielded unexpected result.");

    m3 = GLKMatrix3MakeWithColumns(GLKVector3Make(0.f, 1.f, 2.f), GLKVector3Make(3.f, 4.f, 5.f), GLKVector3Make(6.f, 7.f, 8.f));
    EXPECT_TRUE_MSG(m3.m[0] == values[0] && m3.m[1] == values[1] && m3.m[2] == values[2] && m3.m[3] == values[3] && m3.m[4] == values[4] &&
                        m3.m[5] == values[5] && m3.m[6] == values[6] && m3.m[7] == values[7] && m3.m[8] == values[8],
                    "GLKMatrix3MakeWithColumns yielded unexpected result.");

    m3 = GLKMatrix3MakeWithArray(values);
    EXPECT_TRUE_MSG(m3.m[0] == values[0] && m3.m[1] == values[1] && m3.m[2] == values[2] && m3.m[3] == values[3] && m3.m[4] == values[4] &&
                        m3.m[5] == values[5] && m3.m[6] == values[6] && m3.m[7] == values[7] && m3.m[8] == values[8],
                    "GLKMatrix3MakeWithArray yielded unexpected result.");

    m3 = GLKMatrix3MakeWithArrayAndTranspose(values);
    EXPECT_TRUE_MSG(m3.m[0] == values[0] && m3.m[1] == values[3] && m3.m[2] == values[6] && m3.m[3] == values[1] && m3.m[4] == values[4] &&
                        m3.m[5] == values[7] && m3.m[6] == values[2] && m3.m[7] == values[5] && m3.m[8] == values[8],
                    "GLKMatrix3MakeWithArrayAndTranspose yielded unexpected result.");

    m = GLKMatrix4MakeWithArray(values);
    m3 = GLKMatrix4GetMatrix3(m);
    GLKMatrix2 m2 = GLKMatrix4GetMatrix2(m);
    GLKMatrix2 m2_2 = GLKMatrix3GetMatrix2(m3);

    EXPECT_TRUE_MSG(m3.m00 == m.m00 && m3.m01 == m.m01 && m3.m02 == m.m02 &&
                    m3.m10 == m.m10 && m3.m11 == m.m11 && m3.m12 == m.m12 &&
                    m3.m20 == m.m20 && m3.m21 == m.m21 && m3.m22 == m.m22,
                    "GLKMatrix4GetMatrix3 yielded unexpected result.");

    EXPECT_TRUE_MSG(m2.m00 == m.m00 && m2.m01 == m.m01 && m2.m10 == m.m10 && m2.m11 == m.m11,
                    "GLKMatrix4GetMatrix2 yielded unexpected result.");
    
    EXPECT_TRUE_MSG(m2_2.m00 == m3.m00 && m2_2.m01 == m3.m01 && m2_2.m10 == m3.m10 && m2_2.m11 == m3.m11,
                    "GLKMatrix3GetMatrix2 yielded unexpected result.");
}

TEST(GLKit, Quaternions) {
    float values[4] = { 0.f, 1.f, 2.f, 3.f };
    GLKQuaternion q = GLKQuaternionMake(0.f, 1.f, 2.f, 3.f);
    GLKQuaternion q2 = GLKQuaternionMakeWithArray(values);
    GLKQuaternion q3 = GLKQuaternionMakeWithVector3(GLKVector3Make(0.f, 1.f, 2.f), 3.f);
    EXPECT_TRUE_MSG(q.x == q2.x && q.y == q2.y && q.z == q2.z && q.w == q2.w, "Basic quaternion construction failed!");
    EXPECT_TRUE_MSG(q.x == q3.x && q.y == q3.y && q.z == q3.z && q.w == q3.w, "Basic quaternion construction failed!");

    q = GLKQuaternionNormalize(q);
    EXPECT_TRUE_MSG(fabsf(GLKQuaternionLength(q) - 1.f) <= COMPARISON_EPSILON, "Normalized quaternion has bad length.");

    q = GLKQuaternionMakeWithAngleAndAxis(M_PI, 0.f, 1.f, 0.f);
    q2 = GLKQuaternionMakeWithAngleAndVector3Axis(M_PI, GLKVector3YAxis());
    EXPECT_TRUE_MSG(q.x == q2.x && q.y == q2.y && q.z == q2.z && q.w == q2.w, "Quaternion angle/axis construction failed!");

    GLKVector3 axis = GLKQuaternionAxis(q);
    float angle = GLKQuaternionAngle(q);
    EXPECT_TRUE_MSG(fabsf(angle - (float)M_PI) <= COMPARISON_EPSILON, "Incorrect angle extracted!");
    EXPECT_TRUE_MSG(GLKVector3AllEqualToVector3(axis, GLKVector3YAxis()), "Incorrect rotation axis extracted!");

    GLKVector3 rotated = GLKVector3XAxis();
    GLKQuaternionRotateVector3Array(q, &rotated, 1);
    EXPECT_TRUE_MSG(GLKVector3AllEqualToScalar(GLKVector3Add(rotated, GLKVector3XAxis()), 0.f), "Quaternion rotation appears incorrect.");

    GLKMatrix3 xrot = GLKMatrix3MakeXRotation(M_PI / 3.f);
    GLKMatrix3 xrot2 = GLKMatrix3Make(1.f, 0.f, 0.f, 0.f, -1.f, 0.f, 0.f, 0.f, -1.f);
    GLKMatrix3 yrot = GLKMatrix3Make(-1.f, 0.f, 0.f, 0.f, 1.f, 0.f, 0.f, 0.f, -1.f);
    GLKMatrix3 zrot = GLKMatrix3Make(-1.f, 0.f, 0.f, 0.f, -1.f, 0.f, 0.f, 0.f, 1.f);

    q = GLKQuaternionMakeWithMatrix3(xrot);
    EXPECT_TRUE_MSG(fabsf(GLKQuaternionLength(q) - 1.f) <= COMPARISON_EPSILON, "Quaternion length incorrect");
    axis = GLKQuaternionAxis(q);
    angle = GLKQuaternionAngle(q);
    EXPECT_TRUE_MSG(fabsf(angle - ((float)M_PI / 3.f)) <= COMPARISON_EPSILON, "Quaternion angle extracted incorrectly!");
    EXPECT_TRUE_MSG(GLKVector3AllEqualToVector3(axis, GLKVector3XAxis()), "Incorrect rotation axis extracted!");

    q = GLKQuaternionMakeWithMatrix3(xrot2);
    EXPECT_TRUE_MSG(fabsf(GLKQuaternionLength(q) - 1.f) <= COMPARISON_EPSILON, "Quaternion length incorrect");
    axis = GLKQuaternionAxis(q);
    angle = GLKQuaternionAngle(q);
    EXPECT_TRUE_MSG(fabsf(angle - (float)M_PI) <= COMPARISON_EPSILON, "Quaternion angle extracted incorrectly!");
    EXPECT_TRUE_MSG(GLKVector3AllEqualToVector3(axis, GLKVector3XAxis()), "Incorrect rotation axis extracted!");

    q = GLKQuaternionMakeWithMatrix3(yrot);
    EXPECT_TRUE_MSG(fabsf(GLKQuaternionLength(q) - 1.f) <= COMPARISON_EPSILON, "Quaternion length incorrect");
    axis = GLKQuaternionAxis(q);
    angle = GLKQuaternionAngle(q);
    EXPECT_TRUE_MSG(fabsf(angle - (float)M_PI) <= COMPARISON_EPSILON, "Quaternion angle extracted incorrectly!");
    EXPECT_TRUE_MSG(GLKVector3AllEqualToVector3(axis, GLKVector3YAxis()), "Incorrect rotation axis extracted!");

    q = GLKQuaternionMakeWithMatrix3(zrot);
    EXPECT_TRUE_MSG(fabsf(GLKQuaternionLength(q) - 1.f) <= COMPARISON_EPSILON, "Quaternion length incorrect");
    axis = GLKQuaternionAxis(q);
    angle = GLKQuaternionAngle(q);
    EXPECT_TRUE_MSG(fabsf(angle - (float)M_PI) <= COMPARISON_EPSILON, "Quaternion angle extracted incorrectly!");
    EXPECT_TRUE_MSG(GLKVector3AllEqualToVector3(axis, GLKVector3ZAxis()), "Incorrect rotation axis extracted!");
}

TEST(GLKit, Rotations) {
    GLKVector4 v = GLKVector4Make(3.f, 2.f, 1.f, 0.f);

    GLKMatrix4 mx = GLKMatrix4MakeXRotation(M_PI);
    GLKMatrix4 my = GLKMatrix4MakeYRotation(M_PI);
    GLKMatrix4 mz = GLKMatrix4MakeZRotation(M_PI);

    auto projx = GLKVector4MultiplyScalar(GLKVector4Project(v, GLKVector4Make(1.f, 0.f, 0.f, 0.f)), 2.f);
    auto projy = GLKVector4MultiplyScalar(GLKVector4Project(v, GLKVector4Make(0.f, 1.f, 0.f, 0.f)), 2.f);
    auto projz = GLKVector4MultiplyScalar(GLKVector4Project(v, GLKVector4Make(0.f, 0.f, 1.f, 0.f)), 2.f);

    auto dx = GLKMatrix4MultiplyVector4(mx, v);
    auto dy = GLKMatrix4MultiplyVector4(my, v);
    auto dz = GLKMatrix4MultiplyVector4(mz, v);

    EXPECT_TRUE_MSG(GLKVector4AllEqualToScalar(GLKVector4Subtract(GLKVector4Add(v, dx), projx), 0.f), "Unexpected vector addition result.");
    EXPECT_TRUE_MSG(GLKVector4AllEqualToScalar(GLKVector4Subtract(GLKVector4Add(v, dy), projy), 0.f), "Unexpected vector addition result.");
    EXPECT_TRUE_MSG(GLKVector4AllEqualToScalar(GLKVector4Subtract(GLKVector4Add(v, dz), projz), 0.f), "Unexpected vector addition result.");

    GLKMatrix4 m = GLKMatrix4MakeRotation(M_PI / 2.f, 1.f, 1.f, 1.f);
    v = GLKVector4Make(4.f, 5.f, 6.f, 0.f);

    auto v2 = GLKMatrix4MultiplyVector4(m, v);
    auto v3 = GLKMatrix4MultiplyVector4(m, v2);
    auto v4 = GLKMatrix4MultiplyVector4(m, v3);

    GLKVector4 dv =
        GLKVector4Make(GLKVector4Distance(v, v2), GLKVector4Distance(v2, v3), GLKVector4Distance(v3, v4), GLKVector4Distance(v4, v));
    EXPECT_TRUE_MSG(GLKVector4AllEqualToScalar(dv, dv.x), "Unexpected vector distance result.");

    GLKMatrix3 m3x = GLKMatrix3MakeXRotation(M_PI / 2.f);
    GLKMatrix3 m3xInv = GLKMatrix3Invert(m3x, NULL);

    GLKVector3 v31 = GLKVector3Make(1.f, 1.f, 1.f);
    GLKVector3 v3rot = GLKMatrix3MultiplyVector3(m3xInv, GLKMatrix3MultiplyVector3(m3x, v31));
    EXPECT_TRUE_MSG(GLKVector3AllEqualToVector3(v31, v3rot), "Incorrect inversion of 3x3 matrix.");
}

TEST(GLKit, Interpolation) {
    GLKVector4 a = GLKVector4Make(4.f, 3.f, 2.f, 1.f);
    GLKVector4 b = GLKVector4Negate(a);

    auto res = GLKVector4Lerp(a, b, 0.5f);
    EXPECT_TRUE_MSG(GLKVector4AllEqualToScalar(res, 0.f), "Unexpected interpolation result.");

    float dist = GLKVector4Distance(a, b);
    EXPECT_LE_MSG(fabsf(dist - 2.f * sqrtf(GLKVector4DotProduct(a, a))), COMPARISON_EPSILON, "Interpolation not within acceptable error.");

    GLKVector3 v = GLKVector3Make(0.f, 1.f, 1.f);
    GLKVector3 proj = GLKVector3Project(v, GLKVector3ZAxis());
    EXPECT_TRUE_MSG(GLKVector3AllEqualToVector3(proj, GLKVector3ZAxis()), "GLKVector3 projection failed!");

    GLKVector4 v4 = GLKVector4Make(0.f, 1.f, 1.f, 0.f);
    GLKVector4 zAxis = GLKVector4MakeWithVector3(GLKVector3ZAxis(), 0.f);
    GLKVector4 proj4 = GLKVector4Project(v4, zAxis);
    EXPECT_TRUE_MSG(GLKVector4AllEqualToVector4(proj4, zAxis), "GLKVector4 projection failed!");
}

TEST(GLKit, Performance) {
    // Time tracking
    struct mach_timebase_info tinfo;
    mach_timebase_info(&tinfo);
    const int64_t cpuFrequency = tinfo.denom;
    uint64_t beginTick = 0;
    uint64_t endTick = 0;
    uint64_t totalTicks[GLKFuncEnumMax] = { 0 };

    // Samples
    const uint64_t numSamples = 100000;
    const float numSamplesF32 = static_cast<float>(numSamples);

    // Output buffer
    const int numOutputBufferEntries = 64;
    const int numOutputBufferEntriesDw = numOutputBufferEntries * sizeof(OutputData) / sizeof(int);
    OutputData outputBuffer[numOutputBufferEntries];
    unsigned int* pOutputBuffer = reinterpret_cast<unsigned int*>(outputBuffer);
    volatile int bufferIndex;

    // Start/Current values
    GLKVector3 rotation = { 0.0f, 0.0f, 0.0f };
    GLKVector3 eye = { 0.0f, 6.5f, -11.0f };
    GLKVector3 look = { 0.0f, 0.0f, 0.0f };
    GLKVector3 up = { 0.0f, 1.0f, 0.0f };
    GLKVector3 scale = { 1.0f, 1.0f, 1.0f };
    GLKVector3 translate = { 0.0f, 0.0f, 0.0f };
    GLKVector4 scale4 = { 1.0f, 1.0f, 1.0f, 1.0f };
    GLKVector4 translate4 = { 0.0f, 0.0f, 0.0f, 1.0f };
    GLKVector3 rotationAxis = { 0.0f, 0.0f, 0.0f };
    GLKVector4 rotation4Axis = { 0.0f, 0.0f, 0.0f, 1.0f };
    float yrad = M_PI / 3.0f;
    float left = -200.0f;
    float right = 200.0f;
    float top = -150.0f;
    float bot = 150.0f;
    float aspect = (left - right) / (bot - top);
    float nearZ = 0.01f;
    float farZ = 100.0f;

    // Final values
    const GLKVector3 rotationMax = { M_PI * 2.0f, M_PI * 2.0f, M_PI * 2.0f };
    const GLKVector3 eyeMax = { 0.5f, 7.0f, -10.5f };
    const GLKVector3 lookMax = { 0.5f, 0.5f, 0.5f };
    const GLKVector3 upMax = { 0.0f, 1.0f, 0.0f };
    const GLKVector3 scaleMax = { 10.0f, 10.0f, 10.0f };
    const GLKVector3 translateMax = { 10.0f, 10.0f, 10.0f };
    const GLKVector4 scale4Max = { 10.0f, 10.0f, 10.0f, 1.0f };
    const GLKVector4 translate4Max = { 10.0f, 10.0f, 10.0f, 1.0f };
    const GLKVector3 rotationAxisMax = { 3.0f, 2.0f, 1.0f };
    const GLKVector4 rotation4AxisMax = { 3.0f, 2.0f, 1.0f, 1.0f };
    const float yradMax = M_PI / 2.0f;
    const float aspectMax = 16.0f / 9.0f;
    const float nearZMax = 0.5f;
    const float farZMax = 25.f;
    const float leftMax = -800.0f;
    const float rightMax = 800.0f;
    const float topMax = -450.0f;
    const float botMax = 450.0f;

    // Other constants
    const GLKVector4 vector4Ones = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    const GLKVector3 vector3Ones = GLKVector3Make(1.0f, 1.0f, 1.0f);

    // Deltas
    GLKVector3 rotationDelta = GLKVector3DivideScalar(GLKVector3Subtract(rotationMax, rotation), numSamplesF32);
    GLKVector3 eyeDelta = GLKVector3DivideScalar(GLKVector3Subtract(eyeMax, eye), numSamplesF32);
    GLKVector3 lookDelta = GLKVector3DivideScalar(GLKVector3Subtract(lookMax, look), numSamplesF32);
    GLKVector3 upDelta = GLKVector3DivideScalar(GLKVector3Subtract(upMax, up), numSamplesF32);
    GLKVector3 scaleDelta = GLKVector3DivideScalar(GLKVector3Subtract(scaleMax, scale), numSamplesF32);
    GLKVector3 translateDelta = GLKVector3DivideScalar(GLKVector3Subtract(translateMax, translate), numSamplesF32);
    GLKVector4 scale4Delta = GLKVector4DivideScalar(GLKVector4Subtract(scale4Max, scale4), numSamplesF32);
    GLKVector4 translate4Delta = GLKVector4DivideScalar(GLKVector4Subtract(translate4Max, translate4), numSamplesF32);
    GLKVector3 rotationAxisDelta = GLKVector3DivideScalar(GLKVector3Subtract(rotationAxisMax, rotationAxis), numSamplesF32);
    GLKVector4 rotation4AxisDelta = GLKVector4DivideScalar(GLKVector4Subtract(rotation4AxisMax, rotation4Axis), numSamplesF32);
    float yradDelta = (yradMax - yrad) / numSamplesF32;
    float aspectDelta = (aspectMax - aspect) / numSamplesF32;
    float nearZDelta = (nearZMax - nearZ) / numSamplesF32;
    float farZDelta = (farZMax - farZ) / numSamplesF32;
    float leftDelta = (leftMax - left);
    float rightDelta = (rightMax - right);
    float topDelta = (topMax - top);
    float botDelta = (botMax - bot);

    // Intermediates
    bool isInvertible;
    unsigned int invertibleCount = 0;
    GLKMatrix4 matrix4LookAt;
    GLKMatrix4 matrix4Rotate;
    GLKMatrix4 matrix4RotateX;
    GLKMatrix4 matrix4RotateY;
    GLKMatrix4 matrix4RotateZ;
    GLKMatrix4 matrix4Translate;
    GLKMatrix4 matrix4Identity;
    GLKMatrix4 matrix4Ortho;
    GLKMatrix3 matrix3RotateX;

    srand((unsigned)time(NULL));

    for (uint64_t i = 0; i < numSamples; i++) {
        // Identities
        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4MakeIdentity();
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MakeIdentity] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].quat = GLKQuaternionMakeIdentity();
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumQuaternionMakeIdentity] += endTick - beginTick;


        // Projection matrices
        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4MakeLookAt(eye.x, eye.y, eye.z, look.x, look.y, look.z, up.x, up.y, up.z);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MakeLookAt] += endTick - beginTick;
        matrix4LookAt = outputBuffer[bufferIndex].mat4;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4MakeOrtho(left, right, bot, top, nearZ, farZ);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MakeOrtho] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4MakeFrustum(left, right, bot, top, nearZ, farZ);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MakeFrustum] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4MakePerspective(yrad, aspect, nearZ, farZ);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MakePerspective] += endTick - beginTick;


        // Rotation Matrices
        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4MakeXRotation(rotation.x);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MakeXRotation] += endTick - beginTick;
        matrix4RotateX = outputBuffer[bufferIndex].mat4;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4MakeYRotation(rotation.y);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MakeYRotation] += endTick - beginTick;
        matrix4RotateY = outputBuffer[bufferIndex].mat4;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4MakeZRotation(rotation.z);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MakeZRotation] += endTick - beginTick;
        matrix4RotateZ = outputBuffer[bufferIndex].mat4;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4RotateX(matrix4Identity, rotation.x);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4RotateX] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4RotateY(matrix4Identity, rotation.y);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4RotateY] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4RotateZ(matrix4Identity, rotation.z);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4RotateZ] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4Rotate(matrix4Identity, rotation.x, rotationAxis.x, rotationAxis.y, rotationAxis.z);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4Rotate] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4MakeRotation(rotation.x, rotationAxis.x, rotationAxis.y, rotationAxis.z);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MakeRotation] += endTick - beginTick;
        matrix4Rotate = outputBuffer[bufferIndex].mat4;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4RotateWithVector3(matrix4Identity, rotation.x, rotationAxis);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4RotateWithVector3] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4RotateWithVector4(matrix4Identity, rotation.x, rotation4Axis);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4RotateWithVector4] += endTick - beginTick;


        // Translation
        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4MakeTranslation(translate.x, translate.y, translate.z);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MakeTranslation] += endTick - beginTick;
        matrix4Translate = outputBuffer[bufferIndex].mat4;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4TranslateWithVector3(matrix4Rotate, translate);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4TranslateWithVector3] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4TranslateWithVector4(matrix4Rotate, translate4);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4TranslateWithVector4] += endTick - beginTick;


        // Matrix Transforms
        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4Transpose(matrix4LookAt);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4Transpose] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4InvertAndTranspose(matrix4RotateX, &isInvertible);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4InvertAndTranspose] += endTick - beginTick;

        if (isInvertible == true) {
            invertibleCount++;
        }

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4Invert(matrix4LookAt, &isInvertible);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4Invert] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4Multiply(matrix4Translate, matrix4RotateZ);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4Multiply] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4Scale(matrix4Rotate, scale.x, scale.y, scale.z);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4Scale] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4ScaleWithVector3(matrix4Rotate, scale);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4ScaleWithVector3] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4ScaleWithVector4(matrix4Rotate, scale4);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4ScaleWithVector4] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4Add(matrix4Rotate, matrix4Translate);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4Add] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4Subtract(matrix4Rotate, matrix4Translate);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4Subtract] += endTick - beginTick;

        matrix3RotateX = GLKMatrix4GetMatrix3(matrix4RotateX);
        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat3 = GLKMatrix3Invert(matrix3RotateX, &isInvertible);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix3Invert] += endTick - beginTick;

        if (isInvertible == true) {
            invertibleCount++;
        }

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat3 = GLKMatrix3InvertAndTranspose(matrix3RotateX, &isInvertible);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix3InvertAndTranspose] += endTick - beginTick;

        // Vector Transforms
        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].vec4 = GLKMatrix4MultiplyVector4(matrix4LookAt, vector4Ones);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MultiplyVector4] += endTick - beginTick;

        /*
        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].quat = GLKQuaternionRotateVector3Array(GLKQuaternion q, GLKVector3* vecs, size_t numVecs);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumQuaternionRotateVector3Array] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4MultiplyVector4Array(GLKMatrix4 m, GLKVector4* vecs, size_t numVecs);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MultiplyVector4Array] += endTick - beginTick;


        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4MultiplyVector3ArrayWithTranslation(matrix4LookAt, GLKVector3* vecs, size_t numVecs);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MultiplyVector3ArrayWithTranslation] += endTick - beginTick;


        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].mat4 = GLKMatrix4MultiplyVector3Array(matrix4LookAt, GLKVector3* vecs, size_t numVecs);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MultiplyVector3Array] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].quat = GLKQuaternionRotateVector4Array(GLKQuaternion q, GLKVector4* vecs, size_t numVecs);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumQuaternionRotateVector4Array] += endTick - beginTick;

        */

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].vec3 = GLKMatrix4MultiplyVector3(matrix4LookAt, vector3Ones);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MultiplyVector3] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].vec3 = GLKMatrix4MultiplyVector3WithTranslation(matrix4LookAt, vector3Ones);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumMatrix4MultiplyVector3WithTranslation] += endTick - beginTick;

        // Quaternion
        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].quat = GLKQuaternionMakeWithMatrix3(matrix3RotateX);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumQuaternionMakeWithMatrix3] += endTick - beginTick;

        bufferIndex = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntries);
        beginTick = mach_absolute_time();
        outputBuffer[bufferIndex].quat = GLKQuaternionMakeWithMatrix4(matrix4Rotate);
        endTick = mach_absolute_time();
        totalTicks[GLKFuncEnumQuaternionMakeWithMatrix4] += endTick - beginTick;

        // Increment varying values
        eye = GLKVector3Add(eye, eyeDelta);
        look = GLKVector3Add(look, lookDelta);
        up = GLKVector3Add(up, upDelta);
        scale = GLKVector3Add(scale, scaleDelta);
        rotation = GLKVector3Add(rotation, rotationDelta);
        rotationAxis = GLKVector3Add(rotationAxis, rotationAxisDelta);
        translate = GLKVector3Add(translate, translateDelta);
        scale4 = GLKVector4Add(scale4, scale4Delta);
        rotation4Axis = GLKVector4Add(rotation4Axis, rotation4AxisDelta);
        translate4 = GLKVector4Add(translate4, translate4Delta);
        yrad += yradDelta;
        left += leftDelta;
        right += rightDelta;
        top += topDelta;
        bot += botDelta;
        nearZ += nearZDelta;
        farZ += farZDelta;

        // Recalculate aspect with incremented base values
        aspect = (left - right) / (bot - top);
    }

    unsigned int bufferIndexDw = (double)rand() / (RAND_MAX + 1) * (numOutputBufferEntriesDw);

    const char* funcNameStr = "Function Name";
    const char* execTimeStr = "Time(ms)";
    const char* lineStr = "-------------------------------------------------------------------------------";

    LOG_INFO("[ Print a random outBuffer value to guarantee dependency is created by the compiler %d]\n", pOutputBuffer[bufferIndexDw]);
    LOG_INFO("%-48s %-s", funcNameStr, execTimeStr);
    LOG_INFO("%.*s", 57, lineStr);
    double totalTimeInMs = 0.0;


    for (int i = 0; i < GLKFuncEnumMax; i++) {
        double timeInMs = (double)totalTicks[i] / cpuFrequency * 1000.0;
        LOG_INFO("%-48s %-f", glkFunctionNames[i], timeInMs);
        totalTimeInMs += timeInMs;
    }

    LOG_INFO("Number of inversions: %d", invertibleCount);
    LOG_INFO("Total Execution Time: %f", totalTimeInMs);
}
