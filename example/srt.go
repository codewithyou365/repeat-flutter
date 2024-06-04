package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"strings"
)

const QaMode = "qa"
const NormalMode = ""

type segment struct {
	QStart string `json:"qStart,omitempty"`
	QEnd   string `json:"qEnd,omitempty"`
	Q      string `json:"q,omitempty"`
	AStart string `json:"aStart,omitempty"`
	AEnd   string `json:"aEnd,omitempty"`
	Tip    string `json:"tip,omitempty"`
	A      string `json:"a,omitempty"`
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
	mode := ""
	modeOffset := 0
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if mode == "" {
			if line == QaMode {
				mode = QaMode
				continue
			} else {
				mode = NormalMode
			}
		}
		if len(line) == 0 {
			continue
		} else {
			if offset%3 == 1 {
				if mode == QaMode {
					if modeOffset%2 == 0 {
						se := strings.Split(line, "-->")
						if curr.QStart == "" {
							curr.QStart = strings.TrimSpace(se[0])
						}
						curr.QEnd = strings.TrimSpace(se[1])
					} else {
						se := strings.Split(line, "-->")
						if curr.AStart == "" {
							curr.AStart = strings.TrimSpace(se[0])
						}
						curr.AEnd = strings.TrimSpace(se[1])
					}
				} else {
					se := strings.Split(line, "-->")
					if curr.AStart == "" {
						curr.AStart = strings.TrimSpace(se[0])
					}
					curr.AEnd = strings.TrimSpace(se[1])
				}
			}
			if offset%3 == 2 {
				if mode == QaMode {
					if modeOffset%2 == 0 {
						if strings.HasSuffix(line, "|") {
							curr.Q = curr.Q + strings.TrimRight(line, "|")
						} else {
							curr.Q = curr.Q + line
							modeOffset++
						}
					} else {
						if strings.HasSuffix(line, "|") {
							curr.A = curr.A + strings.TrimRight(line, "|")
						} else {
							curr.A = curr.A + line
							segments = append(segments, curr)
							curr = &segment{}
							modeOffset++
						}
					}
				} else {
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
			}
			offset++
		}
	}
	if len(segments) != 0 {
		{
			millis := timeRangeToMillis(segments[0].AStart)
			segments[0].AStart = forStart(millis, 500)
			millis = timeRangeToMillis(segments[len(segments)-1].AEnd)
			segments[len(segments)-1].AEnd = forEnd(millis, 500)

			for i := 1; i < len(segments); i++ {
				pe := timeRangeToMillis(segments[i-1].AEnd)
				cs := timeRangeToMillis(segments[i].AStart)
				middleGap := (cs - pe) / 2
				middleGap -= 50
				if middleGap < 0 {
					continue
				}
				if middleGap > 500 {
					middleGap = 500
				}
				segments[i].AStart = forStart(cs, middleGap)
				segments[i-1].AEnd = forEnd(pe, middleGap)
			}
		}
		if mode == QaMode {
			millis := timeRangeToMillis(segments[0].QStart)
			segments[0].QStart = forStart(millis, 500)
			millis = timeRangeToMillis(segments[len(segments)-1].QEnd)
			segments[len(segments)-1].QEnd = forEnd(millis, 500)

			for i := 1; i < len(segments); i++ {
				pe := timeRangeToMillis(segments[i-1].QEnd)
				cs := timeRangeToMillis(segments[i].QStart)
				middleGap := (cs - pe) / 2
				middleGap -= 50
				if middleGap < 0 {
					continue
				}
				if middleGap > 500 {
					middleGap = 500
				}
				segments[i].QStart = forStart(cs, middleGap)
				segments[i-1].QEnd = forEnd(pe, middleGap)
			}
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
