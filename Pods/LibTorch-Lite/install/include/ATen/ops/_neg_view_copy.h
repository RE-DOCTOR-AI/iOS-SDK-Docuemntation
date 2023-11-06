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



#include <ATen/ops/_neg_view_copy_ops.h>

namespace at {


// aten::_neg_view_copy(Tensor self) -> Tensor
TORCH_API inline at::Tensor _neg_view_copy(const at::Tensor & self) {
    return at::_ops::_neg_view_copy::call(self);
}

// aten::_neg_view_copy.out(Tensor self, *, Tensor(a!) out) -> Tensor(a!)
TORCH_API inline at::Tensor & _neg_view_copy_out(at::Tensor & out, const at::Tensor & self) {
    return at::_ops::_neg_view_copy_out::call(self, out);
}

// aten::_neg_view_copy.out(Tensor self, *, Tensor(a!) out) -> Tensor(a!)
TORCH_API inline at::Tensor & _neg_view_copy_outf(const at::Tensor & self, at::Tensor & out) {
    return at::_ops::_neg_view_copy_out::call(self, out);
}

}
