FROM registry.access.redhat.com/ubi9/ubi:9.4
RUN sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm &&dnf install -y iputils net-tools iproute bind-utils traceroute tcpdump httpd procps-ng mysql openssh-clients strace
EXPOSE 80
CMD sleep infinity