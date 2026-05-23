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
	DatabaseURL         string `required:"false" envconfig:"DATABASE_URL"`
	GithubClientID      string `envconfig:"GITHUB_CLIENT_ID"  default:""`
	GithubClientSecret  string `envconfig:"GITHUB_CLIENT_SECRET"  default:""`
	StorageBucketName   string `required:"false" envconfig:"STORAGE_BUCKET_NAME"`
	GoEnv               string `required:"true" envconfig:"GO_ENV"`
	DBType              string `required:"false" envconfig:"DB_TYPE"`
	DBMaxConns          int32  `envconfig:"DB_MAX_CONNS" default:"10"`
	DBMinConns          int32  `envconfig:"DB_MIN_CONNS" default:"2"`
	ShareEncryptKey     string `required:"false" envconfig:"SHARE_ENCRYPT_KEY"`
	EncryptPublicKey    string `required:"false" envconfig:"ENCRYPT_PUBLIC_KEY"`
	EncryptPrivateKey   string `required:"false" envconfig:"ENCRYPT_PRIVATE_KEY"`
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
