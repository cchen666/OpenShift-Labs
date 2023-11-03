package main

import (
	"fmt"
)

// Car struct representing the product
type Car struct {
	Make  string
	Model string
	Color string
}

// CarBuilder interface that outlines the builder methods
type CarBuilder interface {
	WithMake(string) CarBuilder
	WithModel(string) CarBuilder
	WithColor(string) CarBuilder
	Build() Car
}

// concreteBuilder struct that implements the CarBuilder interface
type concreteBuilder struct {
	car Car
}

func (b *concreteBuilder) WithMake(make string) CarBuilder {
	b.car.Make = make
	return b
}

func (b *concreteBuilder) WithModel(model string) CarBuilder {
	b.car.Model = model
	return b
}

func (b *concreteBuilder) WithColor(color string) CarBuilder {
	b.car.Color = color
	return b
}

func (b *concreteBuilder) Build() Car {
	return b.car
}

// NewCarBuilder provides an instance of CarBuilder
func NewCarBuilder() CarBuilder {
	return &concreteBuilder{}
}

func main() {
	builder := NewCarBuilder()
	car := builder.WithMake("Toyota").WithModel("Corolla").WithColor("Red").Build()

	fmt.Printf("Car Details: Make = %s, Model = %s, Color = %s\n", car.Make, car.Model, car.Color)
}
