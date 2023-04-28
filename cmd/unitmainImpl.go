package main

import (
	"crypto/md5"
	"crypto/sha1"
	"crypto/sha256"
	"crypto/sha512"
	"errors"
	"fmt"
	"hash"
	"hash/crc32"
	"hash/fnv"
	"os"
	"runtime"
	"strings"
	"sync"
	"time"

	"github.com/dustin/go-humanize"
	"github.com/ying32/govcl/vcl"
	"github.com/ying32/govcl/vcl/types"
)

type HashAlg struct {
	Name string
	Hash hash.Hash
}

type hashAlgConfig struct {
	Name    string
	HashFn  func() hash.Hash
	Enabled bool
}

var hashAlgConfigList = []hashAlgConfig{
	{Name: "crc32", HashFn: func() hash.Hash { return crc32.NewIEEE() }, Enabled: true},
	{Name: "md5", HashFn: func() hash.Hash { return md5.New() }, Enabled: true},
	{Name: "sha1", HashFn: func() hash.Hash { return sha1.New() }, Enabled: true},
	{Name: "sha256", HashFn: func() hash.Hash { return sha256.New() }, Enabled: true},
	{Name: "sha512", HashFn: func() hash.Hash { return sha512.New() }, Enabled: false},
	{Name: "fnv1/32", HashFn: func() hash.Hash { return fnv.New32() }, Enabled: false},
	{Name: "fnv1a/32", HashFn: func() hash.Hash { return fnv.New32a() }, Enabled: false},
	{Name: "fnv1/64", HashFn: func() hash.Hash { return fnv.New64() }, Enabled: false},
	{Name: "fnv1a/64", HashFn: func() hash.Hash { return fnv.New64a() }, Enabled: false},
	{Name: "fnv1/128", HashFn: func() hash.Hash { return fnv.New128() }, Enabled: false},
	{Name: "fnv1a/128", HashFn: func() hash.Hash { return fnv.New128a() }, Enabled: false},
}

// TFormMainFields
// ::private::
type TFormMainFields struct {
	MapProgressBar    map[string]*vcl.TProgressBar
	MapCheckBox       map[string]*vcl.TCheckBox
	ProgressBarFinish *vcl.TProgressBar
	LabelFinish       *vcl.TLabel

	Stopped bool
}

func (f *TFormMain) initComponents() {
	f.MapProgressBar = map[string]*vcl.TProgressBar{}
	f.MapCheckBox = map[string]*vcl.TCheckBox{}
	var (
		topProgressBar int32 = 426
		topCheckBox    int32 = 416
		step           int32 = 40
	)
	for _, config := range hashAlgConfigList {
		pb := vcl.NewProgressBar(f)
		pb.SetParent(f)
		pb.SetMin(0)
		pb.SetMax(100)
		pb.SetHeight(16)
		pb.SetWidth(790)
		pb.SetLeft(24)
		pb.SetTop(topProgressBar)
		topProgressBar += step
		cb := vcl.NewCheckBox(f)
		cb.SetParent(f)
		cb.SetCaption(config.Name)
		cb.SetLeft(832)
		cb.SetChecked(config.Enabled)
		cb.SetTop(topCheckBox)
		topCheckBox += step
		f.MapProgressBar[config.Name] = pb
		f.MapCheckBox[config.Name] = cb
	}
	f.ProgressBarFinish = vcl.NewProgressBar(f)
	f.ProgressBarFinish.SetParent(f)
	f.ProgressBarFinish.SetMin(0)
	f.ProgressBarFinish.SetMax(100)
	f.ProgressBarFinish.SetHeight(16)
	f.ProgressBarFinish.SetWidth(790)
	f.ProgressBarFinish.SetLeft(24)
	f.ProgressBarFinish.SetTop(topProgressBar)
	f.LabelFinish = vcl.NewLabel(f)
	f.LabelFinish.SetParent(f)
	f.LabelFinish.SetCaption("就绪")
	f.LabelFinish.SetLeft(832)
	f.LabelFinish.SetTop(topCheckBox)

	f.SetHeight(f.Height() + step*int32(1+len(hashAlgConfigList)))
}

func (f *TFormMain) hashAlgList() []HashAlg {
	var res []HashAlg
	for _, config := range hashAlgConfigList {
		if cb, ok := f.MapCheckBox[config.Name]; ok && cb.Checked() {
			res = append(res, HashAlg{Name: config.Name, Hash: config.HashFn()})
		}
	}
	return res
}

func (f *TFormMain) OnFormCreate(sender vcl.IObject) {
	f.initComponents()
	f.ButtonStop.SetEnabled(false)
}

func (f *TFormMain) OnButtonBrowseClick(sender vcl.IObject) {
	if f.OpenDialog.Execute() {
		files := f.OpenDialog.Files()
		var fileNames []string
		for i := int32(0); i < files.Count(); i++ {
			fileNames = append(fileNames, files.S(i))
		}
		f.hashFileList(fileNames)
	}
}

func (f *TFormMain) OnButtonClearClick(sender vcl.IObject) {
	f.MemoLogger.Clear()
	runtime.GC()
}

