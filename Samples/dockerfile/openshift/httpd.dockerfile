# podman build -t quay.io/rhn_support_cchen/toolbox:v1.2 .
# podman push quay.io/rhn_support_cchen/toolbox:v1.2
# podman pull quay.io/rhn_support_cchen/toolbox:v1.2
# podman run -p 9090:80 -dt --name toolbox quay.io/rhn_support_cchen/toolbox:v1.2  /bin/bash
FROM registry.access.redhat.com/ubi8/ubi:8.5
RUN dnf install -y iputils net-tools iproute bind-utils tcpdump httpd procps-ng
RUN echo "helloworld" > /var/www/html/index.html
EXPOSE 80
ENTRYPOINT /usr/sbin/httpd -DFOREGROUND