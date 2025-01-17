FROM registry.access.redhat.com/ubi9/ubi:9.2
RUN dnf install -y python3 iputils net-tools iproute bind-utils tcpdump httpd procps-ng mysql openssh-clients NetworkManager
EXPOSE 80
CMD sleep infinity