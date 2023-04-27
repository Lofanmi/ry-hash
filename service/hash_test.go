package service

import (
	"crypto/md5"
	"hash/crc32"
	"testing"
)

func TestFileHash(t *testing.T) {
	filename := `/Users/a37/code/github/Lofanmi/ry-hash/ryHash.res`
	fh, err := NewFileHash(filename)
	if err != nil {
		t.Log(err)
	}
	h := md5.New()
	s, _ := fh.Hash(h)
	t.Logf("hash=%s, p=%d%%", s, fh.ProgressRecorder.Percentage())
	h = crc32.NewIEEE()
	s, _ = fh.Hash(h)
	t.Logf("hash=%s, p=%d%%", s, fh.ProgressRecorder.Percentage())
}
