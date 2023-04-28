#!/bin/bash
CGO_ENABLED=1 go build -o "ry-hash" -ldflags="-w -s" ./ui/