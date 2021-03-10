package main

import (
	"context"
	"flag"
	"fmt"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
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
	ctx := context.Background()
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		fmt.Printf("failed to get clientset and error is %s\n", err.Error())
	}
	// Pod is in Core/v1 API group
	pods, err := clientset.CoreV1().Pods("openshift-etcd").List(ctx, metav1.ListOptions{})
	if err != nil {
		fmt.Printf("failed to get pods and error is %s\n", err.Error())
	}
	fmt.Println("Pods from default namespace")
	for _, pod := range pods.Items {
		fmt.Printf("pod name %s\n", pod.Name)
	}
	// Deployment is apps/v1 API group
	deployments, err := clientset.AppsV1().Deployments("openshift-etcd").List(ctx, metav1.ListOptions{})
	if err != nil {
		fmt.Printf("failed to get deployments and error is %s\n", err.Error())
	}
	fmt.Println("Deployments Information")
	for _, deploy := range deployments.Items {
		fmt.Printf("%s, %s\n", deploy.Name, deploy.CreationTimestamp)
	}
}
