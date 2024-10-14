package main

import (
	_flag "github.com/humanbelnik/db-class/01_init/flag"
	"github.com/humanbelnik/db-class/01_init/generator"
)

func main() {
	flags := _flag.Parse()
	idPool := generator.IDs()
	generators := generator.MapGenerators()

	for _, f := range flags {
		if f.Value == nil {
			continue
		}

		generators[f.Name](idPool, *f.Value)
	}
}
