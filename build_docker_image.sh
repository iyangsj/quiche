#!/bin/bash

set -e
set -x

bazel build //quiche:quic_client //quiche:quic_server --local_cpu_resources=3

rm ./interop/quic_client ./interop/quic_server -f
cp ./bazel-bin/quiche/quic_client ./interop
cp ./bazel-bin/quiche/quic_server ./interop

docker build -t tquicgroup/qirgq -f interop/Dockerfile .
