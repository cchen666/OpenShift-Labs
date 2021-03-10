# $1: version

VERSION=$1
WORKDIR=/Users/cchen/Code/ocp_install/openstack
ARCH=mac

source ~/.config/openstack/sbr-shift-psi-lab-openrc.sh

CLUSTER_ID=gcg-shift
CLUSTER_DOMAIN=cchen.work
openstack floating ip create --description  "api.$CLUSTER_ID.$CLUSTER_DOMAIN" shared_net_3 # API floating IP
openstack floating ip create --description "apps.$CLUSTER_ID.$CLUSTER_DOMAIN" shared_net_3 # Ingress floating IP

apiIP=`openstack floating ip list --long | grep "api.$CLUSTER_ID.$CLUSTER_DOMAIN" | awk '{print $4}'`
ingressIP=`openstack floating ip list --long | grep "apps.$CLUSTER_ID.$CLUSTER_DOMAIN" | awk '{print $4}'`

mkdir $WORKDIR/$VERSION

cd $WORKDIR/$VERSION

cat > install-config.yaml <<EOF
apiVersion: v1
baseDomain: $CLUSTER_DOMAIN
compute:
- hyperthreading: Enabled
  name: worker
  platform:
    openstack:
      type: g.standard.xl
  replicas: 3
controlPlane:
  hyperthreading: Enabled
  name: master
  platform:
    openstack:
      type: g.standard.xl
  replicas: 3
compute:
- name: worker
  platform:
    openstack:
      type: g.standard.xl
  replicas: 2
metadata:
  creationTimestamp: null
  name: $CLUSTER_ID
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineCIDR: 192.168.0.0/16
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
platform:
  openstack:
    cloud: openstack
    apiFloatingIP: $apiIP
    ingressFloatingIP: $ingressIP
    externalNetwork: shared_net_3
pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K3JobnN1cHBvcnRjY2hlbjF0ZHZiNmJzYTZ2OXp6cXF3aGRyYnFxc2drYTpGVUgzVEpRTjZXTURSSzVHVFNISjBJQVQ5WTNHRzA4VjJDRkFDMVY4VlcwUVBERVBLUExHWFIzMzA1RjNYRkVY","email":"cchen@redhat.com"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K3JobnN1cHBvcnRjY2hlbjF0ZHZiNmJzYTZ2OXp6cXF3aGRyYnFxc2drYTpGVUgzVEpRTjZXTURSSzVHVFNISjBJQVQ5WTNHRzA4VjJDRkFDMVY4VlcwUVBERVBLUExHWFIzMzA1RjNYRkVY","email":"cchen@redhat.com"},"registry.connect.redhat.com":{"auth":"NTk0NDQ2Mnx1aGMtMVRkdkI2QnNBNlY5WnpRcVdIRHJCUXFTR2thOmV5SmhiR2NpT2lKU1V6VXhNaUo5LmV5SnpkV0lpT2lKalptRTRNV0kxTlRGbU5XUTBPVGd5WWprMlpHWTBZVGd3WlRaaU16azBOU0o5LlpCR1I0ZHZMUzlnQWxiSWVWZzVJRXg4M0hDLXVlcXIwYzVMNGh5cXVtbWdaTTZGUnZYX3RLYkhJXzU4bEwzd0lfb3BkZFlnOE9fYzhuSERGLTc1NlhuZmlwaHlCTE1VWTdsTjU3Qkl1TFoyZmJKWUtNaUZjNjZieEtSLTNJd0k4Q2p3ekxpU01MdFBRbkFRbllHdXFJZmFodXFZR09Rb3VZVFpjUC1DOVlPMVM2WlduNXRRTzFDM28xaUt5MHpHM0JUUjJTdmJrUHQwWmVxZFhVcGQ0WVBSenk4WUtEaVhXTDkyMWd6dlVYeEs4QXpUMVZYZE9aUlJ5RkpIa3ZLYlVoZnZ0bU12LW9qZFQtYlZqSjdUSHBYeVR5dGZXS2tsblg5VU5PdWt0U29kT0NZcDJaRWlOd3NfR3oteHpGUjJnWl84Mm9DT0ZweEF1QUtfeGJVYzd4S1RVTDg2NzZtNi1hUUt0aXZtVTgtTkh5cjdJcy10WkZyb3A0SHdNMUtWcUo0eGlqVGljTmZPNF9PV2FOanZHd0tCM1dEa1NzTU1GZldVVi1GNDNhMlRSR3FkRmkwT0R3MjlLQVVCNnRJbW5QeEE1Ni03RlRlSlVRdG5FVXdBV0ZfT3RQU0FvendGVmFJVUVTNjRUQVo4ZDR0TUdYQXpZUy1NSzVMLVpMeGZLRDZjWnREVDdCUTRqQ0RsNGtPVEViWTlmQlZscXBfYUhqRXBqVG9TZFZNVFgxdzAzSEpqYzgxSlVWVFd5bjQ0OTJkTC1aeGE4ZktWT0l1WVZ0VF9KbDRORV9XYWNvZHBJUnZiRTZ1d0toTTNSZzBSYkhKUmlwZEJXSjlSN1FpME1YN3I3SkJkNEJMaDhhWUNMT2FWM1E4dlRSOTB0MmxSc2plWFhxZU1tM0c4","email":"cchen@redhat.com"},"registry.redhat.io":{"auth":"NTk0NDQ2Mnx1aGMtMVRkdkI2QnNBNlY5WnpRcVdIRHJCUXFTR2thOmV5SmhiR2NpT2lKU1V6VXhNaUo5LmV5SnpkV0lpT2lKalptRTRNV0kxTlRGbU5XUTBPVGd5WWprMlpHWTBZVGd3WlRaaU16azBOU0o5LlpCR1I0ZHZMUzlnQWxiSWVWZzVJRXg4M0hDLXVlcXIwYzVMNGh5cXVtbWdaTTZGUnZYX3RLYkhJXzU4bEwzd0lfb3BkZFlnOE9fYzhuSERGLTc1NlhuZmlwaHlCTE1VWTdsTjU3Qkl1TFoyZmJKWUtNaUZjNjZieEtSLTNJd0k4Q2p3ekxpU01MdFBRbkFRbllHdXFJZmFodXFZR09Rb3VZVFpjUC1DOVlPMVM2WlduNXRRTzFDM28xaUt5MHpHM0JUUjJTdmJrUHQwWmVxZFhVcGQ0WVBSenk4WUtEaVhXTDkyMWd6dlVYeEs4QXpUMVZYZE9aUlJ5RkpIa3ZLYlVoZnZ0bU12LW9qZFQtYlZqSjdUSHBYeVR5dGZXS2tsblg5VU5PdWt0U29kT0NZcDJaRWlOd3NfR3oteHpGUjJnWl84Mm9DT0ZweEF1QUtfeGJVYzd4S1RVTDg2NzZtNi1hUUt0aXZtVTgtTkh5cjdJcy10WkZyb3A0SHdNMUtWcUo0eGlqVGljTmZPNF9PV2FOanZHd0tCM1dEa1NzTU1GZldVVi1GNDNhMlRSR3FkRmkwT0R3MjlLQVVCNnRJbW5QeEE1Ni03RlRlSlVRdG5FVXdBV0ZfT3RQU0FvendGVmFJVUVTNjRUQVo4ZDR0TUdYQXpZUy1NSzVMLVpMeGZLRDZjWnREVDdCUTRqQ0RsNGtPVEViWTlmQlZscXBfYUhqRXBqVG9TZFZNVFgxdzAzSEpqYzgxSlVWVFd5bjQ0OTJkTC1aeGE4ZktWT0l1WVZ0VF9KbDRORV9XYWNvZHBJUnZiRTZ1d0toTTNSZzBSYkhKUmlwZEJXSjlSN1FpME1YN3I3SkJkNEJMaDhhWUNMT2FWM1E4dlRSOTB0MmxSc2plWFhxZU1tM0c4","email":"cchen@redhat.com"}}}'
sshKey: |
  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDTPFzWldumzMj3l5AndYGxTyUQxUi1cdUTHsUnwjMfcZXHc3dH9G8y1HUkfs4g3+gwLX/FmGsVWz6/61Y/+RyPJg5wI8XyP0QEYCaJ8BDiJw3rlMwrbBdIYBDwvdaMn655IM7qYgQbaXNIYKVRgaRStA2DzZqKJkdkLRW0JxA2nrRhKTLqtGzQXMYh897Aur5lt1NgafZYZbBy66LozCxe3c22avYpY7f3Of8zinJo4ZXQufHa0jQcL+6j/TpP0PYkK4R2/7UqWHP9+NREr5iKqBm3H9Ddc7ZtroKV9AaIckVyZcC8s+RlaHjI2PuSl+OBU2FnSHZbfnehSIRFhLr4O8MHy1jw3Ki/eR+V/2kDHIDHIi+1d7TTwBZMjMjXn8lffFezYze67bV+dHe+DonbZGJqXqA8+df8A3jMcl5/GQ1l5giNu6xUvQU0exH4Y2YurF7wcTy0dYJ60kM40l6QbXzNC00NShd8s5ixo8sv3rqpEpUq/JWNuZ5QNoA0eik= cchen@Chens-MacBook-Pro.local
EOF

wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/$VERSION/openshift-install-$ARCH.tar.gz
tar xvf openshift-install-$ARCH.tar.gz
mkdir install
cp install-config.yaml install

