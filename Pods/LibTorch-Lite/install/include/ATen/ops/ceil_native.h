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
#include <ATen/ops/ceil_meta.h>

namespace at {
namespace native {

TORCH_API at::Tensor ceil(const at::Tensor & self);
TORCH_API at::Tensor & ceil_(at::Tensor & self);
struct TORCH_API structured_ceil_out : public at::meta::structured_ceil {
void impl(const at::Tensor & self, const at::Tensor & out);
};
TORCH_API at::Tensor ceil_sparse(const at::Tensor & self);
TORCH_API at::Tensor & ceil_sparse_out(const at::Tensor & self, at::Tensor & out);
TORCH_API at::Tensor & ceil_sparse_(at::Tensor & self);
TORCH_API at::Tensor ceil_sparse_csr(const at::Tensor & self);
TORCH_API at::Tensor & ceil_sparse_csr_out(const at::Tensor & self, at::Tensor & out);
TORCH_API at::Tensor & ceil_sparse_csr_(at::Tensor & self);

} // namespace native
} // namespace at
