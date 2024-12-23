FROM quay.io/rhn_support_cchen/toolbox:v1.3
RUN dnf install -y trace-cmd
CMD sleep infinity