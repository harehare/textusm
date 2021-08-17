package settings

type Settings struct {
	Font            string   `json:"font"`
	Width           int      `json:"width"`
	Height          int      `json:"height"`
	BackgroundColor string   `json:"BackgroundColor"`
	ActivityColor   Color    `json:"activityColor"`
	TaskColor       Color    `json:"taskColor"`
	StoryColor      Color    `json:"storyColor"`
	LineColor       string   `json:"lineColor"`
	LabelColor      string   `json:"labelColor"`
	TextColor       *string  `json:"textColor"`
	ZoomControl     *bool    `json:"zoomControl"`
	Scale           *float64 `json:"scale"`
}

type Color struct {
	ForegroundColor string `json:"foregroundColor"`
	BackgroundColor string `json:"backgroundColor"`
}
