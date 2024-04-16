#!/bin/bash

# Copyright (c) 2024 Sijie Yang.
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

set -e
set -x

# Set up the routing needed for the simulation.
/setup.sh

case "$TESTCASE" in
http3)
    ;;
chacha20)
    if [ "$ROLE" == "client" ]; then
        exit 127
    fi
    ;;
handshake|multiconnect|resumption|retry|transfer|zerortt|keyupdate|ecn|v2)
    exit 127
    ;;
*)
    exit 127
    ;;
esac

QUICHE_DIR="/quiche"
QUICHE_CLIENT="quic_client"
QUICHE_SERVER="quic_server"
ROOT_DIR="/www"
DOWNLOAD_DIR="/downloads"
LOG_DIR="/logs"
QLOG_DIR="/logs/qlog"

CC_ALGOR="CUBIC"
case ${CONGESTION^^} in
BBR)
    CC_ALGOR="BBR"
    ;;
BBR3)
    CC_ALGOR="BBR3"
    ;;
COPA)
    CC_ALGOR="COPA"
    ;;
*)
    ;;
esac

COMMON_ARGS="--keylog-file $SSLKEYLOGFILE --log-level DEBUG --log-file $LOG_DIR/$ROLE.log --congestion-control-algor $CC_ALGOR"

if [ "$ROLE" == "client" ]; then
    # Wait for the simulator to start up.
    /wait-for-it.sh sim:57832 -s -t 30

    REQS=($REQUESTS)

    CLIENT_ARGS="$COMMON_ARGS --dump-dir ${DOWNLOAD_DIR} --max-concurrent-requests ${#REQS[@]}"

elif [ "$ROLE" == "server" ]; then
    SERVER_ARGS="$COMMON_ARGS --certificate_file /certs/cert.pem --key_file /certs/priv.key --port 443 --quic_response_cache_dir $ROOT_DIR --quic_response_cache_format raw --stderrthreshold 0"

    $QUICHE_DIR/$QUICHE_SERVER $SERVER_ARGS
fi
