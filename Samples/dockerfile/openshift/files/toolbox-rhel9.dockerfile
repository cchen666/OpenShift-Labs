FROM registry.access.redhat.com/ubi8/ubi:9.2
RUN dnf install -y iputils net-tools iproute bind-utils tcpdump httpd procps-ng mysql openssh-clients strace systemd
EXPOSE 80
CMD sleep infinity