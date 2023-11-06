#pragma once

// @generated by torchgen/gen.py from Function.h

#include <ATen/Context.h>
#include <ATen/DeviceGuard.h>
#include <ATen/TensorUtils.h>
#include <ATen/TracerMode.h>
#include <ATen/core/Generator.h>
#include <ATen/core/Reduction.h>
#include <ATen/core/Tensor.h>
#include <c10/core/Scalar.h>
#include <c10/core/Storage.h>
#include <c10/core/TensorOptions.h>
#include <c10/util/Deprecated.h>
#include <c10/util/Optional.h>



#include <ATen/ops/fft_fftn_ops.h>

namespace at {


// aten::fft_fftn(Tensor self, int[1]? s=None, int[1]? dim=None, str? norm=None) -> Tensor
TORCH_API inline at::Tensor fft_fftn(const at::Tensor & self, at::OptionalIntArrayRef s=c10::nullopt, at::OptionalIntArrayRef dim=c10::nullopt, c10::optional<c10::string_view> norm=c10::nullopt) {
    return at::_ops::fft_fftn::call(self, s, dim, norm);
}

// aten::fft_fftn.out(Tensor self, int[1]? s=None, int[1]? dim=None, str? norm=None, *, Tensor(a!) out) -> Tensor(a!)
TORCH_API inline at::Tensor & fft_fftn_out(at::Tensor & out, const at::Tensor & self, at::OptionalIntArrayRef s=c10::nullopt, at::OptionalIntArrayRef dim=c10::nullopt, c10::optional<c10::string_view> norm=c10::nullopt) {
    return at::_ops::fft_fftn_out::call(self, s, dim, norm, out);
}

// aten::fft_fftn.out(Tensor self, int[1]? s=None, int[1]? dim=None, str? norm=None, *, Tensor(a!) out) -> Tensor(a!)
TORCH_API inline at::Tensor & fft_fftn_outf(const at::Tensor & self, at::OptionalIntArrayRef s, at::OptionalIntArrayRef dim, c10::optional<c10::string_view> norm, at::Tensor & out) {
    return at::_ops::fft_fftn_out::call(self, s, dim, norm, out);
}

}
