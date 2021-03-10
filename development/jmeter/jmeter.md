# Installation

## Install openjdk 1.8

~~~bash

$ yum install openjdk-1.8

~~~

## Download Jmeter Binary

~~~bash

$ cd ~/Downloads
$ wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.5.tgz

$ mkdir /usr/local/jmeter
$ cp ~/Downloads/apache-jmeter-5.5.tgz /usr/local/jmeter
$ tar xvf /usr/local/jmeter/apache-jmeter-5.5.tgz
~~~

## Configure Environment Variables

~~~bash
$ tail -n 2 ~/.bashrc
export JMETER_HOME=/usr/local/jmeter/apache-jmeter-5.5
export PATH=${JMETER_HOME}/bin:$PATH
~~~

## Run Some Test

* We firstly create `Thread Group` under `Test Plan`

![add_thread_group](../images/add_thread_group.png)

* Then we add `http request sampler` under `Threads Groups`

![add_http_request](../images/add_http_request.png)

* Then we add `aggregate report` under `HTTP Request`

![add_aggregate_report](../images/add_aggregate_report.png)

* Specify the `threads count` and HTTP URL that we'd like to test

![test_threads_count](../images/test_threads_count.png)

![configure_http_URL](../images/configure_http_URL.png)

* Run the test and check the result

~~~bash

$ oc get pods
NAME                               READY   STATUS      RESTARTS   AGE
openshift-flask-2-build            0/1     Completed   0          38m
openshift-flask-598b7c644f-2fjnj   1/1     Running     0          36m
openshift-flask-598b7c644f-74pzm   1/1     Running     0          3s
openshift-flask-598b7c644f-8g54m   1/1     Running     0          2m51s
openshift-flask-598b7c644f-tnd4r   1/1     Running     0          3m28s

~~~

![check_report](../images/check_report-1.png)

~~~bash
$ oc get pods # Shrink Pods from 4 to 2

NAME                               READY   STATUS      RESTARTS   AGE
openshift-flask-2-build            0/1     Completed   0          57m
openshift-flask-598b7c644f-2fjnj   1/1     Running     0          55m
openshift-flask-598b7c644f-8g54m   1/1     Running     0          21m
~~~

![check_report_2](../images/check_report-2.png)

* Save the Test Plan as jmx file

![save_test_plan](../images/save_test_plan.png)
