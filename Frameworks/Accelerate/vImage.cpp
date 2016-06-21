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

#include "Accelerate/vImage.h"
#include <assert.h>
#include <new>

/**
@Status Interoperable
*/

vImage_Error vImageBoxConvolve_ARGB8888(const vImage_Buffer* src,
                                        const vImage_Buffer* dest,
                                        void* tempBuffer,
                                        vImagePixelCount srcOffsetToROI_X,
                                        vImagePixelCount srcOffsetToROI_Y,
                                        uint32_t kernel_height,
                                        uint32_t kernel_width,
                                        const Pixel_8888 backgroundColor,
                                        vImage_Flags flags) {
    if (src == nullptr || dest == nullptr || src->data == nullptr || dest->data == nullptr) {
        return kvImageNullPointerArgument;
    } else if (!(kernel_height & kernel_width & 1)) {
        return kvImageInvalidKernelSize;
    } else if (srcOffsetToROI_X > src->width) {
        return kvImageInvalidOffset_X;
    } else if (srcOffsetToROI_Y > src->height) {
        return kvImageInvalidOffset_Y;
    } else if ((srcOffsetToROI_Y + dest->height > src->height) || (srcOffsetToROI_X + dest->width > src->width)) {
        return kvImageRoiLargerThanInputBuffer;
    } else if (!(flags & kvImageCopyInPlace) && !(flags & kvImageBackgroundColorFill) && !(flags & kvImageEdgeExtend) &&
               !(flags & kvImageTruncateKernel)) {
        return kvImageInvalidEdgeStyle;
    }

    const unsigned long maxVal = 2147483647;

    //  Caveat: We return kvImageInvalidParameter for height, width, srcOffsetToROI_X, and srcOffsetToROI_Y >=2^31
    //  For 32 bit OS, we don't expect size >= 2^31. Hence it is not supported in current release.
    //  TODO for 64-bit
    if (src->height > maxVal || src->width > maxVal || dest->height > maxVal || dest->width > maxVal || srcOffsetToROI_X > maxVal ||
        srcOffsetToROI_Y > maxVal || kernel_height > maxVal || kernel_width > maxVal) {
        return kvImageInvalidParameter;
    }

    int KW_d2 = kernel_width / 2;
    int KH_d2 = kernel_height / 2;

    //  The following 4 variable denote the location of the first and last pixel to have the kernel
    //  completely overlapping with source image
    uint32_t start_i = 0;
    uint32_t start_j = 0;
    uint32_t end_i = dest->height - 1;
    uint32_t end_j = dest->width - 1;

    if (static_cast<int>(srcOffsetToROI_Y) < KH_d2) {
        start_i = KH_d2 - srcOffsetToROI_Y;
    }

    if (static_cast<int>(srcOffsetToROI_X) < KW_d2) {
        start_j = KW_d2 - srcOffsetToROI_X;
    }

    if (src->height < (srcOffsetToROI_Y + dest->height + KH_d2)) {
        end_i = src->height - srcOffsetToROI_Y - KH_d2 - 1;
    }

    if (src->width < (srcOffsetToROI_X + dest->width + KW_d2)) {
        end_j = src->width - srcOffsetToROI_X - KW_d2 - 1;
    }

    //  The following two variable denote the no of rows required for temporary storage for first pass
    //  above and below the RoI
    int top = KH_d2 - start_i;
    int below = end_i + 1 + KH_d2 - dest->height;

    //  returns the size of temporary buffer data
    if (flags & kvImageGetTempBufferSize) {
        return (dest->height + (top + below) * dest->width) * sizeof(Pixel_8888_s);
    }

    //  Pointer to access the temporary buffer data.
    Pixel_8888_s* temp_buf;
    bool tempBuffer_flag = 0;
    if (tempBuffer == nullptr) {
        temp_buf = new (std::nothrow) Pixel_8888_s[(dest->height + (top + below) * dest->width)];
        if (temp_buf == nullptr) {
            return kvImageMemoryAllocationError;
        }
        tempBuffer_flag = 1;
    } else {
        temp_buf = static_cast<Pixel_8888_s*>(tempBuffer);
    }

    uint32_t sum[4] = { 0 };
    uint32_t src_i;
    uint32_t src_j;
    Pixel_8888_s* src_buf = static_cast<Pixel_8888_s*>(src->data);
    Pixel_8888_s* dest_buf = static_cast<Pixel_8888_s*>(dest->data);
    size_t src_rowstride = src->rowBytes / sizeof(Pixel_8888);
    size_t dest_rowstride = dest->rowBytes / sizeof(Pixel_8888);

    //  This block deals with code for flag kvImageCopyInPlace, which require the pixel to be copied as is
    //  from source image when the kernel does not overlap with the image data
    if (flags & kvImageCopyInPlace) {
        bool sum_flag = 0;

        //  First pass (horizontal)
        for (uint32_t i = 0; i < dest->height; ++i) {
            src_i = srcOffsetToROI_Y + i;
            src_j = srcOffsetToROI_X;
            sum_flag = 0;
            sum[0] = 0;
            sum[1] = 0;
            sum[2] = 0;
            sum[3] = 0;

            for (uint32_t j = 0; j < dest->width; ++j, src_j++) {
                //  Copying the pixel data as is from source for no kernel overlap section
                if (j < start_j || j > end_j) {
                    dest_buf[i * dest_rowstride + j] = src_buf[src_i * src_rowstride + src_j];
                } else {
                    if (sum_flag == 0) {
                        sum_flag = 1;
                        for (int k = -KW_d2; k <= KW_d2; ++k) {
                            sum[0] += src_buf[src_i * src_rowstride + src_j + k].val[0];
                            sum[1] += src_buf[src_i * src_rowstride + src_j + k].val[1];
                            sum[2] += src_buf[src_i * src_rowstride + src_j + k].val[2];
                            sum[3] += src_buf[src_i * src_rowstride + src_j + k].val[3];
                        }
                    } else {
                        sum[0] += -src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[0] +
                                  src_buf[src_i * src_rowstride + src_j + KW_d2].val[0];
                        sum[1] += -src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[1] +
                                  src_buf[src_i * src_rowstride + src_j + KW_d2].val[1];
                        sum[2] += -src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[2] +
                                  src_buf[src_i * src_rowstride + src_j + KW_d2].val[2];
                        sum[3] += -src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[3] +
                                  src_buf[src_i * src_rowstride + src_j + KW_d2].val[3];
                    }

                    dest_buf[i * dest_rowstride + j].val[0] = sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                    dest_buf[i * dest_rowstride + j].val[1] = sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                    dest_buf[i * dest_rowstride + j].val[2] = sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                    dest_buf[i * dest_rowstride + j].val[3] = sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
                }
            }
        }

        //  first pass above("top") the RoI
        for (int i = start_i - KH_d2; i < 0; ++i) {
            src_i = srcOffsetToROI_Y + i;
            src_j = srcOffsetToROI_X;
            sum_flag = 0;
            sum[0] = 0;
            sum[1] = 0;
            sum[2] = 0;
            sum[3] = 0;

            for (uint32_t j = 0; j < dest->width; ++j, src_j++) {
                //  Copying the pixel data as is from source for no kernel overlap section
                if (j < start_j || j > end_j) {
                    temp_buf[(top + i) * dest_rowstride] = src_buf[src_i * src_rowstride + src_j];
                } else {
                    if (sum_flag == 0) {
                        sum_flag = 1;
                        for (int k = -KW_d2; k <= KW_d2; ++k) {
                            sum[0] += src_buf[src_i * src_rowstride + src_j + k].val[0];
                            sum[1] += src_buf[src_i * src_rowstride + src_j + k].val[1];
                            sum[2] += src_buf[src_i * src_rowstride + src_j + k].val[2];
                            sum[3] += src_buf[src_i * src_rowstride + src_j + k].val[3];
                        }
                    } else {
                        sum[0] = sum[0] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[0] +
                                 src_buf[src_i * src_rowstride + src_j + KW_d2].val[0];
                        sum[1] = sum[1] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[1] +
                                 src_buf[src_i * src_rowstride + src_j + KW_d2].val[1];
                        sum[2] = sum[2] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[2] +
                                 src_buf[src_i * src_rowstride + src_j + KW_d2].val[2];
                        sum[3] = sum[3] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[3] +
                                 src_buf[src_i * src_rowstride + src_j + KW_d2].val[3];
                    }

                    temp_buf[(top + i) * dest_rowstride + j].val[0] = sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                    temp_buf[(top + i) * dest_rowstride + j].val[1] = sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                    temp_buf[(top + i) * dest_rowstride + j].val[2] = sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                    temp_buf[(top + i) * dest_rowstride + j].val[3] = sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
                }
            }
        }

        //  first pass below the RoI
        for (uint32_t i = dest->height; i <= end_i + KH_d2; ++i) {
            src_i = srcOffsetToROI_Y + i;
            src_j = srcOffsetToROI_X;
            sum_flag = 0;
            sum[0] = 0;
            sum[1] = 0;
            sum[2] = 0;
            sum[3] = 0;

            for (uint32_t j = 0; j < dest->width; ++j, src_j++) {
                //  Copying the pixel data as is from source for no kernel overlap section
                if (j < start_j || j > end_j) {
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j] = src_buf[src_i * src_rowstride + src_j];
                } else {
                    if (sum_flag == 0) {
                        sum_flag = 1;
                        for (int k = -KW_d2; k <= KW_d2; ++k) {
                            sum[0] += src_buf[src_i * src_rowstride + src_j + k].val[0];
                            sum[1] += src_buf[src_i * src_rowstride + src_j + k].val[1];
                            sum[2] += src_buf[src_i * src_rowstride + src_j + k].val[2];
                            sum[3] += src_buf[src_i * src_rowstride + src_j + k].val[3];
                        }
                    } else {
                        sum[0] = sum[0] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[0] +
                                 src_buf[src_i * src_rowstride + src_j + KW_d2].val[0];
                        sum[1] = sum[1] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[1] +
                                 src_buf[src_i * src_rowstride + src_j + KW_d2].val[1];
                        sum[2] = sum[2] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[2] +
                                 src_buf[src_i * src_rowstride + src_j + KW_d2].val[2];
                        sum[3] = sum[3] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[3] +
                                 src_buf[src_i * src_rowstride + src_j + KW_d2].val[3];
                    }

                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[0] =
                        sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[1] =
                        sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[2] =
                        sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[3] =
                        sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
                }
            }
        }

        //  Second pass (vertical)
        for (uint32_t j = start_j; j <= end_j; ++j) {
            sum_flag = 0;
            sum[0] = 0;
            sum[1] = 0;
            sum[2] = 0;
            sum[3] = 0;

            for (int i = start_i; i <= static_cast<int>(end_i); ++i) {
                if (sum_flag == 0) {
                    sum_flag = 1;
                    for (int k = -KH_d2; k <= KH_d2; ++k) {
                        if (i + k < 0) {
                            sum[0] += temp_buf[(top + (i + k)) * dest_rowstride + j].val[0];
                            sum[1] += temp_buf[(top + (i + k)) * dest_rowstride + j].val[1];
                            sum[2] += temp_buf[(top + (i + k)) * dest_rowstride + j].val[2];
                            sum[3] += temp_buf[(top + (i + k)) * dest_rowstride + j].val[3];
                        } else {
                            sum[0] += dest_buf[(i + k) * dest_rowstride + j].val[0];
                            sum[1] += dest_buf[(i + k) * dest_rowstride + j].val[1];
                            sum[2] += dest_buf[(i + k) * dest_rowstride + j].val[2];
                            sum[3] += dest_buf[(i + k) * dest_rowstride + j].val[3];
                        }
                    }
                } else {
                    if (i - KH_d2 - 1 < 0) {
                        sum[0] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[0];
                        sum[1] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[1];
                        sum[2] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[2];
                        sum[3] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[3];
                    } else {
                        sum[0] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[0];
                        sum[1] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[1];
                        sum[2] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[2];
                        sum[3] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[3];
                    }

                    if (i + KH_d2 >= static_cast<int>(dest->height)) {
                        sum[0] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[0];
                        sum[1] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[1];
                        sum[2] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[2];
                        sum[3] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[3];
                    } else {
                        sum[0] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[0];
                        sum[1] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[1];
                        sum[2] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[2];
                        sum[3] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[3];
                    }
                }

                temp_buf[(top + below) * dest_rowstride + i - start_i].val[0] =
                    sum[0] > (255 * kernel_height) ? 255 : sum[0] / kernel_height;
                temp_buf[(top + below) * dest_rowstride + i - start_i].val[1] =
                    sum[1] > (255 * kernel_height) ? 255 : sum[1] / kernel_height;
                temp_buf[(top + below) * dest_rowstride + i - start_i].val[2] =
                    sum[2] > (255 * kernel_height) ? 255 : sum[2] / kernel_height;
                temp_buf[(top + below) * dest_rowstride + i - start_i].val[3] =
                    sum[3] > (255 * kernel_height) ? 255 : sum[3] / kernel_height;
            }

            for (uint32_t i = start_i; i <= end_i; ++i) {
                dest_buf[i * dest_rowstride + j] = temp_buf[(top + below) * dest_rowstride + i - start_i];
            }
        }

        for (uint32_t i = 0; i < start_i; ++i) {
            src_i = srcOffsetToROI_Y + i;
            src_j = srcOffsetToROI_X + start_j;
            for (uint32_t j = start_j; j <= end_j; ++j, src_j++) {
                dest_buf[i * dest_rowstride + j] = src_buf[src_i * src_rowstride + src_j];
            }
        }

        for (uint32_t i = end_i + 1; i < dest->height; ++i) {
            src_i = srcOffsetToROI_Y + i;
            src_j = srcOffsetToROI_X + start_j;
            for (uint32_t j = start_j; j <= end_j; ++j, src_j++) {
                dest_buf[i * dest_rowstride + j] = src_buf[src_i * src_rowstride + src_j];
            }
        }
    }

    //  This block deals with code for flag kvImageTruncateKernel, which require the kernel to be truncated
    //  when it does not overlap with the image data
    else if (flags & kvImageTruncateKernel) {
        uint32_t divisor;

        //  First pass (horizontal)
        for (int i = static_cast<int>(start_i) - KH_d2; i <= static_cast<int>(end_i) + KH_d2; ++i) {
            src_i = srcOffsetToROI_Y + i;
            src_j = srcOffsetToROI_X;
            sum[0] = 0;
            sum[1] = 0;
            sum[2] = 0;
            sum[3] = 0;
            divisor = kernel_width - start_j;

            for (int k = start_j - KW_d2; k <= KW_d2; ++k) {
                sum[0] += src_buf[src_i * src_rowstride + src_j + k].val[0];
                sum[1] += src_buf[src_i * src_rowstride + src_j + k].val[1];
                sum[2] += src_buf[src_i * src_rowstride + src_j + k].val[2];
                sum[3] += src_buf[src_i * src_rowstride + src_j + k].val[3];
            }

            if (i < 0) {
                temp_buf[(top + i) * dest_rowstride].val[0] = sum[0] > (255 * divisor) ? 255 : sum[0] / divisor;
                temp_buf[(top + i) * dest_rowstride].val[1] = sum[1] > (255 * divisor) ? 255 : sum[1] / divisor;
                temp_buf[(top + i) * dest_rowstride].val[2] = sum[2] > (255 * divisor) ? 255 : sum[2] / divisor;
                temp_buf[(top + i) * dest_rowstride].val[3] = sum[3] > (255 * divisor) ? 255 : sum[3] / divisor;
            } else if (i >= static_cast<int>(dest->height)) {
                temp_buf[(top + (i - dest->height)) * dest_rowstride].val[0] = sum[0] > (255 * divisor) ? 255 : sum[0] / divisor;
                temp_buf[(top + (i - dest->height)) * dest_rowstride].val[1] = sum[1] > (255 * divisor) ? 255 : sum[1] / divisor;
                temp_buf[(top + (i - dest->height)) * dest_rowstride].val[2] = sum[2] > (255 * divisor) ? 255 : sum[2] / divisor;
                temp_buf[(top + (i - dest->height)) * dest_rowstride].val[3] = sum[3] > (255 * divisor) ? 255 : sum[3] / divisor;
            } else {
                dest_buf[i * dest_rowstride].val[0] = sum[0] > (255 * divisor) ? 255 : sum[0] / divisor;
                dest_buf[i * dest_rowstride].val[1] = sum[1] > (255 * divisor) ? 255 : sum[1] / divisor;
                dest_buf[i * dest_rowstride].val[2] = sum[2] > (255 * divisor) ? 255 : sum[2] / divisor;
                dest_buf[i * dest_rowstride].val[3] = sum[3] > (255 * divisor) ? 255 : sum[3] / divisor;
            }

            src_j++;

            for (uint32_t j = 1; j < dest->width; ++j, src_j++) {
                if (j <= start_j) {
                    divisor++;
                    sum[0] += src_buf[src_i * src_rowstride + src_j + KW_d2].val[0];
                    sum[1] += src_buf[src_i * src_rowstride + src_j + KW_d2].val[1];
                    sum[2] += src_buf[src_i * src_rowstride + src_j + KW_d2].val[2];
                    sum[3] += src_buf[src_i * src_rowstride + src_j + KW_d2].val[3];
                } else if (j <= end_j) {
                    sum[0] +=
                        src_buf[src_i * src_rowstride + src_j + KW_d2].val[0] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[0];
                    sum[1] +=
                        src_buf[src_i * src_rowstride + src_j + KW_d2].val[1] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[1];
                    sum[2] +=
                        src_buf[src_i * src_rowstride + src_j + KW_d2].val[2] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[2];
                    sum[3] +=
                        src_buf[src_i * src_rowstride + src_j + KW_d2].val[3] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[3];
                } else {
                    divisor--;
                    sum[0] -= src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[0];
                    sum[1] -= src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[1];
                    sum[2] -= src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[2];
                    sum[3] -= src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[3];
                }

                if (i < 0) {
                    temp_buf[(top + i) * dest_rowstride + j].val[0] = sum[0] > (255 * divisor) ? 255 : sum[0] / divisor;
                    temp_buf[(top + i) * dest_rowstride + j].val[1] = sum[1] > (255 * divisor) ? 255 : sum[1] / divisor;
                    temp_buf[(top + i) * dest_rowstride + j].val[2] = sum[2] > (255 * divisor) ? 255 : sum[2] / divisor;
                    temp_buf[(top + i) * dest_rowstride + j].val[3] = sum[3] > (255 * divisor) ? 255 : sum[3] / divisor;
                } else if (i >= static_cast<int>(dest->height)) {
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[0] = sum[0] > (255 * divisor) ? 255 : sum[0] / divisor;
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[1] = sum[1] > (255 * divisor) ? 255 : sum[1] / divisor;
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[2] = sum[2] > (255 * divisor) ? 255 : sum[2] / divisor;
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[3] = sum[3] > (255 * divisor) ? 255 : sum[3] / divisor;
                } else {
                    dest_buf[i * dest_rowstride + j].val[0] = sum[0] > (255 * divisor) ? 255 : sum[0] / divisor;
                    dest_buf[i * dest_rowstride + j].val[1] = sum[1] > (255 * divisor) ? 255 : sum[1] / divisor;
                    dest_buf[i * dest_rowstride + j].val[2] = sum[2] > (255 * divisor) ? 255 : sum[2] / divisor;
                    dest_buf[i * dest_rowstride + j].val[3] = sum[3] > (255 * divisor) ? 255 : sum[3] / divisor;
                }
            }
        }

        //  Second pass (vertical)
        for (uint32_t j = 0; j < dest->width; ++j) {
            sum[0] = 0;
            sum[1] = 0;
            sum[2] = 0;
            sum[3] = 0;
            divisor = kernel_height - start_i;

            for (int k = start_i - KH_d2; k < 0; ++k) {
                sum[0] += temp_buf[(top + k) * dest_rowstride + j].val[0];
                sum[1] += temp_buf[(top + k) * dest_rowstride + j].val[1];
                sum[2] += temp_buf[(top + k) * dest_rowstride + j].val[2];
                sum[3] += temp_buf[(top + k) * dest_rowstride + j].val[3];
            }

            for (int k = 0; k <= KH_d2; ++k) {
                sum[0] += dest_buf[k * dest_rowstride + j].val[0];
                sum[1] += dest_buf[k * dest_rowstride + j].val[1];
                sum[2] += dest_buf[k * dest_rowstride + j].val[2];
                sum[3] += dest_buf[k * dest_rowstride + j].val[3];
            }

            temp_buf[(top + below) * dest_rowstride].val[0] = sum[0] > (255 * divisor) ? 255 : sum[0] / divisor;
            temp_buf[(top + below) * dest_rowstride].val[1] = sum[1] > (255 * divisor) ? 255 : sum[1] / divisor;
            temp_buf[(top + below) * dest_rowstride].val[2] = sum[2] > (255 * divisor) ? 255 : sum[2] / divisor;
            temp_buf[(top + below) * dest_rowstride].val[3] = sum[3] > (255 * divisor) ? 255 : sum[3] / divisor;

            for (int i = 1; i < static_cast<int>(dest->height); ++i) {
                if (i > static_cast<int>(start_i)) {
                    divisor--;
                    if (i - KH_d2 - 1 < 0) {
                        sum[0] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[0];
                        sum[1] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[1];
                        sum[2] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[2];
                        sum[3] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[3];
                    } else {
                        sum[0] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[0];
                        sum[1] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[1];
                        sum[2] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[2];
                        sum[3] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[3];
                    }
                }

                if (i <= static_cast<int>(end_i)) {
                    divisor++;
                    if (i + KH_d2 >= static_cast<int>(dest->height)) {
                        sum[0] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[0];
                        sum[1] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[1];
                        sum[2] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[2];
                        sum[3] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[3];
                    } else {
                        sum[0] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[0];
                        sum[1] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[1];
                        sum[2] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[2];
                        sum[3] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[3];
                    }
                }

                temp_buf[(top + below) * dest_rowstride + i].val[0] = sum[0] > (255 * divisor) ? 255 : sum[0] / divisor;
                temp_buf[(top + below) * dest_rowstride + i].val[1] = sum[1] > (255 * divisor) ? 255 : sum[1] / divisor;
                temp_buf[(top + below) * dest_rowstride + i].val[2] = sum[2] > (255 * divisor) ? 255 : sum[2] / divisor;
                temp_buf[(top + below) * dest_rowstride + i].val[3] = sum[3] > (255 * divisor) ? 255 : sum[3] / divisor;
            }

            for (uint32_t i = 0; i < dest->height; ++i) {
                dest_buf[i * dest_rowstride + j] = temp_buf[(top + below) * dest_rowstride + i];
            }
        }
    }

    //  This block deals with code for flag kvImageBackgroundColorFill, which requires all pixels outside image to be
    //  set to the parameter backgroundColor
    else if (flags & kvImageBackgroundColorFill) {
        if (backgroundColor == nullptr) {
            return kvImageNullPointerArgument;
        }

        //  First pass (horizontal)
        for (int i = static_cast<int>(start_i) - KH_d2; i <= static_cast<int>(end_i) + KH_d2; ++i) {
            src_i = srcOffsetToROI_Y + i;
            src_j = srcOffsetToROI_X;
            sum[0] = backgroundColor[0] * start_j;
            sum[1] = backgroundColor[1] * start_j;
            sum[2] = backgroundColor[2] * start_j;
            sum[3] = backgroundColor[3] * start_j;

            for (int k = start_j - KW_d2; k <= KW_d2; ++k) {
                sum[0] += src_buf[src_i * src_rowstride + src_j + k].val[0];
                sum[1] += src_buf[src_i * src_rowstride + src_j + k].val[1];
                sum[2] += src_buf[src_i * src_rowstride + src_j + k].val[2];
                sum[3] += src_buf[src_i * src_rowstride + src_j + k].val[3];
            }

            if (i < 0) {
                temp_buf[(top + i) * dest_rowstride].val[0] = sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                temp_buf[(top + i) * dest_rowstride].val[1] = sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                temp_buf[(top + i) * dest_rowstride].val[2] = sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                temp_buf[(top + i) * dest_rowstride].val[3] = sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
            } else if (i >= static_cast<int>(dest->height)) {
                temp_buf[(top + (i - dest->height)) * dest_rowstride].val[0] = sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                temp_buf[(top + (i - dest->height)) * dest_rowstride].val[1] = sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                temp_buf[(top + (i - dest->height)) * dest_rowstride].val[2] = sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                temp_buf[(top + (i - dest->height)) * dest_rowstride].val[3] = sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
            } else {
                dest_buf[i * dest_rowstride].val[0] = sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                dest_buf[i * dest_rowstride].val[1] = sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                dest_buf[i * dest_rowstride].val[2] = sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                dest_buf[i * dest_rowstride].val[3] = sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
            }

            src_j++;

            for (uint32_t j = 1; j < dest->width; ++j, src_j++) {
                if (j <= start_j) {
                    sum[0] += src_buf[src_i * src_rowstride + src_j + KW_d2].val[0] - backgroundColor[0];
                    sum[1] += src_buf[src_i * src_rowstride + src_j + KW_d2].val[1] - backgroundColor[1];
                    sum[2] += src_buf[src_i * src_rowstride + src_j + KW_d2].val[2] - backgroundColor[2];
                    sum[3] += src_buf[src_i * src_rowstride + src_j + KW_d2].val[3] - backgroundColor[3];
                } else if (j <= end_j) {
                    sum[0] +=
                        src_buf[src_i * src_rowstride + src_j + KW_d2].val[0] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[0];
                    sum[1] +=
                        src_buf[src_i * src_rowstride + src_j + KW_d2].val[1] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[1];
                    sum[2] +=
                        src_buf[src_i * src_rowstride + src_j + KW_d2].val[2] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[2];
                    sum[3] +=
                        src_buf[src_i * src_rowstride + src_j + KW_d2].val[3] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[3];
                } else {
                    sum[0] += -src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[0] + backgroundColor[0];
                    sum[1] += -src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[1] + backgroundColor[1];
                    sum[2] += -src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[2] + backgroundColor[2];
                    sum[3] += -src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[3] + backgroundColor[3];
                }

                if (i < 0) {
                    temp_buf[(top + i) * dest_rowstride + j].val[0] = sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                    temp_buf[(top + i) * dest_rowstride + j].val[1] = sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                    temp_buf[(top + i) * dest_rowstride + j].val[2] = sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                    temp_buf[(top + i) * dest_rowstride + j].val[3] = sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
                } else if (i >= static_cast<int>(dest->height)) {
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[0] =
                        sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[1] =
                        sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[2] =
                        sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[3] =
                        sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
                } else {
                    dest_buf[i * dest_rowstride + j].val[0] = sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                    dest_buf[i * dest_rowstride + j].val[1] = sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                    dest_buf[i * dest_rowstride + j].val[2] = sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                    dest_buf[i * dest_rowstride + j].val[3] = sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
                }
            }
        }

        //  Second pass (vertical)
        for (uint32_t j = 0; j < dest->width; ++j) {
            sum[0] = backgroundColor[0] * start_i;
            sum[1] = backgroundColor[1] * start_i;
            sum[2] = backgroundColor[2] * start_i;
            sum[3] = backgroundColor[3] * start_i;

            for (int k = start_i - KH_d2; k < 0; ++k) {
                sum[0] += temp_buf[(top + k) * dest_rowstride + j].val[0];
                sum[1] += temp_buf[(top + k) * dest_rowstride + j].val[1];
                sum[2] += temp_buf[(top + k) * dest_rowstride + j].val[2];
                sum[3] += temp_buf[(top + k) * dest_rowstride + j].val[3];
            }

            for (int k = 0; k <= KH_d2; ++k) {
                sum[0] += dest_buf[k * dest_rowstride + j].val[0];
                sum[1] += dest_buf[k * dest_rowstride + j].val[1];
                sum[2] += dest_buf[k * dest_rowstride + j].val[2];
                sum[3] += dest_buf[k * dest_rowstride + j].val[3];
            }

            temp_buf[(top + below) * dest_rowstride].val[0] = sum[0] > (255 * kernel_height) ? 255 : sum[0] / kernel_height;
            temp_buf[(top + below) * dest_rowstride].val[1] = sum[1] > (255 * kernel_height) ? 255 : sum[1] / kernel_height;
            temp_buf[(top + below) * dest_rowstride].val[2] = sum[2] > (255 * kernel_height) ? 255 : sum[2] / kernel_height;
            temp_buf[(top + below) * dest_rowstride].val[3] = sum[3] > (255 * kernel_height) ? 255 : sum[3] / kernel_height;

            for (int i = 1; i < static_cast<int>(dest->height); ++i) {
                if (i <= static_cast<int>(start_i)) {
                    sum[0] -= backgroundColor[0];
                    sum[1] -= backgroundColor[1];
                    sum[2] -= backgroundColor[2];
                    sum[3] -= backgroundColor[3];
                } else if (i <= KH_d2) {
                    sum[0] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[0];
                    sum[1] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[1];
                    sum[2] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[2];
                    sum[3] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[3];
                } else {
                    sum[0] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[0];
                    sum[1] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[1];
                    sum[2] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[2];
                    sum[3] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[3];
                }

                if (i > static_cast<int>(end_i)) {
                    sum[0] += backgroundColor[0];
                    sum[1] += backgroundColor[1];
                    sum[2] += backgroundColor[2];
                    sum[3] += backgroundColor[3];
                } else if (i >= static_cast<int>(dest->height) - KH_d2) {
                    sum[0] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[0];
                    sum[1] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[1];
                    sum[2] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[2];
                    sum[3] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[3];
                } else {
                    sum[0] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[0];
                    sum[1] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[1];
                    sum[2] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[2];
                    sum[3] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[3];
                }

                temp_buf[(top + below) * dest_rowstride + i].val[0] = sum[0] > (255 * kernel_height) ? 255 : sum[0] / kernel_height;
                temp_buf[(top + below) * dest_rowstride + i].val[1] = sum[1] > (255 * kernel_height) ? 255 : sum[1] / kernel_height;
                temp_buf[(top + below) * dest_rowstride + i].val[2] = sum[2] > (255 * kernel_height) ? 255 : sum[2] / kernel_height;
                temp_buf[(top + below) * dest_rowstride + i].val[3] = sum[3] > (255 * kernel_height) ? 255 : sum[3] / kernel_height;
            }

            for (uint32_t i = 0; i < dest->height; ++i) {
                dest_buf[i * dest_rowstride + j] = temp_buf[(top + below) * dest_rowstride + i];
            }
        }
    }

    //  This block deals with code for flag kvImageEdgeExtend, which requires all pixels outside image to be
    //  replicated by the edges of the image outwards.
    else if (flags & kvImageEdgeExtend) {
        //  For storing the first and the last pixel if the image is to be extended
        Pixel_8888_s first_pixel;
        Pixel_8888_s last_pixel;

        //  First pass (horizontal)
        for (int i = static_cast<int>(start_i) - KH_d2; i <= static_cast<int>(end_i) + KH_d2; ++i) {
            src_i = srcOffsetToROI_Y + i;
            src_j = srcOffsetToROI_X;
            first_pixel = src_buf[src_i * src_rowstride + src_j + (start_j - KW_d2)];
            last_pixel = src_buf[src_i * src_rowstride + src_j + end_j + KW_d2];
            sum[0] = first_pixel.val[0] * start_j;
            sum[1] = first_pixel.val[1] * start_j;
            sum[2] = first_pixel.val[2] * start_j;
            sum[3] = first_pixel.val[3] * start_j;

            for (int k = start_j - KW_d2; k <= KW_d2; ++k) {
                sum[0] += src_buf[src_i * src_rowstride + src_j + k].val[0];
                sum[1] += src_buf[src_i * src_rowstride + src_j + k].val[1];
                sum[2] += src_buf[src_i * src_rowstride + src_j + k].val[2];
                sum[3] += src_buf[src_i * src_rowstride + src_j + k].val[3];
            }

            if (i < 0) {
                temp_buf[(top + i) * dest_rowstride].val[0] = sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                temp_buf[(top + i) * dest_rowstride].val[1] = sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                temp_buf[(top + i) * dest_rowstride].val[2] = sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                temp_buf[(top + i) * dest_rowstride].val[3] = sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
            } else if (i >= static_cast<int>(dest->height)) {
                temp_buf[(top + (i - dest->height)) * dest_rowstride].val[0] = sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                temp_buf[(top + (i - dest->height)) * dest_rowstride].val[1] = sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                temp_buf[(top + (i - dest->height)) * dest_rowstride].val[2] = sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                temp_buf[(top + (i - dest->height)) * dest_rowstride].val[3] = sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
            } else {
                dest_buf[i * dest_rowstride].val[0] = sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                dest_buf[i * dest_rowstride].val[1] = sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                dest_buf[i * dest_rowstride].val[2] = sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                dest_buf[i * dest_rowstride].val[3] = sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
            }

            src_j++;

            for (uint32_t j = 1; j < dest->width; ++j, src_j++) {
                if (j <= start_j) {
                    sum[0] += src_buf[src_i * src_rowstride + src_j + KW_d2].val[0] - first_pixel.val[0];
                    sum[1] += src_buf[src_i * src_rowstride + src_j + KW_d2].val[1] - first_pixel.val[1];
                    sum[2] += src_buf[src_i * src_rowstride + src_j + KW_d2].val[2] - first_pixel.val[2];
                    sum[3] += src_buf[src_i * src_rowstride + src_j + KW_d2].val[3] - first_pixel.val[3];
                } else if (j <= end_j) {
                    sum[0] +=
                        src_buf[src_i * src_rowstride + src_j + KW_d2].val[0] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[0];
                    sum[1] +=
                        src_buf[src_i * src_rowstride + src_j + KW_d2].val[1] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[1];
                    sum[2] +=
                        src_buf[src_i * src_rowstride + src_j + KW_d2].val[2] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[2];
                    sum[3] +=
                        src_buf[src_i * src_rowstride + src_j + KW_d2].val[3] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[3];
                } else {
                    sum[0] += last_pixel.val[0] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[0];
                    sum[1] += last_pixel.val[1] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[1];
                    sum[2] += last_pixel.val[2] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[2];
                    sum[3] += last_pixel.val[3] - src_buf[src_i * src_rowstride + src_j - KW_d2 - 1].val[3];
                }

                if (i < 0) {
                    temp_buf[(top + i) * dest_rowstride + j].val[0] = sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                    temp_buf[(top + i) * dest_rowstride + j].val[1] = sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                    temp_buf[(top + i) * dest_rowstride + j].val[2] = sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                    temp_buf[(top + i) * dest_rowstride + j].val[3] = sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
                } else if (i >= static_cast<int>(dest->height)) {
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[0] =
                        sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[1] =
                        sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[2] =
                        sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                    temp_buf[(top + (i - dest->height)) * dest_rowstride + j].val[3] =
                        sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
                } else {
                    dest_buf[i * dest_rowstride + j].val[0] = sum[0] > (255 * kernel_width) ? 255 : sum[0] / kernel_width;
                    dest_buf[i * dest_rowstride + j].val[1] = sum[1] > (255 * kernel_width) ? 255 : sum[1] / kernel_width;
                    dest_buf[i * dest_rowstride + j].val[2] = sum[2] > (255 * kernel_width) ? 255 : sum[2] / kernel_width;
                    dest_buf[i * dest_rowstride + j].val[3] = sum[3] > (255 * kernel_width) ? 255 : sum[3] / kernel_width;
                }
            }
        }

        //  Second pass (vertical)
        for (uint32_t j = 0; j < dest->width; ++j) {
            if (top > 0) {
                first_pixel = temp_buf[j];
            } else {
                first_pixel = dest_buf[j];
            }

            if (below > 0) {
                last_pixel = temp_buf[(top + below - 1) * dest_rowstride + j];
            } else {
                last_pixel = dest_buf[(dest->height - 1) * dest_rowstride + j];
            }

            sum[0] = first_pixel.val[0] * start_i;
            sum[1] = first_pixel.val[1] * start_i;
            sum[2] = first_pixel.val[2] * start_i;
            sum[3] = first_pixel.val[3] * start_i;

            for (int k = start_i - KH_d2; k < 0; ++k) {
                sum[0] += temp_buf[(top + k) * dest_rowstride + j].val[0];
                sum[1] += temp_buf[(top + k) * dest_rowstride + j].val[1];
                sum[2] += temp_buf[(top + k) * dest_rowstride + j].val[2];
                sum[3] += temp_buf[(top + k) * dest_rowstride + j].val[3];
            }

            for (int k = 0; k <= KH_d2; ++k) {
                sum[0] += dest_buf[k * dest_rowstride + j].val[0];
                sum[1] += dest_buf[k * dest_rowstride + j].val[1];
                sum[2] += dest_buf[k * dest_rowstride + j].val[2];
                sum[3] += dest_buf[k * dest_rowstride + j].val[3];
            }

            temp_buf[(top + below) * dest_rowstride].val[0] = sum[0] > (255 * kernel_height) ? 255 : sum[0] / kernel_height;
            temp_buf[(top + below) * dest_rowstride].val[1] = sum[1] > (255 * kernel_height) ? 255 : sum[1] / kernel_height;
            temp_buf[(top + below) * dest_rowstride].val[2] = sum[2] > (255 * kernel_height) ? 255 : sum[2] / kernel_height;
            temp_buf[(top + below) * dest_rowstride].val[3] = sum[3] > (255 * kernel_height) ? 255 : sum[3] / kernel_height;

            for (int i = 1; i < static_cast<int>(dest->height); ++i) {
                if (i <= static_cast<int>(start_i)) {
                    sum[0] -= first_pixel.val[0];
                    sum[1] -= first_pixel.val[1];
                    sum[2] -= first_pixel.val[2];
                    sum[3] -= first_pixel.val[3];
                } else if (i <= KH_d2) {
                    sum[0] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[0];
                    sum[1] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[1];
                    sum[2] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[2];
                    sum[3] -= temp_buf[(top + (i - KH_d2 - 1)) * dest_rowstride + j].val[3];
                } else {
                    sum[0] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[0];
                    sum[1] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[1];
                    sum[2] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[2];
                    sum[3] -= dest_buf[(i - KH_d2 - 1) * dest_rowstride + j].val[3];
                }

                if (i > static_cast<int>(end_i)) {
                    sum[0] += last_pixel.val[0];
                    sum[1] += last_pixel.val[1];
                    sum[2] += last_pixel.val[2];
                    sum[3] += last_pixel.val[3];
                } else if (i >= static_cast<int>(dest->height) - KH_d2) {
                    sum[0] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[0];
                    sum[1] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[1];
                    sum[2] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[2];
                    sum[3] += temp_buf[(top + (i + KH_d2) - dest->height) * dest_rowstride + j].val[3];
                } else {
                    sum[0] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[0];
                    sum[1] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[1];
                    sum[2] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[2];
                    sum[3] += dest_buf[(i + KH_d2) * dest_rowstride + j].val[3];
                }

                temp_buf[(top + below) * dest_rowstride + i].val[0] = sum[0] > (255 * kernel_height) ? 255 : sum[0] / kernel_height;
                temp_buf[(top + below) * dest_rowstride + i].val[1] = sum[1] > (255 * kernel_height) ? 255 : sum[1] / kernel_height;
                temp_buf[(top + below) * dest_rowstride + i].val[2] = sum[2] > (255 * kernel_height) ? 255 : sum[2] / kernel_height;
                temp_buf[(top + below) * dest_rowstride + i].val[3] = sum[3] > (255 * kernel_height) ? 255 : sum[3] / kernel_height;
            }

            for (uint32_t i = 0; i < dest->height; ++i) {
                dest_buf[i * dest_rowstride + j] = temp_buf[(top + below) * dest_rowstride + i];
            }
        }
    } else {
        return kvImageUnknownFlagsBit;
    }

    //  Deallocating the temporary buffer
    if (tempBuffer_flag == 1) {
        delete[] temp_buf;
    }

    return kvImageNoError;
}

