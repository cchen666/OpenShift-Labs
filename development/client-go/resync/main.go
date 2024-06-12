package main

import (
	"log"
	"path/filepath"
	"time"

	corev1 "k8s.io/api/core/v1"
	"k8s.io/client-go/informers"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/cache"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"
	"k8s.io/client-go/util/workqueue"
)

// PodHandler handles events for Pods
type PodHandler struct {
	queue workqueue.RateLimitingInterface
}

func (h *PodHandler) logEvent(eventType string, obj interface{}) {
	timestamp := time.Now().Format(time.RFC3339)
	pod, ok := obj.(*corev1.Pod)
	if !ok {
		log.Printf("[%s] %s event: unable to cast object to Pod\n", timestamp, eventType)
		return
	}
	log.Printf("[%s] %s event: Pod Name: %s, Namespace: %s\n", timestamp, eventType, pod.Name, pod.Namespace)
}

func (h *PodHandler) OnAdd(obj interface{}) {
	h.logEvent("Add", obj)
	h.queue.Add(obj)
}

func (h *PodHandler) OnUpdate(oldObj, newObj interface{}) {
	h.logEvent("Update", newObj)
	h.queue.Add(newObj)
}

func (h *PodHandler) OnDelete(obj interface{}) {
	h.logEvent("Delete", obj)
	h.queue.Add(obj)
}

func main() {
	kubeconfig := filepath.Join(homedir.HomeDir(), ".kube", "config")
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		log.Fatalf("Error building kubeconfig: %v\n", err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Fatalf("Error creating Kubernetes client: %v\n", err)
	}

	// Setting a resync period of 15 seconds
	informerFactory := informers.NewSharedInformerFactory(clientset, time.Second*15)
	podInformer := informerFactory.Core().V1().Pods().Informer()

	queue := workqueue.NewRateLimitingQueue(workqueue.DefaultControllerRateLimiter())
	handler := &PodHandler{queue: queue}

	podInformer.AddEventHandler(cache.ResourceEventHandlerFuncs{
		AddFunc:    handler.OnAdd,
		UpdateFunc: handler.OnUpdate,
		DeleteFunc: handler.OnDelete,
	})

	stopCh := make(chan struct{})
	defer close(stopCh)

	go podInformer.Run(stopCh)

	// Wait forever
	select {}
}
