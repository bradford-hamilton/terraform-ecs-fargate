package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/go-chi/chi"
)

func main() {
	var err error
	time.Local, err = time.LoadLocation("America/New_York")
	if err != nil {
		panic("timezone not loaded!")
	}

	mux := chi.NewRouter()
	mux.Get("/health", health)
	mux.Get("/", handler)

	log.Println("listening on :3000")
	http.ListenAndServe(":3000", mux)
}

func health(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("ok " + time.Now().Format(time.RFC3339)))
}

func handler(w http.ResponseWriter, r *http.Request) {
	var lat = r.URL.Query().Get("lat")
	if lat == "" {
		lat = "41.495833"
	}

	var lng = r.URL.Query().Get("lng")
	if lng == "" {
		lng = "-81.685278"
	}

	var date, _ = time.Parse(time.RFC3339, r.URL.Query().Get("date"))
	if date.IsZero() {
		date = time.Now()
	}

	u := fmt.Sprintf(
		"https://api.sunrise-sunset.org/json?lat=%s&lng=%s&date=%s&formatted=0",
		lat,
		lng,
		date.Format("2006-01-02"),
	)

	log.Println("sending request to", u)

	resp, err := http.Get(u)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("couldn't make http request"))
		return
	}

	var target struct {
		Status  string `json:"status"`
		Results struct {
			Sunrise   time.Time `json:"sunrise"`
			Sunset    time.Time `json:"sunset"`
			SolarNoon time.Time `json:"solar_noon"`
		} `json:"results"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&target); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("couldn't decode json"))
		return
	}

	resp.Body.Close()

	out := struct {
		OK        bool   `json:"ok"`
		Date      string `json:"date"`
		Sunrise   string `json:"sunrise"`
		Sunset    string `json:"sunset"`
		SolarNoon string `json:"solar_noon"`
	}{
		OK:        true,
		Date:      date.Format("2006-01-02"),
		Sunrise:   target.Results.Sunrise.In(time.Local).Format("3:04 PM"),
		Sunset:    target.Results.Sunset.In(time.Local).Format("3:04 PM"),
		SolarNoon: target.Results.SolarNoon.In(time.Local).Format("3:04 PM"),
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(out)
}
