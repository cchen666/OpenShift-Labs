FROM registry.access.redhat.com/ubi8/ubi:8.5
RUN dnf install -y iputils net-tools iproute procps-ng
RUN setcap cap_net_admin+ep /usr/sbin/ip
CMD sleep infinity
