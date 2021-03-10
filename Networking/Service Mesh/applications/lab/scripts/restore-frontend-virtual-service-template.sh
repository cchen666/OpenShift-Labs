#!/bin/bash
cp istio-files/virtual-service-frontend.bak virtual-service-frontend.yml 
cp istio-files/virtual-service-frontend-fault-inject.bak virtual-service-frontend-fault-inject.yml 
cp istio-files/virtual-service-frontend-header-foo-bar-to-v1.bak virtual-service-frontend-header-foo-bar-to-v1.yml
cp istio-files/virtual-service-frontend-with-gateway.bak virtual-service-frontend-with-gateway.yml
cp istio-files/wildcard-gateway.bak istio-files/wildcard-gateway.yml

