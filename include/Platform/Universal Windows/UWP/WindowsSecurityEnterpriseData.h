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

// WindowsSecurityEnterpriseData.h
// Generated from winmd2objc

#pragma once

#include <UWP/interopBase.h>

// Windows.Security.EnterpriseData.ProtectionPolicyEvaluationResult
enum _WSEProtectionPolicyEvaluationResult {
    WSEProtectionPolicyEvaluationResultAllowed = 0,
    WSEProtectionPolicyEvaluationResultBlocked = 1,
    WSEProtectionPolicyEvaluationResultConsentRequired = 2,
};
typedef unsigned WSEProtectionPolicyEvaluationResult;

#import <Foundation/Foundation.h>
