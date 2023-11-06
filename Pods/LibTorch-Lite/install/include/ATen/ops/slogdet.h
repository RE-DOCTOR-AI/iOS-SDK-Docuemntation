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



#include <ATen/ops/slogdet_ops.h>

namespace at {


// aten::slogdet(Tensor self) -> (Tensor sign, Tensor logabsdet)
TORCH_API inline ::std::tuple<at::Tensor,at::Tensor> slogdet(const at::Tensor & self) {
    return at::_ops::slogdet::call(self);
}

}