vImage_Error vImageMatrixMultiply_ARGB8888(const vImage_Buffer* src,
                                           const vImage_Buffer* dest,
                                           const int16_t matrix[16],
                                           int32_t divisor,
                                           const int16_t* pre_bias_p,
                                           const int32_t* post_bias_p,
                                           vImage_Flags flags) {
    int32_t m00 = matrix[0];
    int32_t m01 = matrix[1];
    int32_t m02 = matrix[2];
    int32_t m03 = matrix[3];
    int32_t m10 = matrix[4];
    int32_t m11 = matrix[5];
    int32_t m12 = matrix[6];
    int32_t m13 = matrix[7];
    int32_t m20 = matrix[8];
    int32_t m21 = matrix[9];
    int32_t m22 = matrix[10];
    int32_t m23 = matrix[11];
    int32_t m30 = matrix[12];
    int32_t m31 = matrix[13];
    int32_t m32 = matrix[14];
    int32_t m33 = matrix[15];
    int32_t post_b0 = post_bias_p ? post_bias_p[0] : 0;
    int32_t post_b1 = post_bias_p ? post_bias_p[1] : 0;
    int32_t post_b2 = post_bias_p ? post_bias_p[2] : 0;
    int32_t post_b3 = post_bias_p ? post_bias_p[3] : 0;
    vImagePixelCount height = src->height;
    vImagePixelCount width = src->width;
    const Pixel_8888_s* in = static_cast<Pixel_8888_s*>(src->data);
    size_t in_rowstride = src->rowBytes / sizeof(Pixel_8888);
    Pixel_8888_s* out = static_cast<Pixel_8888_s*>(dest->data);
    size_t out_rowstride = dest->rowBytes / sizeof(Pixel_8888);

    if (!in || !out) {
        return kvImageNullPointerArgument;
    } else if (height != dest->height || width != dest->width) {
        return kvImageInvalidParameter;
    }

    if (pre_bias_p) {
        int32_t pre_b0 = pre_bias_p[0];
        int32_t pre_b1 = pre_bias_p[1];
        int32_t pre_b2 = pre_bias_p[2];
        int32_t pre_b3 = pre_bias_p[3];

        for (vImagePixelCount i = 0; i < height; ++i) {
            for (vImagePixelCount j = 0; j < width; ++j) {
                struct Pixel_8888_s pixel = in[i * in_rowstride + j];
                int32_t prod[4];
                pixel.val[0] += pre_b0;
                pixel.val[1] += pre_b1;
                pixel.val[2] += pre_b2;
                pixel.val[3] += pre_b3;
                prod[0] = pixel.val[0] * m00 + pixel.val[1] * m10 + pixel.val[2] * m20 + pixel.val[3] * m30 + post_b0;
                prod[1] = pixel.val[0] * m01 + pixel.val[1] * m11 + pixel.val[2] * m21 + pixel.val[3] * m31 + post_b1;
                prod[2] = pixel.val[0] * m02 + pixel.val[1] * m12 + pixel.val[2] * m22 + pixel.val[3] * m32 + post_b2;
                prod[3] = pixel.val[0] * m03 + pixel.val[1] * m13 + pixel.val[2] * m23 + pixel.val[3] * m33 + post_b3;

                if (divisor != 1) {
                    prod[0] /= divisor;
                    prod[1] /= divisor;
                    prod[2] /= divisor;
                    prod[3] /= divisor;
                }

                pixel.val[0] = prod[0] > 255 ? 255 : prod[0] < 0 ? 0 : prod[0];
                pixel.val[1] = prod[1] > 255 ? 255 : prod[1] < 0 ? 0 : prod[1];
                pixel.val[2] = prod[2] > 255 ? 255 : prod[2] < 0 ? 0 : prod[2];
                pixel.val[3] = prod[3] > 255 ? 255 : prod[3] < 0 ? 0 : prod[3];

                out[i * out_rowstride + j] = pixel;
            }
        }
    } else {
        for (vImagePixelCount i = 0; i < height; ++i) {
            for (vImagePixelCount j = 0; j < width; ++j) {
                struct Pixel_8888_s pixel = in[i * in_rowstride + j];
                int32_t prod[4];
                prod[0] = pixel.val[0] * m00 + pixel.val[1] * m10 + pixel.val[2] * m20 + pixel.val[3] * m30 + post_b0;
                prod[1] = pixel.val[0] * m01 + pixel.val[1] * m11 + pixel.val[2] * m21 + pixel.val[3] * m31 + post_b1;
                prod[2] = pixel.val[0] * m02 + pixel.val[1] * m12 + pixel.val[2] * m22 + pixel.val[3] * m32 + post_b2;
                prod[3] = pixel.val[0] * m03 + pixel.val[1] * m13 + pixel.val[2] * m23 + pixel.val[3] * m33 + post_b3;

                if (divisor != 1) {
                    prod[0] /= divisor;
                    prod[1] /= divisor;
                    prod[2] /= divisor;
                    prod[3] /= divisor;
                }

                pixel.val[0] = prod[0] > 255 ? 255 : prod[0] < 0 ? 0 : prod[0];
                pixel.val[1] = prod[1] > 255 ? 255 : prod[1] < 0 ? 0 : prod[1];
                pixel.val[2] = prod[2] > 255 ? 255 : prod[2] < 0 ? 0 : prod[2];
                pixel.val[3] = prod[3] > 255 ? 255 : prod[3] < 0 ? 0 : prod[3];

                out[i * out_rowstride + j] = pixel;
            }
        }
    }

    return kvImageNoError;
}

