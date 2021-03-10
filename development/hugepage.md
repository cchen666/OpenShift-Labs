# Use Hugepage in Pod

<https://docs.openshift.com/container-platform/4.10/scalability_and_performance/what-huge-pages-do-and-how-they-are-consumed-by-apps.html>

## Check Worker Node Status

~~~bash
$ cat /proc/meminfo | grep -i huge
HugePages_Total:    1024
HugePages_Free:     1024
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
Hugetlb:         2097152 kB
~~~

## Create Hugepage Pod and Start Application

~~~bash
$ oc create -f files/hugepage-pod.yaml
$ gcc hugepage.c
$ oc cp a.out hugepage-pod-XXXXXX:/tmp
$ oc rsh hugepage-pod-XXXXXX
sh-4.2# cd /tmp/
sh-4.2# ./a.out
address returned 0x7f5e80a00000
address returned 0x7f5e80800000
address returned 0x7f5e80600000
address returned 0x7f5e80400000
address returned 0x7f5e80200000
address returned 0x7f5e80000000
address returned 0x7f5e7fe00000
address returned 0x7f5e7fc00000
address returned 0x7f5e7fa00000
address returned 0x7f5e7f800000
address returned 0x7f5e7f600000
address returned 0x7f5e7f400000
address returned 0x7f5e7f200000
address returned 0x7f5e7f000000
address returned 0x7f5e7ee00000
address returned 0x7f5e7ec00000

$ cat /proc/meminfo | grep -i huge
HugePages_Total:    1024
HugePages_Free:     1008 # <==========
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
Hugetlb:         2097152 kB
~~~
