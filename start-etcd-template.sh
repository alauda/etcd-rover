setDrbd="failed"
while [ $setDrbd == "failed" ]; do
  if drbdadm primary etcd >/dev/null; then
    setDrbd="success"
  else
    echo "wait for peer set secondary"
  fi
  sleep 1
done

fs=$(blkid /dev/drbd0 | grep ext4)
if [ -z "$fs" ]; then
  mkfs.ext4 /dev/drbd0
fi

mp=$(mountpoint /data/etcd/ | grep not)
if [ -n "$mp" ]; then
  mount /dev/drbd0 /data/etcd/
fi

pid=$(ps -ef | grep etcd | grep "/data/etcd " | grep -v grep | awk '{print $2}')
if [ -z "$pid" ]; then
  etcd --name infra3 --data-dir /data/etcd --listen-client-urls http://vip-need-config:22379 --advertise-client-urls http://vip-need-config:22379 --listen-peer-urls http://vip-need-config:22380 --initial-advertise-peer-urls http://vip-need-config:22380 --initial-cluster-token etcd-cluster-1 --initial-cluster 'infra1=http://ip1-need-config:12380,infra2=http://ip2-need-config:12380,infra3=http://vip-need-config:22380' --initial-cluster-state new &
fi