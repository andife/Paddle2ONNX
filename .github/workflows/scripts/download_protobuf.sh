#!/bin/bash

# Copyright (c) 2024 PaddlePaddle Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

# Detect the operating system
OS=$(uname -s)
ARCH=$(uname -m)

# Check if the operating system is Linux
if [ "$OS" = "Linux" ]; then
    if [[ "$ARCH" == "x86_64" ]]; then
      protobuf_tgz_name="protobuf-linux-x64-3.21.12.tgz"
      protobuf_sha256="66ff01d581ae15efb06246cd6af15387e4f806cb277e291bc667bbd37c58d8be"
    elif [[ "$ARCH" == "arm"* || "$ARCH" == "aarch64" ]]; then
      protobuf_tgz_name="protobuf-linux-aarch64-3.16.0.tgz"
      protobuf_sha256="afdd6dbc992479ef35b7d09b5b6a7fdf28143ac45fd8987600a5d88b2e21636a"
    else
        echo "When the operating system is Linux, the system architecture only supports (x86_64 and aarch64), but the current architecture is $ARCH."
        exit 1
    fi
    protobuf_url="https://bj.bcebos.com/paddle2onnx/third_party/$protobuf_tgz_name"
# Check if the operating system is Darwin (macOS)
elif [ "$OS" = "Darwin" ]; then
    if [[ "$ARCH" == "x86_64" ]]; then
      protobuf_tgz_name="protobuf-osx-x86_64-3.16.0.tgz"
      protobuf_sha256="03ae408b044f49781bb83ea8eb547995530acf38aa40998fec0a3a74a1b70eb5"
    elif [[ "$ARCH" == "arm64" ]]; then
      protobuf_tgz_name="protobuf-osx-arm64-3.16.0.tgz"
      protobuf_sha256="71b3ae3106d862198d47410256cdadab7049b0dbca3c93ea7f2201763fc010bb"
    else
      echo "When the operating system is Darwin, the system architecture only supports (x86_64 and arm64), but the current architecture is $ARCH."
      exit 1
    fi
    protobuf_url="https://bj.bcebos.com/fastdeploy/third_libs/$protobuf_tgz_name"
else
   echo "The system only supports (Linux and Darwin), but the current system is $OS."
   exit 1
fi

wget -q --https-only -O "$protobuf_tgz_name" "$protobuf_url"
printf '%s  %s\n' "$protobuf_sha256" "$protobuf_tgz_name" | shasum -a 256 --check -

if tar -tzf "$protobuf_tgz_name" | awk '$0 ~ /^\// || $0 ~ /(^|\/)\.\.(\/|$)/ { found=1 } END { exit !found }'; then
  echo "The protobuf archive contains an unsafe path."
  exit 1
fi

if tar -tvzf "$protobuf_tgz_name" | awk 'substr($1, 1, 1) !~ /[-d]/ { found=1 } END { exit !found }'; then
  echo "The protobuf archive contains an unsupported entry type."
  exit 1
fi

protobuf_save_dir="$PWD/installed_protobuf"
mkdir -p "$protobuf_save_dir"
tar --no-same-owner -zxf "$protobuf_tgz_name" -C "$protobuf_save_dir"
export PATH="$protobuf_save_dir/bin:${PATH}"
