package main

import (
	"crypto/rand"
	"fmt"
	"html/template"
	"io/ioutil"
	"log"
	"mime"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

const maxUploadSize = 100 * 1024 * 1024 // 100 mb
var uploadPath = "./"

func main() {
	http.HandleFunc("/upload", uploadFileHandler())

	fs := http.FileServer(http.Dir("./"))
	http.Handle("/files/", http.StripPrefix("/files", fs))

	log.Print("Server started on localhost:18139, use /upload for uploading files and /files/{fileName} for downloading")
	log.Fatal(http.ListenAndServe(":18139", nil))
}

func uploadFileHandler() http.HandlerFunc {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == "GET" {
			t, _ := template.ParseFiles("upload.gtpl")
			t.Execute(w, nil)
			return
		}
		if err := r.ParseMultipartForm(maxUploadSize); err != nil {
			fmt.Printf("Could not parse multipart form: %v\n", err)
			renderError(w, "CANT_PARSE_FORM", http.StatusInternalServerError)
			return
		}

		// parse and validate file and post parameters
		file, fileHeader, err := r.FormFile("file")
		if err != nil {
			renderError(w, "INVALID_FILE", http.StatusBadRequest)
			return
		}
		defer file.Close()
		// Get and print out file size
		fileSize := fileHeader.Size
		fmt.Printf("File size (bytes): %v\n", fileSize)
		// validate file size
		if fileSize > maxUploadSize {
			renderError(w, "FILE_TOO_BIG", http.StatusBadRequest)
			return
		}
		fileBytes, err := ioutil.ReadAll(file)
		if err != nil {
			renderError(w, "INVALID_FILE", http.StatusBadRequest)
			return
		}

		// check file type, detectcontenttype only needs the first 512 bytes
		detectedFileType := http.DetectContentType(fileBytes)
		fileName := strconv.FormatInt(time.Now().UnixNano(), 36)
		fileEndings, err := mime.ExtensionsByType(detectedFileType)
		if err != nil {
			renderError(w, "CANT_READ_FILE_TYPE", http.StatusInternalServerError)
			return
		}

		newFileName := fileName + fileEndings[0]
		newPath := filepath.Join(uploadPath, newFileName)
		fmt.Printf("FileType: %s, File: %s\n", detectedFileType, newPath)

		// write file
		newFile, err := os.Create(newPath)
		if err != nil {
			renderError(w, "CANT_WRITE_FILE", http.StatusInternalServerError)
			return
		}
		defer newFile.Close() // idempotent, okay to call twice
		if _, err := newFile.Write(fileBytes); err != nil || newFile.Close() != nil {
			renderError(w, "CANT_WRITE_FILE", http.StatusInternalServerError)
			return
		}
		w.Write([]byte(fmt.Sprintf("SUCCESS - use /files/%v or /files/%v to access the file", newFileName, fileHeader.Filename)))
		// copy
		copyPath := filepath.Join(uploadPath, fileHeader.Filename)
		if err := copyFile(newPath, copyPath); err != nil {
			renderError(w, "CANT_COPY_FILE", http.StatusInternalServerError)
			return
		}
	})
}
func copyFile(src, dst string) error {
	input, err := ioutil.ReadFile(src)
	if err != nil {
		return err
	}

	err = ioutil.WriteFile(dst, input, 0644)
	if err != nil {
		return err
	}

	return nil
}
func renderError(w http.ResponseWriter, message string, statusCode int) {
	w.WriteHeader(statusCode)
	w.Write([]byte(message))
}

func randToken(len int) string {
	b := make([]byte, len)
	rand.Read(b)
	return fmt.Sprintf("%x", b)
}
