package firebase

import (
	"bytes"
	"compress/gzip"
	"context"
	"io"

	firebaseStorage "firebase.google.com/go/storage"
	"github.com/samber/mo"
)

type CloudStorage struct {
	client *firebaseStorage.Client
}

func NewCloudStorage(client *firebaseStorage.Client) CloudStorage {
	return CloudStorage{client: client}
}

func getObjectName(uid, itemID string) string {
	return uid + "/" + itemID + ".txt.gz"
}

func (s *CloudStorage) Put(ctx context.Context, uid, itemID string, text *string) mo.Result[bool] {
	bucket, err := s.client.DefaultBucket()

	if err != nil {
		return mo.Err[bool](err)
	}

	var gb bytes.Buffer
	gw := gzip.NewWriter(&gb)
	if _, err = gw.Write([]byte(*text)); err != nil {
		gw.Close()
		return mo.Err[bool](err)
	}

	if err := gw.Flush(); err != nil {
		gw.Close()
		return mo.Err[bool](err)
	}
	gw.Close()

	ow := bucket.Object(getObjectName(uid, itemID)).NewWriter(ctx)
	ow.ContentType = "application/x-gzip"
	_, err = ow.Write(gb.Bytes())

	if err != nil {
		return mo.Err[bool](err)
	}

	if err := ow.Close(); err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}

func (s *CloudStorage) Get(ctx context.Context, uid, itemID string) mo.Result[string] {
	bucket, err := s.client.DefaultBucket()

	if err != nil {
		return mo.Err[string](err)
	}

	or, err := bucket.Object(getObjectName(uid, itemID)).NewReader(ctx)

	if err != nil {
		return mo.Err[string](err)
	}

	defer or.Close()

	if err != nil {
		return mo.Err[string](err)
	}

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

func (s *CloudStorage) Delete(ctx context.Context, uid, itemID string) mo.Result[bool] {
	bucket, err := s.client.DefaultBucket()

	if err != nil {
		return mo.Err[bool](err)
	}

	if err = bucket.Object(getObjectName(uid, itemID)).Delete(ctx); err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}
