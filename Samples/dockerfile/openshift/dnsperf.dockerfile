FROM registry.access.redhat.com/ubi8/ubi:8.6
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/e/epel-release-8-19.el8.noarch.rpm && \
    yum install dnsperf iputils net-tools iproute bind-utils tcpdump httpd procps-ng -y
CMD sleep infinity
