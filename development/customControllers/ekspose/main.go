package main

import (
	"flag"
	"fmt"
	"time"

	"k8s.io/client-go/informers"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	kube_file_default := "/Users/cchen/Code/ocp_install/4.8.46/auth/kubeconfig"
	kubeconfig := flag.String("kubeconfig", kube_file_default, "Default kubeconfig file")
	flag.Parse()
	config, err := clientcmd.BuildConfigFromFlags("", *kubeconfig)
	if err != nil {
		fmt.Printf("failed to get config and error is %s\n", err.Error())
		// If this is a Pod inside the cluster
		config, err = rest.InClusterConfig()
		if err != nil {
			fmt.Printf("failed to get InClusterConfig,%s", err.Error())
		}
	}
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		fmt.Printf("failed to get clientset and error is %s\n", err.Error())
	}
	ch := make(chan struct{})
	informers := informers.NewSharedInformerFactory(clientset, 10*time.Minute)
	c := newController(clientset, informers.Apps().V1().Deployments())
	informers.Start(ch)
	c.run(ch)
}
