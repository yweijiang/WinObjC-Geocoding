//******************************************************************************
//
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

extern "C" int UIApplicationMainLoop();
extern "C" void UIApplicationMainHandleHighMemoryUsageEvent();
extern "C" void UIApplicationMainHandleWindowVisibilityChangeEvent(bool isVisible);
extern "C" void UIApplicationMainHandleToastNotificationEvent(const char* notificationData);
extern "C" void UIApplicationMainHandleVoiceCommandEvent(IInspectable* voiceCommandResult);
extern "C" void UIApplicationMainHandleProtocolEvent(IInspectable* protocolUri, const wchar_t* sourceApplication);
extern "C" void UIApplicationMainHandleSuspendEvent();
extern "C" void UIApplicationMainHandleResumeEvent();
