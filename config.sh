#!/bin/sh

## process param

helpFunction() {
  echo "Usage: $0 start"
  echo -e "\t--gateway the gateway address"
  echo -e "\t--vip the keepalived virtual ip"
  echo -e "\t--net the network that vip bind"
  echo -e "\t--nip1 the node1 ip"
  echo -e "\t--nip2 the node2 ip"
  echo -e "\t--d1 the node1 disk"
  echo -e "\t--d2 the node2 disk"
  echo -e "\t--n1 the node1 hostname"
  echo -e "\t--n2 the node2 hostname"
  exit 1 # Exit script after printing help
}

pa=$(echo "$@" | grep start)
if [ -z "$pa" ]; then
  helpFunction
fi

ARGS=$(getopt -l gateway:,vip:,net:,nip1:,nip2:,d1:,d2:,n1:,n2:,help -- "$@")

[ $? -ne 0 ] && helpFunction
#set -- "${ARGS}"
eval set -- "${ARGS}"
while true; do
  case "$1" in
  --gateway)
    GATEWAY="$2"
    shift
    ;;
  --vip)
    VIP="$2"
    shift
    ;;
  --net)
    NET="$2"
    shift
    ;;
  --nip1)
    DRBD_IP1="$2"
    shift
    ;;
  --nip2)
    DRBD_IP2="$2"
    shift
    ;;
  --d1)
    DRBD_DISK1="$2"
    shift
    ;;
  --d2)
    DRBD_DISK2="$2"
    shift
    ;;
  --n1)
    DRBD_HOST1_NAME="$2"
    shift
    ;;
  --n2)
    DRBD_HOST2_NAME="$2"
    shift
    ;;
  --help) helpFunction ;;
  --)
    shift
    break
    ;;
  esac
  shift
done
# Print helpFunction in case parameters are empty
if [ -z "$GATEWAY" ] || [ -z "$VIP" ] || [ -z "$NET" ] || [ -z "$DRBD_IP1" ] || [ -z "$DRBD_IP2" ] || [ -z "$DRBD_DISK1" ] || [ -z "$DRBD_DISK2" ] ||
  [ -z "$DRBD_HOST1_NAME" ] || [ -z "$DRBD_HOST2_NAME" ]; then
  echo "Some or all of the parameters are empty"
  helpFunction
fi

echo "gaateway is $GATEWAY"
echo "vip is $VIP "
echo "net is $NET "
echo "drbd host1 name is $DRBD_HOST1_NAME"
echo "drbd ip1 is $DRBD_IP1"
echo "drbd disk1 name is $DRBD_DISK1"
echo "drbd host2 name is $DRBD_HOST2_NAME"
echo "drbd ip2 is $DRBD_IP2"
echo "drbd disk2 name is $DRBD_DISK2"

echo "start config drbd"
sed -e "s/host1-need-config/$DRBD_HOST1_NAME/g" -e "s/host2-need-config/$DRBD_HOST2_NAME/g" \
  -e "s/ip1-need-config/$DRBD_IP1/g" -e "s/ip2-need-config/$DRBD_IP2/g" \
  -e "s%disk1-need-config%$DRBD_DISK1%g" -e "s%disk2-need-config%$DRBD_DISK2%g" /etcd-rover/template/etcd-drbd-template.res >/etcd-rover/config/etcd.res

echo "no" | drbdadm create-md etcd

if drbdadm up etcd >/dev/null; then
  echo "up drbd res etcd successful"
else
  echo "drbd up existing"
fi

echo "config etcd process"

sed -e "s%ip1-need-config%$DRBD_IP1%g" -e "s%ip2-need-config%$DRBD_IP2%g" \
  -e "s%vip-need-config%$VIP%g" /etcd-rover/template/start-etcd-template.sh >/etcd-rover/config/start-etcd.sh

echo "config keepalived"
sed -e "s/vip_need_config/$VIP/g" -e "s/dev_need_config/$NET/g" /etcd-rover/template/keepalived-template.conf >/etcd-rover/config/keepalived.conf
sed -e "s/vip_need_config/$VIP/g" -e "s/gateway_need_config/$GATEWAY/g" /etcd-rover/template/check-vip-template.conf > /etcd-rover/config/check-vip.sh
cp /etcd-rover/template/notify.sh  /etcd-rover/config/notify.sh
cp /etcd-rover/template/stop-etcd.sh /etcd-rover/config/stop-etcd.sh
chmod +x /etcd-rover/config/notify.sh /etcd-rover/config/stop-etcd.sh /etcd-rover/config/check-vip.sh /etcd-rover/config/start-etcd.sh