/// Separates an ARGB8888 image into four Planar8 images.
vImage_Error vImageConvert_ARGB8888toPlanar8(const vImage_Buffer* srcARGB,
                                             const vImage_Buffer* destA,
                                             const vImage_Buffer* destR,
                                             const vImage_Buffer* destG,
                                             const vImage_Buffer* destB,
                                             vImage_Flags flags) {
    assert((destA != nullptr) && (destR != nullptr) && (destG != nullptr) && (destB != nullptr) && (srcARGB != nullptr));
    assert((srcARGB->height == destA->height) && (srcARGB->height == destR->height) && (srcARGB->height == destG->height) &&
           (srcARGB->height == destB->height));
    assert((srcARGB->width == destA->width) && (srcARGB->width == destR->width) && (srcARGB->width == destG->width) &&
           (srcARGB->width == destB->width));

    const size_t srcRowPitch = srcARGB->rowBytes;
    const size_t dstRowPitch = destA->rowBytes;
    const unsigned int bytesPerChannel = 1;
    const unsigned int bytesPerPixel = 4;
    const unsigned int width = srcARGB->width;
    const unsigned int height = srcARGB->height;
    const size_t srcRowPixelPitch = srcARGB->rowBytes / bytesPerPixel;

    assert(srcARGB->rowBytes % bytesPerPixel == 0);
    assert(srcRowPitch >= width * bytesPerPixel);
    assert(dstRowPitch >= width * bytesPerChannel);

#if (VIMAGE_USE_SSE == 1)
    if (width > 16) {
        const unsigned int pixelsPerIteration = 16;
        const unsigned int pixelsPerIteration_2 = pixelsPerIteration >> 1;
        const unsigned int iterationsPerRow = width / pixelsPerIteration + ((width % pixelsPerIteration != 0) ? 1 : 0);

        char* pixelRowBytePtr = reinterpret_cast<char*>(srcARGB->data);
        char* alphaRowBytePtr = reinterpret_cast<char*>(destA->data);
        char* redRowBytePtr = reinterpret_cast<char*>(destR->data);
        char* greenRowBytePtr = reinterpret_cast<char*>(destG->data);
        char* blueRowBytePtr = reinterpret_cast<char*>(destB->data);

        __m128i *pixelRowM128Ptr, *alphaRowM128Ptr, *redRowM128Ptr, *greenRowM128Ptr, *blueRowM128Ptr;
        __m128i vPixelBlocks[4], vBlocks02A, vBlocks13A, vBlocks02B, vBlocks13B, vBlocks_02A_13A_A, vBlocks_02A_13A_B, vBlocks_02B_13B_A, vBlocks_02B_13B_B;
        __m128i vAlphaRedEven, vAlphaRedOdd, vGreenBlueEven, vGreenBlueOdd;
        __m128i vAlpha, vRed, vGreen, vBlue;

        for (unsigned int i = 0; i < height; i++) {

            alphaRowM128Ptr = reinterpret_cast<__m128i*>(alphaRowBytePtr);
            redRowM128Ptr = reinterpret_cast<__m128i*>(redRowBytePtr);
            greenRowM128Ptr = reinterpret_cast<__m128i*>(greenRowBytePtr);
            blueRowM128Ptr = reinterpret_cast<__m128i*>(blueRowBytePtr);
            pixelRowM128Ptr = reinterpret_cast<__m128i*>(pixelRowBytePtr);

            for (unsigned int j = 0; j < iterationsPerRow; j++) {
                vPixelBlocks[0] = _mm_loadu_si128(&pixelRowM128Ptr[0]);
                vPixelBlocks[1] = _mm_loadu_si128(&pixelRowM128Ptr[1]);
                vPixelBlocks[2] = _mm_loadu_si128(&pixelRowM128Ptr[2]);
                vPixelBlocks[3] = _mm_loadu_si128(&pixelRowM128Ptr[3]);

                // Interleave blocks 0 and 2
                vBlocks02A = _mm_unpacklo_epi8(vPixelBlocks[0], vPixelBlocks[2]);
                vBlocks02B = _mm_unpackhi_epi8(vPixelBlocks[0], vPixelBlocks[2]);

                // Interleave blocks 1 and 3
                vBlocks13A = _mm_unpacklo_epi8(vPixelBlocks[1], vPixelBlocks[3]);
                vBlocks13B = _mm_unpackhi_epi8(vPixelBlocks[1], vPixelBlocks[3]);

                // Interleave 02A and 13A
                vBlocks_02A_13A_A = _mm_unpacklo_epi8(vBlocks02A, vBlocks13A);
                vBlocks_02A_13A_B = _mm_unpackhi_epi8(vBlocks02A, vBlocks13A);

                // Interleave 02B and 13B
                vBlocks_02B_13B_A = _mm_unpacklo_epi8(vBlocks02B, vBlocks13B);
                vBlocks_02B_13B_B = _mm_unpackhi_epi8(vBlocks02B, vBlocks13B);

                vAlphaRedEven = _mm_unpacklo_epi8(vBlocks_02A_13A_A, vBlocks_02B_13B_A);
                vGreenBlueEven = _mm_unpackhi_epi8(vBlocks_02A_13A_A, vBlocks_02B_13B_A);

                vAlphaRedOdd = _mm_unpacklo_epi8(vBlocks_02A_13A_B, vBlocks_02B_13B_B);
                vGreenBlueOdd = _mm_unpackhi_epi8(vBlocks_02A_13A_B, vBlocks_02B_13B_B);

                vAlpha = _mm_unpacklo_epi8(vAlphaRedEven, vAlphaRedOdd);
                vRed = _mm_unpackhi_epi8(vAlphaRedEven, vAlphaRedOdd);

                vGreen = _mm_unpacklo_epi8(vGreenBlueEven, vGreenBlueOdd);
                vBlue = _mm_unpackhi_epi8(vGreenBlueEven, vGreenBlueOdd);

                _mm_store_si128(&alphaRowM128Ptr[j], vAlpha);
                _mm_store_si128(&redRowM128Ptr[j], vRed);
                _mm_store_si128(&greenRowM128Ptr[j], vGreen);
                _mm_store_si128(&blueRowM128Ptr[j], vBlue);

                pixelRowM128Ptr += 4;
            }

            alphaRowBytePtr += destA->rowBytes;
            redRowBytePtr += destR->rowBytes;
            greenRowBytePtr += destG->rowBytes;
            blueRowBytePtr += destB->rowBytes;
            pixelRowBytePtr += srcARGB->rowBytes;
        }
    } else {
#endif
        Pixel_8888_s* pSrc = reinterpret_cast<Pixel_8888_s*>(srcARGB->data);
        unsigned char* pDstA = reinterpret_cast<unsigned char*>(destA->data);
        unsigned char* pDstR = reinterpret_cast<unsigned char*>(destR->data);
        unsigned char* pDstG = reinterpret_cast<unsigned char*>(destG->data);
        unsigned char* pDstB = reinterpret_cast<unsigned char*>(destB->data);

        for (unsigned int i = 0; i < height; i++) {
            for (unsigned int j = 0; j < width; j++) {
                pDstA[j] = pSrc[j].val[0];
                pDstR[j] = pSrc[j].val[1];
                pDstG[j] = pSrc[j].val[2];
                pDstB[j] = pSrc[j].val[3];
            }

            pDstA += destA->rowBytes;
            pDstR += destR->rowBytes;
            pDstG += destG->rowBytes;
            pDstB += destB->rowBytes;
            pSrc += srcRowPixelPitch;
        }
#if (VIMAGE_USE_SSE == 1)
    }
#endif


    return kvImageNoError;
}

