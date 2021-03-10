#### 1. How we can get the console and the password of kubeadmin after installation
* To get the console
~~~
$ oc get console.config.openshift.io cluster -o yaml | grep consoleURL
  consoleURL: https://console-openshift-console.apps.mycluster.xxx.com
~~~
* To get the password
You need to login to the installer and check `kubeadmin-password` file.
