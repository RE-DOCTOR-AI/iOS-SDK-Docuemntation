#pragma once

// @generated by torchgen/gen.py from NativeMetaFunction.h

#include <c10/core/Scalar.h>
#include <c10/core/Storage.h>
#include <c10/core/TensorOptions.h>
#include <c10/util/Deprecated.h>
#include <c10/util/Optional.h>
#include <c10/core/QScheme.h>
#include <ATen/core/Reduction.h>
#include <ATen/TensorIterator.h>
#include <ATen/TensorMeta.h>
#include <tuple>
#include <vector>

namespace at {
namespace meta {

struct TORCH_API structured_linalg_cross : public at::impl::MetaBase {
    
                template <bool DIM = false>
                struct TORCH_API precompute_out {
                    
                    precompute_out<true> set_dim(int64_t value) {
                        static_assert(DIM == false, "dim already set");
                        precompute_out<true> ret;
ret.dim = value;
return ret;
                    }
                
                    int64_t dim;
            };
    using meta_return_ty = precompute_out <true>;
    meta_return_ty meta(const at::Tensor & self, const at::Tensor & other, int64_t dim);
};

} // namespace native
} // namespace at
