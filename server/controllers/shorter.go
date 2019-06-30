package controllers

import (
	"io/ioutil"
	"net/http"
	"os"
	"time"
)

func Shorter(w http.ResponseWriter, r *http.Request) {
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	req, err := http.NewRequest("POST", "https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key="+os.Getenv("FIREBASE_API_KEY"), r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	resp, err := client.Do(req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Write(data)
}
