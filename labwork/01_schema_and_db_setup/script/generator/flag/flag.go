package _flag

import "flag"

var (
	ClFlag   = "cl"
	CltrFlag = "cltr"
	EqFlag   = "eq"
)

type IntFlag struct {
	Name  string
	Value *int
}

func NewIntFlag(name string, v *int) *IntFlag {
	f := &IntFlag{}
	f.Name = name

	if *v != 0 {
		f.Value = v
	}

	return f
}

func Parse() []*IntFlag {
	cl := flag.Int(ClFlag, 0, "")
	cltr := flag.Int(CltrFlag, 0, "")
	eq := flag.Int(EqFlag, 0, "")

	flag.Parse()

	return []*IntFlag{
		NewIntFlag(ClFlag, cl),
		NewIntFlag(CltrFlag, cltr),
		NewIntFlag(EqFlag, eq),
	}
}
