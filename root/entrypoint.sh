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

# Define Healthcheck Functions
_nmc_core_is_up () {
    return 1
}
_health_namecoind () {
  echo "We are doing this shit"
  return 0
}
_health_coredns () {
  curl -s http://localhost:1053/health
}
# Run application
namecoind -conf=/data/namecoin-core/namecoin.conf >/dev/null & \
ncdns -conf /data/ncdns/ncdns.conf & \
coredns -conf /data/coredns/corefile & \
# HealthCheck
until _nmc_core_is_up
do
    sleep 15
    if namecoin-cli getblockchaininfo | grep -q '"initialblockdownload": true'; then
      echo "Namecoin-Core is still syncing with the blockchain."
    fi
    _health_namecoind
    _health_ncdns
    _health_coredns
done & \
wait -n
