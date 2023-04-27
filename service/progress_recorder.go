package service

import (
	"math"
	"sync/atomic"
)

type ProgressRecorder interface {
	Reset()
	Inc(step int)
	Percentage() int
}

type progressRecorder struct {
	total   int64
	current int64
}

func NewProgressRecorder(total int64) ProgressRecorder {
	s := &progressRecorder{total: total}
	return s
}

func (s *progressRecorder) Reset() {
	atomic.StoreInt64(&s.current, 0)
}

func (s *progressRecorder) Inc(step int) {
	atomic.AddInt64(&s.current, int64(step))
}

func (s *progressRecorder) Percentage() int {
	current := atomic.LoadInt64(&s.current)
	return int(math.Round(float64(current)/float64(s.total))) * 100
}
