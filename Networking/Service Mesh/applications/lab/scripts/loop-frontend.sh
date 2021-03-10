#!/bin/sh
MAX=50
COUNT=0
OK=0
TARGET_URL=$(oc get route $(oc get route -n $USERID-istio-system | grep frontend | awk '{print $1}') -n $USERID-istio-system -o yaml  -o jsonpath='{.spec.host}')
while [ $COUNT -lt $MAX ];
do
  OUTPUT=$(curl $TARGET_URL -s -w "Elapsed Time:%{time_total}")
  HOST=$(echo $OUTPUT|awk -F'Host:' '{print $2}'| awk -F',' '{print $1}')
  VERSION=$(echo $OUTPUT|awk -F'Backend version:' '{print $2}'| awk -F',' '{print $1}')
  RESPONSE=$(echo $OUTPUT|awk -F',' '{print $2}' | awk -F':' '{print $2}')
  TIME=$(echo $OUTPUT| awk -F"Elapsed Time:" '{print $2}'|awk -F'#' '{print $1}')
  echo "Backend:$VERSION, Response Code:$RESPONSE, Host:$HOST, Elapsed Time:$TIME sec"
  COUNT=$(expr $COUNT + 1)
  if [ $RESPONSE -eq 200 ];
   then
      OK=$(expr $OK + 1)
   fi
done
echo "========================================================"
echo "Total Request: $MAX"
echo "200 OK: $OK"
echo "NOT 200 OK: $(expr $MAX - $OK)"
echo "========================================================"
