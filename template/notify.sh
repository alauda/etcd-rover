#!/bin/bash

TYPE=$1
NAME=$2
STATE=$3

case $STATE in
    "MASTER")
        echo "I'm the MASTER! Whup whup." > /proc/1/fd/1
        echo "start etcd process" >  /proc/1/fd/1
        flock -xo /usr/local/etc/keepalived/etcd.lock -c /container/service/keepalived/assets/start-etcd.sh > /proc/1/fd/1
        echo "start etcd process end" >  /proc/1/fd/1
        exit 0
    ;;
    "BACKUP")
        echo "Ok, i'm just a backup, great." > /proc/1/fd/1
        echo "stop etcd process" >  /proc/1/fd/1
        flock -xo /usr/local/etc/keepalived/etcd.lock -c /container/service/keepalived/assets/stop-etcd.sh > /proc/1/fd/1
        exit 0
    ;;
    "FAULT")
        echo "Fault, what ?" > /proc/1/fd/1
        echo "stop etcd process" >  /proc/1/fd/1
        flock -xo /usr/local/etc/keepalived/etcd.lock -c /container/service/keepalived/assets/stop-etcd.sh > /proc/1/fd/1
        exit 0
    ;;
    *)  echo "Unknown state" > /proc/1/fd/1
        exit 1
    ;;
esac