package export

import (
	"context"
	"encoding/json"
	"log"
	"net/http"

	"github.com/harehare/textusm/server/models"
)

type Exporter interface {
	CreateProject(ctx context.Context, data *models.UsmData) error
	CreateList(ctx context.Context, data *models.UsmData, release models.Release) error
	CreateCard(ctx context.Context, data *models.UsmData, task models.Task) error
	CreateURL(data *models.UsmData) string
}

func Export(data *models.UsmData, e Exporter, w http.ResponseWriter, r *http.Request) {
	res := models.Response{Total: 0, Failed: 0, Successful: 0, Url: ""}
	ctx := context.Background()
	err := e.CreateProject(ctx, data)

	if err != nil {
		log.Println(err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	setResult(&res, err)

	for _, release := range data.Releases {

		err = e.CreateList(ctx, data, release)

		if err != nil {
			log.Println(err)
			http.Error(w, err.Error(), http.StatusBadRequest)
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
		log.Println(err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
	} else {
		w.Write(b)
	}
}

func setResult(res *models.Response, err error) {
	if err != nil {
		log.Println(err)
		res.Failed++
	} else {
		res.Successful++
	}
	res.Total++
}
