#!/usr/bin/env bash

# Proxy signals
sp_processes=("electrum-nmc" "ncdns" "coredns")
. /signalproxy.sh

set -ex

# Overload Traps
  #none

# Configure Stuff
electrum-nmc $FLAGS --offline setconfig rpcuser ${ELECTRUM_USER}
electrum-nmc $FLAGS --offline setconfig rpcpassword ${ELECTRUM_PASSWORD}
electrum-nmc $FLAGS --offline setconfig rpchost 0.0.0.0
electrum-nmc $FLAGS --offline setconfig rpcport 7000

# Run application
electrum-nmc $FLAGS daemon & \
ncdns -conf /data/ncdns/ncdns.conf & \
coredns -conf /data/coredns/corefile & \
wait -n
