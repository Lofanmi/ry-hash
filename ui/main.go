package main

import (
	"github.com/ying32/govcl/vcl"
)

func main() {
	vcl.Application.SetScaled(true)
	vcl.Application.SetTitle("ry-hash v1.0 / Lofanmi")
	vcl.Application.Initialize()
	vcl.Application.SetMainFormOnTaskBar(true)
	vcl.Application.CreateForm(&FormMain)
	vcl.Application.Run()
}
