#!/bin/sh
while [ 1 ];
do
curl -H foo:bar ${GATEWAY_URL};echo ""
done
