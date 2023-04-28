windows:
	CGO_ENABLED=1 go build -o "ryHash.exe" -buildmode=exe -ldflags="-H windowsgui -w -s" -tags="tempdll" ./cmd/

macos:
	CGO_ENABLED=1 go build -o "ryHash" -ldflags="-w -s" ./cmd/