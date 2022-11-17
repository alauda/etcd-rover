FROM build-harbor.alauda.cn/3rdparty/coreos/etcd:v3.4.14 as etcd

FROM osixia/keepalived:2.0.20
COPY --from=etcd /usr/local/bin/etcd /usr/local/bin/etcd
COPY ./service/keepalived/ /container/service/keepalived/
RUN apk update && apk add drbd-utils util-linux e2fsprogs





