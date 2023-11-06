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



#include <ATen/ops/arccosh_ops.h>

namespace at {


// aten::arccosh(Tensor self) -> Tensor
TORCH_API inline at::Tensor arccosh(const at::Tensor & self) {
    return at::_ops::arccosh::call(self);
}

// aten::arccosh_(Tensor(a!) self) -> Tensor(a!)
TORCH_API inline at::Tensor & arccosh_(at::Tensor & self) {
    return at::_ops::arccosh_::call(self);
}

// aten::arccosh.out(Tensor self, *, Tensor(a!) out) -> Tensor(a!)
TORCH_API inline at::Tensor & arccosh_out(at::Tensor & out, const at::Tensor & self) {
    return at::_ops::arccosh_out::call(self, out);
}

// aten::arccosh.out(Tensor self, *, Tensor(a!) out) -> Tensor(a!)
TORCH_API inline at::Tensor & arccosh_outf(const at::Tensor & self, at::Tensor & out) {
    return at::_ops::arccosh_out::call(self, out);
}

}