/// Combines four Planar8 images into one ARGB8888 image.
vImage_Error vImageConvert_Planar8toARGB8888(const vImage_Buffer* srcA,
                                             const vImage_Buffer* srcR,
                                             const vImage_Buffer* srcG,
                                             const vImage_Buffer* srcB,
                                             const vImage_Buffer* dest,
                                             vImage_Flags flags) {
    assert((srcA != nullptr) && (srcR != nullptr) && (srcG != nullptr) && (srcB != nullptr) && (dest != nullptr));
    assert((dest->height == srcA->height) && (dest->height == srcR->height) && (dest->height == srcG->height) &&
           (dest->height == srcB->height));
    assert((dest->width == srcA->width) && (dest->width == srcR->width) && (dest->width == srcG->width) && (dest->width == srcB->width));

    const unsigned int bytesPerChannel = 1;
    const unsigned int bytesPerPixel = 4;
    const unsigned int width = dest->width;
    const unsigned int height = dest->height;
    const size_t srcRowPitch = srcA->rowBytes;
    const size_t dstRowPixelPitch = dest->rowBytes / bytesPerPixel;

    assert(dest->rowBytes % bytesPerPixel == 0);

    assert(srcRowPitch >= width * bytesPerChannel);
    assert(dstRowPixelPitch >= width);

#if (VIMAGE_USE_SSE == 1)
    if (width > 16) {
        const unsigned int pixelsPerIteration = 16;
        const unsigned int pixelsPerIteration_2 = pixelsPerIteration >> 1;
        const unsigned int iterationsPerRow = width / pixelsPerIteration + ((width % pixelsPerIteration != 0) ? 1 : 0);

        char* pixelRowBytePtr = reinterpret_cast<char*>(dest->data);
        char* alphaRowBytePtr = reinterpret_cast<char*>(srcA->data);
        char* redRowBytePtr = reinterpret_cast<char*>(srcR->data);
        char* greenRowBytePtr = reinterpret_cast<char*>(srcG->data);
        char* blueRowBytePtr = reinterpret_cast<char*>(srcB->data);

        __m128i *pixelRowM128Ptr, *alphaRowM128Ptr, *redRowM128Ptr, *greenRowM128Ptr, *blueRowM128Ptr;
        __m128i vA, vR, vG, vB, vAG, vRB, vARGB;

        for (unsigned int i = 0; i < height; i++) {

            alphaRowM128Ptr = reinterpret_cast<__m128i*>(alphaRowBytePtr);
            redRowM128Ptr = reinterpret_cast<__m128i*>(redRowBytePtr);
            greenRowM128Ptr = reinterpret_cast<__m128i*>(greenRowBytePtr);
            blueRowM128Ptr = reinterpret_cast<__m128i*>(blueRowBytePtr);
            pixelRowM128Ptr = reinterpret_cast<__m128i*>(pixelRowBytePtr);

            for (unsigned int j = 0; j < iterationsPerRow; j++) {
                vA = _mm_loadu_si128(&alphaRowM128Ptr[j]);
                vR = _mm_loadu_si128(&redRowM128Ptr[j]);
                vG = _mm_loadu_si128(&greenRowM128Ptr[j]);
                vB = _mm_loadu_si128(&blueRowM128Ptr[j]);

                /// Lower half
                // First pixel group
                vAG = _mm_unpacklo_epi8(vA, vG);
                vRB = _mm_unpacklo_epi8(vR, vB);
                vARGB = _mm_unpacklo_epi8(vAG, vRB);
                _mm_store_si128(pixelRowM128Ptr, vARGB);
                pixelRowM128Ptr++;

                // Second group
                vARGB = _mm_unpackhi_epi8(vAG, vRB);
                _mm_store_si128(pixelRowM128Ptr, vARGB);
                pixelRowM128Ptr++;

                /// Higher half
                // Third pixel group
                vAG = _mm_unpackhi_epi8(vA, vG);
                vRB = _mm_unpackhi_epi8(vR, vB);
                vARGB = _mm_unpacklo_epi8(vAG, vRB);
                _mm_store_si128(pixelRowM128Ptr, vARGB);
                pixelRowM128Ptr++;

                // Fourth pixel group
                vARGB = _mm_unpackhi_epi8(vAG, vRB);
                _mm_store_si128(pixelRowM128Ptr, vARGB);
                pixelRowM128Ptr++;
            }


            alphaRowBytePtr += srcA->rowBytes;
            redRowBytePtr += srcR->rowBytes;
            greenRowBytePtr += srcG->rowBytes;
            blueRowBytePtr += srcB->rowBytes;
            pixelRowBytePtr += dest->rowBytes;
        }
    } else {
#endif
        unsigned char* alphaRow = reinterpret_cast<unsigned char*>(srcA->data);
        unsigned char* redRow = reinterpret_cast<unsigned char*>(srcR->data);
        unsigned char* greenRow = reinterpret_cast<unsigned char*>(srcG->data);
        unsigned char* blueRow = reinterpret_cast<unsigned char*>(srcB->data);
        Pixel_8888_s* pixelRow = reinterpret_cast<Pixel_8888_s*>(dest->data);

        for (unsigned int i = 0; i < height; i++) {
            for (unsigned int j = 0; j < width; j++) {
                pixelRow[j].val[0] = alphaRow[j];
                pixelRow[j].val[1] = redRow[j];
                pixelRow[j].val[2] = greenRow[j];
                pixelRow[j].val[3] = blueRow[j];
            }

            alphaRow += srcA->rowBytes;
            redRow += srcR->rowBytes;
            greenRow += srcG->rowBytes;
            blueRow += srcB->rowBytes;
            pixelRow += dstRowPixelPitch;
        }
#if (VIMAGE_USE_SSE == 1)
    }
#endif

    return kvImageNoError;
}