func (f *TFormMain) OnButtonCopyClick(sender vcl.IObject) {
	text := f.MemoLogger.Lines().Text()
	if len(text) <= 0 {
		return
	}
	vcl.Clipboard.SetAsText(text)
	if vcl.Clipboard.AsText() == text {
		vcl.MessageDlg("成功复制到剪切板！", types.MtInformation, types.MbOK)
		f.MemoLogger.SetFocus()
		f.MemoLogger.SelectAll()
	}
}

func (f *TFormMain) OnButtonSaveClick(sender vcl.IObject) {
	if f.SaveDialog.Execute() {
		filename := f.SaveDialog.FileName()
		err := os.WriteFile(filename, []byte(f.MemoLogger.Lines().Text()), 0755)
		if err != nil {
			message := fmt.Sprintf("保存文件失败 [%s]！", filename)
			vcl.MessageDlg(message, types.MtError, types.MbOK)
		} else {
			message := fmt.Sprintf("成功保存到文件 [%s]！", filename)
			vcl.MessageDlg(message, types.MtInformation, types.MbOK)
		}
	}
}

func (f *TFormMain) OnButtonStopClick(sender vcl.IObject) {
	f.Stopped = true
}

func (f *TFormMain) OnFormDropFiles(sender vcl.IObject, fileNames []string) {
	f.hashFileList(fileNames)
}

func (f *TFormMain) hashFileList(fileNames []string) {
	f.ButtonStop.SetEnabled(true)
	f.Stopped = false
	hashAlgList := f.hashAlgList()
	length := len(fileNames)
	step := 100 / length
	for _, bar := range f.MapProgressBar {
		bar.SetPosition(0)
	}
	f.ProgressBarFinish.SetPosition(0)
	for i, filename := range fileNames {
		f.hashFile(filename, hashAlgList)
		position := f.ProgressBarFinish.Position() + int32(step)
		f.ProgressBarFinish.SetPosition(position)
		f.LabelFinish.SetCaption(fmt.Sprintf("%d / %d", i+1, length))
	}
	f.ProgressBarFinish.SetPosition(f.ProgressBarFinish.Max())
	f.ButtonStop.SetEnabled(false)

	runtime.GC()
	time.AfterFunc(time.Second*5, func() {
		vcl.ThreadSync(func() {
			f.LabelFinish.SetCaption("就绪")
		})
	})
}

func (f *TFormMain) hashFile(filename string, hashAlgList []HashAlg) {
	t := time.Now()
	fileInfo, err := os.Stat(filename)
	if errors.Is(err, os.ErrNotExist) {
		return
	}
	if err != nil {
		return
	}
	res := map[string]string{}
	finish := make(chan struct{})
	mapFileHash := map[string]*FileHash{}
	for _, hashAlg := range hashAlgList {
		fileHash, _ := NewFileHash(filename)
		mapFileHash[hashAlg.Name] = fileHash
	}

	go func() {
		mu := new(sync.RWMutex)
		wg := new(sync.WaitGroup)
		for _, hashAlg := range hashAlgList {
			wg.Add(1)
			go func(alg HashAlg) {
				defer wg.Done()
				fh, ok := mapFileHash[alg.Name]
				if !ok {
					return
				}
				s, e := fh.Hash(alg.Hash)
				if e != nil {
					return
				}
				mu.Lock()
				t2 := time.Since(t)
				res[alg.Name] = fmt.Sprintf("%s [elapsed=%s] [speed=%s/s]", s, t2,
					humanize.IBytes(uint64(float64(fileInfo.Size())/t2.Seconds())),
				)
				mu.Unlock()
			}(hashAlg)
		}
		wg.Wait()
		close(finish)
	}()

	timer := time.NewTicker(time.Second)
	defer timer.Stop()
	for {
		select {
		case <-timer.C:
			for algName, fileHash := range mapFileHash {
				if f.Stopped {
					fileHash.Stop()
					continue
				}
				percentage := fileHash.ProgressRecorder.Percentage()
				pb := f.MapProgressBar[algName]
				pb.SetPosition(int32(percentage))
			}
		case <-finish:
			for algName := range mapFileHash {
				pb := f.MapProgressBar[algName]
				pb.SetPosition(100)
			}
			goto showResult
		default:
			vcl.Application.ProcessMessages()
		}
	}

showResult:
	var info strings.Builder
	info.WriteString(fmt.Sprintf("文件: %s\r\n", filename))
	info.WriteString(fmt.Sprintf("大小: %s (%d 字节)\r\n", humanize.IBytes(uint64(fileInfo.Size())), fileInfo.Size()))
	info.WriteString(fmt.Sprintf("修改时间: %s\r\n", fileInfo.ModTime().Format("2006-01-02 15:04:05")))
	for _, hashAlg := range hashAlgList {
		if s, ok := res[hashAlg.Name]; ok {
			info.WriteString(fmt.Sprintf("%s: %s\r\n", hashAlg.Name, s))
		}
	}
	info.WriteString(fmt.Sprintf("总耗时: %s\r\n", time.Since(t)))
	info.WriteString(fmt.Sprintf("平均速度: %s/s\r\n", humanize.IBytes(uint64(float64(fileInfo.Size())/time.Since(t).Seconds()))))
	f.MemoLogger.Lines().Add(info.String())
}
