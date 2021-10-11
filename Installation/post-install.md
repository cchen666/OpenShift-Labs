# Post Install

## How we can get the console and the password of kubeadmin after installation

* To get the console

~~~bash
$ oc get console.config.openshift.io cluster -o yaml | grep consoleURL
  consoleURL: https://console-openshift-console.apps.mycluster.xxx.com
~~~

* To get the password

You need to login to the installer and check `kubeadmin-password` file.

## Configure bash auto-completion

* Install the package

~~~bash
$ brew install bash-completion
$ oc completion bash > oc_bash_completion
$ sudo cp oc_bash_completion /usr/local/etc/bash_completion.d/
~~~

* Add following line in ~/.bash_profile

~~~bash
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
~~~

* Relogin the bash or source ~/.bash_profile
