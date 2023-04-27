package service

import (
	"encoding/hex"
	"errors"
	"hash"
	"io"
	"os"
)

type FileHash struct {
	Filename         string
	File             *os.File
	FileInfo         os.FileInfo
	ProgressRecorder ProgressRecorder
}

func NewFileHash(filename string) (p *FileHash, err error) {
	fh := FileHash{Filename: filename}
	if fh.FileInfo, err = os.Stat(filename); errors.Is(err, os.ErrNotExist) {
		return
	}
	if err != nil {
		return
	}
	fh.File, _ = os.Open(filename)
	fh.ProgressRecorder = NewProgressRecorder(fh.FileInfo.Size())
	p = &fh
	return
}

func (r *FileHash) Hash(h hash.Hash) (s string, err error) {
	buf := make([]byte, r.bufSize())
	if _, err = r.File.Seek(0, 0); err != nil {
		return
	}
	r.ProgressRecorder.Reset()
	if _, err = r.copyBuffer(h, r.File, buf); err != nil {
		return
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}

func (r *FileHash) copyBuffer(dst io.Writer, src io.Reader, buf []byte) (written int64, err error) {
	for {
		nr, er := src.Read(buf)
		if nr > 0 {
			nw, ew := dst.Write(buf[0:nr])
			if nw < 0 || nr < nw {
				nw = 0
				if ew == nil {
					ew = errors.New("invalid write result")
				}
			}
			written += int64(nw)
			r.ProgressRecorder.Inc(nw)
			if ew != nil {
				err = ew
				break
			}
			if nr != nw {
				err = io.ErrShortWrite
				break
			}
		}
		if er != nil {
			if er != io.EOF {
				err = er
			}
			break
		}
	}
	return written, err
}

func (r *FileHash) bufSize() int {
	const MB = 1024 * 1024
	size := r.FileInfo.Size()
	if size <= MB {
		return MB
	}
	if size <= 32*MB {
		return 8 * MB
	}
	if size <= 128*MB {
		return 16 * MB
	}
	if size <= 512*MB {
		return 32 * MB
	}
	return 64 * MB
}