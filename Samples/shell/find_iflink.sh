while true; do
    chroot /host oc get pods | grep sctpserver | grep Running -q
    if [[ $? == 0 ]]; then
    break
    else
    sleep 1
    fi
done
echo "sctpserver is running now"
chroot /host oc logs -f sctpserver | while read LOGLINE;
do
  if [[ "$LOGLINE" == iflink* ]];
      then iflink=`echo $LOGLINE | awk '{print $2}'`;
      veth=`ip addr 2>/dev/null | grep ^$iflink | awk -F: '{print $2}' | awk -F@ '{print $1}'`
      tcpdump -i $veth
  fi
done