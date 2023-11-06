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



#include <ATen/ops/_make_dual_ops.h>

namespace at {


// aten::_make_dual(Tensor(a) primal, Tensor tangent, int level) -> Tensor(a)
TORCH_API inline at::Tensor _make_dual(const at::Tensor & primal, const at::Tensor & tangent, int64_t level) {
    return at::_ops::_make_dual::call(primal, tangent, level);
}

}
