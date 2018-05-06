/**
 * @brief Implementation file for matrix broadcasting
 * 
 * @file matrix_broadcast.cu
 * @author David Chan
 * @date 2018-04-04
 * Copyright (c) 2018, Regents of the University of California
 */

#include "include/util/matrix_broadcast_utils.h"

// Performs the operation matrix[i, :] = binary_op(matrix[i, :],
// alpha * vector) for each row i in the matrix
template<typename BinaryFunction, typename T>
__global__ void tsnecuda::util::BroadcastRowVector(
        T * __restrict__ d_matrix,
        const T * __restrict__ d_vector,
        const uint32_t N,
        const uint32_t M,
        BinaryFunction binary_operation,
        const T alpha) {
    const uint32_t TID = threadIdx.x + blockIdx.x * blockDim.x;
    const uint32_t i = TID % N;
    const uint32_t j = TID / N;
    if (j < M) d_matrix[j * N + i] = binary_operation(d_matrix[j * N + i],
                                            alpha * d_vector[j]);
}

// Performs the operation matrix[:, j] = binary_op(matrix[:, j],
// alpha * vector) for each col i in the matrix
template<typename BinaryFunction, typename T>
__global__ void tsnecuda::util::BroadcastColumnVector(
        T * __restrict__ d_matrix,
        const T * __restrict__ d_vector,
        const uint32_t N,
        const uint32_t M,
        BinaryFunction binary_operation,
        const T alpha) {
     const uint32_t TID = threadIdx.x + blockIdx.x * blockDim.x;
     const uint32_t i = TID % N;
     const uint32_t j = TID / N;

     if (j < M) d_matrix[j * N + i] = binary_operation(d_matrix[j * N + i],
                                            alpha * d_vector[i]);
}

template<typename BinaryFunction, typename T>
void tsnecuda::util::BroadcastMatrixVector(
        thrust::device_vector<T> &d_matrix,
        const thrust::device_vector<T> &d_vector,
        const uint32_t N,
        const uint32_t M,
        BinaryFunction binary_operation,
        const uint32_t axis,
        const T alpha) {
    // Checks to make sure dimensions are correct
    assert(d_matrix.size() >= N * M);
    assert((axis == 0 && d_vector.size() >= N) ||
            (axis == 1 && d_vector.size() >= M));

    const uint32_t kBlockSize = 32;
    const uint32_t kNumBlocks = iDivUp(N * M, kBlockSize);
    if (axis == 0) {
    tsnecuda::util::BroadcastColumnVector<<<kNumBlocks, kBlockSize>>>(
            thrust::raw_pointer_cast(d_matrix.data()),
            thrust::raw_pointer_cast(d_vector.data()),
            N, M, binary_operation, alpha);
    } else {
    tsnecuda::util::BroadcastRowVector<<<kNumBlocks, kBlockSize>>>(
            thrust::raw_pointer_cast(d_matrix.data()),
            thrust::raw_pointer_cast(d_vector.data()),
            N, M, binary_operation, alpha);
    }
}


// Explicit instantiations of the method
template void tsnecuda::util::BroadcastMatrixVector<thrust::divides<float>, float>(
        thrust::device_vector<float> &d_matrix,
        const thrust::device_vector<float> &d_vector,
        const uint32_t N,
        const uint32_t M,
        thrust::divides<float> binary_operation,
        const uint32_t axis,
        const float alpha);
template void tsnecuda::util::BroadcastMatrixVector<thrust::minus<float>, float>(
        thrust::device_vector<float> &d_matrix,
        const thrust::device_vector<float> &d_vector,
        const uint32_t N,
        const uint32_t M,
        thrust::minus<float> binary_operation,
        const uint32_t axis,
        const float alpha);
