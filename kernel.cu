
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <iostream>

cudaError_t bitonicWithCuda(int *a, unsigned int size);

__global__ void bitonicKernel(int* a, int nodes, int sets, int core, int index, int allDown, int parentIndex)
{
	int i = threadIdx.x;
	int leftIndex = ((nodes / sets) * (i / (core / sets))) + (i % (core / sets));
	int rightIndex = leftIndex ^ (1 << (index));
	int direction = ((i / (core / (nodes / 2 / (0 ^ (1 << (parentIndex))))))) % 2;

	if (allDown == 1) {
		direction = 0;
	}

	//printf("pre %d: %d;  %d: %d;  alldown: %d; direction: %d \n", leftIndex, a[leftIndex], rightIndex, a[rightIndex], allDown, direction);

	if (a[leftIndex] > a[rightIndex] && (direction == 0)) {
		int temp = a[leftIndex];
		a[leftIndex] = a[rightIndex];
		a[rightIndex] = temp;
	}
	else if (a[leftIndex] < a[rightIndex] && (direction == 1)) {
		int temp = a[leftIndex];
		a[leftIndex] = a[rightIndex];
		a[rightIndex] = temp;
	}
	//printf("post %d: %d;  %d: %d; direction: %d \n", leftIndex, a[leftIndex], rightIndex, a[rightIndex], direction);
}
__global__ void print(int* a) {
	if (threadIdx.x == 0) {
		for (int i = 0; i < 8; i++) {
			printf("%d ", a[i]);
		}
		printf("\n");
	}
}

int main()
{
    const int arraySize = 32;
    int a[arraySize] = { 1,2,3,4,8,7,6,5,1,2,3,4,8,7,6,5,3,4,2,1,66,77,5,4,3,4,5,6,789,5,4,3 };
    int c[arraySize] = { 0 };

    // Add vectors in parallel.
    cudaError_t cudaStatus = bitonicWithCuda(a, arraySize);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addWithCuda failed!");
        return 1;
    }

	for (int i = 0; i < arraySize; i++) {
		std::cout << a[i] << " ";
	}

    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }

    return 0;
}

// Helper function for using CUDA to add vectors in parallel.
cudaError_t bitonicWithCuda(int *a, unsigned int size)
{
    int *dev_a = 0;
    int *dev_b = 0;
    int *dev_c = 0;
    cudaError_t cudaStatus;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_a, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }


    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_a, a, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    // Launch a kernel on the GPU with one thread for each pair of elements.

	//(int *a, int nodes, int sets, int core, int index, int allDown)
	int index = 0;
	int allDown = 0;
	for (int i = 0; 0 ^ (1 << (i)) < size; i++) {
		index = i;
		if (0 ^ (1 << (i)) == size) {
			allDown = 1;
		}
		while (index > -1) {
			bitonicKernel << <1, size / 2 >> > (dev_a, size, size/2/( 0 ^ (1 << (index))), size/2, index, allDown, i);
			index--;

			//print << <1, 1 >> > (dev_a);
			// Check for any errors launching the kernel
			cudaStatus = cudaGetLastError();
			if (cudaStatus != cudaSuccess) {
				fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
				goto Error;
			}

			// cudaDeviceSynchronize waits for the kernel to finish, and returns
			// any errors encountered during the launch.
			cudaStatus = cudaDeviceSynchronize();
			if (cudaStatus != cudaSuccess) {
				fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
				goto Error;
			}
			// Copy output vector from GPU buffer to host memory.
			cudaStatus = cudaMemcpy(a, dev_a, size * sizeof(int), cudaMemcpyDeviceToHost);
			if (cudaStatus != cudaSuccess) {
				fprintf(stderr, "cudaMemcpy failed!");
				goto Error;
			}
			
		}
	}





Error:
    cudaFree(dev_a);
    
    return cudaStatus;
}
