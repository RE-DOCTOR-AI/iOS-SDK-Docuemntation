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



#include <ATen/ops/subtract_ops.h>

namespace at {


// aten::subtract.out(Tensor self, Tensor other, *, Scalar alpha=1, Tensor(a!) out) -> Tensor(a!)
TORCH_API inline at::Tensor & subtract_out(at::Tensor & out, const at::Tensor & self, const at::Tensor & other, const at::Scalar & alpha=1) {
    return at::_ops::subtract_out::call(self, other, alpha, out);
}

// aten::subtract.out(Tensor self, Tensor other, *, Scalar alpha=1, Tensor(a!) out) -> Tensor(a!)
TORCH_API inline at::Tensor & subtract_outf(const at::Tensor & self, const at::Tensor & other, const at::Scalar & alpha, at::Tensor & out) {
    return at::_ops::subtract_out::call(self, other, alpha, out);
}

// aten::subtract.Tensor(Tensor self, Tensor other, *, Scalar alpha=1) -> Tensor
TORCH_API inline at::Tensor subtract(const at::Tensor & self, const at::Tensor & other, const at::Scalar & alpha=1) {
    return at::_ops::subtract_Tensor::call(self, other, alpha);
}

// aten::subtract.Scalar(Tensor self, Scalar other, Scalar alpha=1) -> Tensor
TORCH_API inline at::Tensor subtract(const at::Tensor & self, const at::Scalar & other, const at::Scalar & alpha=1) {
    return at::_ops::subtract_Scalar::call(self, other, alpha);
}

}