/// Converts a Planar8 image to a PlanarF image.
vImage_Error vImageConvert_Planar8toPlanarF(
    const vImage_Buffer* src, const vImage_Buffer* dest, Pixel_F maxFloat, Pixel_F minFloat, vImage_Flags flags) {
    assert((src != nullptr) && (dest != nullptr));
    assert(src->width == dest->width);
    assert(src->height == dest->height);

    const size_t srcRowPitch = src->rowBytes;
    const size_t dstRowPitch = dest->rowBytes;
    const unsigned int bytesPerChannel = 1;
    const unsigned int bytesPerPixel = 4;
    const unsigned int width = src->width;
    const unsigned int height = src->height;

    assert(srcRowPitch >= width * bytesPerChannel);
    assert(dstRowPitch >= width * bytesPerPixel);

    unsigned char* pSrc = reinterpret_cast<unsigned char*>(src->data);
    Pixel_F* pDst = reinterpret_cast<Pixel_F*>(dest->data);

    for (unsigned int i = 0; i < height; i++) {
        for (unsigned int j = 0; j < width; j++) {
            pDst[j] = vImageConvertAndClampUint8ToFloat(pSrc[j], minFloat, maxFloat);
        }

        pDst += dstRowPitch;
        pSrc += srcRowPitch;
    }

    return kvImageNoError;
}

