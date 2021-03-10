#!/bin/sh
COUNT=0
MAX=50
VERSION1=0
VERSION2=0
TARGET_URL=$FRONTEND_URL
#TARGET_URL=$GATEWAY_URL
while [ $COUNT -lt $MAX ];
do
  OUTPUT=$(curl $TARGET_URL -s -w "Elapsed Time:%{time_total}")
  HOST=$(echo $OUTPUT|awk -F'Host:' '{print $2}'| awk -F',' '{print $1}')
  VERSION=$(echo $OUTPUT|awk -F'Backend version:' '{print $2}'| awk -F',' '{print $1}')
  RESPONSE=$(echo $OUTPUT|awk -F',' '{print $2}' | awk -F':' '{print $2}')
  TIME=$(echo $OUTPUT| awk -F"Elapsed Time:" '{print $2}'|awk -F'#' '{print $1}')
  echo "Backend:$VERSION, Response Code:$RESPONSE, Host:$HOST, Elapsed Time:$TIME sec"
  COUNT=$(expr $COUNT + 1)
  if [$RESPONSE -eq 200 ];
   then
      if [ $VERSION == "v1" ];
       then
         VERSION1=$(expr $VERSION1 + 1)
       fi
      if [ $VERSION == "v2" ];
       then
         VERSION2=$(expr $VERSION2 + 1)
       fi
   fi
done
echo "========================================================"
echo "Total Request: $MAX"
echo "Version v1: $VERSION1"
echo "Version v2: $VERSION2"
echo "========================================================"
