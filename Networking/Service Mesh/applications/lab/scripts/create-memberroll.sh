#!/bin/sh
# For Linux
# sed -i 's/userX/'${USERID}'/g' install/memberroll.yml
# For OSX
sed -i'.original' -e 's/userX/'${USERID}'/g' install/memberroll.yml
oc apply -f install/memberroll.yml -n ${USERID}-istio-system 
cp install/memberroll.yml.original install/memberroll.yml
