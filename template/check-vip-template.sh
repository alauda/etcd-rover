
echo "start check gateway and drbd status"
while true; do
  ## if gaateway can not access we should stop keepalived && etcd and set drbd secondary prevent brain split
  if ! arping -I vip_need_config -c 5 gateway_need_config >/dev/null; then
    echo "gateway can not access"
    echo "stop keepalived"
    kill $PPID
  else
    ##if the drbd res is primary and standalone, try connect peer
    pst=$(drbdadm status etcd | grep "etcd role" | grep Primary)
    sst=$(drbdadm status etcd | grep "etcd role" | grep Secondary)
    cst=$(drbdadm status etcd | grep StandAlone)
    peer=$(drbdadm status etcd | grep peer-disk | grep UpToDate)
    if [ -n "$pst" ] && [ -n "$cst" ]; then
      echo "drbd primary connect peer"
      drbdadm connect etcd
    fi
    ##if the drbd res is secondary and standalone, try connect peer with discard data
    if [ -n "$sst" ] && [ -n "$cst" ]; then
      echo "drbd secondary connect peer"
      drbdadm connect etcd --discard-my-data
    fi
    ## check etcd process if drbd status is health we should start etcd process
    if [ -n "$pst" ] && [ -n "$peer" ]; then
      pid=$(ps -ef | grep etcd | grep "/data/etcd " | grep -v grep | awk '{print $2}')
      if [ -z "$pid" ]; then
        echo "should start etcd process"
        flock -xo /usr/local/etc/keepalived/etcd.lock -c /container/service/keepalived/assets/start-etcd.sh
      fi
    fi
  fi
done