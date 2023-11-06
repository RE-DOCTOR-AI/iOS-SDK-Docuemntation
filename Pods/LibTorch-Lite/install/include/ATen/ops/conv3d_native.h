#pragma once

// @generated by torchgen/gen.py from NativeFunction.h

#include <c10/core/Scalar.h>
#include <c10/core/Storage.h>
#include <c10/core/TensorOptions.h>
#include <c10/util/Deprecated.h>
#include <c10/util/Optional.h>
#include <c10/core/QScheme.h>
#include <ATen/core/Reduction.h>
#include <ATen/core/Tensor.h>
#include <tuple>
#include <vector>


namespace at {
namespace native {

TORCH_API at::Tensor conv3d(const at::Tensor & input, const at::Tensor & weight, const c10::optional<at::Tensor> & bias={}, at::IntArrayRef stride=1, at::IntArrayRef padding=0, at::IntArrayRef dilation=1, int64_t groups=1);
TORCH_API at::Tensor conv3d(const at::Tensor & input, const at::Tensor & weight, const c10::optional<at::Tensor> & bias={}, at::IntArrayRef stride=1, c10::string_view padding="valid", at::IntArrayRef dilation=1, int64_t groups=1);

} // namespace native
} // namespace at
