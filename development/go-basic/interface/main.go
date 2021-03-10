// Output:
// This is dog Puppy Speaking
// This is dog Puppy Walking
// This is cat Catty Speaking
// This is cat Catty Walking

package main

import (
	"fmt"
	"io"
	"os"
)

type Animal interface {
	Say() string
	Walk() string
}

type Dog struct {
	name string
}

type Cat struct {
	name string
}

func (d *Dog) Say() string {
	return "This is dog " + d.name + " Speaking"
}

func (c *Cat) Say() string {
	return "This is cat " + c.name + " Speaking"
}

func (d *Dog) Walk() string {
	return "This is dog " + d.name + " Walking"
}

func (d *Cat) Walk() string {
	return "This is cat " + d.name + " Walking"
}

func Behave(i Animal) {
	fmt.Println(i.Say())
	fmt.Println(i.Walk())
}

func main() {
	var w io.Writer
	w = os.Stdout
	w.Write([]byte("Hello World~"))
	dog := &Dog{"Puppy"}
	cat := &Cat{"Catty"}
	Behave(dog)
	Behave(cat)
}