/// Combines three Planar8 images into one RGB888 image.
vImage_Error vImageConvert_Planar8toRGB888(const vImage_Buffer* planarRed,
                                           const vImage_Buffer* planarGreen,
                                           const vImage_Buffer* planarBlue,
                                           const vImage_Buffer* rgbDest,
                                           vImage_Flags flags) {
    assert((planarRed != nullptr) && (planarGreen != nullptr) && (planarBlue != nullptr) && (rgbDest != nullptr));
    assert(planarRed->width == planarBlue->width == planarGreen->width == rgbDest->width);
    assert(planarRed->height == planarBlue->height == planarGreen->height == rgbDest->height);

    const size_t srcRowPitch = planarRed->rowBytes;
    const size_t dstRowPitch = rgbDest->rowBytes;
    const unsigned int bytesPerChannel = 1;
    const unsigned int bytesPerPixel = 4;
    const unsigned int width = rgbDest->width;
    const unsigned int height = rgbDest->height;

    assert(srcRowPitch >= width * bytesPerChannel);
    assert(dstRowPitch >= width * bytesPerPixel);

    Pixel_8888_s* pDst = reinterpret_cast<Pixel_8888_s*>(rgbDest->data);
    unsigned char* pSrcR = reinterpret_cast<unsigned char*>(planarRed->data);
    unsigned char* pSrcG = reinterpret_cast<unsigned char*>(planarGreen->data);
    unsigned char* pSrcB = reinterpret_cast<unsigned char*>(planarBlue->data);

    for (unsigned int i = 0; i < height; i++) {
        for (unsigned int j = 0; j < width; j++) {
            pDst[j].val[0] = pSrcR[j];
            pDst[j].val[1] = pSrcG[j];
            pDst[j].val[2] = pSrcB[j];
        }

        pSrcR += planarRed->rowBytes;
        pSrcG += planarGreen->rowBytes;
        pSrcB += planarBlue->rowBytes;
        pDst += dstRowPitch;
    }

    return kvImageNoError;
}

