package main

import (
	"net/http"
)

func main() {
	err := http.ListenAndServe(":18139", http.FileServer(http.Dir("./")))
	if err != nil {
		panic(err)
	}
}
