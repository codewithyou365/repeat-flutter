package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

type segment struct {
	Start string `json:"start"`
	End   string `json:"end"`
	Q     string `json:"q"`
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
						lineQ := strings.TrimSpace(scanner.Text())
						if len(lineQ) == 0 {
							continue
						}
						curr.Q = lineQ
						break
					}
					segments = append(segments, curr)
					curr = &segment{}
				}
			}
			offset++
		}
	}
	out, _ := json.MarshalIndent(segments, "", "  ")
	fmt.Print(string(out))
}
