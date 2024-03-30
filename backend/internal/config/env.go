package config

import (
	"log/slog"

	"github.com/kelseyhightower/envconfig"
)

type Env struct {
	Host                string `envconfig:"API_HOST"`
	Version             string `required:"true" envconfig:"API_VERSION"`
	Port                string `required:"true" envconfig:"PORT"`
	Credentials         string `required:"true" envconfig:"GOOGLE_APPLICATION_CREDENTIALS_JSON"`
	DatabaseCredentials string `required:"true" envconfig:"DATABASE_GOOGLE_APPLICATION_CREDENTIALS_JSON"`
	TlsCertFile         string `envconfig:"TLS_CERT_FILE" default:""`
	TlsKeyFile          string `envconfig:"TLS_KEY_FILE"  default:""`
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
