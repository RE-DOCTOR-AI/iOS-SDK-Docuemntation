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



#include <ATen/ops/logaddexp_ops.h>

namespace at {


// aten::logaddexp.out(Tensor self, Tensor other, *, Tensor(a!) out) -> Tensor(a!)
TORCH_API inline at::Tensor & logaddexp_out(at::Tensor & out, const at::Tensor & self, const at::Tensor & other) {
    return at::_ops::logaddexp_out::call(self, other, out);
}

// aten::logaddexp.out(Tensor self, Tensor other, *, Tensor(a!) out) -> Tensor(a!)
TORCH_API inline at::Tensor & logaddexp_outf(const at::Tensor & self, const at::Tensor & other, at::Tensor & out) {
    return at::_ops::logaddexp_out::call(self, other, out);
}

// aten::logaddexp(Tensor self, Tensor other) -> Tensor
TORCH_API inline at::Tensor logaddexp(const at::Tensor & self, const at::Tensor & other) {
    return at::_ops::logaddexp::call(self, other);
}

}