/// Converts a PlanarF image to a Planar8 image, clipping values to the provided minimum and maximum values.
vImage_Error vImageConvert_PlanarFtoPlanar8(
    const vImage_Buffer* src, const vImage_Buffer* dest, Pixel_F maxFloat, Pixel_F minFloat, vImage_Flags flags) {
    assert((src != nullptr) && (dest != nullptr));
    assert(src->width == dest->width);
    assert(src->height == dest->height);

    const size_t srcRowPitch = src->rowBytes;
    const size_t dstRowPitch = dest->rowBytes;
    const unsigned int bytesPerChannel = 1;
    const unsigned int bytesPerPixel = 4;
    const unsigned int width = src->width;
    const unsigned int height = src->height;

    assert(srcRowPitch >= width * bytesPerPixel);
    assert(dstRowPitch >= width * bytesPerChannel);

    Pixel_F* pSrc = reinterpret_cast<Pixel_F*>(src->data);
    unsigned char* pDst = reinterpret_cast<unsigned char*>(dest->data);

    for (unsigned int i = 0; i < height; i++) {
        for (unsigned int j = 0; j < width; j++) {
            pDst[j] = vImageClipConvertAndSaturateFloatToUint8(pSrc[j], minFloat, maxFloat);
        }

        pDst += dstRowPitch;
        pSrc += srcRowPitch;
    }

    return kvImageNoError;
}

