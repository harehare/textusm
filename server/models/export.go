package models

type UsmData struct {
	OauthToken string    `json:"oauth_token"`
	Name       string    `json:"name"`
	Releases   []Release `json:"releases"`
	Tasks      []Task    `json:"tasks"`

	OauthVerifier string `json:"oauth_verifier,omitempty"`

	Github Github `json:"github,omitempty"`
}

type Github struct {
	Owner string `json:"owner"`
	Repo  string `json:"repo"`
}

type Release struct {
	Name   string `json:"name"`
	Period string `json:"period"`
}

type Task struct {
	Name    string  `json:"name"`
	Comment string  `json:"comment"`
	Stories []Story `json:"stories"`
}

type Story struct {
	Name    string `json:"name"`
	Comment string `json:"comment"`
	Release int    `json:"release"`
}

type Response struct {
	Total      int    `json:"total"`
	Failed     int    `json:"failed"`
	Successful int    `json:"successful"`
	Url        string `json:"url"`
}