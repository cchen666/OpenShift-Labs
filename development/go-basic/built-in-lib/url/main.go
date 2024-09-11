package main

import (
	"fmt"
	"net/url"
)

func main() {
	url1, _ := url.Parse("unix:///var/lib/kubelet/csi.sock")
	fmt.Printf("url host is %v\n", url1.Host)
	fmt.Printf("url scheme is %v\n", url1.Scheme)
	fmt.Printf("url path is %v\n\n", url1.Path)

	url2, _ := url.Parse("https://www.google.com")
	fmt.Printf("url2 host is %v\n", url2.Host)
	fmt.Printf("url2 scheme is %v\n", url2.Scheme)
	fmt.Printf("url2 path is %v\n", url2.Path)
}
