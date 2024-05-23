package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"strings"
)

type segment struct {
	Start string `json:"start"`
	End   string `json:"end"`
	Tip   string `json:"tip"`
	A     string `json:"a"`
}

func main() {
	file, err := os.Open("srt.srt")
	if err != nil {
		fmt.Println("Error opening file:", err)
		return
	}

	defer func() { _ = file.Close() }()
	offset := 0
	scanner := bufio.NewScanner(file)
	segments := make([]*segment, 0, 10)
	curr := &segment{}
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if len(line) == 0 {
			continue
		} else {
			if offset%3 == 1 {
				se := strings.Split(line, "-->")
				if curr.Start == "" {
					curr.Start = strings.TrimSpace(se[0])
				}
				curr.End = strings.TrimSpace(se[1])
			}
			if offset%3 == 2 {
				if strings.HasSuffix(line, "|") {
					curr.A = curr.A + strings.TrimRight(line, "|")
				} else {
					curr.A = curr.A + line
					for scanner.Scan() {
						lineTip := strings.TrimSpace(scanner.Text())
						if len(lineTip) == 0 {
							continue
						}
						curr.Tip = lineTip
						break
					}
					segments = append(segments, curr)
					curr = &segment{}
				}
			}
			offset++
		}
	}
	if len(segments) != 0 {
		millis := timeRangeToMillis(segments[0].Start)
		segments[0].Start = forStart(millis, 500)
		millis = timeRangeToMillis(segments[len(segments)-1].End)
		segments[len(segments)-1].End = forEnd(millis, 500)

		for i := 1; i < len(segments); i++ {
			pe := timeRangeToMillis(segments[i-1].End)
			cs := timeRangeToMillis(segments[i].Start)
			middleGap := (cs - pe) / 2
			middleGap -= 50
			if middleGap < 0 {
				continue
			}
			if middleGap > 500 {
				middleGap = 500
			}
			segments[i].Start = forStart(cs, middleGap)
			segments[i-1].End = forEnd(pe, middleGap)
		}
	}

	out, _ := json.MarshalIndent(segments, "", "  ")
	fmt.Print(string(out))
}
func forStart(millis, duration int) string {
	millis -= duration
	if millis < 0 {
		millis = 0
	}
	return millisToTimeRange(millis)
}
func forEnd(millis, duration int) string {
	millis += duration
	return millisToTimeRange(millis)
}
func timeRangeToMillis(timeStr string) int {
	parts := strings.Split(timeStr, ":")
	secParts := strings.Split(parts[2], ",")
	hour, _ := strconv.Atoi(parts[0])
	min, _ := strconv.Atoi(parts[1])
	sec, _ := strconv.Atoi(secParts[0])
	millisec, _ := strconv.Atoi(secParts[1])
	return hour*3600000 + min*60000 + sec*1000 + millisec
}

// Convert milliseconds to time string format (hh:mm:ss,mmm)
func millisToTimeRange(millis int) string {
	hour := millis / 3600000
	min := (millis % 3600000) / 60000
	sec := (millis % 60000) / 1000
	millisec := millis % 1000
	return fmt.Sprintf("%02d:%02d:%02d,%03d", hour, min, sec, millisec)
}
