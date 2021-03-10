#!/bin/sh
while [ 1 ];
do
curl -w"\n" ${FRONTEND_URL}
done
