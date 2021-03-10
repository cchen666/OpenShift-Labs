# Distribution the Load

## Create two versions

~~~bash

$ kn service create greeter
   --image quay.io/rhdevelopers/knative-tutorial-greeter:quarkus \
   --namespace serverless-tutorial \
   --revision-name greeter-v1

$ kn service update greeter
   --image quay.io/rhdevelopers/knative-tutorial-greeter:quarkus \
   --namespace serverless-tutorial \
   --revision-name greeter-v2 \
   --env MESSAGE_PREFIX=GreeterV2

$ kn service list
NAME      URL                                                              LATEST       AGE   CONDITIONS   READY   REASON
greeter   https://greeter-serverless-tutorial.apps.mycluster.nancyge.com   greeter-v2   15m   3 OK / 3     True

$ kn route list
NAME      URL                                                              READY
greeter   https://greeter-serverless-tutorial.apps.mycluster.nancyge.com   True

~~~bash

## Distrbution

~~~bash

$ kn service update greeter \
   --traffic greeter-v1=50 \
   --traffic greeter-v2=50 \
   --tag greeter-v1=current \
   --tag greeter-v2=prev \
   --tag @latest=latest

$ kn route describe greeter
Name:       greeter
Namespace:  serverless-tutorial
Age:        12m
URL:        https://greeter-serverless-tutorial.apps.mycluster.nancyge.com
Service:    greeter

Traffic Targets:
    0%  @latest (greeter-v2) #latest
        URL:  https://latest-greeter-serverless-tutorial.apps.mycluster.nancyge.com
   50%  greeter-v1 #current
        URL:  https://current-greeter-serverless-tutorial.apps.mycluster.nancyge.com
   50%  greeter-v2 #prev
        URL:  https://prev-greeter-serverless-tutorial.apps.mycluster.nancyge.com

Conditions:
  OK TYPE                      AGE REASON
  ++ Ready                      4m
  ++ AllTrafficAssigned        12m
  ++ CertificateProvisioned    12m TLSNotEnabled
  ++ IngressReady               4m

$ APP_ROUTE=$(kn route list | awk '{print $2}' | sed -n 2p)

$ for run in {1..10}
do
  curl --insecure $APP_ROUTE
done
GreeterV2  greeter => '9861675f8845' : 1
Hi  greeter => '9861675f8845' : 1
Hi  greeter => '9861675f8845' : 2
GreeterV2  greeter => '9861675f8845' : 2
Hi  greeter => '9861675f8845' : 3
Hi  greeter => '9861675f8845' : 4
Hi  greeter => '9861675f8845' : 5
GreeterV2  greeter => '9861675f8845' : 3
Hi  greeter => '9861675f8845' : 6
Hi  greeter => '9861675f8845' : 7

~~~
