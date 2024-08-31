package config

import (
	"log/slog"

	"github.com/kelseyhightower/envconfig"
)

type Env struct {
	Version             string `required:"true" envconfig:"API_VERSION"`
	Port                string `required:"true" envconfig:"PORT"`
	Credentials         string `required:"false" envconfig:"GOOGLE_APPLICATION_CREDENTIALS_JSON"`
	DatabaseCredentials string `required:"false" envconfig:"DATABASE_GOOGLE_APPLICATION_CREDENTIALS_JSON"`
	GithubClientID      string `envconfig:"GITHUB_CLIENT_ID"  default:""`
	GithubClientSecret  string `envconfig:"GITHUB_CLIENT_SECRET"  default:""`
	StorageBucketName   string `required:"true" envconfig:"STORAGE_BUCKET_NAME"`
	GoEnv               string `required:"true" envconfig:"GO_ENV"`
	RedisUrl            string `required:"false" envconfig:"REDIS_URL"`
}

func NewEnv() (*Env, error) {
	var env Env
	err := envconfig.Process("", &env)

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return nil, err
	}

	return &env, nil
}
