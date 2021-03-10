package main

import (
	"context"
	"fmt"
	"io/ioutil"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

func handleError(e error) {
	if e != nil {
		fmt.Printf("Operation Failed and the error is %s", e.Error())
	}
}

func main() {
	config, err := rest.InClusterConfig()
	handleError(err)

	ns, err := ioutil.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/namespace")
	handleError(err)

	ctx := context.Background()
	clientset, err := kubernetes.NewForConfig(config)
	handleError(err)

	// Pod is in Core/v1 API group
	pods, err := clientset.CoreV1().Pods(string(ns)).List(ctx, metav1.ListOptions{
		TypeMeta: metav1.TypeMeta{
			Kind:       "",
			APIVersion: "",
		},
		LabelSelector:        "",
		FieldSelector:        "",
		Watch:                false,
		AllowWatchBookmarks:  false,
		ResourceVersion:      "",
		ResourceVersionMatch: "",
		TimeoutSeconds:       new(int64),
		Limit:                0,
		Continue:             "",
	})

	handleError(err)

	for _, pod := range pods.Items {
		fmt.Printf("pod name %s\n", pod.Status.PodIP)
	}
}
