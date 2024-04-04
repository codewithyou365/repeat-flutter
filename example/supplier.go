package main

import (
	"net/http"
)

func main() {
	err := http.ListenAndServe("0.0.0.0:18139", http.FileServer(http.Dir("./")))
	if err != nil {
		panic(err)
	}
}
