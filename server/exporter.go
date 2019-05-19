package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
)

type Exporter interface {
	CreateProject(ctx context.Context, data *UsmData) error
	CreateList(ctx context.Context, data *UsmData, release Release) error
	CreateCard(ctx context.Context, data *UsmData, task Task) error
	CreateURL(data *UsmData) string
}

func Export(data *UsmData, e Exporter, w http.ResponseWriter, r *http.Request) {
	res := Response{Total: 0, Failed: 0, Successful: 0, Url: ""}
	ctx := context.Background()
	err := e.CreateProject(ctx, data)

	if err != nil {
		log.Println(err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	setResult(&res, err)

	for _, release := range data.Releases {

		err = e.CreateList(ctx, data, release)

		if err != nil {
			log.Println(err)
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		setResult(&res, err)
	}

	for _, task := range data.Tasks {
		err = e.CreateCard(ctx, data, task)
		setResult(&res, err)
	}

	res.Url = e.CreateURL(data)
	b, err := json.Marshal(res)

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
	} else {
		w.Write(b)
	}
}
