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



#include <ATen/ops/result_type_ops.h>

namespace at {


// aten::result_type.Tensor(Tensor tensor, Tensor other) -> ScalarType
TORCH_API inline at::ScalarType result_type(const at::Tensor & tensor, const at::Tensor & other) {
    return at::_ops::result_type_Tensor::call(tensor, other);
}

// aten::result_type.Scalar(Tensor tensor, Scalar other) -> ScalarType
TORCH_API inline at::ScalarType result_type(const at::Tensor & tensor, const at::Scalar & other) {
    return at::_ops::result_type_Scalar::call(tensor, other);
}

// aten::result_type.Scalar_Tensor(Scalar scalar, Tensor tensor) -> ScalarType
TORCH_API inline at::ScalarType result_type(const at::Scalar & scalar, const at::Tensor & tensor) {
    return at::_ops::result_type_Scalar_Tensor::call(scalar, tensor);
}

// aten::result_type.Scalar_Scalar(Scalar scalar1, Scalar scalar2) -> ScalarType
TORCH_API inline at::ScalarType result_type(const at::Scalar & scalar1, const at::Scalar & scalar2) {
    return at::_ops::result_type_Scalar_Scalar::call(scalar1, scalar2);
}

}
