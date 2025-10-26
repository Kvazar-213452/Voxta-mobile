package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
)

type AvatarRequest struct {
	Avatar string `json:"avatar"`
}

type FileRequest struct {
	File string `json:"file"`
	Name string `json:"name"`
}

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Ошибка загрузки .env файла")
	}

	portStr := os.Getenv("PORT")
	port, err := strconv.Atoi(portStr)
	if err != nil {
		log.Fatal("Неверный порт в переменной PORT")
	}

	r := mux.NewRouter()

	r.HandleFunc("/upload_avatar_base64", uploadAvatarBase64).Methods("POST")
	r.HandleFunc("/upload_file_base64", uploadFileBase64).Methods("POST")

	fs := http.FileServer(http.Dir("./data/"))
	r.PathPrefix("/").Handler(http.StripPrefix("/", fs))

	r.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Hello, Microservice on Go!"))
	}).Methods("GET")

	fmt.Printf("server start %d\n", port)
	log.Fatal(http.ListenAndServe(":"+strconv.Itoa(port), r))
}

func uploadAvatarBase64(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	fmt.Printf("Received request to /upload_avatar_base64\n")

	var req AvatarRequest

	decoder := json.NewDecoder(r.Body)
	if err := decoder.Decode(&req); err != nil {
		fmt.Printf("JSON decode error: %v\n", err)
		http.Error(w, "Invalid JSON: "+err.Error(), http.StatusBadRequest)
		return
	}

	if req.Avatar == "" {
		fmt.Printf("Empty avatar data\n")
		http.Error(w, "No avatar data provided", http.StatusBadRequest)
		return
	}

	fmt.Printf("Avatar data length: %d\n", len(req.Avatar))

	parts := strings.Split(req.Avatar, ",")
	if len(parts) != 2 {
		fmt.Printf("Invalid base64 format, parts: %d\n", len(parts))
		http.Error(w, "Invalid base64 format", http.StatusBadRequest)
		return
	}

	mimeTypePart := parts[0]
	base64Data := parts[1]

	fmt.Printf("MIME type: %s\n", mimeTypePart)

	var extension string
	if strings.Contains(mimeTypePart, "jpeg") || strings.Contains(mimeTypePart, "jpg") {
		extension = ".jpg"
	} else if strings.Contains(mimeTypePart, "png") {
		extension = ".png"
	} else if strings.Contains(mimeTypePart, "gif") {
		extension = ".gif"
	} else {
		fmt.Printf("Unsupported MIME type: %s\n", mimeTypePart)
		http.Error(w, "Unsupported image type", http.StatusBadRequest)
		return
	}

	imageData, err := base64.StdEncoding.DecodeString(base64Data)
	if err != nil {
		fmt.Printf("Base64 decode error: %v\n", err)
		http.Error(w, "Failed to decode base64: "+err.Error(), http.StatusBadRequest)
		return
	}

	fmt.Printf("Decoded image size: %d bytes\n", len(imageData))

	avatarsDir := "data/avatars"
	if err := os.MkdirAll(avatarsDir, 0755); err != nil {
		fmt.Printf("Failed to create directory: %v\n", err)
		http.Error(w, "Failed to create avatars directory", http.StatusInternalServerError)
		return
	}

	uniqueFileName := uuid.New().String() + extension
	filePath := filepath.Join(avatarsDir, uniqueFileName)

	fmt.Printf("Saving to: %s\n", filePath)

	if err := os.WriteFile(filePath, imageData, 0644); err != nil {
		fmt.Printf("Failed to write file: %v\n", err)
		http.Error(w, "Failed to save avatar: "+err.Error(), http.StatusInternalServerError)
		return
	}

	scheme := "http"
	if r.TLS != nil {
		scheme = "https"
	}
	avatarURL := fmt.Sprintf("%s://%s/avatars/%s", scheme, r.Host, uniqueFileName)

	fmt.Printf("Avatar saved successfully: %s\n", avatarURL)

	response := map[string]string{"url": avatarURL}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

func uploadFileBase64(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	fmt.Printf("Received request to /upload_file_base64\n")

	var req FileRequest

	decoder := json.NewDecoder(r.Body)
	if err := decoder.Decode(&req); err != nil {
		fmt.Printf("JSON decode error: %v\n", err)
		http.Error(w, "Invalid JSON: "+err.Error(), http.StatusBadRequest)
		return
	}

	if req.File == "" {
		fmt.Printf("Empty file data\n")
		http.Error(w, "No file data provided", http.StatusBadRequest)
		return
	}

	if req.Name == "" {
		fmt.Printf("Empty file name\n")
		http.Error(w, "No file name provided", http.StatusBadRequest)
		return
	}

	var extension string
	if lastDot := strings.LastIndex(req.Name, "."); lastDot != -1 {
		extension = req.Name[lastDot:]
	} else {
		extension = ""
	}

	var base64Data string
	if strings.Contains(req.File, ",") {
		parts := strings.Split(req.File, ",")
		if len(parts) == 2 {
			base64Data = parts[1]
		} else {
			base64Data = req.File
		}
	} else {
		base64Data = req.File
	}

	fileData, err := base64.StdEncoding.DecodeString(base64Data)
	if err != nil {
		fmt.Printf("Base64 decode error: %v\n", err)
		http.Error(w, "Failed to decode base64: "+err.Error(), http.StatusBadRequest)
		return
	}

	fileDir := "data/file"
	if err := os.MkdirAll(fileDir, 0755); err != nil {
		fmt.Printf("Failed to create directory: %v\n", err)
		http.Error(w, "Failed to create file directory", http.StatusInternalServerError)
		return
	}

	uniqueFileName := uuid.New().String() + extension
	filePath := filepath.Join(fileDir, uniqueFileName)

	if err := os.WriteFile(filePath, fileData, 0644); err != nil {
		fmt.Printf("Failed to write file: %v\n", err)
		http.Error(w, "Failed to save file: "+err.Error(), http.StatusInternalServerError)
		return
	}

	scheme := "http"
	if r.TLS != nil {
		scheme = "https"
	}
	fileURL := fmt.Sprintf("%s://%s/file/%s", scheme, r.Host, uniqueFileName)

	fmt.Printf("File saved successfully: %s\n", fileURL)

	response := map[string]string{"url": fileURL}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}
