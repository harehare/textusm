package firebase

import (
	"bytes"
	"compress/gzip"
	"context"
	"errors"
	"io"
	"strings"

	"cloud.google.com/go/storage"
	firebaseStorage "firebase.google.com/go/v4/storage"
	"github.com/samber/mo"
)

type CloudStorage struct {
	client *firebaseStorage.Client
}

func NewCloudStorage(client *firebaseStorage.Client) CloudStorage {
	return CloudStorage{client: client}
}

func getObjectName(prefix string, paths ...string) string {
	return prefix + "/" + strings.Join(paths, "/") + ".txt.gz"
}

func (s *CloudStorage) Put(ctx context.Context, text *string, prefix string, paths ...string) mo.Result[bool] {
	bucket, err := s.client.DefaultBucket()

	if err != nil {
		return mo.Err[bool](err)
	}

	var gb bytes.Buffer
	gw := gzip.NewWriter(&gb)
	if _, err = gw.Write([]byte(*text)); err != nil {
		return mo.Err[bool](err)
	}

	defer gw.Close()

	if err := gw.Flush(); err != nil {
		return mo.Err[bool](err)
	}

	ow := bucket.Object(getObjectName(prefix, paths...)).NewWriter(ctx)
	ow.ContentType = "application/x-gzip"

	defer ow.Close()

	_, err = ow.Write(gb.Bytes())

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}

func (s *CloudStorage) Get(ctx context.Context, prefix string, paths ...string) mo.Result[string] {
	bucket, err := s.client.DefaultBucket()

	if err != nil {
		return mo.Err[string](err)
	}

	or, err := bucket.Object(getObjectName(prefix, paths...)).NewReader(ctx)

	if err != nil {
		return mo.Err[string](err)
	}

	defer or.Close()

	gr, err := gzip.NewReader(or)

	if err != nil {
		return mo.Err[string](err)
	}

	gr.Multistream(false)
	defer gr.Close()
	body, err := io.ReadAll(gr)

	if err != nil {
		return mo.Err[string](err)
	}

	return mo.Ok(string(body))
}

func (s *CloudStorage) Delete(ctx context.Context, prefix, uid, itemID string) mo.Result[bool] {
	bucket, err := s.client.DefaultBucket()

	if err != nil {
		return mo.Err[bool](err)
	}

	if err = bucket.Object(getObjectName(prefix, uid, itemID)).Delete(ctx); err != nil {
		if ok := errors.Is(err, storage.ErrObjectNotExist); ok {
			return mo.Ok(true)
		}

		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}
