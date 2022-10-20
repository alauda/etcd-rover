#!/bin/bash

case $3 in
MASTER)

  ## 1. set drbd volume primary and check status until drbd volume is ok and then
  ## 2. mount drbd volume to etcd data path
  ## 3. start etcd process
  ## primary drbd volume
  echo "keeplived switch to master"
  echo "start set drbd volume to primary"

  echo "start etcd process"
  flock -xo /etc/keepalived/etcd.lock -c /etc/keepalived/start-etcd.sh
  exit 0
  ;;
BACKUP)
  ## 1. stop etcd process
  ## 2. unmount drbd volume
  ## 3. set drbd volume secondary
  echo "keeplived switch to backup"
  flock -xo /etc/keepalived/etcd.lock -c /etc/keepalived/stop-etcd.sh
  exit 0
  ;;
FAULT)
  ## 1. stop etcd process
  ## 2. unmount drbd volume
  ## 3. set drbd volume secondary
  flock -xo /etc/keepalived/etcd.lock -c /etc/keepalived/stop-etcd.sh
  exit 0
  ;;
*)
  echo "Usage: $(basename $0) {master|backup|fault}"
  exit
  ;;
esac
