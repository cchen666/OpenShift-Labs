yum install gcc python39 xz patch -y
pip3 install pyelftools meson ninja

cd /
curl -o dpdk.tar.xz https://fast.dpdk.org/rel/dpdk-21.11.tar.xz
tar -xf dpdk.tar.xz
cd dpdk-21.11
cp /002-dpdk-log.patch .
patch --ignore-whitespace -p0 drivers/net/iavf/iavf_rxtx_vec_avx2.c 002-dpdk-log.patch

meson -Dplatform=generic build
cd build
meson configure -Dexamples=ethtool
ninja