package service

type UI interface {
	//
}

type ui struct {
	ProgressRecorder ProgressRecorder
}

func NewUI(recorder ProgressRecorder) UI {
	s := &ui{
		ProgressRecorder: recorder,
	}
	return s
}

func (s *ui) s() {

}
