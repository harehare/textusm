package values

type GistID string

func NewGistID(s string) GistID {
	return GistID(s)
}

func (i GistID) String() string {
	return string(i)
}
