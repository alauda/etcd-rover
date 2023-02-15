#!/bin/bash -e

# set -x (bash debug) if log level is trace
# https://github.com/osixia/docker-light-baseimage/blob/stable/image/tool/log-helper
log-helper level eq trace && set -x

FIRST_START_DONE="${CONTAINER_STATE_DIR}/docker-keepalived-first-start-done"
# container first start
if [ ! -e "$FIRST_START_DONE" ]; then

  #
  # bootstrap config
  #
  sed -i "s|{{ KEEPALIVED_STATE }}|$KEEPALIVED_STATE|g" ${CONTAINER_SERVICE_DIR}/keepalived/assets/keepalived.conf
  sed -i "s|{{ KEEPALIVED_ROUTER_ID }}|$KEEPALIVED_ROUTER_ID|g" ${CONTAINER_SERVICE_DIR}/keepalived/assets/keepalived.conf
  sed -i "s|{{ KEEPALIVED_INTERFACE }}|$KEEPALIVED_INTERFACE|g" ${CONTAINER_SERVICE_DIR}/keepalived/assets/keepalived.conf
  sed -i "s|{{ KEEPALIVED_PRIORITY }}|$KEEPALIVED_PRIORITY|g" ${CONTAINER_SERVICE_DIR}/keepalived/assets/keepalived.conf
  sed -i "s|{{ KEEPALIVED_PASSWORD }}|$KEEPALIVED_PASSWORD|g" ${CONTAINER_SERVICE_DIR}/keepalived/assets/keepalived.conf

  if [ -n "$KEEPALIVED_NOTIFY" ]; then
    sed -i "s|{{ KEEPALIVED_NOTIFY }}|notify \"$KEEPALIVED_NOTIFY\"|g" ${CONTAINER_SERVICE_DIR}/keepalived/assets/keepalived.conf
    chmod +x $KEEPALIVED_NOTIFY
  else
    sed -i "/{{ KEEPALIVED_NOTIFY }}/d" ${CONTAINER_SERVICE_DIR}/keepalived/assets/keepalived.conf
  fi

  # unicast peers
  for peer in $(complex-bash-env iterate KEEPALIVED_UNICAST_PEERS)
  do
    sed -i "s|{{ KEEPALIVED_UNICAST_PEERS }}|${!peer}\n    {{ KEEPALIVED_UNICAST_PEERS }}|g" ${CONTAINER_SERVICE_DIR}/keepalived/assets/keepalived.conf
  done
  sed -i "/{{ KEEPALIVED_UNICAST_PEERS }}/d" ${CONTAINER_SERVICE_DIR}/keepalived/assets/keepalived.conf

  # virtual ips
  for vip in $(complex-bash-env iterate KEEPALIVED_VIRTUAL_IPS)
  do
    sed -i "s|{{ KEEPALIVED_VIRTUAL_IPS }}|${!vip}\n    {{ KEEPALIVED_VIRTUAL_IPS }}|g" ${CONTAINER_SERVICE_DIR}/keepalived/assets/keepalived.conf
  done
  sed -i "/{{ KEEPALIVED_VIRTUAL_IPS }}/d" ${CONTAINER_SERVICE_DIR}/keepalived/assets/keepalived.conf

  touch $FIRST_START_DONE
fi

# try to delete virtual ips from interface
for vip in $(complex-bash-env iterate KEEPALIVED_VIRTUAL_IPS)
do
  IP=$(echo ${!vip} | awk '{print $1}')
  IP_INFO=$(ip addr list | grep ${IP}) || continue
  IP_V6=$(echo "${IP_INFO}" | grep "inet6") || true

  # ipv4
  if [ -z "${IP_V6}" ]; then
    IP_INTERFACE=$(echo "${IP_INFO}" |  awk '{print $5}')
  # ipv6
  else
    echo "skipping address: ${IP} - ipv6 not supported yet :("
    continue
  fi

  ip addr del ${IP} dev ${IP_INTERFACE} || true
done

cp -f /etcd-rover/config/keepalived.conf /container/service/keepalived/assets/keepalived.conf
cp -f /etcd-rover/config/notify.sh /container/service/keepalived/assets/notify.sh
cp -f /etcd-rover/config/start-etcd.sh /container/service/keepalived/assets/start-etcd.sh
cp -f /etcd-rover/config/stop-etcd.sh /container/service/keepalived/assets/stop-etcd.sh
cp -f /etcd-rover/config/check-vip.sh /container/service/keepalived/assets/check-vip.sh
cp -f /etcd-rover/config/etcd.res /etc/drbd.d/etcd.res

if [ ! -e "/usr/local/etc/keepalived/keepalived.conf" ]; then
  ln -sf ${CONTAINER_SERVICE_DIR}/keepalived/assets/keepalived.conf /usr/local/etc/keepalived/keepalived.conf
fi

rm -f /run/keepalived.pid || true

set +e
echo "start create drbd res metadata"
if [ ! -f /data/drbd.touch ];then
   drbdadm create-md etcd --force > /dev/null
   drbdadm attach etcd > /dev/null
   touch /data/drbd.touch
fi
drbdadm up etcd >/dev/null
set -e

exit 0
