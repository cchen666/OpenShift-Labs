# Install the Serverless Operator

## installer.sh

~~~bash

echo "Setting up Serverless..."

# Login as admin
oc login -u admin -p admin

# Wait for katacoda to copy our stuff?
while [ ! -f 01-prepare/operator-subscription.yaml ]
do
        sleep 5
done

# Apply the serverless operator
oc create -f 01-prepare/operator-subscription.yaml
sleep 3

echo "Serverless Operator Subscribed, waiting for deployment..."
# Setup waiting function
bash 01-prepare/watch-serverless-operator.bash
sleep 3

echo "Serverless Operator deployed. Deploying knative-serving..."
# If we make it this far we have deployed the Serverless Operator!
# Next, Knative Serving
oc create -f 01-prepare/serving.yaml
sleep 3

echo "Serving created, waiting for deployment..."
# Wait for Serving to install
bash 01-prepare/watch-knative-serving.bash
sleep 3

echo "Serving deployed. Setting up developer env..."
# If we make it this far we are GOOD TO GO!
# Login as the developer and create a new project for our tutorial
# oc login -u developer -p developer
# oc new-project serverless-tutorial

# Done.
sleep 3
#clear
echo "Serverless Tutorial Ready!"

~~~

## operator-subscription.yaml

~~~bash
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: serverless-operator
  namespace: openshift-operators
spec:
  channel: "stable"
  installPlanApproval: Automatic
  name: serverless-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
~~~

## knavie-serving

~~~bash
apiVersion: operator.knative.dev/v1alpha1
kind: KnativeServing
metadata:
  name: knative-serving
  namespace: knative-serving
~~~

## watch-knative-serving.bash

~~~bash
#!/usr/bin/env bash

A=1
while : ;
do
  output=`oc get knativeserving.operator.knative.dev/knative-serving -n knative-serving --template='{{range .status.conditions}}{{printf "%s=%s\n" .type .status}}{{end}}'`
  echo "$A: $output"
  if [ -z "${output##*'Ready=True'*}" ] ; then echo "Installed"; break; fi;
  A=$((A+1))
  sleep 10
done
~~~

## watch-serverless-operator.bash

~~~bash
#!/usr/bin/env bash

function wait_for_operator_install {
  local A=1
  local sub=$1
  while : ;
  do
        sleep 10
    echo "$A: Checking..."
    phase=`oc get csv -n openshift-operators $sub -o jsonpath='{.status.phase}'`
    if [[ $phase == "Succeeded" ]]; then echo "$sub Installed"; break; fi
    A=$((A+1))
  done
}

SERVERLESS_OP_NAME=""

function install_operator {
  echo SERVERLESS_OP_NAME ${SERVERLESS_OP_NAME}

  while [ -z $SERVERLESS_OP_NAME ] ;
  do
        sleep 10
        ops=`oc get csv -n openshift-operators`
        pat='(serverless-operator\S+)'
        [[ $ops =~ $pat ]] # From this line
    SERVERLESS_OP_NAME=${BASH_REMATCH[0]}
    install_operator
  done

}

install_operator
wait_for_operator_install
~~~