package main

import (
	"github.com/ying32/govcl/vcl"
)

func main() {
    vcl.Application.SetScaled(true)
    vcl.Application.SetTitle("ryHash - 速度飞快的文件哈希工具 v1.0 - https://imlht.com")
	vcl.Application.Initialize()
	vcl.Application.SetMainFormOnTaskBar(true)
    vcl.Application.CreateForm(&FormMain)
	vcl.Application.Run()
}
