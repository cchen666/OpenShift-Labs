FROM registry.access.redhat.com/ubi8/ubi:8.6
COPY 002-dpdk-log.patch /
COPY build-dpdk.sh /build-dpdk.sh
RUN /bin/bash -x /build-dpdk.sh

FROM registry.access.redhat.com/ubi8/ubi:8.6
RUN yum install -y iputils iproute ethtool tcpdump nc procps-ng dpdk
COPY --from=0 /dpdk-21.11/build/examples/dpdk-ethtool /dpdk-ethtool
COPY --from=0 /dpdk-21.11/build/app/dpdk-testpmd /dpdk-testpmd
COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]