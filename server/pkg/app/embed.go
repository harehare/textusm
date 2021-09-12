//go:build embed

package app

import (
	"embed"
	"io"
	"io/fs"
	"net/http"
	"path"
)

//go:embed dist/*
var webResources embed.FS

func EmbedFileServeHandler() func(w http.ResponseWriter, r *http.Request) {
	root, _ := fs.Sub(webResources, "dist")
	fileSystem := http.FileServer(http.FS(root))
	return func(w http.ResponseWriter, r *http.Request) {
		f, err := webResources.Open(path.Join("dist", r.RequestURI))
		if err != nil {
			f, err := fs.FS.Open(webResources, path.Join("dist", "index.html"))
			if err != nil {
				return
			}
			defer f.Close()
			w.Header().Set("Content-Type", "text/html")
			_, err = io.Copy(w, f)
		} else {
			fileSystem.ServeHTTP(w, r)
			defer f.Close()
		}
	}
}
