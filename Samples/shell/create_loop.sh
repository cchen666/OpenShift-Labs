for i in $(seq 1 200); do
    echo "Attempt #$i"
    helm uninstall test-mychart
    echo "Sleep 200 waiting for delete"
    sleep 100
#    oc get pv | grep -q Released
#    result=$?
#    if [ $result -eq 0 ]; then
#        echo "Found Released PVs"
#        oc get pv
#        exit 1
#    fi
    helm install test-mychart .
    echo "Sleep 100 waiting for install"
    sleep 60
    # oc get pods | grep -q -i init
    # result=$?
    # if [ $result -eq 0 ]; then
    #     echo "Found INIT Pod"
    #     oc get pods
    #     exit 1
    # fi
done