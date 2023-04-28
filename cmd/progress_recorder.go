package main

import (
	"math"
	"sync"
)

type ProgressRecorder interface {
	Reset()
	Inc(step int)
	Percentage() int
}

func NewProgressRecorder(total int64) ProgressRecorder {
	return &progressRecorderMutex{mu: new(sync.Mutex), total: total}
}

type progressRecorderMutex struct {
	mu      *sync.Mutex
	total   int64
	current int64
}

func (s *progressRecorderMutex) Reset() {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.current = 0
}

func (s *progressRecorderMutex) Inc(step int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.current += int64(step)
}

func (s *progressRecorderMutex) Percentage() int {
	s.mu.Lock()
	defer s.mu.Unlock()
	return int(math.Round(float64(s.current) / float64(s.total) * 100))
}
