FROM registry.redhat.io/rhel9/support-tools
RUN  yum install --enablerepo=rhel-9-for-x86_64-baseos-rpms \
                 --enablerepo=rhel-9-for-x86_64-appstream-rpms \
                 --enablerepo=rhel-9-for-x86_64-baseos-debug-rpms \
                 systemtap gcc kernel-devel-5.14.0-284.64.1.el9_2.x86_64 \
                 kernel-core-5.14.0-284.64.1.el9_2.x86_64 \
                 kernel-headers-5.14.0-284.64.1.el9_2.x86_64 \
                 kernel-debuginfo-5.14.0-284.64.1.el9_2.x86_64 -y \
                 && yum clean all