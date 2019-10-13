package controllers

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"strconv"

	firebase "firebase.google.com/go"
	"github.com/gorilla/mux"
	"github.com/harehare/textusm/server/middleware"
	"github.com/harehare/textusm/server/models"
	"github.com/harehare/textusm/server/services"
)

type addUserRequest struct {
	DiaramID string `json:"diagram_id"`
	Mail     string `json:"mail"`
}

type updateUserRequest struct {
	DiaramID string `json:"diagram_id"`
	Role     string `json:"role"`
}

type addUserResponse struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	PhotoURL string `json:"photo_url"`
	Role     string `json:"role"`
	Mail     string `json:"mail"`
}

type updateUserResponse struct {
	ID   string `json:"id"`
	Role string `json:"role"`
}

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

	uid := r.Context().Value(middleware.UIDKey)

	if q != "" {
		items, err = services.Search(uid.(string), q, page)
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

func Item(app *firebase.App) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		client, err := app.Auth(ctx)

		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		vars := mux.Vars(r)
		uid := ctx.Value(middleware.UIDKey)
		item, err := services.GetItem(uid.(string), vars["ID"])

		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		users := []models.User{}
		for _, i := range item.Users {
			u, err := client.GetUser(ctx, i.ID)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			users = append(users, models.User{ID: i.ID, Name: u.DisplayName, PhotoURL: u.PhotoURL, Mail: u.Email, Role: i.Role})
		}

		item.Users = users
		res, err := json.Marshal(item)

		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.Write(res)
	}
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
	err = services.Save(uid.(string), &item)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func AddUserToDiagram(app *firebase.App) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		b, err := ioutil.ReadAll(r.Body)
		defer r.Body.Close()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		var req addUserRequest

		err = json.Unmarshal(b, &req)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		client, err := app.Auth(r.Context())
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		u, err := client.GetUserByEmail(r.Context(), req.Mail)
		if err != nil {
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}
		uid := r.Context().Value(middleware.UIDKey)
		err = services.AddUserToDiagram(uid.(string), u.UID, req.DiaramID)

		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		res := addUserResponse{
			ID:       u.UID,
			Name:     u.DisplayName,
			PhotoURL: u.PhotoURL,
			Role:     models.RoleViewer,
			Mail:     u.Email,
		}
		// TODO: send mail
		jsonRes, err := json.Marshal(res)

		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.Write(jsonRes)
	}
}

func UpdateRole(w http.ResponseWriter, r *http.Request) {
	b, err := ioutil.ReadAll(r.Body)
	defer r.Body.Close()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var req updateUserRequest

	err = json.Unmarshal(b, &req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	vars := mux.Vars(r)
	uid := r.Context().Value(middleware.UIDKey)
	err = services.UpdateRole(uid.(string), vars["ID"], req.DiaramID, req.Role)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	res := updateUserResponse{ID: vars["ID"], Role: req.Role}

	jsonRes, err := json.Marshal(res)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Write(jsonRes)
}

func DeleteUser(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	uid := r.Context().Value(middleware.UIDKey)
	err := services.DeleteUser(uid.(string), vars["ID"], vars["DiagramID"])

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
