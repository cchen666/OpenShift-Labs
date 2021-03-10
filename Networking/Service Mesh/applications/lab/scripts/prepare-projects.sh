#!/bin/bash
INDEX=1
MAX=20
while [ $INDEX -lt $MAX ];
do
  oc new-project user$INDEX
  oc new-project user$INDEX-istio-system
  oc new-project user$INDEX-load-test
  oc adm policy add-role-to-user admin user$INDEX -n user$INDEX
  oc adm policy add-role-to-user admin user$INDEX -n user$INDEX-istio-system
  oc adm policy add-role-to-user admin user$INDEX -n user$INDEX-load-test
  INDEX=$(expr $INDEX + 1)
done 
