FROM build-harbor.alauda.cn/ops/busybox:stable
COPY ./template /etcd-rover/template/
COPY ./config.sh /config.sh
RUN chmod +x /config.sh
ENTRYPOINT ["/config.sh"]