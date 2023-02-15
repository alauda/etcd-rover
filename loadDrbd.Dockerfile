FROM quay.io/piraeusdatastore/drbd9-centos7:v9.2.0 as tool
COPY ./drbd-entry.sh /entry.sh
RUN chmod +x  /entry.sh