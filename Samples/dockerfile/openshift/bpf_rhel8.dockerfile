FROM registry.access.redhat.com/ubi8/ubi:8.6
RUN dnf install -y iputils net-tools iproute bind-utils tcpdump httpd procps-ng bcc python36 kmod && yum install -y https://debuginfo.centos.org/8/x86_64/kernel-debuginfo-common-x86_64-$4.18.0-372.40.1.el8_6.x86_64.rpm && \
    yum install -y https://debuginfo.centos.org/8/x86_64/kernel-debuginfo-4.18.0-372.40.1.el8_6.x86_64.rpm
COPY tcptop.py .
ENTRYPOINT python3 tcptop.py --cgroupmap /sys/fs/bpf/test01