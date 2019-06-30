package controllers

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/harehare/textusm/middleware"
	"github.com/harehare/textusm/models"
	"github.com/harehare/textusm/services"
)

func Search(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query().Get("q")
	pageNo := r.URL.Query().Get("page")

	var items *[]models.ItemDto
	var page services.Page

	i, err := strconv.Atoi(pageNo)

	if err != nil {
		page = services.NewPage(1)
	} else {
		page = services.NewPage(i)
	}

	if q != "" {
		items, err = services.Search(q, page)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	} else {
		items = &[]models.ItemDto{}
	}

	res, err := json.Marshal(items)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Write(res)
}

func Item(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	uid := r.Context().Value(middleware.UIDKey)
	item, err := services.GetItem(uid.(string), vars["ID"])

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	res, err := json.Marshal(item)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Write(res)
}

func Items(w http.ResponseWriter, r *http.Request) {
	pageNo := r.URL.Query().Get("page")
	var page services.Page

	i, err := strconv.Atoi(pageNo)

	if err != nil {
		page = services.NewPage(1)
	} else {
		page = services.NewPage(i)
	}

	uid := r.Context().Value(middleware.UIDKey)
	items, err := services.GetItems(uid.(string), page)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	res, err := json.Marshal(items)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Write(res)
}

func PublicItems(w http.ResponseWriter, r *http.Request) {
	pageNo := r.URL.Query().Get("page")
	var page services.Page

	i, err := strconv.Atoi(pageNo)

	if err != nil {
		page = services.NewPage(1)
	} else {
		page = services.NewPage(i)
	}

	items, err := services.GetPublicItems(page)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	res, err := json.Marshal(items)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Write(res)
}

func Remove(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	uid := r.Context().Value(middleware.UIDKey)
	err := services.Remove(uid.(string), vars["ID"])

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func Save(w http.ResponseWriter, r *http.Request) {
	b, err := ioutil.ReadAll(r.Body)
	defer r.Body.Close()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var item models.Item

	err = json.Unmarshal(b, &item)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	uid := r.Context().Value(middleware.UIDKey)
	item.OwnerID = uid.(string)

	err = services.Save(&item)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
