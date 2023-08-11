IMAGE=/home/sno/images/agent.x86_64.iso
for i in $(seq 1 200); do
    echo "Attempt #$i"
    bash cleanup.sh 2>&1 >/dev/null
    sleep 10
    for i in 0 1 2; \
        do virt-install -n ocp-master-$i --memory 16384 \
        --os-variant=fedora-coreos-stable --vcpus=4  --accelerate  \
        --cpu host-passthrough,cache.mode=passthrough  \
        --disk path=/home/sno/images/ocp-master-$i.qcow2,size=120  \
        --network network=default,mac=02:02:00:00:00:1$i \
        --network network=default,mac=02:02:00:00:00:2$i \
        --network network=default,mac=02:02:00:00:00:3$i \
        --network network=default,mac=02:02:00:00:00:4$i \
        --network network=default,mac=02:02:00:00:00:5$i \
        --network network=default,mac=02:02:00:00:00:6$i \
        --network network=default,mac=02:02:00:00:00:7$i \
        --cdrom $IMAGE 2>&1 >/dev/null & done
    sleep 600
    for i in $(seq 1 20); do
        sleep 60
        rm -rf ~/.ssh/known_hosts
        ssh -o "StrictHostKeyChecking no" core@192.168.122.80 sudo crictl ps | grep machine-config-server
        rc=$?
        if [ $rc -eq 0 ]; then
            echo "MCS found, quitting the loop"
            break
        fi
        echo "Retrying #$i"
        if [ $i -eq 20 ]; then
            echo "No MCS Found after 1800 seconds, assuming issue reproduced"
            exit 1
        fi
    done
done