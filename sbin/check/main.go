package main

import (
	"encoding/json"
	"fmt"
	"github.com/sergi/go-diff/diffmatchpatch"
	"io"
	"log"
	"os"
	"sort"
	"strings"
	"time"
)

type Segment struct {
	QStart string `json:"qStart"`
	QEnd   string `json:"qEnd"`
	Q      string `json:"q"`
	AStart string `json:"aStart"`
	AEnd   string `json:"aEnd"`
	Tip    string `json:"tip"`
	A      string `json:"a"`
}

type Lesson struct {
	URL        string `json:"url"`
	Path       string `json:"path"`
	Key        string `json:"key"`
	Title      string `json:"title"`
	TitleStart string `json:"titleStart"`
	TitleEnd   string `json:"titleEnd"`
	// raw text for checking
	Raw []string `json:"raw"`

	Segment []Segment `json:"segment"`
}

type AudioKV struct {
	Type     string   `json:"type"`
	RootPath string   `json:"rootPath"`
	Key      string   `json:"key"`
	Lesson   []Lesson `json:"lesson"`
}

type Content struct {
	StartTime time.Time
	Text      string
}

func parseTime(timeStr string) time.Time {
	if timeStr == "" {
		timeStr = "00:00:00,000"
	}
	// Example time format "00:00:14,060"
	parsedTime, err := time.Parse("15:04:05,000", timeStr)
	if err != nil {
		log.Fatalf("Error parsing time: %v", err)
	}
	return parsedTime
}

func main() {
	fileName := "raw.json"
	if len(os.Args) > 1 {
		fileName = os.Args[1]
	}
	spaceReplace := ""
	if len(os.Args) > 2 {
		spaceReplace = os.Args[2]
	}

	file, err := os.Open(fileName)
	if err != nil {
		fmt.Println("Error opening file:", err)
		return
	}
	jsonBytes, _ := io.ReadAll(file)
	var audioKV AudioKV
	err = json.Unmarshal(jsonBytes, &audioKV)
	if err != nil {
		log.Fatalf("Error unmarshalling JSON: %v", err)
	}

	for _, lesson := range audioKV.Lesson {
		var raw = lesson.Raw
		var contents []Content
		if lesson.Title != "" {
			contents = append(contents, Content{
				StartTime: parseTime(lesson.TitleStart),
				Text:      lesson.Title,
			})
		}
		for _, segment := range lesson.Segment {
			if segment.Q != "" {
				contents = append(contents, Content{
					StartTime: parseTime(segment.QStart),
					Text:      segment.Q,
				})
			}
			contents = append(contents, Content{
				StartTime: parseTime(segment.AStart),
				Text:      segment.A,
			})
		}
		sort.Slice(contents, func(i, j int) bool {
			return contents[i].StartTime.Before(contents[j].StartTime)
		})
		if len(raw) == 0 {
			continue
		}
		rawText := ""
		for i, _ := range raw {
			rawText += raw[i] + " "
		}
		a := strings.Fields(rawText)
		aOffset := 0
		aText := ""
		bText := ""
		// Print the sorted content
		for _, content := range contents {
			contentWithDesc := strings.SplitN(content.Text, "\n", 2)
			bText += strings.TrimSpace(contentWithDesc[0]) + "\n"
			b := strings.Fields(contentWithDesc[0])
			line := ""
			for range b {
				if aOffset < len(a) {
					line += fmt.Sprintf("%s ", a[aOffset])
				}
				aOffset++
			}
			aText += strings.TrimSpace(line) + "\n"
		}

		if spaceReplace != "" {
			aText = strings.ReplaceAll(aText, " ", spaceReplace)
			bText = strings.ReplaceAll(bText, " ", spaceReplace)
		}
		dmp := diffmatchpatch.New()
		diffs := dmp.DiffMain(aText, bText, false)
		if len(diffs) > 0 {
			isDiff := false
			for _, diff := range diffs {
				if diff.Type != diffmatchpatch.DiffEqual {
					isDiff = true
					break
				}
			}
			if isDiff {
				fmt.Println("")
				fmt.Println(dmp.DiffPrettyText(diffs))
			}
		}
	}
}
