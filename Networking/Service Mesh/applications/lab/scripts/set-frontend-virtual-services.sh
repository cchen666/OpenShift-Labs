#!/bin/bash
platform=$(uname)
SUBDOMAIN=$(oc whoami --show-console | awk -F'.apps.' '{print $2}')
CONTROL_PLANE=$USERID-istio-system
DATA_PLANE=$USERID
if [ "$platform" = 'Darwin' ];
then
  sed -i '.org' -e 's/SUBDOMAIN/'$SUBDOMAIN'/' istio-files/wildcard-gateway.yml
  sed -i '.org' -e 's/SUBDOMAIN/'$SUBDOMAIN'/' istio-files/virtual-service-frontend-*.yml
  sed -i '.org' -e 's/CONTROL_PLANE/'$CONTROL_PLANE'/' istio-files/virtual-service-frontend-*.yml
  sed -i '.org' -e 's/DATA_PLANE/'$DATA_PLANE'/' istio-files/virtual-service-frontend*.yml
else
  sed -i  's/SUBDOMAIN/'$SUBDOMAIN'/' istio-files/wildcard-gateway.yml
  sed -i  's/SUBDOMAIN/'$SUBDOMAIN'/' istio-files/virtual-service-frontend-*.yml
  sed -i  's/CONTROL_PLANE/'$CONTROL_PLANE'/' istio-files/virtual-service-frontend-*.yml
  sed -i  's/DATA_PLANE/'$DATA_PLANE'/' istio-files/virtual-service-frontend-*.yml
fi
