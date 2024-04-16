# Copyright (c) 2023 The TQUIC Authors.
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

# QUIC docker image for interoperability testing.
# See: https://github.com/marten-seemann/quic-interop-runner

FROM ubuntu:23.04 as build

WORKDIR /build

COPY . ./

RUN apt-get update && apt install apt-transport-https curl gnupg -y && \
    curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor >bazel-archive-keyring.gpg && \
    mv bazel-archive-keyring.gpg /usr/share/keyrings && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list && \
    apt update && \
    apt install bazel-6.2.1 -y && \
    rm -rf /var/lib/apt/lists/*

RUN /usr/bin/bazel-6.2.1 build //quiche:quic_server //quiche:quic_client


FROM tquicgroup/quic-network-simulator-endpoint:latest as tquic-interop

WORKDIR /quiche

COPY --from=build \
     /build/bazel-bin/quiche/quic_server \
     /build/bazel-bin/quiche/quic_client \
     /build/run_endpoint.sh \
     ./

RUN chmod u+x ./run_endpoint.sh

ENTRYPOINT [ "./run_endpoint.sh" ]
