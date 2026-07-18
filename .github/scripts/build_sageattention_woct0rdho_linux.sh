#!/usr/bin/env bash
set -euo pipefail

SAGE_VERSION="${SAGE_VERSION:-2.2.0.post5}"
SAGE_BRANCH="${SAGE_BRANCH:-head_dim_256}"
PYTHON_VERSION="${PYTHON_VERSION:-3.10}"
PYTORCH_VERSION="${PYTORCH_VERSION:-2.10.0}"
CUDA_VERSION="${CUDA_VERSION:-12.8}"
CUDA_VERSION_SHORT_NODOT="${CUDA_VERSION_SHORT_NODOT:-$(echo "$CUDA_VERSION" | tr -d '.')}"
CXX11_ABI="${CXX11_ABI:-0}"

# Map short CUDA version to PyTorch index URL
INDEX_URL="https://download.pytorch.org/whl/cu${CUDA_VERSION_SHORT_NODOT}"

# Clone the fork
git clone --depth 1 --branch "$SAGE_BRANCH" https://github.com/woct0rdho/SageAttention.git sageattn-src
cd sageattn-src

# Patch the package version so the produced wheel has the desired name
sed -i "s/version='2.2.0'/version='${SAGE_VERSION}'/" setup.py

# Set version suffix so we can distinguish this Linux build
export SAGEATTENTION_WHEEL_VERSION_SUFFIX="+cu${CUDA_VERSION}torch${PYTORCH_VERSION}cxx11abi${CXX11_ABI}"

# Install the exact torch from the CUDA-specific index
pip install --upgrade pip
pip install --no-cache-dir "torch==${PYTORCH_VERSION}+cu${CUDA_VERSION_SHORT_NODOT}" --index-url "$INDEX_URL"

# Install remaining build deps from PyPI
pip install --no-cache-dir numpy packaging pybind11 setuptools wheel

# Propagate CXX11 ABI and target archs
export TORCH_CUDA_ARCH_LIST="8.0 8.6 8.9 9.0+PTX"
export GLIBCXX_USE_CXX11_ABI="${CXX11_ABI}"

# Build the wheel
python setup.py bdist_wheel --verbose

# Show produced wheel
ls -lh dist/
