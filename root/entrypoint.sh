#!/usr/bin/env bash

# Proxy signals
sp_processes=("namecoind" "namecoin-cli" "ncdns" "coredns")
. /signalproxy.sh

#set -e



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

# Run application
namecoind -conf=/data/namecoin-core/namecoin.conf >/dev/null & \
ncdns -conf /data/ncdns/ncdns.conf & \
coredns -conf /data/coredns/corefile & \
wait -n
