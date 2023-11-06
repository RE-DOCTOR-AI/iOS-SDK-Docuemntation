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



#include <ATen/ops/histc_ops.h>

namespace at {


// aten::histc.out(Tensor self, int bins=100, Scalar min=0, Scalar max=0, *, Tensor(a!) out) -> Tensor(a!)
TORCH_API inline at::Tensor & histc_out(at::Tensor & out, const at::Tensor & self, int64_t bins=100, const at::Scalar & min=0, const at::Scalar & max=0) {
    return at::_ops::histc_out::call(self, bins, min, max, out);
}

// aten::histc.out(Tensor self, int bins=100, Scalar min=0, Scalar max=0, *, Tensor(a!) out) -> Tensor(a!)
TORCH_API inline at::Tensor & histc_outf(const at::Tensor & self, int64_t bins, const at::Scalar & min, const at::Scalar & max, at::Tensor & out) {
    return at::_ops::histc_out::call(self, bins, min, max, out);
}

// aten::histc(Tensor self, int bins=100, Scalar min=0, Scalar max=0) -> Tensor
TORCH_API inline at::Tensor histc(const at::Tensor & self, int64_t bins=100, const at::Scalar & min=0, const at::Scalar & max=0) {
    return at::_ops::histc::call(self, bins, min, max);
}

}