/// Takes an RGBA8888 image in premultiplied alpha format and transforms it into an image in nonpremultiplied alpha format.
vImage_Error vImageUnpremultiplyData_RGBA8888(const vImage_Buffer* src, const vImage_Buffer* dest, vImage_Flags flags) {
    assert((src != nullptr) && (dest != nullptr));
    assert(src->width == dest->width);
    assert(src->height == dest->height);

    const size_t srcRowPitch = src->rowBytes;
    const size_t dstRowPitch = dest->rowBytes;
    const unsigned int bytesPerChannel = 1;
    const unsigned int bytesPerPixel = 4;
    const unsigned int width = src->width;
    const unsigned int height = src->height;

    assert(srcRowPitch >= width * bytesPerPixel);
    assert(dstRowPitch >= width * bytesPerPixel);

    Pixel_8888_s* pSrc = reinterpret_cast<Pixel_8888_s*>(src->data);
    Pixel_8888_s* pDst = reinterpret_cast<Pixel_8888_s*>(dest->data);

    for (unsigned int i = 0; i < height; i++) {
        for (unsigned int j = 0; j < width; j++) {
            pDst[j].val[0] = pSrc[j].val[0] / pSrc[j].val[3];
            pDst[j].val[1] = pSrc[j].val[1] / pSrc[j].val[3];
            pDst[j].val[2] = pSrc[j].val[2] / pSrc[j].val[3];
            pDst[j].val[3] = pSrc[j].val[3];
        }

        pDst += dstRowPitch;
        pSrc += srcRowPitch;
    }

    return kvImageNoError;
}

vImage_Error vImageHistogramCalculation_ARGB8888(const vImage_Buffer* src, vImagePixelCount* histogram[4], vImage_Flags flags) {
    return kvImageNoError;
}

vImage_Error vImageHistogramSpecification_ARGB8888(const vImage_Buffer* src,
                                                   const vImage_Buffer* dest,
                                                   const vImagePixelCount* desired_histogram[4],
                                                   vImage_Flags flags) {
    assert((src != nullptr) && (dest != nullptr));
    assert(src->width == dest->width);
    assert(src->height == dest->height);

    // Debug: Until implemented, just copy input buffer to output buffer

    // ensure source bpp equals dest bpp
    assert((src->rowBytes / src->width) == (dest->rowBytes / dest->width));

    const unsigned int width = src->width;
    const unsigned int height = src->height;
    const unsigned int srcPitch = src->rowBytes;
    const unsigned int dstPitch = dest->rowBytes;
    const unsigned int bpp = src->rowBytes / src->width;
    const unsigned int usedBytesPerRow = bpp * src->rowBytes;
    unsigned char* pSrc = reinterpret_cast<unsigned char*>(src->data);
    unsigned char* pDst = reinterpret_cast<unsigned char*>(dest->data);

    for (unsigned int i = 0; i < height; i++) {
        memcpy(pDst, pSrc, usedBytesPerRow);

        pDst += dstPitch;
        pSrc += srcPitch;
    }

    return kvImageNoError;
}

vImage_Error vImageBuffer_Init(
    vImage_Buffer* buffer, vImagePixelCount height, vImagePixelCount width, uint32_t bitsPerFragment, vImage_Flags flags) {
    assert(flags == kvImageNoFlags);

    vImage_Error returnCode = kvImageNoError;

    buffer->height = height;
    buffer->width = width;

    uint32_t bpp = bitsPerFragment / 8;

    if (padAllocs == true && width > 15 && height > 1 && bpp < 8) {
        // For 4bpp pixels, SSE2 instructions operate on 16 pixels at a time
        const uint32_t pixelPitchAlignment = 16;
        const uint32_t idealMemAlignmentBytes = 16;
        const uint32_t minCompilerAlignmentBytes = 4;
        const uint32_t additionalRowPaddingPixels = (idealMemAlignmentBytes - minCompilerAlignmentBytes) / bpp;
        uint32_t alignedWidth = vImageAlignUInt(width, pixelPitchAlignment);
        const uint32_t maxWidth = alignedWidth + additionalRowPaddingPixels;

        uint32_t allocSize = maxWidth * bpp * height;

        // Note: We can't use alignedMalloc here since the client is responsible for freeing the buffer and can use free or aligned_free
        buffer->data = malloc(allocSize);

        if (buffer->data != nullptr) {
            // SSE2 load store instructions operate best on 16byte aligned memory
            // Padding to ensure that for unaligned allocs, at least:
            // 1. A single 16pixel block can be operated on per row
            // 2. Every second row will be 16byte aligned
            const uint32_t bytePaddingForIdealAlignment =
                (idealMemAlignmentBytes - ((uint32_t)(buffer->data) & (idealMemAlignmentBytes - 1))) % idealMemAlignmentBytes;
            buffer->rowBytes = alignedWidth * bpp + bytePaddingForIdealAlignment;
        } else {
            returnCode = kvImageMemoryAllocationError;
        }
    } else {
        buffer->rowBytes = vImageAlignUInt(width, 16) * bpp;
        buffer->data = malloc(buffer->rowBytes * height);

        if (buffer->data == nullptr) {
            returnCode = kvImageMemoryAllocationError;
        }
    }

    return returnCode;
}