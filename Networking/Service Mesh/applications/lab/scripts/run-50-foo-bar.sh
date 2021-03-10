#!/bin/sh
COUNT=0
MAX=50
VERSION1=0
VERSION2=0
#TARGET_URL=$FRONTEND_URL
TARGET_URL=$GATEWAY_URL
while [ $COUNT -lt $MAX ];
do
  EVEN=$(expr $COUNT % 2) 
  if [ $EVEN -eq 0 ];
  then
    OUTPUT=$(curl -s -H 'User-Agent: foo-bar'  $TARGET_URL )
  else
    OUTPUT=$(curl -s $TARGET_URL)
  fi
  VERSION=$(echo $OUTPUT|awk -F'=>' '{print $1}')
  echo $VERSION
  COUNT=$(expr $COUNT + 1)
done
