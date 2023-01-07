#!/usr/bin/env bash

# Proxy signals
sp_processes=("electrum-nmc" "ncdns" "coredns")
. /signalproxy.sh

set -ex

# Overload Traps
  #none

# Configure Stuff
for CONF in ${CONFS[@]}
do
  if ! [ -f /data/"$CONF" ]; then
    echo "Copying /etc/$CONF to /data/$CONF"
    mkdir -p /data/$CONF && rmdir /data/$CONF
    cp /etc/$CONF /data/$CONF
  fi
done

electrum-nmc $FLAGS --offline setconfig rpcuser $ELECTRUM_USER && \
electrum-nmc $FLAGS --offline setconfig rpcpassword $ELECTRUM_PASSWORD && \
electrum-nmc $FLAGS --offline setconfig rpchost 0.0.0.0 && \
electrum-nmc $FLAGS --offline setconfig rpcport 8334 && \

# Run application
electrum-nmc $FLAGS daemon & \
ncdns -conf /data/ncdns/ncdns.conf & \
coredns -conf /data/coredns/corefile & \
wait -n
