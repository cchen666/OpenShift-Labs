oc apply -f deploy.yaml

for i in $(seq 1 200); do
    echo "Attempt #$i"
    oc delete pod mysql-0 &
    sleep 2
    oc delete pod mysql-0 --force
    sleep 5

    oc delete pod mysql-0 &
    sleep 2
    oc delete pod mysql-0 --force
    sleep 200

    num=`sudo crictl pods | grep mysql-0 | wc -l`
    if [ $num != 1 ]; then
        sleep 400
        if [ $num != 1 ]; then
            echo "Issue Reproduced at attemp $i" >> log.txt
            sudo crictl pods >> log.txt
            break
        fi
    fi
done