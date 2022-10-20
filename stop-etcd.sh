echo "stop etcd process"
pid=$(ps -ef | grep etcd | grep "/data/etcd " | grep -v grep | awk '{print $2}')
if [ -n "$pid" ]; then
  kill "$pid"
fi
## sleep 3s prevent etcd was not killed completely
sleep 3
echo "set drbd volume secondary"
umount /data/etcd
drbdadm secondary etcd