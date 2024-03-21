FROM registry.access.redhat.com/ubi8/ubi:8.6
RUN dnf install -y iputils net-tools iproute bind-utils tcpdump httpd procps-ng mysql openssh-clients NetworkManager
EXPOSE 80
CMD sleep infinity